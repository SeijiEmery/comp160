
%include "asmlib.inc"

section .text
global start
start:
    call runAllTests
    SYSCALL_EXIT 0

%macro ASSERT_EQ 3
    cmp %1, %2
    jz %%testOk
    jnz %%testFail
    section .data
        %%msg: db %3
        %%msg.length: equ $ - %%msg
    section .text
    %%testFail:
        SYSCALL_WRITE STDOUT, %%msg, %%msg.length
    %%testOk:
%endmacro

%macro WRITE_STR_LIT 1
section .data
    %%str: db %1
    %%str.length: equ $ - %%str
section .text
    SYSCALL_WRITE STDOUT, %%str, %%str.length
%endmacro

%macro WRITE_STR_LIT2 1
section .data
    %%str: db %1
section .text
    WRITE_STRZ %%str
%endmacro


; Raw I/O functions (need these to test everything else)
section .data
    io_scratch_buffer: resb 4096
section .text
ioWrite:
    sub edi, io_scratch_buffer
    SYSCALL_WRITE STDOUT, io_scratch_buffer, edi
    mov edi, io_scratch_buffer
    ret

;
; Unit tests
;

DECL_FCN runAllTests
    call test_sanity
    call test_basic_output
    call test_syscall_write_contract
    call test_set_flush_io
    call test_lcg_random
    WRITE_STR_LIT{10,"all tests ok...?",10}
END_FCN runAllTests

DECL_FCN test_sanity
    WRITE_STR_LIT {10,"Testing sanity. If this message does not appear, something broke.",10}
    mov ebx, 2
    add ebx, 2
    ASSERT_EQ ebx, 4, {"This should pass",10}
    ASSERT_EQ ebx, 5, {"This should fail",10}
END_FCN test_sanity

; Write I/O + assert that edi was advanced N bytes
%macro TEST_IO 2
    sub ecx, edi
    call ioWrite
    ASSERT_EQ ecx, %1, %2
    mov ecx, edi
%endmacro

DECL_FCN test_basic_output
    WRITE_STR_LIT {10,"Testing write functions (no asmlib I/O)",10}

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

    WRITE_STR_LIT {10,"WRITE_DEC 0:    "}
    WRITE_DEC dword 0
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
    TEST_IO -2, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_DEC -90:  "}
    WRITE_DEC dword -90
    TEST_IO -3, "  <invalid advance>"

    WRITE_STR_LIT {10,"WRITE_HEX_8 0x0:        "}
    WRITE_HEX_8 0x0
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_8 0x1:        "}
    WRITE_HEX_8 0x1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_8 0x123098:   "}
    WRITE_HEX_8 0x123098
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_8 -0x1:       "}
    WRITE_HEX_8 -1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_16 0x0:       "}
    WRITE_HEX_16 0x0
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_16 0x1:       "}
    WRITE_HEX_16 0x1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_16 0x123098:  "}
    WRITE_HEX_16 0x123098
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_16 -0x1:      "}
    WRITE_HEX_16 -1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_32 0x0:       "}
    WRITE_HEX_32 0x0
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_32 0x1:       "}
    WRITE_HEX_32 0x1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_32 0x123098:  "}
    WRITE_HEX_32 0x123098
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_32 -0x1:      "}
    WRITE_HEX_32 -1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_64 0x0:       "}
    WRITE_HEX_64 0x0
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_64 0x1:       "}
    WRITE_HEX_64 0x1
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_64 0x123098:  "}
    WRITE_HEX_64 0x123098
    TEST_IO -2, "  <>"

    WRITE_STR_LIT {10,"WRITE_HEX_64 -0x1:      "}
    WRITE_HEX_64 -1
    TEST_IO -2, "  <>"

    section .data
        str01: db "Hello, World!",0
        .len: equ $ - str01 - 1
        str02: db "foo",0
        .len: equ $ - str02 - 1
        str03: db "",0
        .len: equ $ - str03 - 1
    section .text
        WRITE_STR_LIT {10,10,"String test 01:"}
        WRITE_STR_LIT {10,"writeAsciiStr:  "}
        mov esi, str01
        mov ecx, str01.len
        call writeAsciiStr
        TEST_IO -str01.len, " <>"

        WRITE_STR_LIT {10,"writeAsciiStrz: "}
        mov esi, str01
        call writeAsciiStrz
        TEST_IO -str01.len, " <>"

        WRITE_STR_LIT {10,10,"String test 02:"}
        WRITE_STR_LIT {10,"writeAsciiStr:  "}
        mov esi, str02
        mov ecx, str02.len
        call writeAsciiStr
        TEST_IO -str02.len, " <>"

        WRITE_STR_LIT {10,"writeAsciiStrz: "}
        mov esi, str02
        call writeAsciiStrz
        TEST_IO -str02.len, " <>"

        WRITE_STR_LIT {10,10,"String test 03:"}
        WRITE_STR_LIT {10,"writeAsciiStr:  "}
        mov esi, str03
        mov ecx, str03.len
        call writeAsciiStr
        TEST_IO -str03.len, " <>"

        WRITE_STR_LIT {10,"writeAsciiStrz: "}
        mov esi, str03
        call writeAsciiStrz
        TEST_IO -str03.len, " <>"

    WRITE_STR_LIT {10}
