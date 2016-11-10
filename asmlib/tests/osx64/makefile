NASM_OSX = nasm -f macho64
LD_OSX   = ld -macosx_version_min 10.7.0 -lSystem

NASM = $(NASM_OSX)
LD   = $(LD_OSX)

interactive_syscall_test:
	when-changed -rs "syscall_test.asm" "../../src/osx64/asmlib.inc" "makefile" -c "clear; make run_syscall_test"
run_syscall_test: build/syscall_test
	$< -foo -bar
build/syscall_test: build/syscall_test.o
	$(LD) -o $@ $<
build/syscall_test.o: syscall_test.asm
	$(NASM) -o $@ $< -I ../../src/osx64/

run: build/asmlib_tests
	build/asmlib_tests
build/asmlib_tests: build/asmlib_tests.o
	$(LD) -o $@ $<
build/asmlib_tests.o: asmlib_tests.asm
	$(NASM) -o $@ $< -I ../../src/osx32/
clean:
	rm -f build/*
interactive:
	when-changed -rs "asmlib_tests.asm" "../../src/osx32/asmlib.inc" -c "clear; make run"
