



%macro WRITE_BYTE 1
    mov [edi], %1
    inc edi
    dec ecx
%endmacro

%macro READ_BYTE 1
    mov %1, [esi]
    inc esi
%endmacro

%macro BRANCH 3
    cmp %1, %2
    jz  %3
%endmacro

;
; This is a _simple_ implementation of printf that supports %s, %d, %x, %%,
; and no fancy formatting.
;
; Inputs passed in esi (source), edi (dst), and assumes that edi has sufficient
; space for the operation.
;
; For variable-sized, lazy buffers, could add ecx as a counter indicating how
; many bytes are remaining in edi. If ecx hits zero, should rewind last op 
; (either preserving _partial_ esi, edi, or resetting both), and return w/ a 
; special error code (or jump to a handler...?), which should flush the buffer,
; rewrite 
;
DECL_FCN _writef
    push eax
    push ebx
    .writeStrLoop:
        READ_BYTE bl
        BRANCH bl 0  .end
        BRANCH bl 37 .writeFmt
    .writeChrAndContinue:
        WRITE_BYTE bl
        jmp .writeStrLoop
    .writeFmt:
        READ_BYTE bl
        BRANCH bl 37  .writeChrAndContinue ; '%%'
        BRANCH bl 100 .writeDecFmt         ; '%d'
        BRANCH bl 115 .writeStrFmt         ; '%s'
        BRANCH bl 120 .writeHexFmt         ; '%x'

        ; None of the above cases... so just write out the full format string 
        ; so we can at least see what went wrong (ie. invalid format string).
        WRITE_BYTE {byte 37}
        jmp .writeChrAndContinue

    .writeDecFmt:
        pop eax
        call writeDecimal
        jmp .writeStrLoop
    .writeStrFmt:
        pop eax
        call writeString
        jmp .writeStrLoop
    .writeHexFmt:
        pop eax
        call writeHex
        jmp .writeStrLoop
    .end:
    pop ebx
    pop eax
END_FCN _writef












