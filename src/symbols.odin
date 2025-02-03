package neep

import "./mcu"

UNKNOWN_SFR_PAGE :: -1

Address_Type :: enum u8 {
	FLASH,
	IRAM,
	IRAM_BIT,
	XRAM,
}

get_sfr_page_reg_address :: proc() -> (address: u8, ok: bool) {
	@(static) last_reported_address := -1

	if last_reported_address >= 0 {
		return u8(last_reported_address), true
	}

	switch get_cmd_opts().mcu {
	case mcu.EFM8BB52:
		last_reported_address = mcu.EFM8BB52_SFR_PAGE_REG_ADDRESS
		return mcu.EFM8BB52_SFR_PAGE_REG_ADDRESS, true
	case:
		last_reported_address = -1
		return 0x00, false
	}
}

symbol_from_address :: proc(address: u16, address_type: Address_Type, sfr_page := UNKNOWN_SFR_PAGE) -> string {
	switch get_cmd_opts().mcu {
	case mcu.EFM8BB52:
		mcu_address_type := mcu.Address_Type(address_type)
		return mcu.efm8bb52_symbol_from_address(address, mcu_address_type, sfr_page)
	case:
		return ""
	}
}
