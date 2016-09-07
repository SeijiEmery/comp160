
NASM_OSX = nasm -f macho
LD_OSX   = ld -arch i386 -macosx_version_min 10.7.0

NASM = $(NASM_OSX)
LD   = $(LD_OSX)

all: build/a3
clean: 
	rm -f build/*
interactive:
	when-changed -rs "src" "clear; make run"

run: build/a3
	./build/a3
build/a3: build/a3.o
	$(LD) -o $@ $<
build/a3.o: src/assignment_3_osx.asm
	$(NASM) -o build/a3.o $<
