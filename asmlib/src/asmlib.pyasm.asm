
$declData('stdout_buffer', 'BYTE', 4096, noInit=True)

$declFcn('Clrscr')
    $if_version('posix')
        $asm_writeStrLit('stdout_buffer', "\x1b[2J\x1b[0;0;H", adv=False)
        $asm_syscall_write($stdout, 'stdout_buffer', len("\x1b[2J\x1b[0;0;H"))
    $elif_version('win32')
        $fixme('Unimplemented Clrscr fcn!')
    $endif_version()
$endFcn('Clrscr')

$if_version('posix')
    $define('begin_io', lambda: '''
        $push_regs( edi = 'stdout_buffer' )
    ''')
    $define('end_io', lambda: '''
        sub edi, 'stdout_buffer'
        $asm_syscall_write($stdout, 'stdout_buffer', edi)
        $pop_regs()
    ''')
$elif_version('win32')

$endif_version()

$declFcn('Gotoxy', link='public', stackframe=True)
    $push_regs( edi = 'stdout_buffer', eax = 0 )
    $asm_writeStrLit('edi', "\x1b[")
    mov al, dh
    push eax
    mov al, dl
    $asm_call('writeDecimal32')
    $asm_writeChar('edi', ';')
    pop eax
    $asm_call('writeDecimal32')
    $asm_writeChar('edi', 'H')

    sub edi, 'stdout_buffer'
    $asm_syscall_write($stdout, 'stdout_buffer', 'edi')
    $pop_regs()
$endFcn('Gotoxy')

;
; Should generate:
;
_Gotoxy:
    push ebp
    mov ebp, esp
    push edi
    mov edi, stdout_buffer
    push eax
    xor eax, eax
    mov [edi + 0], dword 05b1bh ; write '\x1b['
    add edi, 2
    mov al, dh
    push eax
    mov al, dl
    call writeDecimal32
    mov [edi], byte ';'
    inc edi
    pop eax
    call writeDecimal32
    mov [edi], byte 'H'
    inc edi
    sub edi, stdout_buffer
    push edi
    push dword stdout_buffer
    push 1
    int 80h
    pop eax
    pop edi
    ret


; Other features:
$mov('[edi]', 'eax')
$var('foo', 'byte', 1, 0)
$data('foo', 'byte', 20, noInit=True)

; etc...


; Actually, for moves we can probably just use NASM syntax, add a parser, and generate
; MASM syntax automatically...

; We could probably even add 64-bit rax => 32-bit eax conversion for all 
; registers + instructions as well...






