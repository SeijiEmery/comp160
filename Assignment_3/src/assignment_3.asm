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
varA SDWORD 7000
varB SDWORD -600
varC SDWORD 50
varD SDWORD -3
varResult SDWORD 0


.code
main PROC
    mov eax, [varA]
    mov ebx, [varB]
    mov ecx, [varC]
    mov edx, [varD]

    add eax,ebx
    add ecx,edx

    sub eax,ecx
    mov [varResult],eax

	INVOKE ExitProcess,0
main ENDP
END main
