; Assignment 3:
; Program Description: Calculates (A + B) - (C + D); no I/O.
; Author: Seiji Emery (student: M00202623)
; Creation Date: 9/07/16
; Revisions: 
; Date:              Modified by:

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD
.data

.code
main PROC
    mov eax, 7000
    mov ebx, 600
    mov ecx, 50
    mov edx, 3

    add eax,ebx
    add ecx,edx

    sub eax,ecx

	INVOKE ExitProcess,0
main ENDP
END main
