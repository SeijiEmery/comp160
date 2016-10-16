
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


; Raw I/O functions (need these to test everything else)
section .data
    io_scratch_buffer: resb 4096
section .text
ioWrite:
    sub edi, io_scratch_buffer
    CALL_SYSCALL_WRITE STDOUT, io_scratch_buffer, edi
    mov edi, io_scratch_buffer
    ret

;
; Unit tests
;

runAllTests:
    call test_sanity
    call test_basic_output
    call test_syscall_write_contract
    ret

test_sanity:
    WRITE_STR_LIT {10,"Testing sanity. If this message does not appear, something broke.",10}
    mov ebx, 2
    add ebx, 2
    ASSERT_EQ ebx, 4, {"This should pass",10}
    ASSERT_EQ ebx, 5, {"This should fail",10}
    ret

; Write I/O + assert that edi was advanced N bytes
%macro TEST_IO 2
    sub ecx, edi
    call ioWrite
    ASSERT_EQ ecx, %1, %2
    mov ecx, edi
%endmacro

test_basic_output:
    WRITE_STR_LIT {10,"Testing basic I/O",10}

    mov edi, io_scratch_buffer
    mov ecx, edi

    WRITE_STR_LIT {"WRITE_EOL: "}
    WRITE_EOL
    TEST_IO -1, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_0x: "}
    WRITE_0x
    TEST_IO -2, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC 9:    "}
    WRITE_DEC dword 9
    TEST_IO -1, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC 1:    "}
    WRITE_DEC dword 1
    TEST_IO -1, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC 72:   "}
    WRITE_DEC dword 72
    TEST_IO -2, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC 938:  "}
    WRITE_DEC dword 938
    TEST_IO -3, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC 2547: "}
    WRITE_DEC dword 2547
    TEST_IO -4, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC -1:   "}
    WRITE_DEC dword -1
    TEST_IO -1, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC -90:  "}
    WRITE_DEC dword -90
    TEST_IO -2, "  <invalid advance>"



    ret

test_syscall_write_contract:
    mov ebx, esp
    ret
















