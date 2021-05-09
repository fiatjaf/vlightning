import encoding.binary

pub interface Decodable {
	decode([]byte) ?int
}

pub interface Encodable {
	encode() []byte
}

pub struct Reader {
pub:
	buf []byte
mut:
	pos int
}

pub struct Writer {
pub mut:
	buf []byte
}

fn (mut r Reader) read_32(mut ba [32]byte) ? {
	next := r.pos + 32
	if r.buf.len < next {
		return error('buffer has less than 32 remaining bytes ($r.buf.len)')
	}
	for i, b in r.buf[r.pos..next] {
		ba[i] = b
	}
	r.pos = next
}

fn (mut r Reader) read_64(mut ba [64]byte) ? {
	next := r.pos + 64
	if r.buf.len < next {
		return error('buffer has less than 64 remaining bytes ($r.buf.len)')
	}
	for i, b in r.buf[r.pos..next] {
		ba[i] = b
	}
	r.pos = next
}

fn (mut r Reader) read_1366(mut ba [1366]byte) ? {
	next := r.pos + 1366
	if r.buf.len < next {
		return error('buffer has less than 1366 remaining bytes ($r.buf.len)')
	}
	for i, b in r.buf[r.pos..next] {
		ba[i] = b
	}
	r.pos = next
}

fn (mut r Reader) read_bool() ?bool {
	next := r.pos + 1
	if r.buf.len < next {
		return error('buffer has less than 1 remaining bytes ($r.buf.len)')
	}
	res := r.buf[r.pos] != `0`
	r.pos = next
	return res
}

fn (mut r Reader) read_u16() ?u16 {
	next := r.pos + 2
	if r.buf.len < next {
		return error('buffer has less than 2 remaining bytes ($r.buf.len)')
	}
	res := binary.big_endian_u16(r.buf[r.pos..next])
	r.pos = next
	return res
}

fn (mut r Reader) read_u32() ?u32 {
	next := r.pos + 4
	if r.buf.len < next {
		return error('buffer has less than 2 remaining bytes ($r.buf.len)')
	}
	res := binary.big_endian_u32(r.buf[r.pos..next])
	r.pos = next
	return res
}

fn (mut r Reader) read_u64() ?u64 {
	next := r.pos + 8
	if r.buf.len < next {
		return error('buffer has less than 8 remaining bytes ($r.buf.len)')
	}
	res := binary.big_endian_u64(r.buf[r.pos..next])
	r.pos = next
	return res
}

fn (mut r Reader) read_dynamic() ?[]byte {
	size := r.read_u16() ?
	next := r.pos + size
	if r.buf.len < next {
		return error('buffer has less than the required $size bytes remaining ($r.buf.len)')
	}
	res := r.buf[r.pos..next]
	r.pos = next
	return res
}

fn (mut r Reader) read_decodable(mut dec Decodable) ?int {
	size := dec.decode(r.buf[r.pos..]) ?
	r.pos += size
	return size
}

fn (mut w Writer) write_32(data [32]byte) {
	mut tmp := []byte{len: 32, init: `0`}
	for i, b in data {
		tmp[i] = b
	}
	w.buf << tmp
}

fn (mut w Writer) write_64(data [64]byte) {
	mut tmp := []byte{len: 64, init: `0`}
	for i, b in data {
		tmp[i] = b
	}
	w.buf << tmp
}

fn (mut w Writer) write_1366(data [1366]byte) {
	mut tmp := []byte{len: 1366, init: `0`}
	for i, b in data {
		tmp[i] = b
	}
	w.buf << tmp
}

fn (mut w Writer) write_bool(data bool) {
	w.buf << match data {
		true { `1` }
		false { `0` }
	}
}

fn (mut w Writer) write_bigint(data int) {
	if data < 0xfd {
		mut x := []byte{len: 1}
		x[0] = byte(data)
		w.buf << x
	} else if data < 0x10000 {
		mut x := []byte{len: 2}
		binary.big_endian_put_u16(mut x, u16(data))
		mut xx := []byte{len: 3}
		xx[0] = 0xfd
		xx << x
		w.buf << xx
	} else if data < 0x100000000 {
		mut x := []byte{len: 4}
		binary.big_endian_put_u32(mut x, u32(data))
		mut xx := []byte{len: 5}
		xx[0] = 0xfe
		xx << x
		w.buf << xx
	} else {
		mut x := []byte{len: 8}
		binary.big_endian_put_u64(mut x, u64(data))
		mut xx := []byte{len: 9}
		xx[0] = 0xff
		w.buf << xx
	}
}

fn (mut w Writer) write_u16(data u16) {
	mut tmp := []byte{len: 2, init: `0`}
	binary.big_endian_put_u16(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_u32(data u32) {
	mut tmp := []byte{len: 2, init: `0`}
	binary.big_endian_put_u32(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_u64(data u64) {
	mut tmp := []byte{len: 8, init: `0`}
	binary.big_endian_put_u64(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_dynamic(data []byte) {
	w.write_u16(u16(data.len))
	w.buf << data
}

fn (mut w Writer) write_encodable(enc Encodable) {
	w.buf << enc.encode()
}

fn (mut w Writer) write_little_u16(data u16) {
	mut tmp := []byte{len: 2, init: `0`}
	binary.little_endian_put_u16(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_little_u32(data u32) {
	mut tmp := []byte{len: 2, init: `0`}
	binary.little_endian_put_u32(mut tmp, data)
	w.buf << tmp
}

fn (mut w Writer) write_little_u64(data u64) {
	mut tmp := []byte{len: 8, init: `0`}
	binary.little_endian_put_u64(mut tmp, data)
	w.buf << tmp
}
