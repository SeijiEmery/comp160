
global start
section .text
start:
    ; Set registers
    mov eax,7000
    mov ebx,600
    mov ecx,50
    mov edx,3
    _breakpoint_setValues:   ; set a breakpoint here in lldb to inspect values.
    
    ; First addition operation: A += B, C += D.
    add eax,ebx
    add ecx,edx
    _breakpoint_addedValues: ; set a breakpoint here in lldb to inspect values.

    ; Second operation: A -= C.
    sub eax,ecx
    _breakpoint_done:        ; set a breakpoint here in lldb to inspect values.

    ; call exit(0)
    push 0      ; arg (0)
    mov eax,1   ; syscall number (exit)
    int 0x80    ; bsd syscall interrupt
