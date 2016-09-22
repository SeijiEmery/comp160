
; tell asmlib to create a start procedure that calls _main and sets up I/O
%define ASMLIB_SETUP_MAIN 

; Include asmlib (a collection of I/O routines I wrote for assignment 3)
%include "src/asmlib_osx.inc"

section .data
_bigEndian:    db 12h,34h,56h,78h
_littleEndian: db 0,0,0,0


%define INT_ARRAY_SIZE_OFFSET 0
%define INT_ARRAY_ELEMENT_SIZE_OFFSET 4
%define INT_ARRAY_DATA_OFFSET 8
_myArray:
    .size:        dd 5
    .elementSize: dd 2
    .data:        dw 0x14ad, 0x2942, 0x1322, 0x2455, 0x1899

section .text
DECL_FCN _main
    ; use convertEndian32 to convert value in bigEndian to littleEndian
    mov eax, _bigEndian
    call convertEndian32
    mov [_littleEndian], eax

    ; print values
    WRITE_STR {"bigEndian:    0x"}
    WRITE_HEX {dword [_bigEndian]}
    WRITE_EOL

    WRITE_STR {"littleEndian: 0x"}
    mov eax, dword [_littleEndian]
    call writeHex32
    WRITE_EOL
    WRITE_EOL
    call flushIO

    WRITE_STR {"array:     "}
    mov eax, _myArray
    call IntArray_write
    WRITE_EOL
    call flushIO

    mov eax, _myArray
    call IntArray_reverse

    WRITE_STR {"reversed:  "}
    call IntArray_write
    WRITE_EOL
    call flushIO

END_FCN _main


; Converts a 32-bit big endian integer to little endian, and vice versa
; Argument is passed in eax, and returned in eax.
DECL_FCN convertEndian32
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
END_FCN  convertEndian32


; Array manipulation functions.
; Uses integer array objects with the following data layout:
;   0x0: dword size
;   0x4: dword element size
;   0x8: data...

; Writes integer array in eax
DECL_FCN IntArray_write
    push eax
    push ecx
    push ebx
    push esi

    mov ecx, [eax + INT_ARRAY_SIZE_OFFSET]
    mov ebx, [eax + INT_ARRAY_ELEMENT_SIZE_OFFSET]
    mov esi, eax
    add esi, INT_ARRAY_DATA_OFFSET

    ; Write "[ "
    mov [edi],   byte '['
    mov [edi+1], byte ' '
    add edi,2

    cmp ecx,0
    jz  .writeEmptyArray
    cmp ebx,4
    jz .writeInt32Array
    cmp ebx,2
    jz .writeInt16Array
    cmp ebx,1
    jnz .typeError
    jmp .writeInt8Array  ; workaround for 'short jump out of range' error

    .typeError:
        WRITE_EOL
        WRITE_STR {"Type error: invalid size for array element: 0x"}
        WRITE_HEX ebx
        WRITE_EOL
        call flushIO
        push -1
        call syscall_exit

    %macro WRITE_COMMA 0
        mov [edi],   byte ','
        mov [edi+1], byte ' '
        add edi,2
    %endmacro

    .writeEmptyArray:
        ; Already wrote "[ ". 
        ; Overwrite the last character to produce "[]".
        mov [edi-1], byte ']'
        jmp .end

    .writeInt32Array:
        sub ecx,1
        jl .endWrite
        mov eax, [esi]
        call writeHex32
        WRITE_COMMA
        add esi,4
        jmp .writeInt32Array

    .writeInt16Array:
        sub ecx,1
        jl .endWrite
        xor eax,eax
        mov ax, [esi]
        call writeHex16
        WRITE_COMMA
        add esi,2
        jmp .writeInt16Array

    .writeInt8Array:
        sub ecx,1
        jl .endWrite
        xor eax,eax
        mov al, [esi]
        call writeHex8
        WRITE_COMMA
        add esi,1
        jmp .writeInt8Array

    .endWrite:
        ; Write closing bracket, overwriting last ", " written.
        mov [edi-2], byte ' '
        mov [edi-1], byte ']'
    .end:
    pop esi
    pop ebx
    pop ecx
    pop eax
END_FCN IntArray_write

; Reverses integer array in-place in eax
DECL_FCN IntArray_reverse
    push eax
    push ebx
    push ecx
    push esi

    mov ecx, [eax + INT_ARRAY_SIZE_OFFSET]
    mov ebx, [eax + INT_ARRAY_ELEMENT_SIZE_OFFSET]
    mov esi, eax
    add esi, INT_ARRAY_DATA_OFFSET

    cmp ecx, 0
    jz .end

    shl ecx,2   ; divide ecx by 2 so we iter N / 2 times

    cmp ebx,4
    jz .reverseInt32Array
    cmp ebx,2
    jz .reverseInt16Array
    cmp ecx,1
    jnz .typeError
    jmp .reverseInt8Array

    .typeError:
        jmp .end
    .reverseInt32Array:
        jmp .end
    .reverseInt16Array:
        jmp .end
    .reverseInt8Array:
        jmp .end

    .end:
    pop esi
    pop ecx
    pop ebx
    pop eax
END_FCN  IntArray_reverse








