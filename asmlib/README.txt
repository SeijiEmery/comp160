
Note: MOST of the code here is "conceptual" (ie. untested code fragments)
The only "real" implementation of asmlib, thus far, is
    src/osx32/asmlib.inc
    tests/osx32/asmlib_tests.asm

These comprise the "library" (currently just jammed together into an include
file for simplicity), and a collection of unit tests to check the correctness
of that library.

This is NOT crossplatform, and will currently only compile for osx, 32-bit.
(theoretically, it should work on linux, but the syscalls (ie. calling conventions)
are not necessarily portable, and elf is different than mach-o). 
64-bit + windows versions are a bit of a ways off, and _might_ involve creation
of a build tool + higher-level assembler as seen in, for example, the build.py 
concept. I would like to support multiple platforms + architectures, but would 
like to do so in a way that is _not_ just copy-pasting the codebase multiple 
times; ideally I'd have one codebase, and at the very least _most_ of the library
(and tests!), eg. I/O routines can be shared across a given architecture + 
assembler (ie. same code on osx, windows + linux).


Goal is to implement read/write X functions and syscall wrappers (low level),
and eventually buffered I/O, ideally general (files, not just stdout/stdin),
some nice-ish console interface sufficient to build a small text-mode game,
memory management w/ an asm version of malloc, an asm version of printf +
scanf, some basic data structures, and an object library. I'd also like to
explore hotloading, signal intercepts, and dynamic code generation (maybe a
jit compiler, if I'm super ambitious). Most of these are pretty far off, 
obviously, and unfortunately I'm severely limited in the time I can spend on 
this project atm.
