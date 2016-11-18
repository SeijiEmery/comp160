; 
; src/algorithms/printutils.inc
;

;
; Macro utilities: print table
;

; define:
;   - TABLE_NUM_COLS (must be a power of 2 minus 1: 1, 3, 7, 15)
;   - TABLE_NUM_ROWS (any positive integer)
;   - TABLE_EACH_ELEMENT (macro w/ 0 args)
;   – TABLE_EACH_LINE
;       - run each time an Eol (to end the column) is needed / requested
;       - takes one argument, the table index (will be a power of 2)
; then instantiate TABLE_PRINT_ELEMS (no arguments)

%macro TABLE_PRINT_ELEMS 0
    push kax
    push kcx
    mov kcx, TABLE_NUM_ROWS * (TABLE_NUM_COLS + 1)
    %%printTable:
        ; Branch to write Eol + flush buffer every N elements.
        ; Note: this gets triggered on the first run, assuming NUM_COLS + 1 is a power of 2.
        mov kax, kcx
        and kax, TABLE_NUM_COLS   ; write eol every N elements
        jz %%writeLine
        push kcx

        TABLE_EACH_ELEMENT

        pop kcx
        loop %%printTable
    %%writeLine:
        sub kcx, 1
        jle %%endTable
        push kcx 

        mov kax, TABLE_NUM_ROWS * (TABLE_NUM_COLS + 1)
        sub kax, kcx
        TABLE_EACH_LINE kax
        pop kcx
        jmp %%printTable
    %%endTable:
    pop kcx
    pop kax
%endmacro