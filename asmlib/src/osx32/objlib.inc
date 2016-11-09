
%macro mBaseObject_fields
    .type RESD 1
%endmacro
struc BaseObject
    mBaseObject_fields
endstruc

%macro mIObject_fields
    .typeid RESD 1
    .sizeof RESD 1
%endmacro
struc IObject
    mIObject_fields
endstruc

%macro mIAllocator_fields
    mIObject_fields
    .alloc RESD 1
    .free  RESD 1
%endmacro
struc IAllocator
    mIAllocator_fields
endstruc

typeid_None      equ 0
typeid_Allocator equ 1
typeid_String    equ 2
typeid_Number    equ 3


;
; Memory allocators:
;
struc FreeNode
    .allocSz:  RESD 1  
    .nextNode: RESD 1
endstruc

;
; FixedAlocator: super-basic IAllocator that allocates from a fixed memory block.
;
struc FixedAllocator
    mBaseObject_fields
    .ptr: RESD 1
    .rem: RESD 1
    .freelist: RESD 1
    .onPanic:  RESD 1
endstruc
section .data
    typeinfo_FixedAllocator: istruc IAllocator
        at IAllocator.type,   dd typeid_Allocator
        at IAllocator.sizeof, dd FixedAllocator.size
        at IAllocator.alloc,  dd FixedAllocator_alloc
        at IAllocator.free,   dd FixedAllocator_free
    iend
section .text

; FixedAllocator.init():
;   in esi: ptr to FixedAllocator memory
;   in eax: ptr to memory block
;   in ecx: mem block size
;   in edx: ptr to panic handler
DECL_FCN FixedAllocator_init
    mov [esi + FixedAllocator.type], DWORD typeinfo_FixedAllocator
    mov [esi + FixedAllocator.ptr], eax
    mov [esi + FixedAllocator.rem], ecx
    mov [esi + FixedAllocator.freelist], DWORD 0
    mov [esi + FixedAllocator.onPanic], edx
END_FCN  FixedAllocator_init

; FixedAllocator.alloc():
;   in  esi: ptr to FixedAllocator
;   in  ecx: allocation size
;   out eax: allocated ptr 
DECL_FCN FixedAllocator_alloc
    mov eax, [esi + FixedAllocator.freelist]
    cmp eax, 0
    jz  .blockAlloc
    .freelistAlloc:
        .searchNode:
            cmp [eax + FreeNode.allocSz], ecx
            jge .foundNode

            mov eax, [eax + FreeNode.nextNode]
            jz .blockAlloc
            jmp .searchNode
        .foundNode:
            add eax, 4
            jmp .end
    .blockAlloc:
        mov eax, [esi + FixedAllocator.ptr]
        add eax, [esi + FixedAllocator.rem]

        mov [eax], ecx
        add eax, 4

        sub [esi + FixedAllocator.rem], ecx
        jle .panic
        jmp .end
    .panic:
        cmp [esi + FixedAllocator.onPanic], 0
        jz  .hardPanic
        call [esi + FixedAllocator.onPanic]
        .hardPanic:
            ; Out of memory!
            ; TBD
    .end:
END_FCN  FixedAllocator_alloc

; FixedAllocator.free():
;   in esi: ptr to FixedAllocator
;   in eax: previously allocated ptr
DECL_FCN FixedAllocator_free
    push ebx
    mov ebx, [esi + FixedAllocator.freelist]
    sub eax, 4
    mov [eax + FreeNode.nextNode], ebx
    mov [esi + FixedAllocator.freelist], eax
    pop ebx
END_FCN  FixedAllocator_free


;
; PoolAllocator:
;
struc PoolAllocator
    mBaseObject_fields
    .parentAllocator: RESD 1
    .instanceType:    RESD 1
    .instanceSize:    RESD 1
    .freelist:        RESD 1
    .nextPage:        RESD 1
    .firstPage:       RESD 1
endstruc

segment .data
    typeinfo_Pool: istruc IAllocator
        at IAllocator.type,   dd typeid_Allocator
        at IAllocator.sizeof, dd PoolAllocator.size
        at IAllocator.alloc,  dd PoolAllocator_alloc
        at IAllocator.free,   dd PoolAllocator_free
    iend
segment .text

struc PoolPage
    .nextPage: RESD 1
    .rem: RESD 1
endstruc

; alloc_page():
;   in  esi: IAllocator
;   out eax: PoolPage
DECL_FCN alloc_page
    

END_FCN  alloc_page



;
; PoolAllocator.init()
;   in esi: ptr to PoolAllocator
;   in eax: parent allocator (IAllocator)
;   in edx: instance type    (IObject)
;
DECL_FCN PoolAllocator_init
    pushad
    mov [esi + PoolAllocator.type], typeinfo_Pool
    mov [esi + PoolAllocator.parentAllocator], eax
    mov [esi + PoolAllocator.instanceType], edx
    mov edx, [edx + IObject.sizeof]
    mov [esi + PoolAllocator.instanceSize], edx
    mov [esi + PoolAllocator.freelist], DWORD 0

    ; Alloc page
    push esi
    mov esi, eax       ; allocator
    mov ecx, PAGE_SIZE ; allocation size
    xor eax, eax
    call [esi + IAllocator.alloc]
    
    pop esi
    mov [esi + PoolAllocator.nextPage],  eax
    mov [esi + PoolAllocator.firstPage], eax
    popad
END_FCN  PoolAllocator_init

DECL_FCN PoolAllocator_dtor
    sub esp, 8

    ; store allocator.parentAllocator
    mov eax, [esi + PoolAllocator.parentAllocator]
    mov [ebp+4], eax

    ; store allocator.parentAllocator.vtbl.alloc
    mov eax, [eax + BaseObject.type]
    mov eax, [eax + IAllocator.alloc]
    mov [ebp+8], eax

    mov eax, [esi + PoolAllocator.firstPage]
    mov [esi + PoolAllocator.firstPage], DWORD 0
    mov [esi + PoolAllocator.nextPage],  DWORD 0
    .freeAllPages:
        push DWORD [eax + Page.next]
        mov esi, [ebp+4]
        mov ebx, [ebp+8]
        call [ebx]
        pop eax
        test eax, eax
        jnz .freeAllPages
END_FCN  PoolAllocator_dtor

DECL_FCN PoolAllocator_alloc

END_FCN  PoolAllocator_alloc
DECL_FCN PoolAllocator_free

END_FCN  PoolAllocator_free 







segment .data
    typeinfo_Pool: istruc IAllocator
        at IAllocator.typeid, dd typeid_Allocator
        at IAllocator.sizeof, dd Pool.size
    iend
































