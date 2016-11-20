
struc MemPage
    .prev:      res_ptr_t 1
    .next:      res_ptr_t 1
    .nextPtr:   res_ptr_t 1
    .remaining: res_size_t 1
endstruc

struc PageContext
    .parentAllocator: res_ptr_t 1
    .firstPage:       res_ptr_t 1
    .nextPage:        res_ptr_t 1
    .pageSize:        res_size_t 1
endstruc

; createPageContext
;   inout eax pageContext     (non-null)
;   inout esi parentAllocator (non-null)
;   in    ecx pageSize        (non-null)
createPageContext:
    mov [eax + PageContext.parentAllocator], esi
    mov [eax + PageContext.pageSize], ecx
    push edx
    push eax
    mov eax, ecx
    xor edx, edx
    call allocNewPage
    pop edx
    mov [edx + PageContext.nextPage], eax
    mov [edx + PageContext.firstPage], eax
    mov eax, edx
    pop edx
    ret

; releasePageContext
;   inout eax pageContext (non-null)
releasePageContext:
    push esi  ; save registers
    push ebx
    push edx
    push eax

    mov esi, [eax + PageContext.allocator]
    mov edx, [esi + IAllocator.free]

    mov eax, [eax + PageContext.firstPage]
    .releaseLoop:
        mov  ebx, [eax + MemPage.next]
        call edx
        mov  eax, ebx
        test ebx, ebx
        jnz .releaseLoop
    pop eax
    mov [eax + PageContext.firstPage], ptr_t 0
    mov [eax + PageContext.nextPage],  ptr_t 0
    pop edx
    pop ebx
    pop esi
    ret


; allocNewPage
;   inout esi allocator (non-null)
;   inout edx prevPage  (nullable)
;   in    eax pageSize  (non-zero)
;   out   eax MemPage page (non-null)
allocNewPage:
    push edx  ; save prev page
    push eax  ; save size
    mov edx, [esi + IObject.cls]
    call [edx + IAllocator.alloc]
    pop edx
    mov [eax + MemPage.remaining], edx
    mov edx, eax
    sub edx, MemPage.size
    mov [eax + MemPage.nextPtr], edx
    pop edx
    mov [eax + MemPage.prev], edx
    mov [eax + MemPage.next], ptr_t 0
    ret

; pagedAlloc
;   in ecx  pageContext
;   in eax  allocSize
;   out eax allocatedPtr
pagedAlloc:
    push edx  ; Save registers
    push ebx
    mov  edx, [ecx + PageContext.nextPage]
    .findSufficientPage:
        sub [edx + MemPage.remaining], eax
        jl .insufficientMemory
            push ptr_t [edx + MemPage.nextPtr]
            add [edx + MemPage.nextPtr], eax
            pop eax
            pop ebx
            pop edx
            ret
        .insufficientMemory:
        add [edx + MemPage.remaining], eax

        ; If page.next == 0, alloc new page
        cmp [edx + MemPage.next], 0
        jnz .hasNext
            push esi
            push eax
            mov esi, [ecx + PageContext.parentAllocator]
            mov ebx, [ecx + PageContext.pageSize]

            ; Increase size until sufficient to fit allocation
            .checkSize:
                cmp ebx, eax
                jge .sizeOk
                shl ebx
                mov [ecx + PageContext.pageSize], ebx
                jmp .checkSize
            .sizeOk:
            mov eax, ebx
            call allocNewPage
            mov [edx + MemPage.next], eax
            mov [eax + MemPage.prev], edx
            pop eax
            pop esi
        .hasNext:

        ; If page == pageContext.nextPage && page.remaining <= PAGE_THROWAWAY_LIMIT,
        ; set page.nextPage = page.next.
        cmp edx, [ecx + PageContext.nextPage]
        jne .noBump
        cmp [edx + MemPage.remaining], PAGE_THROWAWAY_LIMIT
        jg  .noBump
            mov edx, [edx + MemPage.next]
            mov [ecx + PageContext.nextPage], edx
            jmp .findSufficientPage
        .noBump:
            mov edx, [edx + MemPage.next]
            jmp .findSufficientPage

