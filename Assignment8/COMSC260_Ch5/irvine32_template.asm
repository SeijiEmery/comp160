; //Irvine32 template	(irvine32_template.asm)

; //include Irvine32.inc

INCLUDE Irvine32.inc

CELL_HEIGHT equ 2
CELL_WIDTH equ 2

.code
DrawChessBoard PROC
	jmp @F
.data
	s8 db '  '
	s7 db '  '
	s6 db '  '
	s5 db '  '
	s4 db '  '
	s3 db '  '
	s2 db '  '
	s1 db '  ',0
	lut DWORD s1,1, s2,2, s3,3, s4,4, s5,5, s6,6, s7,7, s8,8
.code
@@:
	pushad
	and eax, 7
	mov esi, [lut + eax * 8]
	mov eax, [lut + eax * 8 + 4]
	mov ebx, ecx

	mov ah, al
	shl al, 2

	; Write color grid
	push eax
	mov eax, [edi]
	call SetTextColor
	pop eax
		call writeGrid
		shr al, 1
		add dl, al
		add dh, ah
		shl al, 1
		call writeGrid

	push eax
	mov eax, [edi + 4]
	call SetTextColor
	pop eax
		sub dh, ah
		call writeGrid
		shr al, 1
		add dh, ah
		sub dl, al
		shl al, 1
		call writeGrid
	popad
	ret

	writeGrid PROC
		pushad
		xor ecx, ecx
	loopGrid:
		mov ch, ah
		writeSegment:
			mov cl, bl
			push edx
			writeLine:
				push edx
				call Gotoxy
				mov edx, esi
				call WriteString
				pop edx
				add dl, al
				dec cl
				jg writeLine
			pop edx
			inc dh
			dec ch
			jg writeSegment
		add dh, ah
		dec bh
		jg loopGrid
		popad
		ret	
	writeGrid ENDP
DrawChessBoard ENDP

DisplayBoard PROC
	LOCAL color1: DWORD, color2: DWORD
	
	mov color1, 0h
	mov color2, 1h
	
	lea edi, color2
	xor edx, edx
	mov cl,  4
	mov ch,  4

	drawColors:
		mov  eax, 5
		call DrawChessBoard
		cmp color1, 0ffh
		jge endLoop
		add color1, 11h

		mov eax, 500
		call Delay
		jmp  drawColors
	endLoop:
	ret
DisplayBoard ENDP


main PROC
	call DisplayBoard
	exit
main ENDP
END main