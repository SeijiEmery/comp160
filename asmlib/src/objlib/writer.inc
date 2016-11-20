
struc IWriter
    IObject_METHODS

    ; method writebuf
    ;   inout eax writer
    ;   in    esi buffer_ptr
    ;   in    ecx buffer_size 
    .writebuf: res_ptr_t 1

    ; method writef
    ;   inout eax writer
    ;   in    esi format_str
    ;   stack args...
    .writef: res_ptr_t 1
endstruc

%include "src/objlib/io/buffer.inc"
%include "src/objlib/io/filewriter.inc"
%include "src/objlib/io/stringwriter.inc"
