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

The design of the abstract syntax representation hierarchy is subject to change as new features are implemented
in the interpreter.

### GraceAST class

// TODO: Complete when merged with NodeFactory and removed the nodelink crap

### Pointers

In the representation of the different parts of the abstract syntax, often a node has to reference other nodes in the tree. Since that memory management of tree nodes was not clear at the beginning of the project, a series of aliases were created to denote pointers to the different major classes of nodes available. These aliases are named `<Nodeclass>Ptr` (e.g. `ExpressionPtr`). For the current representation of the language, only three classes need these pointers specified: Statement, Declaration and Expression. These three classes of pointers give the perfect balance of specificity and generality to be able to express the necessary constructs in Grace. For instance, a variable declaration might want an ExpressionPtr as it's value field, while a method declaration might want DeclarationPtrs for it's formal parameters and high-level StatementPtrs for it's body.

Currently, the aliases are implemented as reference-counted pointers (`std::shared_ptr<>` [@sharedptrcpp]). However, as the project has moved towards a centralized tree manager (`GraceAST`), the possibility of making that clas responsible for the memory of the nodes has arised. This would permit the aliases to switch to weak pointers [@weakptrcpp] or even raw pointers in their representation, probably reducing memory management overhead.

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
distinguish between two types of declarations: __Field Declarations__, and __Method Declarations__.


#### Field Declarations

Field declarations represent the intent of mapping an identifier to a value in the current scope. Depending in the desired mutablity of the expression, these declarations will be represented with either Constant Declarations or Variable Declarations. These two nodes only differ in their evaluation, and their internal representation is identical. They both need an identifier to create the desired field, and optionally an initial value to give to that field.

```c++
class VariableDeclaration : public Declaration {

    std::string _identifier;
    ExpressionPtr _initialValue;

public:

    VariableDeclaration(
    	const std::string &identifier,
    	ExpressionPtr intialValue,
    	int line, int col);

    VariableDeclaration(
    	const std::string &identifier,
    	int line, int col);

    // Accessors and accept()
};
```

Every Field Declaration is a __breakable statement__ (see [Debugging](Debugging)).

#### Method Declarations

Method declarations represent a subroutine inside a grace Object. While their evaluation might be complex, the abstract representation of a method is rather straightforward. Sintactically, a method is comprised of a canonical identifier [@cannonnames], a list of formal parameter definitions (to be later instantiated in the method scope) and a list of statements that comprises the body of the method.

```c++
class MethodDeclaration : public Declaration {

    std::string _name;
    std::vector<DeclarationPtr> _params;
    std::vector<StatementPtr> _body;

public:
    MethodDeclaration(
            const std::string &name,
            const std::vector<DeclarationPtr> &params,
            const std::vector<StatementPtr> &body,
            int line, int col);

    // Accessors and accept()
};
```

### Expression Nodes

#### Control Nodes

Control nodes represent the control structures a user might want to utilize in order to establish the execution flow of the program. Nodes like conditionals, loops and return statements all belong here. Note that, due to the high modularity of Grace, only the most atomic nodes have to be included to make the language Turing-complete, and every other type of control structure (for loops, for instance) can be implemented in a prelude, in a manner transparent to the user [@preludeloops] [@eiffelgraceexample].

##### Conditional Nodes

These nodes form the basis of control flow, and are what makes the foundation of the language. This class includes the IfThen and IfThenElse node definitions:

```c++
class IfThenElse : public Statement {

    ExpressionPtr _condition;
    std::vector<StatementPtr> _then;
    std::vector<StatementPtr> _else;

public:

    IfThenElse(
            ExpressionPtr condition,
            std::vector<StatementPtr> thenExp,
            std::vector<StatementPtr> elseExp,
            int line, int col);

    // Accessors and accept()
};
```

Both nodes have a similar structure, with an expression node as the condition, and blocks of statements to be executed if the condition is met. 

// TODO: Move to evaluation

When evaluating a conditional node, the condition node is evaluated first. Then, if the condition returns `true`, the `then` statements are evaluated. If it is not met, the `else` statements will be evaluated if there are any (IfThenElse nodes), otherwise nothing will be done (IfThen nodes).

#### Loop Nodes

Loop nodes are the nodes used to execute an action repeated times. In this case, only one node type is necessary, the While node.

```c++
class While : public Statement {

    ExpressionPtr _condition;
    std::vector<StatementPtr> _body;

public:
    While(
    	ExpressionPtr condition, 
    	const std::vector<StatementPtr> &body, 
    	int line, int col);

    // Accessors and accept()
};
```

While loops accept a boolean expression as a condition and a list of statements as a body. 

#### Return Nodes

Return is the most basic control structure, and serves to express the desire of terminating the execution of the current method and optionally return a value from it. As such, the only information they hold is the value to be returned.

```c++
class Return : public Statement {

	ExpressionPtr _value;

public:

	// Explicit value return
    Return(
    	ExpressionPtr value,
    	int line, int col);

    // Implicit value return
    Return(int line, int col);

    // Accessors and accept()
};
```

### Assigment

