.equ SFRPAGE, 0xA7
.equ WDTCN, 0x97
.equ P1MDIN, 0xF2
.equ P1MDOUT, 0xA5
.equ P1SKIP, 0xD5
.equ XBR2, 0xE3

.org 0
start:
	mov		SFRPAGE, #0x00
	mov		WDTCN, #0xDE
	mov		WDTCN, #0xAD
	mov		P1MDIN, #0xFF
	mov		P1MDOUT, #0xFF
	mov		P1SKIP, #0xFF
	mov		XBR2, #0x40

loop:
	setb	P1.4
	acall	delay

	clr		P1.4
	acall	delay

	sjmp	loop

delay:
	mov		R0, #0xFF
outer_loop:
	mov		R1, #0xFF
inner_loop:
	djnz	R1, inner_loop
	djnz	R0, outer_loop
	ret
