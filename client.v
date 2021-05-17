module vlightning

import x.json2
import net.unix

pub struct Client {
	path string
}

pub fn (c Client) call(method string, params ...json2.Any) ?json2.Any {
	mut params_to_use := json2.Any(json2.Null{})
	if params.len == 1 && params[0] is map[string]json2.Any {
		params_to_use = params[0]
	} else {
		params_to_use = json2.Any(params)
	}

	mut stream := unix.connect_stream(c.path) or {
		panic("can't use client because $c.path is not usable: $err.msg")
	}
	command := json2.Any(map{
		'jsonrpc': json2.Any('2.0')
		'version': json2.Any(2)
		'id':      json2.Any(0)
		'method':  json2.Any(method)
		'params':  params_to_use
	})
	stream.write_string(command.json_str()) or {
		panic('failed to write to unix socket $c.path: $err.msg')
	}

	mut raw := ''
	mut n := 4096
	for n == 4096 {
		mut response := []byte{len: 4096}
		n = stream.read(mut response) ?
		raw += response.bytestr()
		raw = raw[0..raw.index_byte(0)]
	}

	ival := json2.raw_decode(raw) or { return error('error decoding $raw: $err.msg') }
	val := ival.as_map()
	if 'error' in val {
		return error(val['error'].as_map()['message'].str())
	}

	return val['result'] or {
		map[string]json2.Any{}
	}
}
