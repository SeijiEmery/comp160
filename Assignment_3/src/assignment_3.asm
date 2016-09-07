; Program Template           (Template.asm)

; Assignment 3:
; Program Description: Calculates (A + B) - (C + D); no I/O.
; Author: Seiji Emery (student: M00202623)
; Creation Date: 9/17/16
; Revisions: 
; Date:              Modified by:

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD
.data

.code
main PROC
    mov eax, 42
    mov ebx, 1298
    mov ecx, 1203
    mov edx, 49

    add eax,ebx
    sub eax,ecx
    sub eax,edx

	INVOKE ExitProcess,0
main ENDP
; (insert additional procedures here)
END main
