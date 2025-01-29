package neep

import "./mcu"

UNKNOWN_SFR_PAGE :: -1

Address_Type :: enum u8 {
	FLASH,
	IRAM,
	IRAM_BIT,
	XRAM,
}

get_sfr_page_reg_address :: proc() -> u8 {
	switch get_cmd_opts().mcu {
	case mcu.EFM8BB52:
		return mcu.EFM8BB52_SFR_PAGE_REG_ADDRESS
	case:
		panic("mcu flag is not specified")
	}
}

symbol_from_address :: proc(address: u16, address_type: Address_Type, sfr_page := UNKNOWN_SFR_PAGE) -> (symbol: string, ok: bool) {
	switch get_cmd_opts().mcu {
	case mcu.EFM8BB52:
		mcu_address_type := mcu.Address_Type(address_type)
		return mcu.efm8bb52_symbol_from_address(address, mcu_address_type, sfr_page)
	case:
		panic("mcu flag is not specified")
	}
}
