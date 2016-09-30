NASM_OSX = nasm -f macho
LD_OSX   = ld -arch i386 -macosx_version_min 10.7.0 -no_pie

NASM = $(NASM_OSX)
LD   = $(LD_OSX)

NASM64 = nasm -f macho64
LD64 = ld -arch x86_64 -macosx_version_min 10.7.0 -no_pie


all: build/a4
clean:
	rm -f build/*
interactive:
	when-changed -rs "src" "makefile" -c "clear; make run"

run: build/a4
	build/a4
build/a4: build/a4.o
	$(LD) -o $@ $<
build/a4.o: src/a4_osx.asm
	$(NASM) -o $@ $<

interactive_arraySum:
	when-changed -rs "src" "makefile" -c "clear; make run_arraySum"

run_arraySum: build/array_sum
	build/array_sum
build/array_sum: build/array_sum.o
	$(LD64) -o $@ $<
build/array_sum.o: src/array_sum_osx.asm
	$(NASM64) -o $@ $<
