State of the art
================

Kernan
------

Kernan is currently the most feature-complete implementation of Grace [@kernanfeatures]. It is an interpreter written entirely in C#, and it features some similar execution and AST models as those implemented in Naylang. Specifically, the method dispatch and execution flow takes heavy inspiration from Kernan.

Kernan is publicly available from the Grace website [@kernanlink].

Minigrace
------

Minigrace is the original Grace compiler [@matthomerthesis], which is written in Grace itself via bootstrapping with C [@minigracepage]. It does not include all the current language features, but it still serves as an excellent industrial-grade test case for the language.

Minigrace is currently hosted int GitHub [@minigracerepo].

GDB
------

The GNU Project Debugger has been the de facto debugger for C and C++ for many years, and thus it merits some time to study it. The main influence of GDB in Naylang will be the design of it's command set, that is, the commands if offers to the user. In particular, Naylang will focus on reproducing the functionality of the following commands: `run`, `continue`, `next`, `step`, `break`, `print` [@gdbcommands]. Naylang will add another command, `env`, that allows the user to print the current evaluation scope. This set of core commands is simple yet highly usable, and can be composed to form virtually any behavior desired by the user. Support for commands such as `finish` and `list` will be added as future work.

To offer a controlled and pausable execution of a program, GDB reads the executable metada, and executes it pausing in the desired locations set by user-specified breakpoints. Nince Naylang is an intepreter and thus doesn't generate an executable, this information gathering technique is of course unusable by the project. Instead, Naylang will gather information from the AST directly to control the debugging flow.
