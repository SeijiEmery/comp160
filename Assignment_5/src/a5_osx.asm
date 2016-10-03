; Assignment 5:
; Program Description:
;
; Target platform: osx, 32-bit.
;   Uses posix syscalls (write, exit) using bsd 32-bit calling conventions.
;   Should run on linux with minor modifications.
;
; Author: Seiji Emery (student: M00202623)
; Creation Date: 10/3/16
; Revisions: N/A (see git log)
; Date:              Modified by:
;

; tell asmlib to create a start procedure that calls _main and sets up I/O
%define ASMLIB_SETUP_MAIN 
%include "src/asmlib_osx.inc"

section .data

section .text
DECL_FCN _main
    WRITE_STR {"Hello, Assignment 5!"}
END_FCN _main
