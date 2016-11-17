
; DECL_ARRAY( label, type, contents )
%macro DECL_ARRAY 3
%1: TYPE_DECL(%2) %3
%1.length: equ ($ - %1) / TYPE_SIZE(%2)
%1.sizeof: equ TYPE_SIZE(%2)
%endmacro

; DECL_STRING( label, string )
%macro DECL_STRING 2
%1: char_t %2, 0
%1.length: equ ($ - %1) / TYPE_SIZE(char_t)
%1.sizeof: equ TYPE_SIZE(%2)
%endmacro

; DECL_FCN( name )
%macro DECL_FCN 1
%1:
    push kbp
    mov kbp, ksp
%endmacro

; END_FCN( name )
%macro END_FCN 1
    mov ksp, kbp
    pop kbp
    ret
%endmacro

; STACK_ALLOC( size )
%macro STACK_ALLOC 1
    sub ksp, %1
%endmacro

; STACK_FREE( size )
; Note: optional within DECL_FCN / END_FCN.
%macro STACK_FREE 1
    add ksp, %1
%endmacro

; Array structure
struc Array
    .ptr:          res_ptr_t 1
    .length:       res_dword 1
    .element_size: res_dword 1
endstruc

; CREATE_ARRAY( location, array_ptr, array_length, array_elementSize )
; Loads an array structure into memory at 'location' given array fields.
%macro CREATE_ARRAY 4
    mov [%1 + Array.ptr],          %2
    mov [%1 + Array.length],       %3
    mov [%1 + Array.element_size], %4
%endmacro

; CREATE_ARRAY_FROM_GLOBAL( location, label )
%macro CREATE_ARRAY_FROM_GLOBAL 2
    CREATE_ARRAY %1, %2, {%2}.length, {%2}.sizeof
%endmacro
