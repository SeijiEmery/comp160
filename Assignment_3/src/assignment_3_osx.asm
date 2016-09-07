
global start

section .text
start:
    mov eax,42
    mov ebx,1298
    mov ecx,1203
    mov edx,49

    add eax,ebx
    sub eax,ecx
    sub eax,edx

    push 0
    call syscall_exit

syscall_exit:
    mov eax,1
    int 0x80
