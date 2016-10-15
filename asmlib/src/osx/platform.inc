
%define STDIN 0
%define STDOUT 1
%define STDERR 2

%macro EXEC_SYSCALL %1
    mov eax, %1
    int 0x80
%endmacro

%macro CALL_SYSCALL_EXIT 1
    push %1
    EXEC_SYSCALL 1
%endmacro

%macro CALL_SYSCALL_WRITE 3
    push %3
    push %2
    push %1
    EXEC_SYSCALL 4
%endmacro
