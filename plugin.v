module vlightning

import os
import x.json2

pub struct Plugin {
pub mut:
	name    string
	version string

	lightning_dir string
	rpc_file      string
	network       string
	options       map[string]json2.Any
	dynamic       bool

	client Client

	hooks         map[string]HookHandler = map{}
	subscriptions map[string]SubscriptionHandler = map{}
	rpcmethods    map[string]RPCMethod = map{}
	notifications []Notification       = []
}

pub struct RPCMethod {
	usage            string
	description      string
	long_description string
	handler          RPCMethodHandler
}

pub struct Notification {
	method string
}

pub type HookHandler = fn (Plugin, json2.Any) ?json2.Any

pub type SubscriptionHandler = fn (Plugin, json2.Any)

pub type RPCMethodHandler = fn (Plugin, json2.Any) ?json2.Any

pub fn (p Plugin) log(text string) {
	eprintln('[plugin-$p.name] $text')
}

pub fn (mut p Plugin) initialize() {
	p.log('initialized version $p.version')

	mut buffer := ''
	mut value := ''
	for {
		line := os.get_line()

		// c-lightning guarantees that every command will be followed by an empty line
		// so we buffer everything between empty lines and use that as the message
		if line.len == 0 {
			value = buffer
			buffer = ''
		} else {
			buffer += line
			continue
		}

		raw_message := json2.raw_decode(value) or { continue }
		message := raw_message.as_map()
		mut response := map{
			'jsonrpc': json2.Any('2.0')
			'version': message['version'] or { 0 }
			'id':      message['id']
		}
		match message['method'].str() {
			'getmanifest' {
				mut hooks := []json2.Any{len: p.hooks.len, init: &json2.Null{}}
				mut i := 0
				for k, _ in p.hooks {
					hooks[i] = json2.Any(map{
						'name': json2.Any(k)
					})
					i += 1
				}

				mut subs := []json2.Any{len: p.subscriptions.len, init: &json2.Null{}}
				i = 0
				for k, _ in p.subscriptions {
					subs[i] = json2.Any([json2.Any(k)])
					i += 1
				}

				mut rpcmethods := []json2.Any{len: p.rpcmethods.len, init: &json2.Null{}}
				i = 0
				for name, defs in p.rpcmethods {
					rpcmethods[i] = json2.Any(map{
						'name':             json2.Any(name)
						'usage':            json2.Any(defs.usage)
						'description':      json2.Any(defs.description)
						'long_description': json2.Any(defs.long_description)
					})
					i += 1
				}

				mut ntopics := []json2.Any{len: p.notifications.len, init: &json2.Null{}}
				i = 0
				for notification in p.notifications {
					ntopics[i] = json2.Any(map{
						'method': json2.Any(notification.method)
					})
					i += 1
				}
				mut result := map[string]json2.Any{}
				result['options'] = json2.Any([]json2.Any{cap: 0})
				result['rpcmethods'] = rpcmethods
				result['hooks'] = hooks
				result['subscriptions'] = subs
				result['features'] = json2.Any('')
				result['dynamic'] = p.dynamic
				result['notifications'] = ntopics

				response['result'] = result
			}
			'init' {
				params := message['params'].as_map()
				conf := params['configuration'].as_map()
				p.lightning_dir = conf['lightning-dir'].str()
				p.rpc_file = conf['rpc-file'].str()
				p.network = conf['network'].str()
				p.client = Client{p.lightning_dir + '/' + p.rpc_file}
				p.options = message['options'].as_map()
			}
			else {
				method := message['method'].str()
				for {
					if method in p.hooks {
						hook := p.hooks[method]
						if result := hook(p, message['params']) {
							response['result'] = result
						} else {
							response['error'] = map{
								'code':    json2.Any(err.code)
								'message': json2.Any(err.msg)
							}
						}
						break
					}

					if method in p.subscriptions {
						subs := p.subscriptions[method]
						subs(p, message['params'])
						break
					}

					if method in p.rpcmethods {
						defs := p.rpcmethods[method]
						handler := defs.handler

						// params may be an array or a dict
						params := parse_params(defs.usage, message['params']) or {
							response['error'] = json2.Any(map{
								'code':    json2.Any(err.code)
								'message': json2.Any(err.msg)
							})
							break
						}

						if result := handler(p, params) {
							response['result'] = result
						} else {
							response['error'] = map{
								'code':    json2.Any(err.code)
								'message': json2.Any(err.msg)
							}
						}
						break
					}

					break
				}
			}
		}

		print(response)
		os.flush()
	}
}

fn parse_params(template string, params json2.Any) ?map[string]json2.Any {
	if params is map[string]json2.Any {
		return params
	}

	if params is []json2.Any {
		mut map_params := map[string]json2.Any{}
		param_names := template.replace('[', '').replace(']', '').split(' ')
		for p, param in params {
			if param_names.len > p {
				map_params[param_names[p]] = param
			}
		}
		return map_params
	}

	return error('params is not an array nor a map: $params'), 400
}
