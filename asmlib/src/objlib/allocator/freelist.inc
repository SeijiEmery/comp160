;
; Freelist implementation
;

struc FreeListNode
    .allocSize: res_ptr_t 1
    .next:      res_ptr_t 1
endstruc
ALLOC_SPLIT_THRESHOLD equ 32

; pushFreeList (memory free)
;   inout edx  addr_of_first_node
;   inout eax  alloc_ptr
;   inout ecx  alloc_size
pushFreeList:
    push ebx
    mov ebx, [edx]
    mov [eax + FreeListNode.allocSize], ecx
    mov [eax + freeListNode.next],      ebx
    mov [edx], eax
    pop ebx
    ret

; popFreeList (memory allocation)
;   in    edx  addr_of_first_node
;   inout eax  alloc_size
;   out   edx  alloc_ptr || null
popFreeList:
    push ecx ; Save registers
    push ebx

    mov ecx, edx    ; ecx = addr of node
    mov edx, [edx]  ; edx = node

    test edx, edx   ; If empty, return null
    jnz .searchList
    .noMatch:
        xor edx, edx
    .exit:
        pop ebx
        pop ecx
        ret
    .searchList:
    ; Iterate over nodes until we find one big enough to fit the allocation
    mov ebx, [edx + FreeNode.allocSize]
    sub ebx, eax
    jl .nextNode
        cmp ebx, ALLOC_SPLIT_THRESHOLD
        jge .splitNode
            mov ebx, [edx + FreeNode.next]
            mov [ecx], ebx
            jmp .exit
        .splitNode:
            sub [edx + FreeNode.allocSize], eax
            add edx, ebx
            mov [edx + FreeNode.allocSize], eax
            jmp .exit
    .nextNode:
        lea ecx, [edx + FreeNode.next]
        mov edx, [edx + FreeNode.next]
        test edx, edx
        jz  .noMatch
        jmp .searchList

