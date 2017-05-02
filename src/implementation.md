Implementation
==============

The implementation of Naylang follows that of a completely interpreted language.
First, the source is tokenized and parsed with ANTLR 4. Then, a visitor traverses
the parse tree and generates and Abstract Syntax Tree from the nodes, annotating
each one with useful information such as line numbers when necessary.
Lastly, an evaluator visitor traverses the AST and executes each of the nodes.

In addition to the REPL commands, Naylang includes a debug mode,
which allows to debug a file with the usual commands (run, continue, step in,
step over, break). The mechanisms necessary for controlling the execution
flow are embedded in the evaluator, as is explained later.

Lexing and Parsing
------



Abstract Syntax Tree
------

Object and Execution Model
------

Built-in methods and Prelude
------

Heap and Garbage Collection
------

Debugging
------

Frontend
------
