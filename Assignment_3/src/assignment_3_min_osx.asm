
global start

section .data ; Declare variables
_varA: dd 7000
_varB: dd -600
_varC: dd 50
_varD: dd -3
_varResult: dd 0

section .text
start:
    ; Set registers
    mov eax,[_varA]
    mov ebx,[_varB]
    mov ecx,[_varC]
    mov edx,[_varD]
    _breakpoint_setValues:   ; set a breakpoint here in lldb to inspect values.
    
    ; First addition operation: A += B, C += D.
    add eax,ebx
    add ecx,edx
    _breakpoint_addedValues: ; set a breakpoint here in lldb to inspect values.

    ; Second operation: A -= C.
    sub eax,ecx
    _breakpoint_done:        ; set a breakpoint here in lldb to inspect values.

    mov [_varResult],eax

    ; call exit(0)
    push 0      ; arg (0)
    mov eax,1   ; syscall number (exit)
    int 0x80    ; bsd syscall interrupt
