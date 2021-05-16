module vlightning

import strconv

pub fn parse_short_channel_id(scid string) ?u64 {
	spl := scid.split('x')
	if spl.len != 3 {
		return error('short_channel_id invalid: $scid')
	}

	block := strconv.atoi(spl[0]) ?
	tx := strconv.atoi(spl[1]) ?
	vout := strconv.atoi(spl[2]) ?

	return u64(((block & 0xFFFFFF) << 40) | ((tx & 0xFFFFFF) << 16) | (vout & 0xFFFF))
}
