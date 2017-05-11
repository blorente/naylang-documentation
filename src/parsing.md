\newpage

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

```c++
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