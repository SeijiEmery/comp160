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


drawCell:
section .data
    .space: db "--",0
section .text
    call SetTextColor
    call Gotoxy
    push edx
    mov edx, .space
    call WriteString
    pop edx
    inc dh
    call Gotoxy
    push edx
    mov edx, .space
    call WriteString
    pop edx
    ret

; DrawChessBoard( 
;   u32 screen_x,  (only uses 8 bits)
;   u32 screen_y,  (only uses 8 bits)
;   u32 grid_size, (# x/y cells; clamped to 16)
;   u32 color,     (DOS 4-bit background color)
;)
%define screen_x   [ebp + 20]
%define screen_y   [ebp + 16]
%define grid_size  [ebp + 12]
%define grid_c1    [ebp + 8]
%define grid_c2    [ebp + 9]
_DrawChessBoard:
    pushad
    push ebp
    mov ebp, esp

    call writeBoardStats

    ; Move cursor to top-left of screen
    mov dl, screen_x
    mov dh, screen_y
    call Gotoxy

    ; Load grid color(s)
    mov al, grid_c1
    and al, 0xf
    shl al, 4
    or  al, grid_c1
    mov [ebp + 4], al
    mov [ebp + 5], byte (white << 4) | white
    mov [ebp + 6], al
    mov [ebp + 7], byte (white << 4) | white

    ; Load coords (in ecx)
    mov ecx, grid_size
    and ecx, 0xf
    mov grid_size, ecx
    shl ecx, 16
    xor ebx, ebx

    call writeBoardStats

    .outer_loop:
        mov cx, grid_size
        mov dl, screen_x
        add dh, CELL_HEIGHT
        .inner_loop:
            xor eax, eax
            mov al, [ebp + ebx + 4]

            pushad
            call drawCell
            popad
                
            add dl, CELL_WIDTH
            inc ebx
            and ebx, 1

            sub cx, .inner_loop
            jge .inner_loop
        .end_inner_loop:
        inc ebx
        and ebx, 1
        sub ecx, 0x10000
        jge .outer_loop
    .end_outer_loop:

    ; Load grid size
    mov ecx, grid_size
    and ecx, 0xf
    mov eax, ecx
    shl ecx, 16
    or  ecx, eax

    mov esp, ebp
    pop ebp
    popad
    ret

DECL_FCN DB2
section .data
    .spaceStr: db "    ",0    
section .text
    mov ax, (red << 4) | red
    call SetTextColor

    mov dl, 10
    mov dh, 20

    mov ecx, 0x320000
    .outerLoop:
        and dh, 4
        add dh, 20
        mov cx, 8
        .innerLoop:
            push edx
            call Gotoxy
            mov edx, .spaceStr
            call WriteString
            pop edx
            add dh, 8

            dec cx
            jg .innerLoop
        .endInnerLoop:
        inc  dl
        sub  ecx, 0x10000
        test ecx, 0x20000
        jnz .outerLoop

        add dh, 4
        sub ecx, 0x20000
        jg .outerLoop
    .endOuterLoop:
    call ResetTextColor

END_FCN  DB2




writeBoardStats:
section .data
    .msg_screen_x:   db "screen x:   ",0
    .msg_screen_y:   db "screen y:   ",0
    .msg_grid_size:  db "grid size:  ",0
    .msg_grid_color: db "grid color: ",0
    .msg_self:       db "self:       ",0
section .text
    pushad
    %macro WRITE_X 2
        mov edx, %1
        call WriteString
        mov eax, %2
        call WriteDec
        call Crlf
    %endmacro
    WRITE_X .msg_self, [ebp+4]
    WRITE_X .msg_screen_x, screen_x
    WRITE_X .msg_screen_y, screen_y
    WRITE_X .msg_grid_size, grid_size
    WRITE_X .msg_grid_color, grid_c1

    %macro WRITE_MSG 2
    section .data
        %%string: db %1,": ",0
    section .text
        mov edx, %%string
        call WriteString
        mov eax, %2
        call WriteDec
        call Crlf
    %endmacro

    WRITE_MSG "[ebp-8]", [ebp-8]
    WRITE_MSG "[ebp-4]", [ebp-4]
    WRITE_MSG "[ebp+0]", [ebp+0]
    WRITE_MSG "[ebp+4]", [ebp+4]
    WRITE_MSG "[ebp+8]", [ebp+8]
    WRITE_MSG "[ebp+12]", [ebp+12]
    WRITE_MSG "[ebp+16]", [ebp+16]
    WRITE_MSG "[ebp+20]", [ebp+20]
    WRITE_MSG "[ebp+24]", [ebp+24]
    WRITE_MSG "[ebp+28]", [ebp+28]

    popad
    ret


DECL_FCN DrawBoardDemo
    push dword red
    push dword 8
    push dword 5
    push dword 10
    call _DrawChessBoard
END_FCN  DrawBoardDemo

DECL_FCN DrawRainbowText
section .data
    ; .red_text: db 27,"[44;34m",0
    .text: db "Hello, World!",10,0
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

DECL_FCN _main
    call DB2
    ; call DrawRainbowText
    ; call DrawBoardDemo
END_FCN  _main


