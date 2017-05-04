Implementation
==============

The implementation of Naylang follows that of a completely interpreted language.
First, the source is tokenized and parsed with ANTLRv4. Then, a visitor traverses
the parse tree and generates and Abstract Syntax Tree from the nodes, annotating
each one with useful information such as line numbers when necessary.
Lastly, an evaluator visitor traverses the AST and executes each of the nodes.

In addition to the REPL commands, Naylang includes a debug mode,
which allows to debug a file with the usual commands (run, continue, step in,
step over, break). The mechanisms necessary for controlling the execution
flow are embedded in the evaluator, as is explained later.

//TODO Class diagram
[]

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

Lexing and Parsing
------

This step of the process was performed with the ANTLRv4 tool [@antlr4ref],
specifically the C++ target [@antlr4cpp]. ANTLRv4 generates several lexer and
parser classes for the specified grammar which contain methods that are executed
every time a rule is activated.

These classes can then be extended to override those rule methods and execute
arbitrary code, as will be shown later. This method allows instantiation of the
AST independently from the grammar specification.

### The Naylang Parser Visitor

For this particular program, the Visitor lexer and parser were chosen, since
ANTLRv4's default implementation allowed for a preorder traversal of the parse
tree, but offered enough flexibility to manually modify the traversal if needed.
One might, for example, prefer to visit the right side of the assignment before
moving onto the left side to instantiate particular types of assignment
depending on the assigned value. To that end, the `NaylangParserVisitor.cpp`
class was created, which extends `GraceParserBaseVisitor`, a class designed to
provide the default implementation of a parse tree traversal.

The class definition along with the overriden method list can be found in
`interpreter/src/core/parser/NaylangParserVisitor.h`.
Note that ANTLRv4 names the visitor methods `visit<RuleName>` by convention.
For example, `visitBlock()` will be called when the `block` rule is matched in
parsing.

### The Naylang Parser Stack

During the AST construction process, information must be passed between parser
function calls. A function call parser rule must have information about each of
the parameters available, for example. To that end, the parser methods generated
by ANTLR have a return value of type `antlrcpp::Any`. This however was not usable
by the project, since sometimes more than one value needed to be returned, and
most of all, converting from `Any` to the correct node types proved impossible.

Therefore, a special data structure was developed to pass information between
function calls. The requirements were:

- It must hold references to Statement nodes.
- It must be able to return the n last inserted Statement pointers,
in order of insertion.
- It must be able to return those references as either Statements, Expressions
or Declarations, the three abstract types of AST nodes that the parser handles.

The resulting structure declaration can be found in
`interpreter/src/core/parser/NaylangParserStack.h`. It uses template
metaprogramming to be able to specify the desired return type from the caller
and cast the extracted elements to the right type. Note that a faulty conversion
is possible and the structure does not enforce any type invariants other than
those statically enforced by the compiler. Therefore, the invariants must be
implicitly be preserved by the client class.

The parser class uses wrapper functions for convenience to predefine the most
common operations of this structure. For example:

```cpp
// NaylangParserVisitor.h
std::vector<StatementPtr> popPartialStats(int length);

// NaylangParserVisitor.cpp
std::vector<StatementPtr> NaylangParserVisitor
        ::popPartialStats(int length) {
    return _partials.pop<Statement>(length);
}
```

### Left-Recursion and Operator Precedence

Grace assigns a three levels of precedence for operators: `*` and `/` have the
highest precedence, followed by `+` and '-', and then the rest of prefix and infix
operators along with user methods are executed.

Usually, for an EBNF-like [@standard1996ebnf] grammar language to correctly assign operator
precedence, auxiliary rules must be defined which clutter the grammar with
unnecessary information.
ANTLRv4, however, can handle left-recursive rules as long as they are not indirect [@antlr4ref].
It does this by assigning rule precedence based on the position of the alternative in the rule definition. This way, defining operator precedence becomes trivial:

```antlr
// Using left-recursion and implicit rule precendence.
expr  : expr (MUL | DIV) expr
      | expr (PLUS | MINUS) expr
      | explicitRequest
      | implicitRequest
      | prefix_op expr
      | expr infix_op expr
      | value
      ;
```

As can be seen, the precedence is clearly defined and expressed where it matters
the most (the first two lines). Grace's specification does not define a precedence
for any other type of expression, so the rest is left to the implementer.

A slightly more annotated version of this rule can be found in the parser grammar,
under the `expression` rule.

Abstract Syntax Tree
------

As an intermediate representation of the language, a series of classes has been
developed to denote the different aspects of the abstract syntax. Note that
even though the resulting number of classes is rather small, the iterative
process necessary to arrive to the following hierarchy took many iterations,
due to the sparse specification of the language semantics [@gracespec] and the
close ties this language has with the execution model. This created a loop where
design decisions in the execution model required changes in the AST
representation, and vice versa. The following diagram represents the current
class hierarchy:

// TODO: add class diagram
[]

The design of the AST is subject to change as new features are implemented
in the interpreter.

### Statement Nodes

The Statement nodes are at the top of the hierarchy, defining common traits for
all other nodes, such as source code coordinates. Control structures, such as
IfThen and While, are the closest to pure statements that there is. It could be
said that Return is the purest of statements, since it does not hold any extra
information.

### Declaration Nodes

