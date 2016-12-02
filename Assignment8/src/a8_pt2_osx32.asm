; Assignment 8, part 2
;   Implements + runs tests for a Euclidean GCD algorithm.
;
; Target platform: osx, 32-bit
;   depends on asmlib (../asmlib/)
;   uses rake (a ruby-based build system) for nasm builds
;
; Author: Seiji Emery (student: M00202623)
; Creation Date:  11/28/16
; Revisions, etc: https://github.com/SeijiEmery/comp160/tree/master/Assignment7
;

%define ASMLIB_SETUP_MAIN
%include "osx32/irvine32.inc"

section .data
section .text

CELL_HEIGHT equ 2
CELL_WIDTH  equ 2
CELL_CHR    equ ' '

%define COLOR(foreground, background) (foreground << 4) | background
struc CheckerBoard
    .color1: resd 1
    .color2: resd 1

    .pos_x:  resd 1
    .pos_y:  resd 1

    .size_x: resd 1
    .size_y: resd 1

    .cell_size: resd 1
endstruc

section .data

; Global checkerboard instance
checkerboard: istruc CheckerBoard
    at CheckerBoard.color1, dd COLOR(white, white)
    at CheckerBoard.color2, dd COLOR(black, black)
    at CheckerBoard.pos_x,  dd 4
    at CheckerBoard.pos_y,  dd 10
    at CheckerBoard.size_x, dd 8
    at CheckerBoard.size_y, dd 8
    at CheckerBoard.cell_size, dd 4
iend

; Global application state
application.running:        dd 0
application.currentPalette: dd 0
section .text


; Draws a checkerboard.
;   in eax: checkerboard instance.
CheckerBoard.draw:
    pushad
    mov bl, [eax + CheckerBoard.pos_x]
    mov bh, [eax + CheckerBoard.pos_y]
    mov cl, [eax + CheckerBoard.size_x]
    mov ch, [eax + CheckerBoard.size_y]

    push eax
    mov  eax, [eax + CheckerBoard.color1]
    call SetTextColor
    pop  eax

    call .writeCellGrid
    call ResetTextColor

    popad
    ret

    ; inout edi: pointer to CheckerBoard struct
    ; inout esi: string sufficient to draw one line pass of one cell.
    ; in    cl:  number of cells (per line) to draw.
    ; in    ch:  number of lines / cell.
    ; inout eax: color offset 
    .writeCellRow:
    .writeCellRow.outerLoop:
        mov dx, bx
        call Gotoxy
        inc bh
        ; add bh, [edi + CheckerBoard.cell_size]

        push ecx
        .writeCellRow.innerLoop:
            push eax
            and  eax, 1
            mov  eax, [eax + edi + CheckerBoard.color1]
            call SetTextColor
            pop  eax
            inc  eax

            mov edx, esi 
            call WriteString
            dec  cl
            jg   .writeCellRow.innerLoop

        pop ecx
        dec ch
        jg .writeCellRow.outerLoop
        ret

    ; inout edi: pointer to CheckerBoard struct.
    ; inout bl/bh: x/y grid position.
    .writeCellGrid:
        pushad
        mov edi, eax
        mov esi, [edi + CheckerBoard.cell_size]
        dec esi
        and esi, 7
        mov esi, [.lut + esi * 8]

        mov ecx, [edi + CheckerBoard.size_y]
        xor eax, eax

        .writeCellGrid.writeLines:
            push ecx
            mov dx, bx
            call Gotoxy

            mov cl, [edi + CheckerBoard.size_x]
            mov ch, [edi + CheckerBoard.cell_size]
            call .writeCellRow
            pop ecx
            inc eax
            loop .writeCellGrid.writeLines

        popad
        ret
    section .data
    .s8: db CELL_CHR, CELL_CHR
    .s7: db CELL_CHR, CELL_CHR
    .s6: db CELL_CHR, CELL_CHR
    .s5: db CELL_CHR, CELL_CHR
    .s4: db CELL_CHR, CELL_CHR
    .s3: db CELL_CHR, CELL_CHR
    .s2: db CELL_CHR, CELL_CHR
    .s1: db CELL_CHR, CELL_CHR,0
    .lut: dd .s1,1, .s2,2, .s3,3, .s4,4, .s5,5, .s6,6, .s7,7, .s8,8
    section .text

; Handles one input command
;   in eax: checkerboard instance.
;   in dl:  byte representing one input text character.
CheckerBoard.handleKeyCommand:
    %macro BRANCH 3
        cmp %1, %2
        jz  %3
    %endmacro

section .data
    .lit_inputMsg: db "Recieved input: ",0
