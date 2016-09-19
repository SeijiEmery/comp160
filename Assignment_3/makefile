
NASM_OSX = nasm -f macho
LD_OSX   = ld -arch i386 -macosx_version_min 10.7.0 -no_pie

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
	$(NASM) -o $@ $<

build/a3_min: build/a3_min.o 
	$(LD) -o $@ $<
build/a3_min.o: src/assignment_3_min_osx.asm
	$(NASM) -o $@ $<

debug: build/a3_min
	lldb build/a3_min -s src/lldb_setup_a3_min.txt
auto_debug: build/a3_min
	lldb build/a3_min -s src/lldb_automated_a3_min.txt
interactive_debug:
	when-changed -rs "makefile" "src" -c "clear; make auto_debug"

build/a3_min.lst: src/assignment_3_min_osx.asm
	$(NASM) -l $@ $<
listfile: build/a3_min.lst
	open build/a3_min.lst
