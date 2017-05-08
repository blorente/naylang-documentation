
Frontend
------

One of the design goals of Naylang is to serve as a teaching example of an interpreter. This requires that the execution core (parsing, AST and evaluation) be as isolated as possible from the interaction with the user, with aims to facilitate the student to discern the essential parts of interpreters from the nonessential I/O operations.

Currently, all the user interaction is handled by the `ConsoleFrontend` class, which is in charge of receiving commands from the user and calling one of it's `ExecutionMode`s to handle the commands.

Execution modes (such as REPL or Debug) are in charge of feeding data to and controlling the flow of the interpreters. Each mode has it's own commands, which are implemented using the Command pattern. It can be easily seen how any one of these pieces can be easily swapped, and seemingly relevant changes such as adding a graphical frontend are as simple as replacing `ConsoleFrontend`.

Here is the list of available commands in Naylang:

```
// Global commands (can be called from anywhere)
>>>> debug <file>
  // Start debugging a file
>>>> repl
  // Start REPL mode
>>>> quit
  // Exit Naylang

// REPL mode
>>>> load (l) <filepath>
  // Open the file, parse and execute the contents
>>>> exec (e) <code>    
  // Execute an arbitrary code in the current environment
>>>> print (p) <expr>
  // Execute an expression and print the result,
  // without modifying the environment.

// Debug mode
ndb> break (b) <line>   
  // Place a breakpoint in a given line
ndb> run (r)   
  // Start execution from the beginning of the file
ndb> continue (c)   
  // Resume execution until end of file or a breakpoint is reached
ndb> env (e)   
  // Print the current environment
ndb> step (st)   
  // Step to the next instruction, entering new scopes
ndb> skip (sk)   
  // Step to the next instruction, skipping scope changes and calls
```

// TODO: UML diagram