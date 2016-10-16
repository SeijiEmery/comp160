
%include "asmlib.inc"

section .text
global start
start:
    call runAllTests
    CALL_SYSCALL_EXIT 0

%macro ASSERT_EQ 3
    cmp %1, %2
    jz %%testOk
    jnz %%testFail
    section .data
        %%msg: db %3
        %%msg.length: equ $ - %%msg
    section .text
    %%testFail:
        CALL_SYSCALL_WRITE STDOUT, %%msg, %%msg.length
    %%testOk:
%endmacro

%macro WRITE_STR_LIT 1
section .data
    %%str: db %1
    %%str.length: equ $ - %%str
section .text
    CALL_SYSCALL_WRITE STDOUT, %%str, %%str.length
%endmacro

runAllTests:
    call test_sanity
    call test_syscall_write_contract
    ret

test_sanity:
    WRITE_STR_LIT {10,"Testing sanity. If this message does not appear, something broke.",10}
    mov ebx, 2
    add ebx, 2
    ASSERT_EQ ebx, 4, {"This should pass",10}
    ASSERT_EQ ebx, 5, {"This should fail",10}
    ret

test_syscall_write_contract:
    mov ebx, esp
    ret