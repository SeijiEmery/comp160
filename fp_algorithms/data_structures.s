

; array_alloc (esi allocator, eax size) => edi array ptr. 
array_alloc:
    ASSERT_GT eax, 4,      _ASSERT_ERROR_ARRAY_SIZE_INVALID_EAX)
    ASSERT_LE eax, 0xffff, _ASSERT_ERROR_ARRAY_SIZE_OVERFLOW_EAX)

    push eax
    call _Allocator_allocBytes
    pop eax

    ; Set array capacity (allocated size - bytes) and length (0)
    sub eax,4
    and eax,0xffff
    shl eax,16
    mov [edi],eax

    ; Advance edi to start of array data + return
    add edi,4
    ret

; array_dealloc (esi allocator, edi ptr) => same esi, edi
array_dealloc:
    ; check array not already deallocated (capacity + length will be 0)
    cmp [edi-4], dword 0
    jz .end

    ; Otherwise, set cap + length to 0 and free memory
    mov [edi-4], dword 0
    call _Allocator_deallocBytes
.end:
    ret

; Get array length / capacity. Must use these with v = 16-bit register (ax,bx)
; or a 16-bit memory location (eg. word [eax]).
;
; Valid: 
;   getArrayLength(edi, ax)
;   getArrayLength(edi, word [eax])
; Invalid:
;   getArrayLength(edi, eax)
;   getArrayLength(edi, dword [eax])
;
%define getArrayLength(x,v)   mov [x-2], v
%define getArrayCapacity(x,v) mov [x-4], v

; array_mempcy (edi array, ebx array_offset, esi src_ptr, ecx src_length)
; 
; Writes src_length bytes from src_ptr into array at array_offset if possible;
; byte writes are limited to the array's capacity (getArrayCapacity) and
; writes will be truncated if they would cause the array to overflow.
;
; On return, all registers (incl edi, ebx) will be unchanged except ecx, which will
; be zero unless no bytes written (negative if bounds error), and esi, which will be 
; advanced to the number of bytes written (used to determine if the memcpy operation 
; succeeded, and if not, how to handle that).
;
; Here's a few usecases + examples:
; array_append(edi array, esi target array)
;     xor ebx,ebx
;     getArrayLength(edi, bx)
;
;     xor ecx,ecx
;     getArrayLength(esi, cx)
;
;     push esi         ; save array ptr
;     mov eax, esi
;     add eax, ecx     ; determine expected value for esi after call iff success
;
;     call array_memcpy
;
;     sub eax, esi      ; check esi _and_ calculate # bytes not written in eax
;     jz  .operationOk
;     jg  .notAllBytesWritten
;     jl  .someError    ; would indicate that array_memcpy wrote more than ecx bytes (should not be possible)
;     
;     .notAllBytesWritten:
;     ; Handle this by allocating a new array + retrying, accepting that not all bytes
;     ; were written, or w/e.
;     ; Note: if you allocate a new array with at least arrayCapacity(edi) + eax bytes,
;     ; calling array_memcpy again _should_ be guaranteed to succeed.
;
;     .operationOk:
;
array_memcpy:
    ; Check for null / invalid values
    ASSERT_NE [edi-4], dword 0, _ASSERT_ERROR_ARRAY_NOT_ALLOCATED_EDI

    ; Do bounds check
    push eax        ; save eax
    xor eax, eax
    getArrayCapacity edi, ax

    add eax, ebx    ; calculate array_capacity - offset (remaining capacity)
    cmp eax, ecx    ; compare this with the number of bytes to be written (ecx)
    jge .boundsOk

    ; If writing ecx bytes would cause the array to overflow, clamp ecx 
    ; to the array capacity after array_offset (eax).
    mov ecx, eax

    .boundsOk:
    ; If ecx <= 0 (no bytes to write and/or out of bounds), abort memcpy op.
    cmp ecx, 0
    jle .noCopy

    push edi    ; save edi

    ; advance to offset
    add edi, ebx

    call memcpy

    pop edi     ; restore edi
    .noCopy:
    pop eax     ; restore eax
    ret

; memcpy (dst dsi, src esi, ecx num_bytes)
memcpy:
    cmp ecx,4
    jl .writeWord

    .writeDword:
    mov [edi], dword [esi]
    add edi,4
    add esi,4
    sub ecx,4

    cmp ecx,4
    jge .writeDword

    .writeWord:
    cmp ecx,2
    jl .writeByte

    mov [edi], word [esi]
    add edi,2
    add esi,2
    sub ecx,2

    .writeByte:
    cmp ecx,1
    jl .end

    mov [edi], byte [esi]
    inc edi
    inc esi
    dec ecx

    .end:
    ASSERT_EQ ecx, 0, _ASSERT_ERROR_ARRAY_MEMCPY_INTERNAL_ERROR_ECX
    ret




















