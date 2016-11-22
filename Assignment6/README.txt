
Full source code at https://github.com/SeijiEmery/comp160/tree/master/Assignment6/

Windows build instructions:
– No project files, but there are 2 source files:
    – src/a6_pt1_win32.asm
    – src/a6_pt2_win32.asm
– Both are single, standalone programs that target 32-bit MASM,
  with a dependency on the Irvine32 library from class.

OSX build instructions:
– For once, this is just a port of the windows version, ported to NASM, and
  built against the Irvine32 shims I wrote for asmlib (my own 32-bit / 64-bit
  x86 from-scratch library)
– Depends on git, nasm, rake (build system), and ruby (runs rake; should be 
  installed by default on osx).

Fetching sources:
    cd <some-temp-directory>
    git clone https://github.com/SeijiEmery/comp160.git semery_comp160
    cd semery_comp160/Assignment6/
    mkdir build
    rake          (builds + runs part1, then part2)
 OR rake part1
 OR rake part2    (to run specific parts)

To clean:
    rake clean    (removes build files from build/)

When done:
    cd <some-temp-directory>
    rm -f semery_comp160

OSX DEPENDENCIES
– install brew:  http://brew.sh/
– install dependencies: (exclude whatever you already have)
    brew install git nasm python ruby

To install rake: (requires ruby)
    gem install rake

To install when-changed (a python-based utility optionally used by the build
system for interactive builds: https://github.com/joh/when-changed)
– install pip (python package manager): 
    https://pip.readthedocs.org/en/stable/installing/#install-pip
– with pip installed:
    pip install when-changed
