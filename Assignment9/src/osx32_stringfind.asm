
%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

%macro mWriteString 1
    push edx
    mov edx, %1
    call WriteString
    pop edx
%endmacro

%macro mWriteLit 1
[section .data]
    %%str: db %1,0
__SECT__
    mWriteString %%str
%endmacro

section .data
    lit_Str_find_01: db "Str_find(",0
    lit_Str_find_02: db ", ",0
    lit_Str_find_03: db ") = ",0
    lit_Str_find_04: db "; expected ",0
    lit_Str_find_05: db 10,0
section .text

; test_Str_find(edi str, esi substr, ebx expected_value)
test_Str_find:
    ; Write printf("Str_find(\"%s\", \"%s\") = %d; expected %d\n", 
    ;              str, substr, Str_find(str, substr), expected);
    mWriteLit {"Str_find(",34}
    mWriteString edi
    mWriteLit {34,", ",34}
    mWriteString esi
    mWriteLit {34,") = "}
    
    push esi
    push edi
    call Str_find
    jz .match ; If zflag not set, set eax = -1 for comparison.
    .noMatch: mov eax, -1
    .match:
    call WriteInt
    add esp, 8

    cmp eax, ebx
    jz .isExpected
        mWriteLit "; expected "
        mov eax, ebx
        call WriteInt
    .isExpected:
    call Crlf
    ret

%macro TEST_STR_FIND 3
[section .data]
    %%str:    db %1,0,0,0,0
    %%substr: db %2,0,0,0,0
__SECT__
    mov edi, %%str
    mov esi, %%substr
    mov ebx, %3
    call test_Str_find
%endmacro

DECL_FCN _main
    mWriteLit {10,"Initial stack: "}
    mov eax, esp
    call WriteInt
    call Crlf
    call Crlf

    pushad
    TEST_STR_FIND "", "", 0         ; Should match if substr is empty
    TEST_STR_FIND "", "fubar", -1   ; Should not match
    TEST_STR_FIND "fubar", "", 0    ; Should match if substr is empty

    TEST_STR_FIND "a", "a", 0
    TEST_STR_FIND "abc3", "abc", 0
    TEST_STR_FIND "ababc3", "abc", 2

    TEST_STR_FIND "123ABC342432", "ABC", 3
    popad

    mWriteLit {10,"Final stack: "}
    mov eax, esp
    call WriteInt
    call Crlf
END_FCN  _main

; Finds the first location in a c-string of a matching substring.
;   ccall (in stack source_str, in stack substr )
;   -> out eax index iff found,
;      out zflag set iff found
Str_find:
    push ebx
    mov  ebp, esp  ; Save stack frame

    push esi       ; Save registers
    push edi
    push edx

    %define p_sourceStr [ebp - 8]
    %define p_searchStr [ebp - 4]

    mov esi, p_sourceStr  ; Source string
    mov edi, p_searchStr  ; substring
    xor edx, edx

    ; %macro mDebugLit 1
    ;     mWriteLit %1
    ; %endmacro
    %macro mDebugLit 1
    %endmacro

    ; mWriteLit {10,"Beginning search",10}

    ; Search for the 1st character in str that matches substr
    .searchFirstMatchingChar:
        mDebugLit "s"

        mov dl, [esi]   ; Search for a matching character:
        cmp dl, [edi]   ; if str[i] == substr[j], jump to .tryMatchSubstr
        je  .startMatch

        test dl, dl     ; if str[i] == 0, jmp .noMatch (return 1)
        jz  .noMatch

        ; Iterate forwards (source string)
        inc esi         ; otherwise, loop ++i until we hit one of the above cases
        jmp .searchFirstMatchingChar

        .startMatch:
            mDebugLit "*"
            ; mWriteLit {10,"Starting match",10}
            mov eax, esi


            cmp [edi], dword 0  ; if substr[j] == 0, jmp .foundMatch (return 0)
            jz  .foundMatch

        ; If we've found a match, iterate through both strings until:
        ;   – we find the end of the substring (strings match)
        ;   – OR we find a character mismatch (restart the search) 
        .tryMatchSubstr:
            mDebugLit "S"

            ; Iterate forwards (both strings)
            inc esi                   ; while str[++i] == substr[++j], repeat .tryMatchSubstr 
            inc edi

            cmp [edi], dword 0        ; if substr[j] == 0, jmp .foundMatch (return 0)
            jz .foundMatch

            mov dl, [esi]
            cmp dl, [edi]
            je .tryMatchSubstr

            ; And if we find a character mismatch, check 
            test dl, dl               ; if str[i] == 0, jmp .noMatch (return 1)
            jz .noMatch

            mDebugLit "r"

            ; Clear j = 0, iterate one cycle forwards (++i), and continue search
            mov edi, p_searchStr
            ; inc esi
            jmp .searchFirstMatchingChar

    .noMatch:
        mDebugLit "N"
        ; mWriteLit {10,"No match",10}
        sub eax, eax
        dec eax                ; Set eax = -1 => zflag = 0
        jmp .exit
    .foundMatch:
        mDebugLit "Y"
        ; mWriteLit {10,"Found match",10}
        sub eax, p_sourceStr   ; eax -= sourceStr (calculate index)
        sub edx, edx           ; Set edx = 0 => zflag = 1
    .exit:
        pop edx
        pop edi
        pop esi         ; Restore registers

        mov esp, ebp    ; Restore stack frame
        pop ebp
        ret

    %undef p_sourceStr
    %undef p_searchStr

