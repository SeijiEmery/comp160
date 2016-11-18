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
    push eax
    push ecx
    mov ecx, TABLE_NUM_ROWS * (TABLE_NUM_COLS + 1)
    %%printTable:
        ; Branch to write Eol + flush buffer every N elements.
        ; Note: this gets triggered on the first run, assuming NUM_COLS + 1 is a power of 2.
        mov eax, ecx
        and eax, TABLE_NUM_COLS   ; write eol every N elements
        jz %%writeLine
        push ecx

        TABLE_EACH_ELEMENT

        pop ecx
        loop %%printTable
    %%writeLine:
        sub ecx, 1
        jle %%endTable
        push ecx 

        mov eax, TABLE_NUM_ROWS * (TABLE_NUM_COLS + 1)
        sub eax, ecx
        TABLE_EACH_LINE eax
        pop ecx
        jmp %%printTable
    %%endTable:
    pop ecx
    pop eax
%endmacro