\newpage

Lexing and Parsing
------

This step of the process was performed with the ANTLRv4 tool [@antlr4ref],
specifically the C++ target [@antlr4cpp]. ANTLRv4 generates several lexer and
parser classes for the specified grammar, which contain methods that are executed
every time a rule is activated. These classes can then be extended to override the rule methods and execute
arbitrary code, as will be shown later. 

This method allows instantiation of the AST independently from the grammar specification.

### The Naylang Parser Visitor

For this particular program, the visitor versions of the lexer and parser were chosen from amongst the diferent parsing options provided, since their default implementation allowed for a preorder traversal of the parse
tree, but offered enough flexibility to manually modify the traversal if needed. Note that the choice of the visitor pattern for static analysis is completely independent from that chosen for the runtime intepretation of the code.
One might, for example, prefer to visit the _right_ side of an assignment before
moving onto the _left_ side to instantiate particular types of assignment,
depending on the assigned value. To that end, the `NaylangParserVisitor`
class was created, which extends `GraceParserBaseVisitor`, a class designed to
provide the default preorder implementation of the parse tree traversal.

The class definition along with the overriden method list can be found in
`NaylangParserVisitor.h`.
Note that ANTLRv4 names the visitor methods `visit<RuleName>` by convention.
For example, `visitBlock()` makes it possible to visit the parse tree structure recognized by the `block` rule. 

To pass data between methods, the Naylang Parser Visitor utilizes _two stacks_. The **first stack** stores partial AST nodes that are created as a result of parsing lower branches of the syntax tree, and are then added to the parent node (e.g. the parameter expressions in a method call). A full description of this structure is found in [a following section](#naylang-parser-visitor). The **second stack** stores raw strings, and is used in the construction of proper _canonical names_ and identifiers for methods and fields, respectively.

#### Lexical Tree Visiting Strategy

The strategy followed was to override only the necessary methods to traverse the tree confortably. In general, for a node that depends on child nodes (such as an `Assignment`), the child nodes were visited and instatiated **before** constructing the parent node, as opposed to constructing an empty parent node and adding fields to it as the children were traversed. This approach has two major advantages:

- It corresponds with a postorder traversal of the parse tree, which is more akin to most traditional parsing algorithms.

- As will be seen, it simplifies the design of AST nodes, since it eliminates the need to have mutation operators and transforms them into Data Objects [@dataobjectpattern]. 

#### Prefix and Infix Operators

Prefix and infix operators are a special case of syntactic sugar in Grace, since they allow for the familiar infix and prefix syntax (e.g. `4 + 5`). It is necessary to process these operators as special cases of the syntax, to convert them to valid AST nodes. The Grace specification states that infix and prefix operators must be converted to explicit requests to an object[^gracespecinfixops].

In the case of **prefix operators**, the operation must be transformed to an explicit request in the right-hand receiver. In addition to that, the name of the method to call must be preceded with the `prefix` keyword. For instance, a call to the logical not operator `!x` would be transformed into the explicit request `x.prefix!`. As can be seen, a prefix operator does not take parameters.

For **infix operators** the transformation is similar, but in this case the receiver is the leftmost operand while the right-side operand is passed in as a parameter. In addition, the canonical name of the method must be formed by adding one parameter to the method name, to account for the right-side operand. Therefore, the aforementioned `4 + 5` request would be translated to `4.+(5)`, an explicit request for the `+(_)` method of the object `4` with `5` as a parameter.

### The Naylang Parser Stack

During the AST construction process, information must be passed between parser
function calls. A method call must, for instance, retrieve information about each of its effective parameter expressions. To that end, the parser methods generated
by ANTLR have a return value of type `antlrcpp::Any`. This however was not usable
by the project, since sometimes more than one value needed to be returned and,
most of all, converting from `Any` to the correct node types proved impractical and error-prone.

Therefore, a special data structure was developed to pass information between
function calls. The requirements were that:

- It must hold references to `Statement` nodes.
- It must be able to return the n last inserted `Statement` pointers,
in order of insertion.
- It must be able to return those references as either `Statements`, `Expressions`
or `Declarations`, the three abstract types of AST nodes that the parser handles.

The resulting structure declaration can be found in
`NaylangParserStack.h`. It uses template
metaprogramming [@abrahams2004cpp] to be able to specify the desired return type from the caller
and cast the extracted elements to the right type. Note that a faulty conversion
is possible and the structure does not enforce any type invariants other than
those statically guarranteed by the compiler. Therefore, the invariants must be
implicitly be preserved by the client class.

The parser class uses wrapper functions for convenience to predefine the most
common operations of this structure. For example:

```c++
// NaylangParserVisitor.h
std::vector<StatementPtr> popPartialStats(int length);

// NaylangParserVisitor.cpp
std::vector<StatementPtr> NaylangParserVisitor
        ::popPartialStats(int length) {
    return _partials.pop<Statement>(length);
}
```

An example of the stack usage can be found in parsing user-defined methods, since these require `Statement` nodes for the body and `Declaration`s for the formal parameters. 

```c++
antlrcpp::Any NaylangParserVisitor::
    visitUserMethod(GraceParser::UserMethodContext *ctx) 
	{
	// Parse the signature.
	// After this line, both the node stack and the string stack
	// contain the information regarding the formal parameter nodes
	// and the canonical name, respectively.
    ctx->methodSignature()->accept(this);
	
	// For the method's canonical name by joining each of the parts
    std::string methodName = "";
    for (auto identPart : 
    	popPartialStrs(
    		ctx->methodSignature()->methodSignaturePart().size())) {
        methodName += identPart;
    }

    // Retrieve the formal parameters from the node stack
    int numParams = 0;
    for(auto part : ctx->methodSignature()->methodSignaturePart()){
        numParams += 
        	part->formalParameterList()->formalParameter().size();
    }
    auto formalParams = popPartialDecls(numParams);

	// Parse the method body    
    ctx->methodBody()->accept(this);
    int bodyLength = ctx->methodBody()->methodBodyLine().size();
    auto body = popPartialStats(bodyLength);
    for (auto node : body) {
        notifyBreakable(node);
    }

    // Create the method node
    auto methodDeclaration = 
    	make_node<MethodDeclaration>(
    		methodName, formalParams, body, 
            getLine(ctx), getCol(ctx));

    // Push the new node into the stack as a declaration 
    // for the caller method to consume
    pushPartialDecl(methodDeclaration);
    return 0;
}
```

### Left-Recursion and Operator Precedence

Grace assigns a three levels of precedence for operators: `*` and `/` have the
highest precedence, followed by `+` and `-`, and then the rest of prefix and infix operators along with user and native methods.

Usually, for an EBNF-like [@standard1996ebnf] grammar language to correctly assign operator
precedence, auxiliary rules must be defined which clutter the grammar with
unnecessary information, which is the case for example for LL(k)-grammar parser generators.
ANTLRv4, however, can handle left-recursive rules as long as they are not indirect [@antlr4ref], which allows for the simplification of the grammars by introducing some ambiguity, which is resolved 
by assigning rule precedence based on the position of the alternative in the rule definition. This way, defining operator precedence becomes trivial:

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


[^gracespecinfixops]: http://gracelang.org/documents/grace-spec-0.7.0.html#method-requests