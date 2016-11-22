
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
    %%str: db %1,0
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
    call test_parseInt
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

    ; Table-printing pseudo-template defined in asmlib.inc

    ; Define num cols + rows. Cols must be power of 2 minus 1 (3, 7, 15)
    %define TABLE_NUM_COLS 7
    %define TABLE_NUM_ROWS 20

    ; This gets run for each element in the table
    %macro TABLE_EACH_ELEMENT 0
        call lcgRand32
        WRITE_HEX_32 eax
        WRITE_CHR ' '
    %endmacro

    ; This gets run for each line (before printing elements)
    ; in the table
    %macro TABLE_EACH_LINE 1
        WRITE_EOL
        WRITE_HEX_8 %1
        WRITE_CHR ' '
        call ioWrite
    %endmacro

    ; Setup I/O before table
    mov edi, io_scratch_buffer

    ; Instantiate template
    TABLE_PRINT_ELEMS
    ; push eax
    ; push ecx
    ; mov ecx, TABLE_NUM_ROWS * (TABLE_NUM_COLS + 1)
    ; .printTable:
    ;     ; Branch to write Eol + flush buffer every N elements.
    ;     ; Note: this gets triggered on the first run, assuming NUM_COLS + 1 is a power of 2.
    ;     mov eax, ecx
    ;     and eax, TABLE_NUM_COLS   ; write eol every N elements
    ;     jz .writeLine
    ;     push ecx

    ;     TABLE_EACH_ELEMENT

    ;     pop ecx
    ;     loop .printTable
    ; .writeLine:
    ;     sub ecx, 1
    ;     jle .endTable
    ;     push ecx

    ;     mov eax, TABLE_NUM_ROWS * (TABLE_NUM_COLS + 1)
    ;     sub eax, ecx
    ;     TABLE_EACH_LINE eax
    ;     pop ecx
    ;     jmp .printTable
    ; .endTable:
    ; pop ecx
    ; pop eax

    ; End table
    WRITE_EOL
    call ioWrite
    LCG_SET_SEED dword 0

    WRITE_STR_LIT {10,"lcgRandRange(100)"}
    mov edi, io_scratch_buffer

    %macro TABLE_EACH_ELEMENT 0
        mov eax, 100
        call lcgRandRange
        WRITE_DEC eax
        WRITE_CHR ' '
    %endmacro
    %macro TABLE_EACH_LINE 1
        WRITE_EOL
        WRITE_CHR ' '
        WRITE_CHR ' '
        call ioWrite
    %endmacro

    TABLE_PRINT_ELEMS

    WRITE_EOL
    call ioWrite
    LCG_SET_SEED dword 0

END_FCN  test_lcg_random


section .data
    lit_failMsg: decl_char_t "FAIL",10,0
    lit_failMsg.length: equ ($ - lit_failMsg) / sizeof_char_t
    lit_failMsg.sizeof: equ sizeof_char_t

    ; DECL_STRING lit_failMsg, "FAIL: "
    DECL_STRING lit_arrow,   " => "
section .text

; doParseIntTest
;   in ksi input
;   in kbx base
;   in kdx expected
doParseIntTest:
    push ksi
    call parseInt
    pop  ksi
    push kax
    mov kdi, io_scratch_buffer
    WRITE_CHR 39
    WRITE_STRZ ksi
    WRITE_STR_LIT2 {39," => "}
    WRITE_DEC  kax
    pop kax
    cmp kax, kdx
    jz .ok
        WRITE_STR_LIT2 {" != "}
        WRITE_DEC kdx
        WRITE_STR_LIT2 {": FAIL!",10}
        jmp .done
    .ok:
        WRITE_STR_LIT2 {": OK",10}
    .done:
    call ioWrite
    ret

; PARSE_INT_TEST input string, base, expected
%macro PARSE_INT_TEST 3
section .data
    %%input: db %1,0
section .text
    mov ksi, %%input
    mov kbx, %2
    mov kdx, %3
    call doParseIntTest
%endmacro

DECL_FCN test_parseInt
section .data
    DECL_STRING .input, ""
section .text
    WRITE_STR_LIT {10,"parseInt tests:",10}
    PARSE_INT_TEST "",  10, 0
    PARSE_INT_TEST "",  16, 0

    PARSE_INT_TEST "5", 10, 5
    PARSE_INT_TEST "5", 16, 5

    PARSE_INT_TEST "0", 16, 0
    PARSE_INT_TEST "9", 16, 9
    PARSE_INT_TEST "a", 16, 10
    PARSE_INT_TEST "b", 16, 11
    PARSE_INT_TEST "f", 16, 15
    PARSE_INT_TEST "A", 16, 10
    PARSE_INT_TEST "F", 16, 15

    PARSE_INT_TEST "12cf", 16, 0x12cf
    PARSE_INT_TEST "12CF", 16, 0x12CF
    PARSE_INT_TEST "12cf", 10, 12
    PARSE_INT_TEST "12CF", 10, 12

    PARSE_INT_TEST "-a1", 16, -0xA1

    PARSE_INT_TEST "100", 10, 100
    PARSE_INT_TEST "100", 16, 256
    PARSE_INT_TEST "100", 2,  4
    PARSE_INT_TEST "-102498109", 10, -102498109
    PARSE_INT_TEST "deadbeef", 16, 0xdeadbeef
    PARSE_INT_TEST "102984() ", 10, 102984
END_FCN test_parseInt

