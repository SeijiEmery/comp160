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
    .color1: resb 1
    .color2: resb 1

    .pos_x:  resd 1
    .pos_y:  resd 1

    .size_x: resd 1
    .size_y: resd 1

    .cell_size: resd 1
endstruc

section .data

; Global checkerboard instance
checkerboard: istruc CheckerBoard
    at CheckerBoard.color1, db COLOR(white, white)
    at CheckerBoard.color2, db COLOR(black, black)
    at CheckerBoard.pos_x,  dd 0
    at CheckerBoard.pos_y,  dd 10
    at CheckerBoard.size_x, dd 8
    at CheckerBoard.size_y, dd 8
    at CheckerBoard.cell_size, dd 2
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

    call .drawCell

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




; drawCheckerboard
;   in dl, dh: (x/y) initial grid position
;   in cl, ch: (x/y) # grid cells
;   in al:           cell size (clamped 0-7).
drawCheckerboard:
section .data
    ; .str_lut:
    .s8: db '  '
    .s7: db '  '
    .s6: db '  '
    .s5: db '  '
    .s4: db '  '
    .s3: db '  '
    .s2: db '  '
    .s1: db '  ',0
    ; .s1: db '  ',0
    ; .s2: db '    ',0
    ; .s3: db '      ',0
    ; .s4: db '        ',0
    ; .s5: db '          ',0
    ; .s6: db '            ',0
    ; .s7: db '              ',0
    ; .s8: db '                ',0
    .lut: dd .s1, 1, .s2, 2, .s3, 3, .s4, 4,
          dd .s5, 5, .s6, 6, .s7, 7, .s8, 8
section .text
    pushad
    and eax, 7
    mov esi, [.lut + eax * 8]      ; string ptr
    mov eax, [.lut + eax * 8 + 4]
    mov ebx, ecx                   ; transfer count info to ebx

    mov ah, al
    shl al, 2

    ; Write main color grid
    push eax
    mov eax, [edi]
    call SetTextColor
    pop eax
        call .writeGrid
        shr al, 1
        add dl, al
        add dh, ah
        shl al, 1
        call .writeGrid

    ; Write secondary color
    push eax
    mov eax, [edi + 4]
    call SetTextColor
    pop eax
        sub dh, ah
        call .writeGrid
        shr al, 1
        add dh, ah
        sub dl, al
        shl al, 1
        call .writeGrid

    call ResetTextColor
    popad
    ret

    ; writeGrid
    ;   inout dl: x_pos,           dh: y_pos
    ;   inout al: x_cell_offset,   ah: y_cell_offset  
    ;   inout bl: num_x_cells,     bh: num_y_cells
    ;   inout cl: x_counter,       ch: y_counter
    ;   inout esi: "whitespace" ptr (prints grid sections)
    ;
    .writeGrid:
        pushad
        xor ecx, ecx
    .loopGrid:
        mov ch, ah
        .writeSegment:
            mov cl, bl
            push edx
            .writeLine:
                push edx
                call Gotoxy
                mov  edx, esi
                call WriteString
                pop edx
                add dl, al
                dec cl
                jg .writeLine
            pop edx
            inc dh
            dec ch
            jg .writeSegment
        add dh, ah
        dec bh
        jg .loopGrid
        popad
        ret



DECL_FCN DB2
section .data
    %macro DECL_COLOR_TABLE 2
        dd (%1 << 4) | %1, (%2 << 4) | %2
    %endmacro
    .colorTable: DECL_COLOR_TABLE black, white
section .text
    mov edi, .colorTable
    mov dl, 8
    mov dh, 8

    mov cl, 4
    mov ch, 4
    mov eax, 2
    call drawCheckerboard
END_FCN  DB2

DECL_FCN DrawRainbowText
section .data
    ; .red_text: db 27,"[44;34m",0
    .text: db "Hello,",27,"[46;1m World!",10,0
section .text
    mov ecx, 16

    ; mov edx, .red_text
    ; call WriteString
    mov dl, 10
    mov dh, 15
    .textLoop:
        push ecx
        push edx
        mov ax, 16
        sub ax, cx
        call Gotoxy
        call SetTextColor
        mov edx, .text
        call WriteString
        call ResetTextColor

        mov eax, ecx
        call WriteDec
        pop edx
        inc dl
        inc dh
        pop ecx
        loop .textLoop
END_FCN DrawRainbowText