The declaration nodes are nodes that do not return a value, and bind a specific
value to an identifier. Therefore, all nodes must have a way of retrieving their
names so that the fields can be created in the corresponding objects. We must
distinguish between two types of declarations:

- Constant and Variable Declarations represent the desire to create fields
inside an object, and hold an expression with their initial value. They are also
_breakable statements_ (see [Debugging](Debugging)).
- Method declarations represent a subroutine inside Grace, which contain an
arbitrary-length list of executable Statements, which will be executed every
time the method is called.

### Expression Nodes and Requests

Expression nodes are nodes that, when evaluated, must return a value. This
includes many of the usual constructs such as primitives (BooleanLiteral,
NumberLiteral...), ObjectConstructors and Block constructors. However, it also
includes some unusual classes called `Requests`.

In Grace everything is an object, and therefore every operation, from variable
references to method calls, has a common interface: A Request made to an object.
Syntactically, it is impossible to differentiate a parameterless method call
from a field request, and therefore that has to be resolved in the interpreter
and not the parser. Hence, we need a representation wide enough to incorporate
all sorts of requests, with any expression as parameters.

There are two types of Requests:

- Implicit Requests are Requests made to the current scope, that is, they have
no explicit receiver. These requests are incredibly flexible, and they accept
almost any parameter. The only necessary parameter is the name of the method or
field requested, so that the evaluator can look up the correct object
in the corresponding scope. Optional parameters include a list of expressions
for the parameters passed to a request (in case it's a method request), and code
coordinates.

- Explicit Requests are Requests made to a specified receiver, such as invoking
a method of an object. These Requests are little more than a syntactic
convenience, since they are composed of two Implicit Requests (one for the
receiver, one for the actual request).

Following are some examples of different code snippets, and how they will be
translated into nested Requests (for brevity, we will use IR and ER to denote
ImplicitRequest and ExplicitRequest, respectively):

```grace
x;              // IR("x")
obj.val;        // ER(IR("obj"), "val")
add(4)to(3);    // IR("add(_)to(_)", {4, 3})
4 + 3;          // ER(4, "+(_)", 3)
```

Note that, even in the case of an expression not returning anything, it will
always return the special object `Done` by default.

Methods and Dispatch
------

Object and Execution Model
------

In Grace, everything is an object, and therefore the implementation of these
must be flexible enough to allow for both JavaScript-like objects and native
types such as booleans, numbers and strings.

### GraceObject

For the implementation, a generic `GraceObject` class was created, which defined
how the fields and methods of objects were implemented:

```c++
class GraceObject {
protected:
    std::map<std::string, MethodPtr> _nativeMethods;
    std::map<std::string, MethodPtr> _userMethods;
    std::map<std::string, GraceObjectPtr> _fields;

    GraceObjectPtr _outer;

public:
  // ...
}
```

As can be seen, an object is no more than maps of fields and methods. Since
every __field__ (object contained in another object) has a unique string
identifier, and methods can be differentiated by their canonical name
[@gracecanonname], a plain C++ string is sufficient to serve as index for the
lookup tables of the objects.

`GraceObject` also provides some useful methods to modify and access these maps:

```c++
class GraceObject {
public:
    // Field accessor and modifier
    virtual bool hasField(const std::string &name) const;
    virtual void setField(const std::string &name, GraceObjectPtr value);
    virtual GraceObjectPtr getField(const std::string &name);

    // Method accessor and modifier
    virtual bool hasMethod(const std::string &name) const;
    virtual void addMethod(const std::string &name, MethodPtr method);
    virtual MethodPtr getMethod(const std::string &name);

    // ...
}
```

### Native types

Grace has several native types: `String`, `Number`, `Boolean`, `Iterable` and `Done`. Each of these
is implemented in a subclass of `GraceObject`, and if necessary stores the
corresponding value. For instance:

```c++
class GraceBoolean : public GraceObject {
    bool _value;
public:

    GraceBoolean(bool value);
    bool value() const;

    // ...
}
```

Each of these types has a set of native methods associated with it (such as the
`+(_)` operator for numbers), and those methods have to be instantiated at
initialization. Therefore, `GraceObject` defines an abstract method
`addDefaultMethods()` to be used by the subclasses when adding their own native
methods. For example, this would be the implementation for Number:

```c++
void GraceNumber::addDefaultMethods() {
    _nativeMethods["prefix!"] = make_native<Negative>();
    _nativeMethods["==(_)"] = make_native<Equals>();
    // ...
    _nativeMethods["^(_)"] = make_native<Pow>();
    _nativeMethods["asString(_)"] = make_native<AsString>();
}
```

There are some other native types, most of them used in the implementation and
invisible to the user, but they have no methods and only one element in their
type class, such as `Undefined`, which throws an error whenever the user tries
to interact with it.

### Casting

Since this subset of Grace is dynamically typed, object casting has to be
resolved at runtime. Therefore, `GraceObject`s must have the possibility of
transforming themselves into other types. Namely, we want the possiblity to,
for any given object, retrieve it as a native type at runtime. This is
accomplished via virtual methods in the base class, **which error by default**:

```c++
virtual const GraceBoolean &asBoolean() const;
virtual const GraceNumber &asNumber() const;
virtual const GraceString &asString() const;
// ...
virtual bool isClosure() const;
virtual bool isBlock() const;
```

Heap and Garbage Collection
------

Debugging
------

Frontend
------
