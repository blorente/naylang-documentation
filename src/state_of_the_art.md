
State of the art
================

Grace is a relatively new language, and thus it does not feature most of the vast tools and libraries other languages have. However, the open-source spirit of the language makes it so that it is possible to access the information available without restriction.

Kernan
------

Kernan is currently the most feature-complete implementation of Grace. It is an interpreter written entirely in C# [@hejlsberg2003c], and it features some execution and AST models similar to those implemented in Naylang. Specifically, the method dispatch and execution flow takes heavy inspiration from Kernan. However, Kernan is not visitor-based, and therefore it and Naylang diverge in that regard, as Naylang features a flexible and extensible evaluator structure.

Kernan is publicly available from the Grace website[^kernanlink].

Minigrace
------

Minigrace is the original Grace compiler [@matthomerthesis], which is written in Grace itself via bootstrapping with C [^minigracepage]. It does not include all the current language features, but it still serves as an excellent industrial-grade test case for the language.

Minigrace is currently hosted in GitHub[^minigracerepo].

GDB
------

The GNU Project Debugger has for many years been the de facto debugger for C and C++, and thus it merits some time to study it. The main influence of GDB in Naylang is the design of its command set, that is, the commands it offers to the user. In particular, Naylang will focus on reproducing the functionality of the following commands: `run`, `continue`, `next`, `step`, `break` and `print` [^gdbcommands]. Naylang will add another command, `env`, that allows the user to print the current evaluation scope. This set of core commands is simple yet highly usable, and can be composed to form virtually any behavior desired by the user. Support for commands such as `finish` and `list` will be added as future work.

To offer a controlled and pausable execution of a program, GDB reads the executable metada and executes it pausing in the desired locations set by user-specified breakpoints. Since Naylang is an intepreter and thus doesn't generate an executable, this information gathering technique is of course unusable by the project. Instead, Naylang gathers information from the AST (Abstract Syntax Tree) directly to control the debugging flow.


Evaluation modularity
-------

The means by which a language's evaluation can be modularized have been discussed at length in the field of programming language implementation, specially pertaining to Domain Specific Languages [@jlsthesis]. For Naylang, this topic is specially interesting since the traditionally monolithic approaches to language interpreters [@aho1986compilers] imposed a particularly hard barrier on the scope of the project.

Amongst these techniques, the ones that stood out the most are the monad-based approaches (such as the one formulated in [@espinosa1995semantic]), and the mixin-based approaches (abstract subclassing, as presented in [@duggan2000mixin]). These techniques however differ fundamentally from the Visitor-based interpreter pattern that was the aim of Naylang, and thus were discarded in favor of a new approach detailed in the [Modular Visitor Pattern](#modular-visitor-pattern) section.

[^kernanlink]: http://gracelang.org/applications/grace-versions/kernan/

[^minigracepage]: http://gracelang.org/applications/grace-versions/minigrace/

[^minigracerepo]: https://github.com/gracelang/minigrace

[^gdbcommands]: http://users.ece.utexas.edu/~adnan/gdb-refcard.pdf