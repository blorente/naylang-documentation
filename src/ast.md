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

**Implicit Requests** are Requests made to the current scope, that is, they have no explicit receiver. These requests are incredibly flexible, and they accept
almost any parameter. The only necessary parameter is the name of the method or
field requested, so that the evaluator can look up the correct object
in the corresponding scope. Optional parameters include a list of expressions
for the parameters passed to a request (in case it's a method request), and code
coordinates.

**Explicit Requests** are Requests made to a specified receiver, such as invoking
a method of an object. These Requests are little more than a syntactic
convenience, since they are composed of two Implicit Requests (one for the
receiver, one for the actual request).

Following are some examples of different code snippets, and how they will be
translated into nested Requests (for brevity, IR and ER will be used to denote
ImplicitRequest and ExplicitRequest, respectively):

```grace
x;              // IR("x")
obj.val;        // ER(IR("obj"), "val"))
add(4)to(3);    // IR("add(_)to(_)", {4, 3})
4 + 3;          // ER(4, "+(_)", 3)
```

Note that, even in the case of an expression not returning anything, it will
always return the special object `Done` by default.

### Assigment

Assignments are a special case node. Since, as will be explained later, objects are maps from identifiers to other objects, the easiest way of performing an assignment is to modify the parent's scope. That is, to assign value A to field X of scope Y (`Y.X := A`) the easiest way is to modify Y so that the X identifier is now mapped to A. Note that a user might omit identifier Y (`X := A`), in which case the scope is implicitly set to `self` (the current scope). Therefore, writing `X := A` is syntactically equivalent to writing `self.X := A`.

The ramifications of this decission are clear:

- Firstly, a special case must be defined both in the parser and in the abstract syntax, to allow the retrieval of the field name and optionally the scope in which that field resides:

```c++
class Assignment : public Statement {
public:
  // Explicit scope constructor
  Assignment(
    const std::string &field,
    ExpressionPtr scope,
    ExpressionPtr value);

  // Implicit scope constructor
  Assignment(const std::string &field, ExpressionPtr value);
};

```

- Secondly, the evaluator must also evaluate the new AST node, which is done by evaluating the scope expression first, setting it as the current scope, and then assigning the proper value to the correct field. After that, the previous scope is restored.
