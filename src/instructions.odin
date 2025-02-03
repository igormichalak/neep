package neep

Op :: enum u8 {
	ILLEGAL,
	ACALL,
	ADD,
	ADDC,
	AJMP,
	ANL,
	CJNE,
	CLR,
	CPL,
	DA,
	DEC,
	DIV,
	DJNZ,
	INC,
	JB,
	JBC,
	JC,
	JMP,
	JNB,
	JNC,
	JNZ,
	JZ,
	LCALL,
	LJMP,
	MOV,
	MOVC,
	MOVX,
	MUL,
	NOP,
	ORL,
	POP,
	PUSH,
	RET,
	RETI,
	RL,
	RLC,
	RR,
	RRC,
	SETB,
	SJMP,
	SUBB,
	SWAP,
	XCH,
	XCHD,
	XRL,
}

Op_Mnemonics := [Op]string {
	.ILLEGAL = "",
	.ACALL = "ACALL",
	.ADD   = "ADD",
	.ADDC  = "ADDC",
	.AJMP  = "AJMP",
	.ANL   = "ANL",
	.CJNE  = "CJNE",
	.CLR   = "CLR",
	.CPL   = "CPL",
	.DA    = "DA",
	.DEC   = "DEC",
	.DIV   = "DIV",
	.DJNZ  = "DJNZ",
	.INC   = "INC",
	.JB    = "JB",
	.JBC   = "JBC",
	.JC    = "JC",
	.JMP   = "JMP",
	.JNB   = "JNB",
	.JNC   = "JNC",
	.JNZ   = "JNZ",
	.JZ    = "JZ",
	.LCALL = "LCALL",
	.LJMP  = "LJMP",
	.MOV   = "MOV",
	.MOVC  = "MOVC",
	.MOVX  = "MOVX",
	.MUL   = "MUL",
	.NOP   = "NOP",
	.ORL   = "ORL",
	.POP   = "POP",
	.PUSH  = "PUSH",
	.RET   = "RET",
	.RETI  = "RETI",
	.RL    = "RL",
	.RLC   = "RLC",
	.RR    = "RR",
	.RRC   = "RRC",
	.SETB  = "SETB",
	.SJMP  = "SJMP",
	.SUBB  = "SUBB",
	.SWAP  = "SWAP",
	.XCH   = "XCH",
	.XCHD  = "XCHD",
	.XRL   = "XRL",
}

Operand_Type :: enum u8 {
	NONE,                   // no operand and no value
	ACC,                    // no value (A)
	REG,                    // 3-bit value (Rn)
	AB,                     // no value (AB)
	CARRY_BIT,              // no value (C)
	BIT_ADDR,               // 8-bit address (const)
	INV_BIT_ADDR,           // 8-bit address (/const)
	IMM,	                // 8-bit immediate (#const)
	IMM_LONG,               // 16-bit immediate (#const)
	DPTR,                   // no value (DPTR)
	DIRECT_ADDR,            // 8-bit address (const)
	INDIRECT_REG,           // 1-bit value (@Ri)
	INDIRECT_DPTR,          // no value (@DPTR)
	INDIRECT_ACC_PLUS_DPTR, // no value (@A + DPTR)
	INDIRECT_ACC_PLUS_PC,   // no value (@A + PC)
	ADDR_11,                // 11-bit address (const)
	ADDR_16,                // 16-bit address (const)
	OFFSET,                 // 8-bit signed offset (const)
}

Operand :: struct {
	type: Operand_Type,
	value: i32,
}

Instruction :: struct {
	bytes: u8,
	op: Op,
	using _: struct #raw_union {
		destination: Operand,
		a: Operand,
	},
	using _: struct #raw_union {
		source: Operand,
		b: Operand,
	},
	jump: Operand,
}

Operand_Fetch :: enum u8 {
	NONE,      // no fetch
	BYTE_1,    // byte_1
	BYTE_2,    // byte_2
	TWO_BYTES, // (byte_1 << 8) | byte_2
	ADDR_11,   // ((byte_0 & 0xE0) << 3) | byte_1
}

Operand_Specifier :: struct {
	type: Operand_Type,
	constant: i32,
	fetch: Operand_Fetch,
}

Instruction_Specifier :: struct {
	bytes: u8,
	op: Op,
	a, b, jump: Operand_Specifier,
}

is_branch_op :: proc(op: Op) -> bool {
	#partial switch op {
	case .ACALL, .LCALL, .RET, .RETI, .AJMP, .LJMP, .SJMP, .JMP, .JZ, .JNZ, .CJNE, .DJNZ:
		return true
	case:
		return false
	}
}
