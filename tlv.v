module vlightning

import encoding.binary

pub const (
	tlv_amount_to_forward    = 2
	tlv_outgoing_cltv        = 4
	tlv_outgoing_channel_id  = 6
	tlv_payment_data         = 8

	tlv_invoice_features     = 66097
	tlv_outgoing_node_id     = 66098
	tlv_invoice_routing_info = 66099
	tlv_trampoline_onion     = 66100

	tlv_keysend              = 5482373484
)

pub fn encode_bigsize(data int) []byte {
	if data < 0xfd {
		mut x := []byte{len: 1}
		x[0] = byte(data)
		return x
	} else if data < 0x10000 {
		mut x := []byte{len: 2}
		binary.big_endian_put_u16(mut x, u16(data))
		mut xx := []byte{len: 3}
		xx[0] = 0xfd
		xx << x
		return xx
	} else if data < 0x100000000 {
		mut x := []byte{len: 4}
		binary.big_endian_put_u32(mut x, u32(data))
		mut xx := []byte{len: 5}
		xx[0] = 0xfe
		xx << x
		return xx
	} else {
		mut x := []byte{len: 8}
		binary.big_endian_put_u64(mut x, u64(data))
		mut xx := []byte{len: 9}
		xx[0] = 0xff
		return xx
	}
}

pub fn encode_tu16(data u16) []byte {
	mut tmp := []byte{len: 2, init: `0`}
	binary.big_endian_put_u16(mut tmp, data)
	mut truncated := []byte{}
	if data < 0x01 {
		truncated = []
	} else if data < 0x0100 {
		truncated = tmp[1..]
	} else {
		truncated = tmp.clone()
	}

	return truncated
}

pub fn encode_tu32(data u32) []byte {
	mut tmp := []byte{len: 4, init: `0`}
	binary.big_endian_put_u32(mut tmp, data)

	mut truncated := []byte{}

	if data < 0x01 {
		truncated = []
	} else if data < 0x0100 {
		truncated = tmp[3..]
	} else if data < 0x010000 {
		truncated = tmp[2..]
	} else if data < 0x01000000 {
		truncated = tmp[1..]
	} else {
		truncated = tmp.clone()
	}

	return truncated
}

pub fn encode_tu64(data u64) []byte {
	mut tmp := []byte{len: 8, init: `0`}
	binary.big_endian_put_u64(mut tmp, data)

	mut truncated := []byte{}

	if data < 0x01 {
		truncated = []
	} else if data < 0x0100 {
		truncated = tmp[7..]
	} else if data < 0x010000 {
		truncated = tmp[6..]
	} else if data < 0x01000000 {
		truncated = tmp[5..]
	} else if data < 0x0100000000 {
		truncated = tmp[4..]
	} else if data < 0x010000000000 {
		truncated = tmp[3..]
	} else if data < 0x01000000000000 {
		truncated = tmp[2..]
	} else if data < 0x0100000000000000 {
		truncated = tmp[1..]
	} else {
		truncated = tmp.clone()
	}

	return truncated
}
