
Full sourcecode at https://github.com/SeijiEmery/comp160/tree/master/Assignment_5

OSX build instructions:
    cd <somepath>
    git clone https://github.com/SeijiEmery/comp160.git semery_comp160
    cd semery_comp160/Assignment_5/
    mkdir build
    make run
OR
    open src/a5_osx.asm
    make interactive
    (changes to src/a5_osx.asm or the makefile will trigger a rebuild)

Note: you will also need an up-to-date version of nasm, git, and when-changed (optional)
Full build instructions (ie. from a fresh install of osx) are as follows:

First install brew, which is a package manager for osx
    http://brew.sh/

Then, in a terminal window:
    brew install git
    brew install nasm

To get when-changed, a commandline utility written in python, you should first 
install pip, a python package manager (osx comes with python 2.6+)
    https://pip.readthedocs.org/en/stable/installing/#install-pip

And then follow the instructions at https://github.com/joh/when-changed
    (ie. pip install https://github.com/joh/when-changed/archive/master.zip)
