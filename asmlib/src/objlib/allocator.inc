; asmlib/src/objlib/allocator.inc
;
; Object-oriented allocator implementation (spread across multiple source files)
;
; requires
;   algorithms/algorithms.inc
;   objlib/object.inc
;

; Shared defns

; Interface IAllocator extends IObject
struc IAllocator
    IObject_METHODS

    ; method alloc ( inout esi allocator, in eax size => out eax ptr )
    .alloc: res_ptr_t 1

    ; method free  ( inout esi allocator, in eax ptr )
    .free:  res_ptr_t 1
endstruc

; Internal structure prefixed before each IAllocator allocation.
struc AllocHeader
    .allocSize: res_size_t 1
    .allocator: res_ptr_t  1
endstruc

; malloc
;   inout esi allocator (IAllocator instance)
;   in    eax size
;   out   eax ptr
malloc:
    push edx
    mov edx, [esi + IObject.cls]
    call [edx + IAllocator.alloc]
    pop  edx
    ret

; free
;   in eax ptr
free:
    push edx
    push esi
    mov esi, [eax - AllocHeader.size + AllocHeader.allocator]
    mov edx, [esi + IObject.cls]
    call [edx + IAllocator.free]
    pop esi
    pop edx
    ret

; Allocator implementations
%include "src/objlib/allocator/freelist.inc"
%include "src/objlib/allocator/mempage.inc"
%include "src/objlib/allocator/static_allocator.inc"
%include "src/objlib/allocator/paged_allocator.inc"
