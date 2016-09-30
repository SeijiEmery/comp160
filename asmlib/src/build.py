from asm_build_utils import *
# Not sure if the above line is necessary – we might be importing this file, instead of the
# other way around...

# This is the config file for our awesome, yet-to-be-constructed build system.
# I'm not sure _exactly_ what the backend is / will be (yet), but the general idea is to have
# a robust build tool for assembly projects that supports:
#   – unit tests
#   – libraries + source code dependencies
#   – branching versions (can have a osx_x86 version, an osx_x64 version, and a win_32 version
#     of X, for example)
#   – interactive builds (ie. what I'm doing already w/ when-changed + make, but better
#     and fully compatible w/ all the other features listed here)
#   – multiple build actions (compile / run / debug interactively w/ lldb setup script /
#     debug w/ fully automated lldb script)
#   – extensible: can extend this tool to do anything w/ python hooks in build.py
#
# The frontend for this will be a build tool (ybt?), that uses a build.py script for setup;
# multiple commandline options, etc.
#
#   ybt -i auto_debug assignment_4 --disable_unit_tests io_tests malloc_tests
#
# ie. interactively run the auto_debug build action on the assignment_4 target w/ the
# following unit tests disabled: io_tests, malloc_tests (if they exist in the context 
# of assignment_4)
#
# Changing build.py, the source file (assignment_4.asm), any of the dep files (macros.inc,
# io.inc, platform.inc), etc., will re-compile + re-run the target in lldb (and re-run lldb
# (only) if the lldb scripts change). Changing the library files will also re-run the
# associated unit tests (if they haven't been disabled), and cancel the build w/ an error
# message if any of them failed (but re-run them continuously when changed until/if the
# tests passed or ^C)
#
# Other must-have features:
#   – running interactively (-i) w/ no build.py in the current directory (doesn't exist
#     / has been deleted), a build.py that contains _any_ errors, etc., does not kill
#     the interactive build. ybt will keep trying to run that build.py (and displaying
#     any resulting errors) whenever build.py changes
#   – will _not_ run anything if any stage had errors (build.py, deps, unit tests,
#     the build itself, etc)
#   – all build.py calls thoroughly sanity-check their arguments and raise _helpful_
#     error messages for user errors
#   – the build.py interface is simple, and minimalistic. Should probably consist of:
#       version object
#       define
#       target (w/ build actions)
#       warn_*********** calls to kill current build w/ useful error messages
#       build_action utils (make_target, run_target, debug_target_lldb, etc -- these
#          are just functions that match a _specific_ ybt interface, and can be
#          overridden + extended by the user)
#


# define: adds thing to an internal list of things that can get substituted into
# strings used for paths, other defines, targets, etc. basically:
#   define(thing, string) =>
#       thing_dict[thing] = string.format(thing_dict)
#
define('asmlib_dir', '../asmlib')

# version: thing that behaves as a fcn (list of version identifiers => returns true
# iff matches all of them), object w/ attributes (.os, .arch, .asm, which correspond
# to the os ('osx','win','linux'), architecture ('x86', 'x64'), and assembler ('nasm', 'masm'),
# respectively).
# The implementation should be interesting :) 
# (actually trivial: just an object instance w/ overloaded __call__; maybe other meta hooks)
if version('osx', 'x86'):
    define('platform.inc', '{asmlib_dir}/src/platform/platform_osx_x86.inc')
elif version('osx', 'x64'):
    define('platform.inc', '{asmlib_dir}/src/platform/platform_osx_x64.inc')
else:
    warn_unsupported_version("Missing platform version for {version.os}, {version.arch}")

