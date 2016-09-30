

%macro BEGIN_UNITTEST 1
section .data
    s_unittest_%1_name: %strcat __FILE__
section .text
unittest_%1:
    push ebp
    mov ebp, esp
    push dword 0        ; num attempts
    push dword 0        ; num failures
    push s_unittest_%1_name
    push __LINE__
%endmacro
%macro END_UNITTEST 1
    mov rbx, [ebp+0]    ; num attempts
    sub rax, [ebp+4]    ; num failures
    cmp rax, 0
    jz %%ok

    push [ebp+12]
    call unittest_log_failure
    call unittest_log_attempts
%%ok:
    mov esp, ebp
    pop ebp
    ret
%endmacro

%macro MARK_TEST_FAILURE 0
    dec [ebp+4]
%endmacro
%macro MARK_TEST_OK 0
    inc [ebp+0]
%endmacro

%macro ASSERT_I32_EQ 2
    cmp %1, %2
    jz  .%%assertOk
    push %1
    push %2
    push __LINE__
    call unittest_log_failure
    call unittest_log_ne_i32
    mov eax, -1
    ret
.%%assertOk:
    MARK_TEST_OK
%endmacro

%macro CALL_UNITTEST 1
    call unittest_%1
    cmp rax, 0
    jz .%%assertOk
    MARK_TEST_FAILURE
.%%assertOk:
    MARK_TEST_OK
%endmacro

unittest_failure:
    call unittest_log_failure
    ret

unittest_log_failure:
    WRITE_STR {10,"Unittest failed: "}
    mov esi, [ebp+8]
    call writeStr
    PUT_CHAR ':'
    pop eax
    call writeDecimal
    PUT_CHAR ':'
    PUT_CHAR ' '
    ret

unittest_log_attempts:
    push eax     ; num attempts
    push ebx     ; num failures
    PUT_CHAR '('
    xchg eax, ebx
    sub eax, ebx
    call writeDecimal
    PUT_CHAR '/'
    mov eax, ebx
    call writeDecimal
    PUT_CHAR ')'
    pop ebx
    pop eax
    ret

; write <i32> != <i32>
unittest_log_ne_i32:
    pop eax
    WRITE_HEX_32 eax
    WRITE_STR " != "
    pop eax
    WRITE_HEX_32 eax
    ret
