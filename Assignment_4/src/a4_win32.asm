; Assignment 4:
; Program Description:
;   Performs two functions:
;       – converts a 32-bit integer in bigEndian to littleEndian 
;       – reverses a typed array of integers (uses MASM TYPE, LENGTHOF, etc).
;
; Target platform: windows, 32-bit.
;   Must use a debugger, as this program does no i/o.
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: 9/24/16
; Revisions: N/A (see git log)
; Date:              Modified by:
;

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

.data
bigEndian    BYTE 12h,34h,56h,78h
littleEndian BYTE 0,0,0,0
myArray      WORD 0x0011,0x2233,0x4455,0x6677,0x8899,0xAABB

.code
main PROC
    ; Convert little endian to big endian
    mov eax, OFFSET bigEndian
    call convertEndian32
    mov DWORD PTR [littleEndian], eax

    ; Reverse array.
    mov esi, OFFSET   myArray     ; load array pointer,
    mov ebx, TYPE     myArray     ; size of array elements,
    mov ecx, LENGTHOF myArray     ; and # of array elements

    ; Call IntArray_reverse, which in our win32 impl, will take
    ; direct arguments in esi, ebx, ecx. 
    call IntArray_reverse
    cmp esi,-1
    jz  error

    INVOKE ExitProcess,0
error:
    INVOKE ExitProcess,-1
main ENDP

; Converts a 32-bit big endian integer to little endian, and vice versa
; Argument is passed as an address in eax, and returned as a value in eax.
convertEndian32 PROC
    push ebx
    xor ebx,ebx

    mov bl,[eax]
    shl ebx,8
    mov bl,[eax+1]
    shl ebx,8
    mov bl,[eax+2]
    shl ebx,8
    mov bl,[eax+3]

    mov eax,ebx
    pop ebx
convertEndian32 ENDP

; Reverse a typed 8-32 bit integer array in-place.
; Takes arguments in the following registers:
;   esi - array ptr
;   ebx - size of array elements (1 to 4).
;   ecx - # of array elements
;
; Special cases:
;   If ecx (array length) <= 1, does nothing.
;   If ebx not equal to 1, 2, 4, this is considered an error,
;       and will return w/ esi = -1 (otherwise, esi unchanged).
;   
IntArray_reverse PROC
    push eax
    push ebx
    push ecx
    push esi    ; Save registers (used registers + original args)
    push edi

    cmp ecx,1   ; Skip the following if array has only 1 or 0 elements:
    jle end1     ; an empty array cannot be reversed, and an array w/ only one
                ; element effectively already is reversed.

    ; Jump to different implementations based on array size.
    cmp ebx,4
    jz reverseInt32Array
    cmp ebx,2
    jz reverseInt16Array
    cmp ebx,1
    jz reverseInt8Array

    ; Invalid argument
    mov esi,-1
    jmp end1

    reverseInt32Array:
        dec ecx
        shl ecx, 2
        mov edi, esi
        add edi, ecx   ; mov edi, esi + (ecx - 1) * 4

        loop32:
        cmp esi, edi   ; loop until esi >= edi
        jge end1
        mov eax, [esi] ; swap values at esi, edi
        mov ebx, [edi]
        mov [esi], edx
        mov [edi], ebx
        add esi, 4     ; advance esi, edi by 4 bytes
        sub edi, 4
        jmp loop32

    reverseInt16Array:
        dec ecx
        shl ecx, 1
        mov edi, esi
        add edi, ecx  ; mov edi, esi + (ecx - 1) * 2

        loop16:
        cmp esi, edi  ; loop until esi >= edi
        jge end1
        mov ax, [esi] ; swap values at esi, edi
        mov bx, [edi]
        mov [esi], bx
        mov [edi], ax
        add esi, 2    ; advance esi, edi by 2 bytes
        sub edi, 2
        jmp loop16

    reverseInt8Array:
        dec ecx
        mov edi, esi
        add edi, ecx  ; mov edi, esi + (ecx - 1) * 1

        loop8:
        cmp esi, edi  ; loop until esi >= edi
        jge end1
        mov al, [esi] ; swap values at esi, edi
        mov bl, [edi]
        mov [esi], bl
        mov [edi], al
        inc esi       ; advance esi, edi by 1 byte
        dec edi
        jmp loop8

    end1:
    pop edi
    pop esi     ; Restore registers
    pop ecx
    pop ebx
    pop eax
IntArray_reverse ENDP

END main
