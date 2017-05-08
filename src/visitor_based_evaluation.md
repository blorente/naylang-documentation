Visitor-based Evaluation
------

Before discussing the parsing, the shape of the Abstract Syntax Tree and the implementation of objects, it is necessary to outline the general flow of execution of Naylang.

At it's core, Naylang is designed to be an visitor-based interpreter [@visitorinterp]. This means that the nodes of the AST are only containers of information, and every processing of the tree is done outside it by a Visitor class. This way, we can decouple the information about the nodes from the actual processing of the information, with the added benefit of being able to define arbitrary traversals of the tree for different tasks. Thess visitors are called _evaluators_, and they derive from the base class `Evaluator`. `Evaluator` has an empty virtual method for each type of AST node, and each AST node has an `accept()` method that accepts an evaluator. As can be seen, a subclass of `Evaluator` might include rules to process one or more of the node types simply by overriding the default empty implementation.

The main evaluator in Naylang is ExecutionEvaluator, and it is in charge of traversing the tree and executing the program defined in it, to provide an output. It has several noteworthy parts:

- **The scope** is what determines which fields and methods are accessible at a given time. It is a `GraceObject`, as will be discussed later, and the evaluator features several methods to modify it.
- **The partial** is the means of communicating between function calls. Any objects created as a result of interpreting a node (e.g. a `GraceNumber` created by a `NumberLiteral` node) are placed here, to be cosumed by the caller method.

