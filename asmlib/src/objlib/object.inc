; asmlib/src/objlib/object.inc
;
; requires
;   algorithms/algorithms.inc
;

%macro IObject_METHODS
    .typeid:             res_int_t 1
    .instanceSize:       res_size_t 1
    .instanceInitFields: res_size_t 1
    .ctor:    res_ptr_t 1
    .dtor:    res_ptr_t 1
    ; .toStr:   res_ptr_t 1
    ; .fromStr: res_ptr_t 1
    ; .toHash:  res_ptr_t 1
    ; .opCmp:   res_ptr_t 1
%endmacro

%macro MObject_METHODS
    .cls:  res_ptr_t 1
    .rc:   res_int_t 1
%endmacro

struc IObject
    IObject_METHODS
endstruc

struc MObject
    MObject_METHODS
endstruc

; MAYBE_ASSIGN( field, value )
%macro MAYBE_ASSIGN 2
    cmp %1, 0
    jz %%skip
        mov %1, %2
    %%skip:
%endmacro

; null_method (does nothing)
null_method:
    ret

; IObject.create( inout eax ptr, in edx class_ptr )
IObject_create:
    push ecx      ; Save registers

    ; Copy default fields
    mov edi, eax
    mov esi, [ edx + IObject.instanceInitFields ]
    mov ecx, [ edx + IObject.instanceSize ]
    call memcpy

    ; Set rc = 0, class = <class>
    mov [ eax + MObject.rc ], int_t 0
    mov [ eax + MObject.cls ], edx

    pop ecx      ; Restore registers

    ; Call ctor
    jmp [ edx + IObject.ctor ]

; IObject.retain( inout eax instance )
IObject_retain:
    inc [ eax + MObject.rc ]
    ret

; IObject.release( inout eax instance )
IObject_release:
    sub [ eax + MObject.rc ], 1
    jg .noRelease
        ; Call dtor
        push edx
        mov  edx, [ eax + MObject.cls ]
        call [ edx + IObject.dtor ]
        pop edx

        ; Set eax = 0 to indicate released
        mov eax, 0
    .noRelease:
    ret

