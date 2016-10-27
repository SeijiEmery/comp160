;
; Assignment 6, part 2
;   Implements a boolean "calculator".
;

INCLUDE Irvine32.inc
INCLUDE Macros.inc

STRBUF_SIZE equ 1024
.data
    lit_optionsMenu BYTE "---- Boolean Calculator ----",13,10, \
        "Enter:",13,10, \
        "1. x AND y",13,10, \
        "2. x OR y" ,13,10, \
        "3. NOT x",13,10, \
        "4. x XOR y",13,10, \
        "5. Exit Program",13,10,0
    lit_promptStr  BYTE "> ",0
    lit_hexPrompt1 BYTE "Input the first 32-bit hexadecimal operand: ",0
    lit_hexPrompt2 BYTE "Input the second 32-bit hexadecimal operand: ",0
    lit_hexResult  BYTE "The 32-bit hexadecimal result is: ",0

    ; Temp variables. Might as well store them here b/c a) convenient, b) using
    ; the above memory, so will be in cache anyways.
    var_currentOp DWORD 0
    var_x         DWORD 0
    var_y         DWORD 0

    op_and  EQU 1
    op_or   EQU 2
    op_not  EQU 3
    op_xor  EQU 4
    op_exit EQU 5

    op_min EQU 1
    op_max EQU 5    
.code

runBooleanCalculator PROC
    push ebp       ; save stack frame
    mov ebp, esp

    ; Main loop -- repeat until we choose the exit option.
    L1:
        ; Display options
        mov edx, OFFSET lit_optionsMenu
        call WriteString

        ; Ask user for integer corresponding to a menu option.
        ; If invalid, will repeat this prompt until getting a valid result (0-5).
        L2:
            mov edx, OFFSET lit_promptStr
            call WriteString
            call ReadInt
            call Crlf

            cmp eax, op_min
            jl invalidOption
            cmp eax, op_max
            jg invalidOption
            jmp L2_end
        invalidOption:

            jmp L2
        L2_end:
        mov var_currentOp, eax

        ; Handle exit op
        cmp eax, op_exit
        jz  L1_end

        ; Prompt for first argument
        mov edx, OFFSET lit_hexPrompt1
        call WriteString
        call ReadHex
        mov  var_x, eax
        call Crlf
       
        ; Skip second arg iff unary (op_not)
        cmp var_currentOp, op_not
        jz  execOpNot

        ; Prompt for second argument
        mov edx, OFFSET lit_hexPrompt2
        call WriteString
        call ReadHex
        mov  var_y, eax
        call Crlf

        ;
        ; Exec binary operation
        ;

        ; Load x / y values into eax / edx
        xchg edx, eax
        mov eax, var_x

        ; Jump to corresponding op.
        mov ebx, var_currentOp
        cmp ebx, op_and
        jz  execOpAnd
        cmp ebx, op_or
        jz  execOpOr
        jmp execOpXor

        execOpAnd:
            and eax, edx
            jmp printResult
        execOpOr:
            or eax, edx
            jmp printResult
        execOpNot:        
            mov edx, -1   ; (not a) == (xor a, 0xFFFFFFFF)
        execOpXor:
            xor eax, edx
            jmp printResult
        printResult:
            mov edx, OFFSET lit_hexResult
            call WriteString
            call WriteHex
        call Crlf
        call Crlf
        jmp L1
    L1_end:
    mov esp, ebp   ; restore stack frame
    pop ebp 
    ret
runBooleanCalculator ENDP

main PROC
    call runBooleanCalculator
    exit
main ENDP
END main