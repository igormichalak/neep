package mcu

EFM8BB52 :: "efm8bb52"

EFM8BB52_SFR_PAGE_REG_ADDRESS :: 0xA7

efm8bb52_symbol_from_address :: proc(address: u16, address_type: Address_Type, sfr_page: int) -> (symbol: string, ok: bool) {
	return "", false
}
