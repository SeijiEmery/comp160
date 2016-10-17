; Assignment 5:
; Program Description:
;   Generates + prints a sequence of random integers and strings.
;
; Target platform: windows, 32-bit.
;   Uses the Irvine32 library.
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: 10/16/16
; Revisions: N/A (see git log)
; Date:              Modified by:
;

INCLUDE Irvine32.inc

.data
    ; String constants: comma separator, etc
    commaStr BYTE ", ",0
    str1     BYTE " Random numbers:",0
    str2     BYTE " Random strings:",0

    ; Min / max values for N random numbers.
    ; Note: min inclusive, max exclusive: range = [randMin, randMax).
    randMin DWORD -100
    randMax DWORD 100 

    ; Temp string buffer used for part 2
    strbuf BYTE 1024 DUP ?
.code

; Define the number of random numbers + strings to print.
; Changing these affects both # things printed, and the output text saying # of
; things printed)
NUM_RANDOM_NUMBERS equ 20
NUM_RANDOM_STRINGS equ 30

main PROC
    call Randomize

    ; printf("\n%d Random numbers: \n", NUM_RANDOM_NUMBERS)
    call Crlf
    mov eax, NUM_RANDOM_NUMBERS
    call WriteInt
    mov edx, OFFSET str1
    call WriteString
    call Crlf

    ; Display N random numbers using BetterRandomRange
    mov ecx, NUM_RANDOM_NUMBERS
    brr_loop:
        ; Load min/max + call BetterRandomRange
        mov eax, [randMax]
        mov ebx, [randMin]
        call BetterRandomRange

        ; Write result (stored in eax) to stdout
        call WriteInt

        ; Loop condition (more complex to avoid printing last separator)
        sub ecx, 1
        jle end_loop

        ; print separator ", " and continue
        mov edx, commaStr
        call WriteString
        jmp brr_loop
    end_loop:
    call Crlf

    ; printf("\n%d Random strings: \n", NUM_RANDOM_STRINGS)
    call Crlf
    mov eax, NUM_RANDOM_STRINGS
    call WriteInt
    mov edx, OFFSET str2
    call WriteString
    call Crlf

    ; Display N random strings using CreateRandomString
    mov ecx, NUM_RANDOM_STRINGS
    jmp .str_loop
    str_loop:
        ; call CreateRandomString(100, strbuf)
        mov eax, 100
        mov esi, OFFSET strbuf
        call CreateRandomString

        ; add trailing '\0', b/c WriteString expects null-terminated strings.
        mov BYTE PTR [esi+1], 0

        ; call WriteString (strbuf points to start of the string)
        mov edx, OFFSET strbuf
        call WriteString

        ; Add Eol + continue
        call Crlf
        loop str_loop
    exit
main ENDP

; BetterRandomRange( eax max, ebx min -> eax randomValue )
; returns a random 32-bit integer in [min, max)
BetterRandomRange PROC
    push ebx          ; save min
    sub eax, ebx      ; N = (max - min)
    call RandomRange  ; x = RandomRange(N)
    pop ebx           ; restore min
    add eax, ebx      ; x += min
    ret
BetterRandomRange ENDP


; CreateRandomString( eax maxLength, esi outStr )
; creates a random string 0-maxLength chars long, containing randomized 
; uppercase ascii letters.
CreateRandomString PROC
    push ecx          ; save registers
    push ebx

    call RandomRange  ; count = RandomRange( maxLength )
    mov ecx, eax      ; store in ecx; loop count times.
    chrLoop:
        mov ebx, 'A'  ; x = BetterRandomRange('A', 'Z')
        mov eax, 'Z'
        call BetterRandomRange
        mov BYTE PTR [esi], al ; *(outStr++) = (char)(x)
        inc esi
        loop chrLoop
    pop ebx           ; restore registers
    pop ecx
    ret
CreateRandomString ENDP

END main