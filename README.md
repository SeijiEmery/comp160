Bunch of assembly stuff that I need to clean up + pull out into something else eventually.

## Background: 

I took an x86 Assembly + Comp Organization class, which used http://kipirvine.com/asm/ (FANTASTIC TEXTBOOK), and MASM (microsoft assembler - less... than fantastic; actually extremely godawful and poorly designed – I'll write a blog post on this eventually, lol).

Both the MASM language and its tooling / build environment are completely terrible terrible (visual studio, but with no syntax highlighting or autocomplete, and a really, really shitty assembler that was probably written by one intern in the 90's and has the world's most unhelpful error messages...). And I wanted to work off of OSX. So, I just learned NASM (net assembler – another x86 dialect, and a much BETTER assembler that used the intel (and not at&t) syntax), wrote my own build system / environment (if you could call it that – basically just bash + rake + when-chagned + sublime text), and reimplemented the parts of irvine's utility library that I needed (I/O, memory management, etc) from scratch using osx (bsd) system calls. Cuz obviously linking stdlibc was cheating and this was more fun :)

I've stuck this project here cuz it contains some cool stuff (eg. a mini object-oriented runtime that was half finished; pseudo-unittesting capabilities (in assembly!), some hacks to build interactive text-mode applications using ANSI escape sequences to draw stuff, etc).

Plagarism is a concern, but this was for a small CC class, and if anywone were copying my code it'd be extremely obvious, as everything in here is quite advanced, and somewhat nonstandard (macros everywhere! custom utility library that has an adaptor interface for irvine32 but is otherwise completely different!). Etc.
