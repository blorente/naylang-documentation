\pagebreak



Execution Evaluator
-------

The `ExecutionEvaluator` (or EE) is one of the most crucial components of Naylang. It is its responsibility to traverse the AST created by the parser and interpret each node's meaning, executing the commands necessary to simulate the desired program's behavior. In a sense, it could be said that the `ExecutionEvaluator` is the engine of the interpreter. 

As previously described, the `ExecutionEvaluator` (as do all other subclasses of `Evaluator`) follows the Visitor pattern to encapsulate the processing associated with each node. This particular subclass overrides every node processing, since each one has some sematics associated with it.

### Structure

An important part of the EE is the mechanism used to share information between node evaluations. For instance, there has to be a way for the evaluator to access the number object created after traversing a `NumberLiteral` node. For that, the EE has two mechanisms:

- **The scope** is what determines which fields and methods are accessible at a given time. It is a `GraceObject`, as will be discussed later, and the evaluator features several methods to modify it. The scope can be modified and interchanged depending on the needs of the programs. For example, executing a method requires creating a subscope that contains variables local to the method, and discarding it after it is no longer needed.

- **The partial** result object is the means of communicating between the evaluation of different nodes. Any objects created as a result of interpreting a node (e.g. a `GraceNumber` created by a `NumberLiteral` node) are placed here, to be cosumed by the caller method. For instance, when evaluating an `Assignment` the evaluator needs access to the object generated by evaluating the value node. The phrases "return" and "place in the partial" are used interchangeably in the rest of the section.

```c++
class ExecutionEvaluator : public Evaluator {
    GraceObjectPtr _partial;
    GraceObjectPtr _currentScope;
public:
    ExecutionEvaluator();

    virtual void evaluate(BooleanLiteral &expression) override;
    virtual void evaluate(NumberLiteral &expression) override;
    virtual void evaluate(StringLiteral &expression) override;
    virtual void evaluate(ImplicitRequestNode &expression) override;
    virtual void evaluate(ExplicitRequestNode &expression) override;
    virtual void evaluate(MethodDeclaration &expression) override;
    virtual void evaluate(ConstantDeclaration &expression) override;
    virtual void evaluate(Return &expression) override;
    virtual void evaluate(Block &expression) override;
    virtual void evaluate(ObjectConstructor &expression) override;
    virtual void evaluate(VariableDeclaration &expression) override;

    // Accessors and mutators
};
```

### Evaluations

The following section details how each node class is evaluated. This categorization closely resembles that of the AST description, since the structure of the syntax tree strongly conditions the structure of the evaluator. 

### Expressions

In Naylang's abstract syntax, expressions are nodes that return a value. In terms of the evaluation, this translates to expressions being nodes that, when evaluated, **place an object in the partial**. This object can be new (e.g. when evaluating a primitive) or it can be a reference (e.g. when evaluating a field request). Note that method requests are also in this category, since in Grace every method returns a value (`Done` by default).

#### Primitives

The primitive expressions are the easiest to evaluate, since they are always leaves of the syntax tree and correspond directly to classes in the object model. Therefore, evaluating a primitive expression requires no more than creating a new object of the correct type and placing it in the partial, as shown in the example.

```c++
void ExecutionEvaluator::evaluate(NumberLiteral &expression) {
    _partial = create_obj<GraceNumber>(expression.value());
}
```

#### ObjectConstructor Nodes

The evaluation of Object Constructor nodes requires some additional setup by the evaluator. The final objective is to have **a new object** in the partial, with the field and method values specified in the constructor. Since an `ObjectConstructor` node is a list of valid Grace `Statement` nodes, the easiest way to ensure that the new object has the correct contents is to evaluate each statement inside the constructor sequentially.

However, if no previous work is done, the results of those evaluations would be stored in the current scope of the evaluator, and not in the new object. Therefore, we must ensure that when evaluating the contents of the constructor, we are doing so in the scope of the new object. The following algorithm has been used to evaluate the `ObjectConstructor` nodes:

```c++
void ExecutionEvaluator::evaluate(ObjectConstructor &expression) {
	// Store the current scope to restore it later
    GraceObjectPtr oldScope = _currentScope;

    // Create the target object and set it as the current scope
    _currentScope = create_obj<UserObject>();

    // Evaluate every statement in the constructor in the context
    // of the new object
    for (auto node : expression.statements()) {
        node->accept(*this);
    }

    // Place the result on the partial
    _partial = _currentScope;

    // Restore the previous scope
    _currentScope = oldScope;
}
```

