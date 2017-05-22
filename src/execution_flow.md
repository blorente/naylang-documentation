\newpage

Execution flow
------

Before discussing the parsing, the shape of the Abstract Syntax Tree and the implementation of objects, it is necessary to outline the general execution flow of Naylang.

At it's core, Naylang is designed to be an visitor-based interpreter [@parr2009language]. This means that the nodes of the AST are only containers of information, and every processing of the tree is done outside it by a Visitor class. This way, we can decouple the information about the nodes from the actual processing of the information, with the added benefit of being able to define arbitrary traversals of the tree for different tasks. These visitors are called _evaluators_, and they derive from the base class `Evaluator`. `Evaluator` has an empty virtual method for each type of AST node, and each AST node has an `accept()` method that accepts an evaluator. As can be seen, a subclass of `Evaluator` may include rules to process one or more of the node types simply by overriding the default empty implementation.

The main evaluator in Naylang is `ExecutionEvaluator`, with `DebugEvaluator` extending the functionality by providing the necessary mechanisms for debugging. The implementation of the evaluation has been designed to be extensible and modular by default, which is described in [Modularity](#modularity).

Figure 4.2 presents an example AST and it's evaluation stack trace is presented below:

![Example AST for execution flow](images/eval_flow.pdf)

