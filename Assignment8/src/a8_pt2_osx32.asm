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
.drawCell:
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
    pushad
    mov esi, [eax + CheckerBoard.cell_size]
    mov ecx, [.lut + esi * 8 + 4]
    mov esi, [.lut + esi * 8]

    .writeCellLine:
        mov dx, bx
        call Gotoxy
        mov edx, esi
        call WriteString
        inc bh
        loop .writeCellLine

    popad
    ret

section .text
DECL_FCN _main
    mov eax, checkerboard
    call CheckerBoard.draw
END_FCN  _main