Assignments are a special case node. Since, as will be explained later, objects are maps from identifiers to other objects, the easiest way of performing an assignment is to modify the parent's scope. That is, to assign value A to field X of scope Y (`Y.X := A`) the easiest way is to modify Y so that the X identifier is now mapped to A. Note that a user might omit identifier Y (`X := A`), in which case the scope is implicitly set to `self` (the current scope). Therefore, writing `X := A` is syntactically equivalent to writing `self.X := A`.

The ramifications of this decission are clear. A special case must be defined both in the parser and in the abstract syntax, to allow the retrieval of the field name and optionally the scope in which that field resides:

```c++
class Assignment : public Statement {
public:
  // Explicit scope constructor
  Assignment(
    const std::string &field,
    ExpressionPtr scope,
    ExpressionPtr value);

  // Implicit scope constructor
  Assignment(
  	const std::string &field, 
  	ExpressionPtr value);

  // Accessors and accept()
};
```

### Expressions

Expression nodes are nodes that, when evaluated, must return a value. This
includes many of the usual constructs such as primitives (BooleanLiteral,
NumberLiteral...), ObjectConstructors and Block constructors. However, it also
includes some unusual classes called `Requests`.

#### Primitives

Primitives are the expressions that, when evaluated, must return objects in the a base type of the language. In general, a primitive node is only responsible for holding the information necessary to build an object of it's type, and they correspond directly with native type constructors. For instance, a NumberLiteral node will only need to hold it's numeric value, which is all that's necessary to create a GraceNumber object. Of course, this makes the evaluation of these nodes straightforward, and they will always be leaves of the AST. As an example, this is the defininiton of the primitive node used for strings.

```c++
class StringLiteral : public Expression {

    std::string _value;

public:

    StringLiteral(
    	const std::string &value, 
    	int line, int col);

    // Accessors and accept()
};
```

The list of primitives includes: NumberLiteral, StringLiteral, BooleanLiteral and Lineup.

#### Requests

In Grace everything is an object, and therefore every operation, from variable
references to method calls, has a common interface: A Request made to an object.
Syntactically, it is impossible to differentiate a parameterless method call
from a field request, and therefore that has to be resolved in the interpreter
and not the parser. Hence, we need a representation wide enough to incorporate
all sorts of requests, with any expression as parameters.

```c++
class RequestNode : public Expression {
protected:
    std::string _name;
    std::vector<ExpressionPtr> _params;

public:

	// Request with parameters
    RequestNode(
    	const std::string &methodName, 
    	const std::vector<ExpressionPtr> &params, 
    	int line, int col);

    // Parameterless request (can be a field request)
    RequestNode(
    	const std::string &methodName, 
    	int line, int col);

   	// Accessors and accept()
};
```

There are two types of Requests:

**Implicit Requests** are Requests made to the current scope, that is, they have no explicit receiver. These requests are incredibly flexible, and they accept
almost any parameter. The only necessary parameter is the name of the method or
field requested, so that the evaluator can look up the correct object
in the corresponding scope. Optional parameters include a list of expressions
for the parameters passed to a request (in case it's a method request), and code
coordinates.

```c++
class ImplicitRequestNode : public RequestNode {

public:
	// Constructors inherited from superclass

    ImplicitRequestNode(
    	const std::string &methodName, 
    	const std::vector<ExpressionPtr> &params, 
    	int line, int col);

    ImplicitRequestNode(
    	const std::string &methodName, 
    	int line, int col);

    // Accessors and accept()
};
```

**Explicit Requests** are Requests made to a specified receiver, such as invoking
a method of an object. These Requests are little more than a syntactic
convenience, since they are composed of two Implicit Requests (one for the
receiver, one for the actual request).

```c++
class ExplicitRequestNode : public RequestNode {

    ExpressionPtr _receiver;

public:

	// Constructors call the super() constructor.

    ExplicitRequestNode(
    	const std::string &method, 
    	ExpressionPtr receiver, 
    	const std::vector<ExpressionPtr> &params, 
    	int line, int col);

    ExplicitRequestNode(
    	const std::string &method, 
    	ExpressionPtr receiver, 
    	int line, int col);

    // Accessors and accept()
};
```

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

#### ObjectConstructor Nodes

In Grace (similarly to JavaScript), a user can at any point explicitly create an object with the `object`keyword, followed by the desired contents of the object. this operation is represented in the abstract syntax with an ObjectConstructor node, which evaluates to a user-defined GraceObject.

Since an object can contain virtually any Grace construct, and ObjectConstructor is nothing more than a list of statements that will be evaluated one after the other.

```c++
class ObjectConstructor : public Expression {

    std::vector<StatementPtr> _statements;

public:
    ObjectConstructor(
    	const std::vector<StatementPtr> &statements, 
    	int line, int col);

    // Accessors and accept()
};
```

#### Block Nodes

Blocks are a very particular language feature in Grace. Block expressions create block objects, but also define lambda expressions. Therefore, from the representation's point of view, a block must hold information very similar to that of a method declaration, with formal parameters and a body.

```c++
class Block : public Expression {

    std::vector<StatementPtr> _body;
    std::vector<DeclarationPtr> _params;

public:

    Block(
    	std::vector<StatementPtr> _body,
    	std::vector<DeclarationPtr> _params,
    	int line, int col);

    // Accessors and accept()
};
```