section .text
    push edx
    mov edx, .lit_inputMsg
    call WriteString
    pop edx
    mov eax, edx
    call WriteInt
    call Crlf

    BRANCH dl, 'q', .handleQuit
    BRANCH dl, '+', .increaseGridSize
    BRANCH dl, '=', .increaseGridSize
    BRANCH dl, '-', .decreaseGridSize
    BRANCH dl, '_', .decreaseGridSize
    BRANCH dl, 'a', .moveLeft
    BRANCH dl, 'A', .moveLeft
    BRANCH dl, 'd', .moveRight
    BRANCH dl, 'D', .moveRight
    BRANCH dl, 'w', .moveUp
    BRANCH dl, 'W', .moveUp
    BRANCH dl, 'd', .moveDown
    BRANCH dl, 'D', .moveDown
    BRANCH dl, '[', .prevColor
    BRANCH dl, ']', .nextColor
    BRANCH dl, 'p', .swapPalette
    ret

    %undef BRANCH

    .handleQuit:
        mov [application.running], dword 0
        ret
    .increaseGridSize:
        inc dword [eax + CheckerBoard.cell_size]
        ret
    .decreaseGridSize:
        dec dword [eax + CheckerBoard.cell_size]
        ret
    .moveLeft:
        dec dword [eax + CheckerBoard.pos_x]
        ret
    .moveRight:
        inc dword [eax + CheckerBoard.pos_x]
        ret
    .moveDown:
        dec dword [eax + CheckerBoard.pos_y]
        ret
    .moveUp:
        inc dword [eax + CheckerBoard.pos_y]
        ret
    ; Helper function: getPaletteColor( inout eax checkerboard, out edx color )
    .getPaletteColor:
        mov edx, [application.currentPalette]
        and edx, 1
        mov edx, [eax + CheckerBoard.color1 + edx]
        and edx, 0xf
        ret
    ; Helper function: setPaletteColor( inout eax checkerboard, in edx color )
    .setPaletteColor:
        push ebx
        and edx, 0xf
        
        mov ebx, edx
        shl ebx, 4
        or  edx, ebx

        mov ebx, [application.currentPalette]
        and ebx, 1
        lea ebx, [eax + CheckerBoard.color1 + ebx]
        mov [ebx], edx
        pop ebx
        ret
    .prevColor:
        call .getPaletteColor
        dec edx
        jmp .setPaletteColor
    .nextColor:
        call .getPaletteColor
        inc edx
        jmp .setPaletteColor
    .swapPalette:
        inc dword [application.currentPalette]
        ret


section .bss
    INPUT_BUFFER_SIZE equ 4096
    inputBuffer: resb INPUT_BUFFER_SIZE
section .text
DECL_FCN _main
    call termios.set_mode_immediate

    mov [application.running], dword 1
    .mainLoop:
        mov eax, checkerboard
        call CheckerBoard.draw

        mov eax, INPUT_BUFFER_SIZE
        mov edx, inputBuffer
        call ReadString

        mov ecx, eax
        mov esi, edx

        test ecx, ecx
        jz .noInput

    section .data
        .lit_msg: db "HAVE INPUT!: ",0
    section .text
        mov edx, .lit_msg
        call WriteString
        call WriteInt
        call Crlf

        .processInput:
            mov eax, checkerboard
            xor edx, edx
            mov dl, [esi]
            dec esi
            call CheckerBoard.handleKeyCommand
            loop .processInput
        .noInput:

        cmp [application.running], dword 0
        jnz .mainLoop

    call termios.set_mode_cannonical
END_FCN  _main

;
; termios impl to disable cannonical mode + echo (ie. switch to immediate mode).
; This code is extremely platform-specific, and is only implemented for osx;
;

; Platform-specific to OSX!
; Constants from https://github.com/SeijiEmery/osx_termios_test.
%ifdef PLATFORM_x64
    ; termios data structure
    termios.c_iflag equ 0x0
    termios.c_oflag equ 0x8
    termios.c_cflag equ 0x10
    termios.c_lflag equ 0x18
    termios.size equ 0x48

    ; ioctl get / set termios data
    termios.TIOCGETA equ 0x40487413
    termios.TIOCSETA equ 0x80487414

    ; termios flags
    termios.ICANON   equ 0x100
    termios.ECHO     equ 0x8
%else
    ; termios data structure
    termios.c_iflag equ 0x0
    termios.c_oflag equ 0x4
    termios.c_cflag equ 0x8
    termios.c_lflag equ 0xc
    termsio.c_cc    equ 0x10
    termios.c_ispeed equ 0x24
    termios.c_ospeed equ 0x28
    termios.size    equ 0x2c

    ; ioctl get / set termios data
    termios.TIOCGETA equ 0x40487413
    termios.TIOCSETA equ 0x80487414

    ; termios flags
    termios.ICANON   equ 0x100
    termios.ECHO     equ 0x8
%endif

; Save space for termios structure (temporary global variable).
section .bss
termios.data: resb termios.size
section .text

; Read termios structure into termios_data using ioctl.
termios.read:
    push eax
    mov eax, 54
    push dword termios.data
    push dword termios.TIOCGETA
    push dword STDIN
    sub esp, 4
    int 0x80
    add esp, 16
    test eax, eax
    jnz termios.read.error
    pop eax
    ret

; Write termios structure from termios_data using ioctl.
termios.write:
    push eax
    mov eax, 54
    push dword termios.data
    push dword termios.TIOCSETA
    push dword STDIN
    sub esp, 4
    int 0x80 
    add esp, 16
    test eax, eax
    jnz termios.write.error
    pop eax
    ret

; Turn cannonical (wait for newline), and echo mode on
termios.set_mode_cannonical:
    call termios.read
    or DWORD [termios.data + termios.c_lflag], termios.ICANON
    or DWORD [termios.data + termios.c_lflag], termios.ECHO
    jmp termios.write

; Turn cannonical (wait for newline), and echo mode off
termios.set_mode_immediate:
    call termios.read
    and DWORD [termios.data + termios.c_lflag], ~termios.ICANON
    and DWORD [termios.data + termios.c_lflag], ~termios.ECHO
    jmp termios.write

termios.read.error:
section .data
    .msg: db "termios.read() error: ",0
section .text
    mov edx, .msg
    call WriteString
    push eax
    call WriteInt
    call Crlf
    pop eax
    jmp _sys_exit
termios.write.error:
section .data
    .msg: db "termios.write() error: ",0
section .text
    mov edx, .msg
    call WriteString
    push eax
    call WriteInt
    call Crlf
    pop eax
    jmp _sys_exit
