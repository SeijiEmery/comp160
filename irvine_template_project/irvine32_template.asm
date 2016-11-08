; //Irvine32 template	(irvine32_template.asm)

; //include Irvine32.inc

INCLUDE Irvine32.inc

.data


.code
main PROC
	
	CALL DUMPRegs
	call WriteHex
	call Crlf
	
	exit
main ENDP

END main