;
; asmlib/objlib/allocator/static_allocator.inc
;
; StaticAllocator class implementation:
;   Provides an object-oriented interface to a simple allocator that allocates
;   out of a fixed size memory pool.
;
;   Can be used as the backend to other higher-level allocators (eg. PagedAllocator,
;   w/ FreeListAllocator to cache freed memory). This is sort-of required, as
;   StaticAllocator is actually incapable of freeing memory (it can obly allocate).
;
;   StaticAllocator is designed to be easy to use (use DECL_StaticAllocator macro
;   to define a global instance in 1 line), but is, as the name implies, static, and
;   operates on a fixed pool of memory hardcoded into the executable, and as such
;   will blow up spectacularly if you exceed this.
;  
;   Nevertheless, this should be quite sufficient for small assembly programs, and
;   programs that use a small, fixed and deterministic amount of memory at runtime.
;
;   For a more flexible approach, see the TBD DynamicAllocator, which will use
;   mmap() syscalls to dynamically allocate large memory pages, and will be
;   interchangable with StaticAllocator (and all IAllocator implementations).
;
; requires (included by)
;   asmlib/objlib/allocator.inc
;
section .data

; StaticAllocator class (implements IAllocator)
Class_StaticAllocator: istruc IAllocator
    DECL_Class_IObject TYPEID_STATIC_ALLOCATOR, MStaticAllocator
    DECL_Class_ctor    MStaticAllocator_ctor
    DECL_Class_dtor    null_method
    DECL_Class_toHash  null_method
    DECL_Class_toStr   null_method

    at IAllocator.alloc: MStaticAllocator_alloc
    at IAllocator.free:  null_method
iend

; StaticAllocator instance data (extends MObject)
struc MStaticAllocator
    MObject_FIELDS
    .onOutOfMemory: res_ptr_t 1
    .nextPtr:       res_ptr_t 1
    .remaining:     res_size_t 1
    .totalMem:      res_size_t 1
endstruc

; StaticAllocator initial instance data
MStaticAllocator_initFields: istruc MStaticAllocator
    DECL_DEFAULT_FIELDS_MObject Class_StaticAllocator
    at MStaticAllocator.nextPtr:       decl_ptr_t 0
    at MStaticAllocator.remainder:     decl_ptr_t 0
    at MStaticAllocator.totalMem:      decl_ptr_t 0
    at MStaticAllocator.onOutOfMemory: decl_ptr_t StaticAllocator_defaultOnOutOfMemoryHandler
iend
section .text

;
; There are two interfaces for creating a static allocator:
; 1) Create an instance at runtime using IObject_create + the MStaticAllocator ctor
; 2) Declare a global instance using DECL_StaticAllocator.
;
; Example 1: (in a function defn)
;   mov eax, <some memory location for the Static Allocator>
;   mov esi, <my buffer>
;   mov ecx, <my buffer size>
;   mov edx, Class_StaticAllocator
;   call IObject_create
;
;   ; optional:
;   mov [esi + MStaticAllocator.onOutOfMemory], <my handler>
;   
; Example 2: (at global scope)
;   DECL_StaticAllocator myAllocator, 4096 * 4096, StaticAllocator_defaultOnOutOfMemoryHandler
;   

; StaticAllocator.ctor
;   inout eax  instance
;   in    esi  memory_buffer
;   in    ecx  memory_size
;   in    edi  onOutOfMemory
MStaticAllocator_ctor:
    mov [eax + MStaticAllocator.nextPtr],       esi
    mov [eax + MStaticAllocator.remaining],     ecx
    mov [eax + MStaticAllocator.totalMem],      ecx
    ret

; DECL_StaticAllocator(label, size, onOutOfMemory handler)
%macro DECL_StaticAllocator 2-3
    [section .data]
    %1: istruc MStaticAllocator
        at MStaticAllocator.class:   decl_ptr_t Class_StaticAllocator
        at MStaticAllocator.rc:      decl_int_t RefCount_MAX
        at MStaticAllocator.nextPtr: decl_ptr_t %1.data_buffer
        at MStaticAllocator.remainder: decl_size_t %2
        at MStaticAllocator.totalMem:  decl_size_t %2
    %if %0 == 3
        at MStaticAllocator.onOutOfMemory: decl_ptr_t %3
    %else
        at MStaticAllocator.onOutOfMemory: decl_ptr_t StaticAllocator_defaultOnOutOfMemoryHandler
    %endif
    iend
    [section .bss]
    %1.data_buffer: resb %2
    __SECT__
%endmacro

; StaticAllocator onOutOfMemory handler:
;   esi    allocator instance
;   eax    attempted allocation
;
StaticAllocator_defaultOnOutOfMemoryHandler:
    mov ecx, [esi + MStaticAllocator.remaining]
    mov edx, [esi + MStaticAllocator.totalMem]
    mov bl, 0
    idiv bl
    ret

; StaticAllocator.alloc
;   in  esi allocator_instance
;   in  eax alloc_size
;   out eax allocated_ptr
StaticAllocator_alloc:
    push edx  ; save register: edx

    ; Adjust alloc_size to include AllocHeader
    add  eax, AllocHeader.size

    ; Check that we have enough memory for this allocation
    cmp [esi + MStaticAllocator.remaining], eax
    jl .outOfMemory
        ; Slice memory off of mem block
        sub  [esi + MStaticAllocator.remaining], eax
        push ptr_t [esi + MStaticAllocator.nextPtr]
        add  [esi + MStaticAllocator.nextPtr], eax
        pop edx  ; Set edx = allocated_ptr

        ; Set metadata (our allocator + alloc size)
        mov [edx + AllocHeader.size], eax
        mov [edx + AllocHeader.allocator], esi

        ; Adjust ptr to hide metadata (AllocHeader), and restore edx
        mov eax, edx
        add eax, AllocHeader.size
        pop edx
        ret
    .onOutOfMemory:
        pop edx  ; restore edx
        jmp [esi + MStaticAllocator.onOutOfMemory]


; No StaticAllocator_free method: StaticAllocator does not ever free memory.
; This is not a problem, as StaticAllocator is not intended to be used on its
; own; it acts as the backend (albeit one which can)
; (it's a backend allocator, which other allocators are built upon. This would
; be used as the backend to a PagedAllocator w/ frees cached using a FreeListAllocator,
; for example).



