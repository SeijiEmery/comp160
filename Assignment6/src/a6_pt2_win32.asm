;
; Assignment 6, part 2
;   Implements a boolean "calculator".
;

INCLUDE Irvine32.inc
INCLUDE Macros.inc


.data
    ; Original options table. Now generated procedurally.

    ; lit_optionsMenu BYTE "---- Boolean Calculator ----",13,10, \
    ;     "Enter:",13,10, \
    ;     "1. x AND y",13,10, \
    ;     "2. x OR y" ,13,10, \
    ;     "3. NOT x",13,10, \
    ;     "4. x XOR y",13,10, \
    ;     "5. Exit Program",13,10,0

    ; Various strings for prompts, etc.

    ; Menu prompt.
    lit_menuHeader BYTE "--- Boolean Calculator ---",13,10,"Enter:",13,10,0
    lit_menuSep1   BYTE ". ",0
    lit_menuSep2   BYTE 13,10,0
    lit_promptStr  BYTE "> ",0

    ; 
    lit_hexPrompt1 BYTE "Input the first 32-bit hexadecimal operand: ",0
    lit_hexPrompt2 BYTE "Input the second 32-bit hexadecimal operand: ",0
    lit_hexResult  BYTE "The 32-bit hexadecimal result is: ",0

    ; Operation strings (used in menu prompt, etc)
    lit_and   BYTE "AND",0
    lit_or    BYTE "OR",0
    lit_not   BYTE "NOT",0
    lit_xor   BYTE "XOR",0
    lit_exit  BYTE "Exit Program",0

    ; Calculator op table. This procedurally defines which operations correspond
    ; to what options, their semantics, etc.
    calculatorOp_fcns  DWORD opAnd,   opOr,   opNot,   opXor,   opExit      ; function pointers
    calculatorOp_argc  DWORD 2,       2,      1,       2,       0           ; # function args (eax, ebx)
    calculatorOp_names DWORD lit_and, lit_or, lit_not, lit_xor, lit_exit    ; string names
    NUM_OPS equ LENGTHOF calculatorOp_fcns

    ; Calculator internal run state
    calculator_nextOp  DWORD ?
    calculator_arg0    DWORD ?
    calculator_arg1    DWORD ?
    calculator_running DWORD ?  ; Set this to 0 to terminate the calculator.
.code

;
; Calculator operations. Very flexible -- just change this and the table
; above to change calculator semantics / operations (menus will be updated, etc).
;
; Each operation is a function that takes N (0-2) integer operations
; corresponding to calculatorOp_argc. eax = arg0, ebx = arg1.
; Values undefined for arg[i] if i >= argc.
;
opAnd: and eax, ebx
    ret
opOr: or eax, ebx
    ret
opNot: xor eax, -1
    ret
opXor: xor eax, ebx
    ret
opExit: mov calculator_running, 0
    ret

;
; Calculator entrypoint + run loop. Calls into everything else.
;
runCalculator PROC
    mov calculator_running, 1
    runLoop:
        ; Get next option
        call calculatorGetNextOption
        mov calculator_nextOp, eax

        ; Display which option the user chose
        mWrite "executing operation "
        mov edx, [calculatorOp_names + TYPE calculatorOp_names * eax]
        call WriteString
        mWrite ": "
        call Crlf

        ; call calculatorGetArgs to prompt user for ecx args and store
        ; values into calculator_arg<n>.
        mov ecx, [calculatorOp_argc + eax * TYPE calculatorOp_argc]
        call calculatorGetArgs

        ; Execute next operation
        mov edx, calculator_nextOp
        mov eax, calculator_arg0
        mov ebx, calculator_arg1
        mov edx, [calculatorOp_fcns + edx * TYPE calculatorOp_fcns]
        call edx

        ; Check that we should still be running (if calculator_running set to 0, will terminate immediately)
        cmp calculator_running, 0
        jz  endRunLoop

        ; Display result
        mWriteString lit_hexResult
        call WriteHex
        call Crlf
        call Crlf
        jmp runLoop
    endRunLoop:
    ret
runCalculator ENDP

; calculatorGetArgs ( in ecx numArgs ) => prompt N times for hex values 
; using lit_hexPrompt<n> + store in calculator_arg<n>.
calculatorGetArgs PROC
    dec ecx
    jl  skipPrompt
        mWriteString lit_hexPrompt1
        call ReadHex
        mov calculator_arg0, eax
    dec ecx
    jl  skipPrompt
        mWriteString lit_hexPrompt2
        call ReadHex
        mov calculator_arg1, eax
    skipPrompt:
    ret
calculatorGetArgs ENDP


; Displays calculator menu + asks for a user menu option (repeats until it gets valid input).
; Result stored in eax.
calculatorGetNextOption PROC
    ; Display menu.
    call displayCalculatorMenu

    ; Prompt for menu option.
    ; Repeat until input falls within [min, max).
    mov ebx, 1              ; min accepted value
    mov ecx, NUM_OPS+1      ; max accepted value
    mov edx, OFFSET lit_promptStr  ; prompt string
    call promptRange
    dec eax
    ret
calculatorGetNextOption ENDP


; Displays text for menu options. Builds this procedurally based on calculatorOp_**** values.
displayCalculatorMenu PROC
    mov edx, OFFSET lit_menuHeader
    call WriteString

    mov ecx, 0
    writeMenuOptions:
        mov eax, ecx
        inc eax
        call WriteDec
        mWrite ". "

        mov eax, [calculatorOp_names + ecx * TYPE calculatorOp_names]
        mov ebx, [calculatorOp_argc + ecx * TYPE calculatorOp_argc]
        call writeBinaryOpStr
        
        call Crlf
        inc ecx
        cmp ecx, NUM_OPS
        jl writeMenuOptions
    ret
displayCalculatorMenu ENDP


; writeBinaryOp (in eax op_str, in ebx num_args)
; writes:
;    "x " op_str " y"  if num_args == 2
;    op_str " x"       if num_args == 1
;    op_str            if num_args == 0
writeBinaryOpStr PROC
    .if ebx >= 2
        push eax
        mWrite "x "
        pop edx
        call WriteString
        mWrite " y"
    .else
        mov edx, eax
        call WriteString
        .if ebx == 1
            mWrite " x"
        .endif
    .endif
    ret
writeBinaryOpStr ENDP


; Prompts user for an integer in [ebx, ecx), displaying a prompt string in edx each time.
; Repeats until user input falls within this range
promptRange PROC
    doPrompt:
        call WriteString
        call ReadDec
        jc   repeatPrompt
        cmp  eax, ebx
        jl   repeatPrompt
        cmp  eax, ecx
        jle  endPrompt
    repeatPrompt:
        jmp doPrompt
    endPrompt:
        call Crlf
        ret
promptRange ENDP


main PROC
    call runCalculator
    exit
main ENDP
END main