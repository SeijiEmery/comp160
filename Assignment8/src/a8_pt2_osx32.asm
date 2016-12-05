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

%macro mWriteString 1
[section .data]
    %%str: db %1,0
__SECT__
    push edx
    mov  edx, %%str
    call WriteString
    pop  edx
%endmacro

%macro mWriteInt 1
    push eax
    mov eax, %1
    call WriteInt
    pop eax
%endmacro

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
application.currentPalette: dd 1
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

    test dl, dl
    jz .skip_no_input

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
    BRANCH dl, 's', .moveDown
    BRANCH dl, 'S', .moveDown
    BRANCH dl, '[', .prevColor
    BRANCH dl, ']', .nextColor
    BRANCH dl, 'p', .swapPalette
    .skip_no_input:
    ret

    %undef BRANCH

    .handleQuit:
        mWriteString {"input command: quit",10}
        mov [application.running], dword 0
        ret
    .increaseGridSize:
        mWriteString {"input command: ++cell_size",10}
        inc dword [eax + CheckerBoard.cell_size]
        and dword [eax + CheckerBoard.cell_size], 7
        ret
    .decreaseGridSize:
        mWriteString {"input command: --cell_size",10}
        dec dword [eax + CheckerBoard.cell_size]
        and dword [eax + CheckerBoard.cell_size], 7
        ret
    .moveLeft:
        mWriteString {"input command: --pos_x",10}
        dec dword [eax + CheckerBoard.pos_x]
        ret
    .moveRight:
        mWriteString {"input command: ++pos_x",10}
        inc dword [eax + CheckerBoard.pos_x]
        ret
    .moveDown:
        mWriteString {"input command: --pos_x",10}
        inc dword [eax + CheckerBoard.pos_y]
        ret
    .moveUp:
        mWriteString {"input command: ++pos_y",10}
        dec dword [eax + CheckerBoard.pos_y]
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
        mWriteString {"input command: next color",10}
        call .getPaletteColor
        dec edx
        jmp .setPaletteColor
    .nextColor:
        mWriteString {"input command: prev color",10}
        call .getPaletteColor
        inc edx
        jmp .setPaletteColor
    .swapPalette:
        mWriteString {"input command: switch palette",10}
        inc dword [application.currentPalette]
        ret


section .bss
    INPUT_BUFFER_SIZE equ 4096
    inputBuffer: resb INPUT_BUFFER_SIZE
section .text

writeProgramDescrip:
section .data
    .msg: db "Welcome to the interactive chess-board program:",10
          db "  A / D: move board left/right",10
          db "  W / S: move board up/down",10
          db "  + / -: increase / decrease board size",10
          db "  [ / ]: select prev / next board color",10
          db "  p: switch between foreground / background color",10
          db "  q: exit program",10,0
section .text
    mov dl, 0
    mov dh, 0
    call Gotoxy
    mov edx, .msg
    call WriteString
    ret

DECL_FCN _main
    call termios.init
    call termios.set_raw_mode

    ; Flush input
    ; mov edx, inputBuffer
    ; mov ecx, INPUT_BUFFER_SIZE
    ; call ReadString

    mov [application.running], dword 1
    .mainLoop:
        call Clrscr
        call writeProgramDescrip
        mov eax, checkerboard
        call CheckerBoard.draw
        call Crlf
    .checkInput:
        ; mWriteString {"Checking input",10}
        mov ecx, INPUT_BUFFER_SIZE
        mov edx, inputBuffer
        call ReadString

        mov ecx, eax
        mov esi, edx

        test ecx, ecx
        jz .checkInput

        ; mWriteString "Have input: "
        ; call WriteInt
        ; call Crlf

        .processInput:
            mov eax, checkerboard
            xor edx, edx
            mov dl, [esi]
            inc esi
            pushad
            call CheckerBoard.handleKeyCommand
            popad
            loop .processInput

        cmp [application.running], dword 0
        jnz .mainLoop

    call termios.exit
END_FCN  _main

;
; termios impl to disable cannonical mode + echo (ie. switch to immediate mode).
; This code is extremely platform-specific, and is only implemented for osx;
;

; Platform-specific to OSX!
; Constants from https://github.com/SeijiEmery/osx_termios_test.
; %ifdef PLATFORM_x64
%if 1
    ; termios data structure
    termios.c_iflag  equ 0x0
    termios.c_oflag  equ 0x8
    termios.c_cflag  equ 0x10
    termios.c_lflag  equ 0x18
    termios.size     equ 0x48

    ; ioctl get / set termios data
    termios.TIOCGETA equ 0x40487413
    termios.TIOCSETA equ 0x80487414
