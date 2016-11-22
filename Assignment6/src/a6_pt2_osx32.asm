; Assignment 6, part 2
;   Implements a boolean "calculator", with various options implemented using a FSM.
;
; Target platform: osx, 32-bit
;   depends on asmlib (../asmlib/)
;   uses rake (a ruby-based build system) for nasm builds
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: whatever; ported from win32 version.
; Revisions, etc: https://github.com/SeijiEmery/comp160/tree/master/Assignment6
;

%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

section .data
    ; Original options table. Now generated procedurally.

    ; lit_optionsMenu db "---- Boolean Calculator ----",13,10, \
    ;     "Enter:",13,10, \
    ;     "1. x AND y",13,10, \
    ;     "2. x OR y" ,13,10, \
    ;     "3. NOT x",13,10, \
    ;     "4. x XOR y",13,10, \
    ;     "5. Exit Program",13,10,0

    ; Various strings for prompts, etc.

    ; Menu prompt.
    lit_menuHeader db "--- Boolean Calculator ---",13,10,"Enter:",13,10,0
    lit_menuSep1   db ". ",0
    lit_menuSep2   db 13,10,0
    lit_promptStr  db "> ",0

    ; 
    lit_hexPrompt1 db "Input the first 32-bit hexadecimal operand: ",0
    lit_hexPrompt2 db "Input the second 32-bit hexadecimal operand: ",0
    lit_hexResult  db "The 32-bit hexadecimal result is: ",0

    ; Operation strings (used in menu prompt, etc)
    lit_and   db "AND",0
    lit_or    db "OR",0
    lit_not   db "NOT",0
    lit_xor   db "XOR",0
    lit_exit  db "Exit Program",0

    ; Calculator op table. This procedurally defines which operations correspond
    ; to what options, their semantics, etc.
    calculatorOp_fcns  dd opAnd,   opOr,   opNot,   opXor,   opExit      ; function pointers
    calculatorOp_argc  dd 2,       2,      1,       2,       0           ; # function args (eax, ebx)
    calculatorOp_names dd lit_and, lit_or, lit_not, lit_xor, lit_exit    ; string names
    NUM_OPS equ 5

    ; Calculator internal run state
    calculator_nextOp  dd 0
    calculator_arg0    dd 0
    calculator_arg1    dd 0
    calculator_running dd 0  ; Set this to 0 to terminate the calculator.
section .text

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
opExit: mov [calculator_running], dword 0
    ret

%macro mWriteString 1
    mov edx, %1
    call WriteString
%endmacro
%macro mWrite 1
section .data
    %%str: db %1,0
section .text
    mWriteString %%str
%endmacro

;
; Calculator entrypoint + run loop. Calls into everything else.
;
runCalculator:
    mov [calculator_running], dword 1
    .runLoop:
        ; Get next option
        call calculatorGetNextOption
        mov [calculator_nextOp], eax

        ; Display which option the user chose
        mWrite "executing operation "
        mov edx, [calculatorOp_names + 4 * eax]
        call WriteString
        mWrite ": "
        call Crlf

        ; call calculatorGetArgs to prompt user for ecx args and store
        ; values into calculator_arg<n>.
        mov ecx, [calculatorOp_argc + 4 * eax]
        call calculatorGetArgs

        ; Execute next operation
        mov edx, [calculator_nextOp]
        mov eax, [calculator_arg0]
        mov ebx, [calculator_arg1]
        mov edx, [calculatorOp_fcns + 4 * edx]
        call edx

        ; Check that we should still be running (if calculator_running set to 0, will terminate immediately)
        cmp [calculator_running], dword 0
        jz  .endRunLoop

        ; Display result
        mWriteString lit_hexResult
        call WriteHex
        call Crlf
        call Crlf
        jmp .runLoop
    .endRunLoop:
    ret

; calculatorGetArgs ( in ecx numArgs ) => prompt N times for hex values 
; using lit_hexPrompt<n> + store in calculator_arg<n>.
calculatorGetArgs:
    dec ecx
    jl  .skipPrompt
        mWriteString lit_hexPrompt1
        call ReadHex
        mov [calculator_arg0], eax
    dec ecx
    jl  .skipPrompt
        mWriteString lit_hexPrompt2
        call ReadHex
        mov [calculator_arg1], eax
    .skipPrompt:
    ret


; Displays calculator menu + asks for a user menu option (repeats until it gets valid input).
; Result stored in eax.
calculatorGetNextOption:
    ; Display menu.
    call displayCalculatorMenu

    ; Prompt for menu option.
    ; Repeat until input falls within [min, max).
    mov ebx, 1              ; min accepted value
    mov ecx, NUM_OPS+1      ; max accepted value
    mov edx, lit_promptStr  ; prompt string
    call promptRange
    dec eax
    ret


; Displays text for menu options. Builds this procedurally based on calculatorOp_**** values.
displayCalculatorMenu:
    mov edx, lit_menuHeader
    call WriteString

    mov ecx, 0
    writeMenuOptions:
        mov eax, ecx
        inc eax
        call WriteDec
        mWrite ". "

        mov eax, [calculatorOp_names + 4 * ecx]
        mov ebx, [calculatorOp_argc  + 4 * ecx]
        call writeBinaryOpStr
        
        call Crlf
        inc ecx
        cmp ecx, NUM_OPS
        jl writeMenuOptions
    ret


; writeBinaryOp (in eax op_str, in ebx num_args)
; writes:
;    "x " op_str " y"  if num_args == 2
;    op_str " x"       if num_args == 1
;    op_str            if num_args == 0
writeBinaryOpStr:
    cmp ebx, 2
    jl .lessThan2Args
        push eax
        mWrite "x "
        pop edx
        call WriteString
        mWrite " y"
        jmp .end
    .lessThan2Args:
        mov edx, eax
        call WriteString
        test ebx, ebx
        jz .end
        mWrite " x"
    .end:
    ret


; Prompts user for an integer in [ebx, ecx), displaying a prompt string in edx each time.
; Repeats until user input falls within this range
promptRange:
    .doPrompt:
        call WriteString
        call ReadDec
        cmp  eax, ebx
        jl   .repeatPrompt
        cmp  eax, ecx
        jl  .endPrompt
    .repeatPrompt:
        jmp .doPrompt
    .endPrompt:
        call Crlf
        ret

_main:
    call runCalculator
    ret