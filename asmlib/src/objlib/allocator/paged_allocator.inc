

section .data
; PagedAllocator class (implements IAllocator)
Class_PagedAllocator: istruc IAllocator
    DECL_Class_IObject TYPEID_FREELIST_ALLOCATOR, MPagedAllocator
    DECL_Class_ctor    MPagedAllocator_ctor
    DECL_Class_dtor    MPagedAllocator_dtor
    DECL_Class_toHash  null_method
    DECL_Class_toStr   null_method

    at IAllocator.alloc:  MPagedAllocator_alloc
    at IAllocator.free:   MPagedAllocator_free
iend

; PagedAllocator instance data (extends MObject)
struc MPagedAllocator
    MObject_FIELDS
    .freelist:        res_ptr_t 1
    .pageContext:     resb PageContext.size
endstruc

; PagedAllocator initial instance data
MPagedAllocator_initFields: istruc MStaticAllocator
    DECL_DEFAULT_FIELDS_MObject Class_PagedAllocator
    at MPagedAllocator.freelist:        decl_ptr_t 0
    at MPagedAllocator.pageContext:     decl_ptr_t 0, 0, 0, 0
iend
section .text

; PagedAllocator.ctor
;   inout eax instance
;   in    esi parentAllocator
;   in    ecx pageSize
PagedAllocator_ctor:
    lea eax, [eax + MPagedAllocator.pageContext]
    jmp createPageContext


; PagedAllocator.dtor
;   inout eax instance
PagedAllocator_dtor:
    lea eax, [eax + MPagedAllocator.pageContext]
    jmp releasePageContext

; PagedAllocator_alloc
;   inout esi allocator_instance
;   in    eax alloc_size
;   out   eax allocated_ptr
PagedAllocator_alloc:
    push edx   ; save registers
    push ecx

    ; Adjust alloc size to include AllocHeader.
    add eax, AllocHeader.size

    mov  edx, [esi + MPagedAllocator.freelist]
    test edx, edx
    jz .doPagedAlloc
        call popFreeList
        test edx, edx
        jz .doPagedAlloc

        ; Set parent allocator (this)
        mov [edx + AllocHeader.allocator], esi
        mov eax, edx
        jmp .exit
    .doPagedAlloc:
        lea ecx, [eax + MPagedAllocator.pageContext]
        push eax
        call pagedAlloc
        pop edx
        mov [eax + AllocHeader.allocSize], edx
        mov [eax + AllocHeader.allocator], esi
    .exit:
        pop ecx
        pop edx
        ret

; PagedAllocator_free
;   inout esi  allocator_instance
;   in    eax  allocated_ptr_to_free
PagedAllocator_free:
    push edx
    push ecx
    sub eax, AllocHeader.size
    mov ecx, [eax + AllocHeader.allocSize]
    lea edx, [esi + MPagedAllocator.freelist]
    call pushFreeList
    pop ecx
    pop edx
    ret

