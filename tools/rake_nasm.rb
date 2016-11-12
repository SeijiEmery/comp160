
BUILD_DIR = "build"

NASM = { :x86 => "nasm -f macho", :x64 => "nasm -f macho64"}
LD   = { 
    :x86 => "ld -arch i386 -macosx_version_min 10.7.0 -no_pie",
    :x64 => "ld -macosx_version_min 10.7.0 -lSystem",
}


#
# misc nasm-related helper functions
#

# Join a string / list of strings / nil into a space-separated list
# that can be used in shellcode.
def join_args (args)
    if not args
        return ""
    elsif args.kind_of?(Array)
        return args.join(" ")
    else
        return args
    end
end

# Create a nasm <src files> => <object> task.
def nasm_file (arch, target, src, flags = nil)
    file target => src do
        sh "#{NASM[arch]} #{join_args(flags)} -o #{target} #{join_args(src)}"
    end
end

# Create a nasm <src files> => <list file> task.
def nasm_listfile (arch, target, src, flags = nil)
    file target => src do
        sh "#{NASM[arch]} #{join_args(flags)} -l #{target} #{join_args(src)}"
    end
end

# Create a ld <object files> => <executable> task.
# No direct support for adding libraries, includes, etc., though that
# can / should be possible using flags...?
def link_file (arch, target, libs, flags = nil)
    file target => libs do
        sh "#{LD[arch]} #{join_args(flags)} -o #{target} #{join_args(libs)}"
    end
end

# Take an existing task, and add an interactive version of it (i<taskname>),
# which re-runs the task (using rake) whenever a file in watch_list changes.
def add_interactive_task (target, watch_list)
    task "i#{target}" => target do
        sh "when-changed -rs #{join_args(watch_list)} -c 'clear; rake #{target}'"
    end
end

# View a file. Could use open (osx), or cat (*nix); the latter is simpler
# and less intrusive, so we'll just go with that.
def view_file (file)
    sh "cat #{file}"
end

#
# nasm targets, etc.
#

# Global variables (I know; this was the simplest solution!) that store
# information related to past build targets (build target map, and list
# of source files).
#
# This enables calls subsequent to a nasm_target() call (eg. debug_task)
# to just pass in the build target name, and reuse information from the
# previous call (ie. don't have to supply source files twice; will have
# correct build path, etc).
$nasm_path_map = Hash.new
$nasm_src_map  = Hash.new

# Defines a nasm target / source file, and creates the following tasks:
#   <BUILD_DIR>/<target>.o: compile .asm source files => .o using nasm_file call
#   <BUILD_DIR>/<target>:   link .o file, libs => target using link_file call
#   <target>:               builds + runs target in <BUILD_DIR>/<target>.
#   i<target>:              runs target interactively when source files change
#                           using python when-changed utility (add_interactive_task call) 
def nasm_target (target, src, idir=nil, libonly=false, arch=:x86)
    target_path = "#{BUILD_DIR}/#{target}"
    obj_path    = "#{target_path}.o"

    nasm_flags = []
    if idir && idir.kind_of?(Array)
        idir.each {|dir| nasm_flags << "-I #{dir}" }
    elsif idir
        nasm_flags << "-I #{idir}"
    end

    $nasm_path_map[target] = target_path
    $nasm_src_map[target]  = src

    nasm_file(arch, obj_path, src, nasm_flags)

    if libonly
        task target => obj_path do end
    else
        link_file(arch, target_path, obj_path)

        task target => target_path do sh target_path end
        add_interactive_task(target, src)
    end
end

# Adds a debug task, running lldb on an existing target, w/ optional lldb startup scripts.
# Has an interactive version.
#   <name>:    build + run target within lldb
#   i<name>:   build + run target interactively within lldb using when-changed.
def debug_task (name, target, script)
    target_path = $nasm_path_map[target]
    task name => target_path do
        sh "lldb #{target_path} -s #{script}"
    end
    add_interactive_task(name, $nasm_src_map[target])
end

# Adds a listfile task, generating + opening / viewing a listfile for an existing target.
# Has an interactive version; creates the following tasks:
#   <BUILD_DIR>/<target>.lst: generate a listfile out of target sources.
#   <name>:   generate + view the listfile using cat or w/e
#   i<name>:  generate + view the listfile interactively, updating whenever
#             source files change using when-changed.
def listfile_task (name, target, arch = :x86)
    target_path = "#{$nasm_path_map[target]}.lst"
    src         = $nasm_src_map[target]

    nasm_listfile(arch, target_path, src)
    task name => target_path do view_file(target_path) end
    add_interactive_task(name, src)
end
