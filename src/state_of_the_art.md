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