%else
    ; termios data structure
    termios.c_iflag  equ 0x0
    termios.c_oflag  equ 0x4
    termios.c_cflag  equ 0x8
    termios.c_lflag  equ 0xc
    termsio.c_cc     equ 0x10
    termios.c_ispeed equ 0x24
    termios.c_ospeed equ 0x28
    termios.size     equ 0x2c

    ; ioctl get / set termios data
    termios.TIOCGETA equ 0x40487413
    termios.TIOCSETA equ 0x80487414
%endif

;
; Termios flags
;

; c_iflag constants
IGNBRK equ 0x1
BRKINT equ 0x2
IGNPAR equ 0x4
PARMRK equ 0x8
INPCK equ 0x10
ISTRIP equ 0x20
INLCR equ 0x40
IGNCR equ 0x80
ICRNL equ 0x100
IXON equ 0x200
IXANY equ 0x800
IXOFF equ 0x400
IMAXBEL equ 0x2000
IUTF8 equ 0x4000
; c_oflag constants
OPOST equ 0x1
ONLCR equ 0x2
OCRNL equ 0x10
ONOCR equ 0x20
ONLRET equ 0x40
OFILL equ 0x80
OFDEL equ 0x20000
NLDLY equ 0x300
CRDLY equ 0x3000
TABDLY equ 0xc04
BSDLY equ 0x8000
VTDLY equ 0x10000
FFDLY equ 0x4000
; c_cflag flag constants
CSIZE equ 0x300
CS5 equ 0x0
CS6 equ 0x100
CS7 equ 0x200
CS8 equ 0x300

CSTOPB equ 0x400
CREAD equ 0x800
PARENB equ 0x1000
PARODD equ 0x2000
HUPCL equ 0x4000
CLOCAL equ 0x8000
CRTSCTS equ 0x30000
; c_lflag flag constants
ISIG equ 0x80
ICANON equ 0x100
ECHO equ 0x8
ECHOE equ 0x2
ECHOK equ 0x4
ECHONL equ 0x10
ECHOCTL equ 0x40
ECHOPRT equ 0x20
ECHOKE equ 0x1
FLUSHO equ 0x800000
NOFLSH equ 0x80000000
TOSTOP equ 0x400000
PENDIN equ 0x20000000
IEXTEN equ 0x400



; Save space for termios structure (temporary global variable).
section .bss
termios.data: resb termios.size
termios.stdin_default_settings: resb termios.size
section .text

; Save termios stdin settings -- call at program init
termios.init:
    pushad
    mov eax, STDIN
    mov edi, termios.stdin_default_settings
    call termios.read
    popad
    ret

; Restore termios stdin settings
termios.set_default_mode:
    pushad
    mov eax, STDIN
    mov edi, termios.stdin_default_settings
    call termios.write
    popad
    ret

; Call at program exit
termios.exit:
    jmp termios.set_default_mode


; Set raw input mode (inlined cfmakeraw: http://man7.org/linux/man-pages/man3/termios.3.html)
termios.set_raw_mode:
    pushad
    mov eax, STDIN
    mov edi, termios.data
    call termios.read

    ; and [termios.data + termios.c_iflag], dword ~(IGNBRK | BRKINT | PARMRK | ISTRIP | IXON)
    ; or  [termios.data + termios.c_iflag], dword IXANY

    ; and [termios.data + termios.c_oflag], dword ~OPOST

    and [termios.data + termios.c_lflag], dword ~(ECHO | ECHONL | ICANON)
    
    ; and [termios.data + termios.c_cflag], dword ~(CSIZE | PARENB)
    ; or  [termios.data + termios.c_cflag], dword CS8

    mov eax, STDIN
    mov edi, termios.data
    call termios.write
    popad
    ret


; Read termios structure using ioctl.
;   in eax fd
;   in edi ptr to termios structure
termios.read:
    push edi
    push dword termios.TIOCGETA
    push eax
    sub esp, 4    ; align stack
    mov eax, 54   ; ioctl system call
    int 0x80
    add esp, 16   ; clear stack
    
    ; Assert call ok
    test eax, eax
    jnz termios.read.error
    ret

; Write termios structure from termios_data using ioctl.
termios.write:
    push edi
    push dword termios.TIOCSETA
    push eax
    sub esp, 4    ; align stack
    mov eax, 54   ; ioctl system call
    int 0x80
    add esp, 16   ; clear stack

    ; Assert call ok
    test eax, eax
    jnz termios.write.error
    ret

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
