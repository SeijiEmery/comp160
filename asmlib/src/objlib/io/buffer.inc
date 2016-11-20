
struc IOBuffer
    .buffer:        res_ptr_t  1
    .bufferSize:    res_size_t 1
    .remaining:     res_size_t 1
    .onFlushBuffer: res_ptr_t  1
endstruc

; resizeBuffer
;   inout eax buffer
;   inout esi allocator
;   inout ecx size
resizeBuffer:
    push edx
    mov  edx, eax

    ; Check that we have bytes in the current buffer.
    ; If yes, call flushBuffer
    mov eax, [edx + IOBuffer.remaining]
    cmp eax, [edx + IOBuffer.bufferSize]
    jnz .emptyBuffer
        call flushBuffer
    .emptyBuffer:

    ; If buffer does not exist, alloc the buffer
    ; If buffer does exist + is of correct size, do nothing / skip the allocation
    ; Otherwise, free the existing buffer, alloc a new one, and copy the buffer's
    ; contents to the new buffer, up to the # of used bytes.

    cmp [edx + IOBuffer.buffer], 0
    jz  .skipFree
    cmp ecx, [edx + IOBuffer.bufferSize]
    jz  .skipAlloc
        ; Free existing buffer
        mov eax, [edx + IOBuffer.buffer]
        call free
    .skipFree:

    ; Alloc a new buffer
    mov eax, ecx
    call malloc

    ; Update buffer fields
    mov [edx + IOBuffer.buffer], eax
    mov [edx + IOBuffer.bufferSize], ecx
    mov [edx + IOBuffer.remaining], ecx 

    .skipAlloc:
    pop edx
    ret

; flushBuffer
;   inout eax buffer
flushBuffer:
    call [eax + IOBuffer.onFlushBuffer]
    push 


    mov  [eax + IOBuffer.remaining], 0
    ret

; bufferWriteString
;   inout eax buffer
;   in    esi string_ptr
;   in    ecx string_length
bufferWriteString:
    ; Check size: if writing string would cause buffer to overflow, 
    ; call bufferFlush
    cmp [eax + IOBuffer.remaining], ecx
    jg .bufferOk
        call flushBuffer
    .bufferOk:
    push edi

    ; Calculate read head + copy string
    mov edi, [eax + IOBuffer.buffer]
    add edi, [eax + IOBuffer.bufferSize]
    sub edi, [eax + IOBuffer.remaining]
    push ecx
    call memcpy

    pop ecx
    sub [eax + IOBuffer.remaining], ecx
    pop edi
    ret

; bufferWriteStringz
;   inout eax buffer
;   inout esi string_ptr
bufferWriteStringz:
    call strlen
    jmp bufferWriteString

; bufferReadString
;   inout eax buffer
;   inout edi dst
;   inout ecx length
bufferReadString:
    ret

; Macros used to implement readf / writef

%macro READ_BYTE 1
    mov %1, [esi]
    inc esi
%endmacro
%macro WRITE_BYTE 1
    mov [edi], %1
    inc edi
    dec ecx
    jle .flushBuffer
%endmacro
%macro BRANCH 3
    cmp %1, %2
    jz  %3
%endmacro

; Max contiguous characters
MAX_WRITE_SEQ equ 24

; bufferWritef
;   inout eax buffer
;   in    esi format_str
;   in    stack args...
bufferWritef:
    push ebx    ; Save registers
    push ecx
    push edx
    push edi

    mov ecx, [eax + IOBuffer.remaining]
    sub ecx, MAX_WRITE_SEQ

    mov edi, [eax + IOBuffer.buffer]
    add edi, [eax + IOBuffer.bufferSize]
    sub edi, ecx
    mov edx, eax

    .writeStrLoop:
        READ_BYTE bl
        BRANCH bl 0   .end
        BRANCH bl '%' .writeFmt
        BRANCH bl '\' .writeEsc
        .writeChrAndContinue:
        WRITE_BYTE bl
        jmp .writeStrLoop
        .writeFmt: jmp doWriteFmt
        .writeEsc: jmp doWriteEsc
    .doWriteFmt:
        READ_BYTE bl
        BRANCH bl '%' .writeChrAndContinue
        BRANCH bl 'd' .writeDecFmt
        BRANCH bl 's' .writeStrFmt
        BRANCH bl 'x' .writeHexFmt
        BRANCH bl 'c' .writeChrFmt
        BRANCH bl '@' .writeObjFmt

        ; None of the above cases (error).
        ; Pop value (and discard), and write out the full format string
        ; so we can see what went wrong.
        pop eax
        WRITE_BYTE {byte '%'}
        jmp .writeChrAndContinue
        .writeDecFmt:
            pop  eax
            add  ecx, edi
            call writeDecimal
            sub  ecx, edi
            jle .flushBuffer
            jmp .writeStrLoop
        .writeHexFmt:
            pop  eax
            add  ecx, edi
            call writeHex
            sub  ecx, edi
            jle .flushBuffer
            jmp .writeStrLoop
        .writeChrFmt:
            pop  eax
            call writeEscapedChr
            jmp .writeStrLoop
        .writeStrFmt:
            xchg esi, [esp]

            add ecx, MAX_WRITE_SEQ
            mov [edx + IOBuffer.remaining], ecx

            call bufferWriteString

            mov ecx, [edx + IOBuffer.remaining]
            sub ecx, MAX_WRITE_SEQ

            pop  esi
            jmp .writeStrLoop
        .writeObjFmt:
            pop eax
            add ecx, MAX_WRITE_SEQ
            mov [edx + IOBuffer.remaining], ecx
            push edx

            mov ecx, [eax + MObject.cls]
            call [ecx + IObject.write]

            pop edx
            mov ecx, [edx + IOBuffer.remaining]
            mov edi, [edx + IOBuffer.buffer]
            sub edi, ecx
            sub ecx, MAX_WRITE_SEQ
            jmp .writeStrLoop

    .flushBuffer:
        mov [edx + IOBuffer.remaining], ecx
        mov eax, edx
        call flushBuffer
        mov ecx, [edx + IOBuffer.remaining]
        mov edi, [edx + IOBuffer.buffer]
        sub ecx, MAX_WRITE_SEQ
        jmp .writeStrLoop
    .doWriteEsc:
        READ_BYTE bl
        BRANCH bl '\' .writeBackslash
        BRANCH bl 'n' .writeNewline
        BRANCH bl 't' .writeTab

        WRITE_BYTE {byte '\'}
        jmp .writeChrAndContinue

        .writeBackslash: 
            jmp .writeChrAndContinue
        .writeNewline:
            add ecx, edi
            WRITE_NEWLINE edi
            sub ecx, edi
            jle .flushBuffer
            jmp .writeChrAndContinue
        .writeTab: 
            mov bl, 9
            jmp .writeChrAndContinue
    .end:
    mov eax, edx
    pop edi
    pop edx
    pop ecx 
    pop ebx
    ret

; bufferReadf
;   inout eax buffer
;   in    esi format str
;   in    stack args...
bufferReadf:
    ret


