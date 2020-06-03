.def XL = r26
.def XH = r27
.def YL = r28
.def YH = r29
.def ZL = r30
.def ZH = r31

main:
   ldi  YH, 0x00
	ldi  YL, 0x40
	ldi  XL, 0x00
init:
   ldi  XH, 0x02
loop:	
	ld   r16, X
	st   Y, r16
	;st   Y, XL
	inc  XL
	cpi  XL, 0x00
	breq init
	rjmp loop