END_FCN test_basic_output

DECL_FCN test_syscall_write_contract
    WRITE_STR_LIT {10,"testing contract for syscall write",10}

    mov ecx, 16
    mov edx, esp
    inc ecx
    .testLoop:
        sub ecx, 1
        jle .endLoop
        sub esp, 1

        WRITE_STR_LIT {10, "stack offset: "}
        ; mov eax, edx
        ; sub eax, esp
        mov edi, io_scratch_buffer
        WRITE_DEC esp
        WRITE_CHR ' '
        WRITE_DEC ecx
        WRITE_CHR ' '
        call ioWrite

        mov ebx, esp
        SYSCALL_WRITE STDOUT, str01, str01.len
        ; CALL_SYSCALL_WRITE STDOUT, str01, str01.len
        sub ebx, esp
        cmp ebx, 0
        jz .test01_ok
            pushad
            mov edi, io_scratch_buffer
            WRITE_STR_LIT {10, "Stack contract failed:  "}
            WRITE_0x
            WRITE_HEX_32 ebx
            WRITE_EOL
            call ioWrite
            popad
        .test01_ok:
        jmp .testLoop
    .endLoop:

    WRITE_STR_LIT{10,"done",10}
END_FCN test_syscall_write_contract

section .bss
%define A_SIZE 8
%define B_SIZE 14
%define C_SIZE 120
bufferA: resb A_SIZE
bufferB: resb B_SIZE
bufferC: resb C_SIZE
section .text

DECL_FCN test_set_flush_io
    WRITE_STR_LIT{10, "Test setIO / flushIO",10}

    WRITE_STR_LIT{"bufferA: "}
    SET_IO STDOUT, bufferA, A_SIZE
    WRITE_0x
    WRITE_HEX_32 dword 0x123098
    WRITE_CHR ' '
    WRITE_STR str01, str01.len
    WRITE_CHR ' '
    WRITE_DEC 0x123098
    mov esi, edi 
    FLUSH_IO STDOUT, bufferA, A_SIZE

    WRITE_STR_LIT{10,"overflow bufferA: "}
    SET_IO STDOUT, bufferA, A_SIZE
    mov edi, esi
    FLUSH_IO STDOUT, bufferA, A_SIZE

    WRITE_STR_LIT{10,"overflow bufferB: "}
    SET_IO STDOUT, bufferB, B_SIZE
    mov edi, esi
    FLUSH_IO STDOUT, bufferB, B_SIZE

    WRITE_STR_LIT{10,"overflow bufferC: "}
    SET_IO STDOUT, bufferC, C_SIZE
    mov edi, esi
    FLUSH_IO STDOUT, bufferC, C_SIZE

    WRITE_STR_LIT{10,"empty bufferA: "}
    SET_IO STDOUT, bufferA, A_SIZE
    FLUSH_IO STDOUT, bufferA, A_SIZE

    WRITE_STR_LIT{10,"bufferB: "}
    SET_IO STDOUT, bufferB, B_SIZE
    WRITE_0x
    WRITE_HEX_32 dword 0x123098
    WRITE_CHR ' '
    WRITE_STR str01, str01.len
    WRITE_CHR ' '
    WRITE_DEC 0x123098
    FLUSH_IO STDOUT, bufferB, B_SIZE

    WRITE_STR_LIT{10,"bufferC: "}
    SET_IO STDOUT, bufferC, C_SIZE
    WRITE_0x
    WRITE_HEX_32 dword 0x123098
    WRITE_CHR ' '
    WRITE_STR str01, str01.len
    WRITE_CHR ' '
    WRITE_DEC 0x123098
    FLUSH_IO STDOUT, bufferC, C_SIZE
END_FCN  test_set_flush_io

DECL_FCN test_lcg_random
    WRITE_STR_LIT {10,10,"lcgRand32:"}

    ; Write a table of N numbers. NUM_COLS must be a power of 2 minus 1 (3, 7, 15).
    %define NUM_COLS 7
    %define NUM_ROWS 20

    mov ecx, NUM_ROWS * (NUM_COLS + 1)
    mov edi, io_scratch_buffer
    .l1:
        ; Branch to write Eol + flush buffer every N elements.
        ; Note: this gets triggered on the first run, assuming NUM_COLS + 1 is a power of 2.
        mov eax, ecx
        and eax, NUM_COLS   ; write eol every N elements
        jz .writeEol
        push ecx

        ; Write table element
        call lcgRand32
        WRITE_HEX_32 eax
        WRITE_CHR ' '

        ; equiv to loop .l1
        pop ecx
        sub ecx, 1
        jg .l1
        .writeEol:
            cmp ecx, 0    ; special case for eax == 0:
            jz  .end_l1   ; exit + only write EOL + flush buffer if that's the case (no line num)
            push ecx

            ; Write a newline, followed by printing the column number as an 8-bit hex integer.
            WRITE_EOL
            mov eax, NUM_ROWS * (NUM_COLS + 1)
            sub eax, ecx
            WRITE_HEX_8 eax
            WRITE_CHR ' '

            ; Flush buffer, and continue loop
            call ioWrite
            pop ecx
            sub ecx, 1
            jg .l1
    .end_l1:
    WRITE_EOL
    call ioWrite

END_FCN  test_lcg_random












