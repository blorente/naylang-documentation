\newpage

Project Structure
------

The project is structured as a standard CMake multitarget project.
The root folder contains a `CMakeLists.txt` file detailing the two targets for
the project: The interpreter itself, and the automated test suite. Both folders
have a similar structure, and contain the `.cpp` and `.h` files for the project.
Other folders provide several necessary tools and aids for the project:

```tree
.(root)
  |-- cmake       // CMake modules for the ANTLRv4 C++ target
  |-- dists       // Build script for GCC
  |-- examples    // Examples of Grace Code to test the interpreter
  |-- grammars    // ANTLRv4 grammar files for the Lexer and Parser
  |-- interpreter // Sources to build the Naylang executable
  |-- tests       // Automated test suite
  '-- thirdparty
      '-- antlr   // ANTLRv4 Generator tool and runtime
```

### Sources

The sources folder, `interpreter`, contains the sources necessary to build the
Naylang executable. The directory is structured as a standalone CMake project,
with a `CMakeLists.txt` file and a `src` directory at it's root. Inside the `src`
directory, the project is separated into `core` and `frontends`. Currently only
the console frontend is implemented, but this separation will allow for future
development of other frontends, such as graphical interfaces. The `core`
folder is structured as follows:

```tree
./interpreter/src/core/
|-- control // Controllers for the evaluator traversals
|-- model
|   |-- ast // Definitions of the AST nodes
|   |   |-- control
|   |   |-- declarations
|   |   '-- expressions
|   |       |-- primitives
|   |       '-- requests
|   |-- evaluators // Classes that implement traversals of the AST
|   '-- execution // Classes that describe various runtime components
|       |-- methods
|       '-- objects
'-- parser // Extension of the ANTLRv4-generated parser
```

### Tests

For automated testing, the Catch header-only library was used [@catchcpp].
The interior structure of the `tests` directory **directly mirrors** that of
`interpreter`, and the test file for each class is suffixed with `_test`. Thus,
the test file for `./interpreter/src/core/parser/NaylangParserVisitor` will be
found in `./tests/src/core/parser/NaylangParserVisitor_test.cpp`. Each file has
one or more `TEST_CASE()`s, each with some number of `SECTION()`s. Sections
allow for local shared and local initialization of objects.

### Grammars and examples

There are two Grace-specific folders in the project:

- `grammars` contains the ANTLRv4 grammars necessary to build the project and
generate `NaylangParserVisitor`. The grammar files have the `.g4` extension.

- `examples` contains short code snippets written in the Grace language and
used as integration tests for the interpreter and debugger.

### Build tools

Lastly, the remaining folders contain various aides for compilation and execution:

- `cmake` contains the CMake file bundled with the C++ target, which drives the compilation and linking of the ANTLR runtime. It has been slightly modified to compile a local copy instead of a remote one [@antlr4cmake].

- `thirdparty/antlr` contains two major components:

  - A frozen copy of the ANTLRv4 runtime in the 4.7 version , `antlr-4.7-complete.jar` [@antlr4point7], to be compiled and linked against.
  
  - The ANTLRv4 tool, `antlr-4.7-complete.jar`, which is executed by a macro in the CMake file described earlier to generate the parser and lexer classes. Obviously, this is also in the 4.7 version of ANTLR.