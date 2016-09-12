Assignment 3: Write an assembly program that calculates (A + B) - (C + D)
using registers; use a debugger to inspect + verify values.

This directory includes two implementations: 
– src/assignment_3.asm: a MASM version that _should_ work on windows
– src/assignment_3_osx.asm: a NASM version targeted at osx


To build + run the osx version, a makefile has been provided with the following options:
– `make a3`:     builds an executable build/a3
- `make run`:    builds + runs the executable build/a3
– `make clean`:  removes all build products in the build/ folder.
– `make interactive`:
    interactive mode that re-runs `make run` when a file in src/ is changed.
    this uses a file-watcher utility called when-changed (https://github.com/joh/when-changed)

osx dependencies: nasm, make, when-changed (optional)


osx implementation notes:
    - Since I could not figure out how to use nasm with xcode, everything has been
written using makefiles and a text editor (sublime text). This is much more portable
+ flexible, and I'll be using this build environment in the future (if allowed)
    – Debugging is done via two methods (for redundancy):
    – external debugging / program inspection via lldb. The program has public symbol
hooks (_breakpoint_***** labels), which can be set in lldb using `break set -p <symbol_name>`
    – internal debugging / program inspection. I managed to get basic I/O working via
posix syscalls to write(), wrote writeHex32, writeDecimal, and writeStr functions,
and used these to implement a dumpRegisters() function, which non-destructively writes
the contents of eax,ebx,ecx,edx, to stdout. As such, assignment_3_osx.asm is very large,
and effectively just debugs itself (writes program description, each operation, and
register state after each operation to stdout).

For the I/O implementation:
    – http://stackoverflow.com/questions/2535989/what-are-the-calling-conventions-for-unix-linux-system-calls-on-x86-64
      (covers 32-bit + 64-bit calling conventions on osx (bsd 32-bit / System V 64-bit) + linux)
    – osx syscall listings: http://opensource.apple.com//source/xnu/xnu-1504.3.12/bsd/kern/syscalls.master

Additional notes:
    – since the program is simple, it reserves edi for output and internally uses a 
    global input buffer for all write**** calls (flushIO calls syscall write()).
    – WRITE_STR is a macro that declares a local string value + calls writeStr w/ it
    – DECL_FCN / END_FCN are macros that begin/end a procedure (function label / ret),
    create a stack frame (push ebp, mov ebp,esp), and both take the function name for
    clarity (DECL_FCN foo ... END_FCN foo is clearer than DECL_FCN foo .. END_FCN)
    – in nasm, local labels are prefixed with '.', and public labels / external symbols
    are prefixed with '_' (eg. main declared as _main; lldb cannot access labels + variables
    that are not prefixed with an underscore). 
    – This seems to be the convention on at least bsd + windows, but not elf (linux) 
    for some reason...  http://www.nasm.us/doc/nasmdoc9.html#section-9.1.1
    http://stackoverflow.com/questions/1034852/adding-leading-underscores-to-assembly-symbols-with-gcc-on-win32
