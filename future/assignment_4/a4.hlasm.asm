
function IntArray_reverse (inout eax array) {

    ; Function parameters: (type semantics) (register) (identifier)
    ;   – in: value is passed in via this register. If the register is not used for a corresponding out,
    ;         and is not declared volatile, will be zeroed before function exit
    ;   - out: value is passed out via this register. Overwrites previous contents.
    ;   – inout: value is used for input and output. Original value will be saved + restored if the register
    ;         is used for anything else
    ;   - volatile: the contents of this register can/will be overwritten
    ;   – All of the above function as variable declarations.
    ;   - parameters can also be declared on the stack (eg. stack byte -4 a, stack int -5 b).
    ;
    ; Function call semantics:
    ;   – any registers that will _not_ be saved, and we do _not_ have marked as volatile in the current
    ;     context will be pushed
    ;   – parameters are moved into corresponding registers as defined by the function interface and/or pushed to the stack
    ;   – call instruction
    ;

    ; var declarations:
    ;   - assigns an identifier to a register (var assignment: expands to mov, lea, or xor)
    ;   - when a register gets overwritten / reassigned, the previous value will be saved using push / pop if:
    ;       – we use the previous value later
    ;       - the register was not yet used in this function and is _not_ marked as volatile
    ;   – all exit points will / must inject stack preservation instructions before returing
    ;       - this could just be a label: instead of just returning, we jump to our function return label
    ;         and pop registers, restore the stack frame, and ret from there.


    var esi front = &[array + INT_ARRAY_DATA_OFFSET]
    var ecx size  = [array + INT_ARRAY_SIZE_OFFSET]
    var eax elementSize = [array + INT_ARRAY_ELEMENT_SIZE_OFFSET]

    if size != 0
        size -= 1
        if elementSize == 4
            var edi back = front + size * 4
            var ecx increment = 4
            jmp .reverseLoop
        elif elementSize == 2
            var edi back = front + size * 2
            var ecx increment = 2
            jmp .reverseLoop
        else
            var edi back = front + size
            var ecx increment = 1
            jmp .reverseLoop
        endif
    endif
    fwritef(stdout, "\nType error: invalid size for array element: 0x%h\n", array)
    exit(-1)

    .reverseLoop:
        while front < back
            var eax a = [front]  ; fucked up here: these should actually be separate loops...
            var ebx b = [back]
            [front] = b
            [back]  = a
            front += increment
            back  -= increment
        endwhile

endfunction



