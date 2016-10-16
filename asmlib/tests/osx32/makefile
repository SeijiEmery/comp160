NASM_OSX = nasm -f macho
LD_OSX   = ld -arch i386 -macosx_version_min 10.7.0 -no_pie

NASM = $(NASM_OSX)
LD   = $(LD_OSX)

run: build/asmlib_tests
	build/asmlib_tests
build/asmlib_tests: build/asmlib_tests.o
	$(LD) -o $@ $<
build/asmlib_tests.o: asmlib_tests.asm
	$(NASM) -o $@ $< -I ../../src/osx32/
clean:
	rm -f build/*
interactive:
	when-changed -rs "asmlib_tests.asm" "../../src/osx32/" -c "clear; make run"
