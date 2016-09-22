NASM_OSX = nasm -f macho
LD_OSX   = ld -arch i386 -macosx_version_min 10.7.0 -no_pie

NASM = $(NASM_OSX)
LD   = $(LD_OSX)

all: build/a4
clean:
	rm -f build/*
interactive:
	when-changed -rs "src" "clear; make run"

run: build/a4
	build/a4
build/a4: build/a4.o
	$(LD) -o $@ $<
build/a4.o: src/a4_osx.asm
	$(NASM) -o $@ $<