#### Implicit Requests

These are the most complex nodes to evaluate, since they can represent a number of intents. Said nodes can be either field requests or method calls (with or without parameters), and thus the evaluation has to include several checks to determine its behavior. 

However, Grace provides a useful invariant to design the evaluation of requests: All identifiers are unique within a scope or its outer scopes. As a consequence, for any given object, the sets of field and method identifiers **have to be disjoint**. Therefore, it does not make a difference the order in which we check whether a request is a field request or method call. In the case of Naylang, a decision was made to check whether a request was a field request first, and default to interpreting it as a method request if it wasn't.

Once a request is found to represent a **field request**, its evaluation becomes simple. `Request`s are expressions, and thus must place a value in the partial. `ImplicitRequest`s are requests made to the current scope, and thus it is sufficient to retrieve the value of the field in the current scope.

Evaluating a **method call** requires slightly more processing. First, the values of the effective parameters must be computed by evaluating their expression nodes. These values are then stored in a list that will ultimately be passed to the method object. After that, a request has to be made to the current scope to `dispatch()` the method named in the request, and the return value is stored in the partial. The dispatch and method evaluation mechanism is further discussed in [Methods and Dispatch](#methods-and-dispatch).

```c++
void ExecutionEvaluator::evaluate(ImplicitRequestNode &expression) {

	// Evaluate the node as a field request if possible
    if (expression.params().size() == 0) {
        if (_currentScope->hasField(expression.identifier())) {
            _partial = _currentScope->getField(
                expression.identifier());
            return;
        }
    }

    // Otherwise, evaluate it as a method call
    std::vector<GraceObjectPtr> paramValues;
    for (int i = 0; i < expression.params().size(); i++) {
        expression.params()[i]->accept(*this);
        paramValues.push_back(_partial);
    }

    _partial = _currentScope->dispatch(
        expression.identifier(), *this, paramValues);
}
```

#### Explicit Requests

They are similar to `ImplicitRequest`s, the only difference being that `ExplicitRequest`s can make requests to scopes other than the current one. An additional step must be added to compute the effective scope of the request (which was always `self` in the case of `ImplicitRequest`s). Then, the requests will be done to the newly retrieved object instead of the current scope.

```c++
void ExecutionEvaluator::evaluate(ExplicitRequestNode &expression) {
    expression.receiver()->accept(*this);
    auto receiver = _partial;

    // Note the use of "receiver" instead of _currentScope
    if (expression.params().size() == 0) {
        if (receiver->hasField(expression.identifier())) {
        	_partial = receiver->getField(
                expression.identifier());
            return;
        }
    }

    std::vector<GraceObjectPtr> paramValues;
    for (auto param : expression.params()) {
        param->accept(*this);
        paramValues.push_back(_partial);
    }
    _partial = receiver->dispatch(
        expression.identifier(), *this, paramValues);
}
```

This evaluation contains duplicate code that could certainly be refactorized, but it was left as-is in benefit of clarity by providing evaluation functions that are completely independent from each other.

#### Block Nodes

`Block` nodes are similar to `ObjectConstructor` nodes in that they place a new object with effectively arbitrary content in the partial. The only difference is that while `ObjectConstructor` nodes immediately evaluate every one of the statements, a `Block` node is inherently a lambda method definition, and thus the body of the method cannot be evaluated until all the effective parameters are known.

Therefore, the evaluation of a `Block` in Grace consists of forming an anonymous method with the contents of the `Block` node and creating a `GraceBlock` object with that method as its `apply()` method, to be evaluated whenever it is requested.

```c++
void ExecutionEvaluator::evaluate(Block &expression) {
    auto meth = make_meth(expression.params(), expression.body());
    _partial = create_obj<GraceBlock>(meth);
}
```

### Declaration Nodes

Declarations, from the EE's point of view, are nodes that add to the current scope in some way - be it adding new fields, or new methods. In general, very little processing is done in declarations and they do not modify the partial directly.

#### Field Declarations

Field Declarations are the nodes that, when processed, **insert a new field** with an initial value in the current scope. The processing of these nodes is quite simple, since they delegate the initial value processing to their respective children. After retrieving the initial value, evaluating them is a matter of extending the current scope to include the new field:

```c++
void ExecutionEvaluator::evaluate(VariableDeclaration &expression) {
	// If an explicit initial value is defined, initialize the 
	// variable to that. Otherwise, initialize it to an empty object.
    if (expression.value()) {
        expression.value()->accept(*this);
        _currentScope->setField(expression.name(), _partial);
    } else {
        _currentScope->setField(
            expression.name(), create_obj<UserObject>());
    }
}
```

Note that the evaluation of Field declarations assumes that the scope of the evaluator is the desired one at the time of evaluation.

#### Method Declarations

The evaluation of a `MethodDeclaration` has the aim of extending the method tables of the current scope to contain a new user-defined method. As it is the case with `Blocks`, the body of the `MethodDeclaration` will not be evaluated until a `Request` for it is encountered and effective parameters are provided. 

To evaluate a `MethodDeclaration`, a new `Method` has to be created with the formal parameters and body of the declaration, and it must be added to the current scope:

```c++
void ExecutionEvaluator::evaluate(MethodDeclaration &expression) {
    MethodPtr method = make_meth(expression.params(), expression.body());
    _currentScope->addMethod(expression.name(), method);
}
```

### Control Nodes

Control structures in Grace are identical in behavior to their C++ counterparts, which makes the evaluation of control nodes incredibly intuitive, by using the means natively available in the implementation language.

When evaluating a **conditional node** for example, the condition node is evaluated first. Then, if the condition returns `true`, the `then` statements are evaluated. If it is not met, the `else` statements will be evaluated if there are any (`IfThenElse` nodes), otherwise nothing will be done (`IfThen` nodes).

```c++
void ExecutionEvaluator::evaluate(IfThenElse &expression) {
    expression.condition()->accept(*this);
    auto cond = _partial->asBoolean().value();
    if (cond) {
        for (auto exp : expression.thenPart()) {
            exp->accept(*this);
        }
    } else {
        for (auto exp : expression.elsePart()) {
            exp->accept(*this);
        }
    }
}
```

Analogous implementation is necessary for the `While` nodes.

```c++
void ExecutionEvaluator::evaluate(While &expression) {
    expression.condition()->accept(*this);
    auto cond = _partial->asBoolean().value();
    while (cond) {
        for (auto exp : expression.body()) {
            exp->accept(*this);
        }

        // Re-evaluate condition
        expression.condition()->accept(*this);
        cond = _partial->asBoolean().value();
    }
}
```

Since the method scope management is implemented in the `Method` class, the only responsibility of the `Return` node is to serve as a stopping point (leaf) in the execution tree. Note that the value of the return node is an expression, and thus the return value will be implicitly stored in the partial when returning from this function.

```c++
void ExecutionEvaluator::evaluate(Return &expression) {
	expression.value()->accept(*this);
	return;
}
```

### Assigment

The aim of evaluating an `Assignment` node is to modify a field in the current scope to reference a new object. 

The first step in evaluating an Assignment node is to retrieve the new value we want the field to contain by evaluating the `value` branch of the node. The value branch is an expression, and thus the result of the call will ultimately be located in the partial. From there, we can retrieve it and assign it to the new field later.

An `Assignment` can be performed on a field of the curent scope or a field in any of the objects contained in the scope. Therefore, the second step in evaluating an `Assignment` node is to set the scope to the one where the target field is located, in a manner analogous to the evaluation of the `ObjectConstructors`. For this, it is necessary to evaluate the scope fields of the node, and set the scope to the resulting value. Note that they will always be requests, and almost always they will have the form of field request chains (e.g. `self.obj.x`).

Finally, the only remaining thing is to modify the desired field to hold the new value and restore the original scope.

```c++
void ExecutionEvaluator::evaluate(Assignment &expression) {
	// Calculate the desired value and save it
    expression.value()->accept(*this);
    auto val = _partial;

    // Calculate the target object and set the EE's scope
    auto oldScope = _currentScope;
    expression.scope()->accept(*this);
    _currentScope = _partial;

    // Modify the correct field to have the new value
    _currentScope->setField(expression.field(), val);

    // Restore the old scope
    _currentScope = oldScope;
}
```