NASM_OSX = nasm -f macho
LD_OSX   = ld -arch i386 -macosx_version_min 10.7.0 -no_pie

NASM = $(NASM_OSX)
LD   = $(LD_OSX)

all: build/a5
clean:
	rm -f build/*
interactive:
	when-changed -rs "src" "makefile" -c "clear; make run"

run: build/a5
	build/a5
build/a5: build/a5.o
	$(LD) -o $@ $<
build/a5.o: src/a5_osx.asm
	$(NASM) -o $@ $< -I ../asmlib/src/

along32: build/along32.lib
build/along32.lib: build/along32.o
	$(LD) -static -o $@ $<
build/along32.o: ../Along32/src/Along32.asm
	$(NASM) -o $@ $< -I ../Along32/src/
