
OSX build instructions:
    cd <somepath>
    git clone https://github.com/SeijiEmery/comp160.git semery_comp160
    cd semery_comp160/Assignment_4/
    mkdir build
    make run
OR
    open src/a4_osx.asm
    make interactive

In interactive mode, file changes of src/* or the makefile will trigger a rebuild. 
This requires a python utility called when-changed:
    https://github.com/joh/when-changed