if version('nasm'):
    define('macros.inc', '{asmlib_dir}/src/macros_{version.asm}_{version.arch}.inc')
    define('io.inc',     '{asmlib_dir}/src/io_{version.asm}_{version.arch}.inc')

    # Create a target. Target can be executable, library, or 'include' (a 'library' of include files...)
    # 'include' is special b/c we don't technically compile anything (well, we might textually insert
    # the includes into the source files of anything w/ a dependency on this, b/c nasm %include sucks),
    # but the main thing is it's just a dependency w/ a bunch of includes _that can have build actions
    # and unit tests attached to them_ (and these get re-run whenever the source files change, and this
    # affects any/all build targets in later phases, etc)
    #
    target('asmlib', kind='include', src=[
            'macros.inc', 'platform.inc', 'io.inc'
        ])
        # unittest(name, ...) creates an executable target that:
        #   – automatically inherits everything from its parent target (parent added to deps...?)
        #   – if this executable returns non-zero (ie. how a unit test signals failure), will interrupt
        #     compilation of the parent target and anything that depends on that target.
        #   – this can, ofc, be overridden w/ command line flags
        # 
        .unittest('io_tests', src='{asmlib_dir}/tests/io_test_{version.os}_{version.arch}.asm', enforce_if_absent=False)
        .unittest('str_tests', src='{asmlib_dir}/tests/str_test_{version.os}_{version.arch}.asm', enforce_if_absent=False)
        .unittest('array_tests', src='{asmlib_dir}/tests/array_test_{version.os}_{version.arch}.asm', enforce_if_absent=False)
        .unittest('malloc_tests', src='{asmlib_dir}/tests/malloc_test_{version.os}_{version.arch}.asm', enforce_if_absent=False)

    # if version('osx','x86'):   define('assignment_4.asm', '../assignment_4/src/assignment_4_osx.asm')
    # elif version('osx','x64'): define('assignment_4.asm', '../assignment_4/src/assignment_4_osx_x64.asm')

    # if version('osx','x86'):   define('a4_debug_script.lldb', '../assignment_4/src/a4_debug_script_osx_x86.lldb')
    # elif version('osx','x64'): define('a4_debug_script.lldb', '../assignment_4/src/a4_debug_script_osx_x64.lldb')

    define('assignment_4.asm',     '../assignment_4/src/assignment_4_{version.os}_{version.arch}.asm')
    define('a4_debug_script.lldb', '../assignment_4/src/a4_debug_script_{version.os}_{version.arch}.lldb')
    define('a4_auto_run.lldb',     '../assignment_4/src/a4_auto_run_{version.os}_{version.arch}.lldb')

    target('assignment_4', kind='executable', src='assignment_4.asm', deps='asmlib')
        # Build action: action_identifier => action_callback (plus optional arguments: additional deps for that action, etc)
        #   action_callback: a function that meets a specific interface for ybt; takes a bunch of info about the
        #       target + deps, and should run a build action (or multiple build actions).
        #   builtin actions:
        #       make_target: assembles the target using your os / architecture version, and your default, or specific
        #           assembler for that target, taking into account source files, etc. Sounds complex, but this should
        #           be mostly handled by the stuff that ybt hands this function.
        #       run_target:  runs the resulting executable from make_target
        #       debug_target_lldb: runs the target in a debugger (lldb), using one or more lldb script files to setup
        #           the debugging environment (ie. set breakpoints, etc).
        #       chain: function that calls multiple functions in sequence w/ perfectly forwarded args.
        #
        # Specific function interface tbd, but should be simple-ish, have a relatively simple / clean contract,
        # and not contain magic. All of the default functions (see above) should be implementable by the user
        # without too much effort.
        #
        .build_action('compile', make_target)
        .build_action('run', chain(make_target, run_target))
        .build_action('debug', chain(make_target, debug_target_lldb('a4_debug_script.lldb')), deps='a4_debug_script.lldb')
        .build_action('auto_debug', chain(make_target, debug_target_lldb('a4_debug_script.lldb', 'a4_auto_run.lldb')), 
            deps=['a4_debug_script.lldb', 'a4_auto_run.lldb'])




