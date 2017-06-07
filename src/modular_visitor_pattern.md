
Modular Visitor Pattern
=======

During the development of the Naylang debugger, the need arised to integrate it with the existing architecture. Specifically, it was important to take advantage of the existing evaluation behavior and build the debugging mechanism _on top of it_, thus avoiding the need to reimplement the evaluation of particular AST nodes just so that the debugging behavior could be embedded mid-processing. This left two possibilities: Either the evaluator was modified to include the debugging behavior, or the debugging behavior was specified elsewhere, and then somehow tied with the evaluator.

Even though the first possibility is much easier to implement, it had serious drawbacks affecting the maintainability and extensibility of the evaluation engine. Since the debugging and evaluation behavior would be intermixed, any time a change had to be made to either part, extensive testing would be required to ensure that the other engine did not suffer a regression. Even with these drawbacks this was the first approach taken when implementing Naylang, with the intention of factoring out the debugger behavior later on. When the core debugger behavior was implemented, the factoring process started.

During the factoring process, a new programming pattern arised. This new pattern allowed for the development of completely separate processing engines, each with its own set of behaviors, that could be composed to create more powerful engines. After some experimentation, this pattern yielded great results for implementing the Naylang debugger, and showed promising potential for implementing further features of the language.

Description
-------

This pattern takes advantage of the very structure of Visitor-based interpreters. In this model of computation, every node in the AST has an `Evaluator` method associated with it, which provides implicit entry and exit points to the processing of every node. This gives the class that calls these methods total control over the execution of the tree traversal. Up to this point, this caller class was the evaluator itself.

However, the key to this technique is to take advantage of the intervention points and the extra control over the execution flow and insert arbitrary code in those locations. This code pieces could potentially do anything, from pausing the normal evaluation flow (e.g. in a debugger) to modifying the AST itself, potentially allowing for any new feature to be developed.

This pattern is most comfortably used with classes that implement the same methods as the original class, since that will provide with a common and seamless interface with the rest of the system.

The following sections explain different variations in the pattern, and provide examples based on how Naylang would implement the debugging mechanism with each of the variations.

### Direct Subclass Modularity

The most straightforward way to implement a Modular Visitor is to directly subclass the class that needs to be extended. This way, the old class can be replaced with the new subclass in the parts of the system that need that functionality with minimal influence in the rest of the codebase [@liskov1994behavioral].

By directly subclassing the desired visitor, the implementer only needs to override the parts of the superclass that need code injected, and it can embed the normal execution flow of the application by calling the superclass methods.

Figure 6.1 demonstrates the use of this specific technique. In this case, the instantiation of the visitors would be as follows:

```
proc createExtensionVisitor() {
	return new ExtensionVisitor();
}
```

![Direct Subclass Modular Visitor Pattern](images/mod_direct.pdf)

#### Example

In Naylang, this would translate to creating a direct subclass of `ExecutionEvaluator`, called `DebugEvaluator`. As is described in [Debugging](#debugging), the aim of this class is to maintain and handle the current debug state of the evaluation (`STOP`, `RUN`...), and to maintain breakpoints.

Assuming the previous mechanisms are in place to handle state, the only capability required from the debugger is to be able to **block the evaluation** of the AST at the points where it is required (e.g. by a breakpoint). As previously described this can only happen in _stoppable_ nodes, and therefore only the processing of those nodes need to be modified. For this example, assume that only `VariableDeclaration` and `ConstantDeclaration` nodes are stoppable, and that we need to add processing **both at the beginning and at the end** of the node evaluation to handle changing debug states.

To implement this, it is sufficient to override the methods that process those nodes, and to insert the calls to the debug state handlers before and after the call to the parent class. Every other processing would follow its flow as normal.

```c++
class DebugEvaluator : public ExecutionEvaluator {
	DebugState _state;

public:
	// Override the desired function
	virtual evaluate(VariableDeclaration &expression) override;
}

void DebugEvaluator::evaluate(VariableDeclaration &expression) {
	// Call to the debug mechanism
	beginDebug(expression);
	// Call superclass to handle regular evaluation
	ExecutionEvaluator::evaluate(expression);
	// Call to the debug mechanism
	endDebug(expression);
}
```

#### Discussion

This version of the pattern is the most straightforward to implement, and has minimal impact in how the visitors are used and instantiated. However, it is the version that most limits the modularity of the evaluation system since as more visitors get added to the class hierarchy the inheritance tree deepens considerably. This oftern will result in an unmaintainable class hierarchy with very little flexibility.

### Composite Modularity

As a way of solving the rigidity issues posed by the previous version of the pattern, this second version transforms the pattern to use _composition instead of inheritance_, as it is usually preferred by the industry [@compositionoverinheritance].

In this technique, what previously was a subclass of the extended class is now at the same level in the class hierarchy. Instead of calling the superclass to access the implementation of the main visitor, the extender class _holds a reference_ to the main class and uses it to call the desired evaluation methods.

Obviously, since the main visitor is not being extended anymore, **all of the methods** it implements will have to be overriden from the extender class to include _at least_ calls to the main evaluator.

Figure 6.2 demonstrates an implementation of this pattern. In this case, the instantiation of the extension is as follows:

```
proc createExtensionVisitor() {
	super := new MainVisitor();
	return new ExtensionVisitor(super);
}
```

![Composite Modular Visitor Patern](images/mod_composite.pdf)

#### Example

There is little to be changed from the previous example in terms of code. The only necessary changes are to adapt the class declaration of `DebugEvaluator` to hold an instance of `ExecutionEvaluator` instead of inheriting from it, and to change the call to the superclass inside the evaluation methods. All of the methods implemented by `ExecutionEvaluator` must be overriden by `DebugEvaluator`, to include at least calls to `ExecutionEvaluator`.

Lastly, `DebugEvaluator` needs to have some way of obtaining a reference to a valid `ExecutionEvaluator` instance, be it by receiving it in the constructor or by creating an instance itself at startup.

```c++
class DebugEvaluator : public Evaluator {
	DebugState _state;
	// Note that it will accept any subclass of Evaluator
	Evaluator *_super;

public:
	// Obtain a reference to the desired evaluator
	DebugEvaluator(Evaluator *super);
	// Override from Evaluator this time.
	virtual evaluate(VariableDeclaration &expression) override;
	virtual evaluate(NumberLiteral &expression) override;
	// ...
}

void DebugEvaluator::evaluate(VariableDeclaration &expression) {
	// Call to the debug mechanism
	beginDebug(expression);
	// Call ExecutionEvaluator to handle regular evaluation
	_super->evaluate(expression);
	// Call to the debug mechanism
	endDebug(expression);
}

void DebugEvaluator::evaluate(NumberLiteral &expression) {
	// Only need to call the normal evaluation
	_super->evaluate(expression);
}
```


#### Discussion

The Composite Modularity method simplifies greatly the class hierarchy by moving the composition of visitors from the subclassing mechanism to runtime instantiation, creating wider, more shallow class hierarchies. However, this also means that the desired composition of visitors must be explicitly instantiated and passed to their respective constructors (e.g. via _factory methods_ [@compositionoverinheritance]).

This problem can be circunvented by having the extender class explicitly create the instances of the visitors it nedds directly into its constructor. This can be a solution in some cases, but implementors must be aware of the tradeoff in flexibility that it poses, since then the extender is bound to have only one possible class to call.

Lastly, another great drawback of this technique is that it forces the extender class to implement at least the same methods as the main visitor implemented, to include calls to that. This might not be desirable in extensions that only require one or two methods to be modified from the main class.

### Wrapper Superclass Modularity

This final version of the Modular Visitor Pattern tries to solve some of the issues with the previous two implementations, while having minimal tradeoffs. Specifically, it aims to provide a system that:

- Is flexible enough to allow for a shallow inheritance tree and composability, and
- Only requires a visitor extension to override the methods that it needs to override, and not be conditioned by the class it is extending.

One way to accomplish these goals is to define an intermediate layer of inheritance in the class hierarchy such that all the default calls to the main visitor are implemented in a superclass, and only the relevant functionality is implemented in a subclass. Roughly speaking, it consists on **grouping together** extensions that need to interject the execution at similar times, and **moving all the non-specific code to a superclass**. This way, it is the superclass that has the responsibility of handling the main evaluator instance.

Figure 6.3 demonstrates an implementation of this pattern. In this case, the instantiation of the extension is as follows:

```
proc createExtensionVisitor() {
	super := new MainVisitor();
	return new ExtensionVisitorA(super);
}
```

![Wrapper Superclass Modular Pattern](images/mod_group.pdf)

#### Example

Following the previous example, it is possible to define a superclass that bundles the behavior of "executing code before and after evaluating a node". Let us call that class `BeforeAfterEvaluator`. This class has the responsibility of implementing calls to the regular evaluation and providing interfaces for the `before()` and `after()` operations.

```c++
class BeforeAfterEvaluator : public Evaluator {
protected:
	Evaluator *_super;

public:
	BeforeAfterEvaluator(Evaluator *super);

	virtual evaluate(VariableDeclaration &expression) override {
		before(&expression);
		_super->evaluate(expression);
		after(&expression);
	}
	// ...
	virtual void before(Statement *stat) = 0;
	virtual void after(Statement *stat) = 0;
}
```

Having done that, we can transform `DebugEvaluator` to be a subclass of `BeforeAfterEvaluator`, and thus inherit the regular calls to the main evaluator. We can then override the processing of `VariableDeclarations` to include calls to `before()` and `after()`, and implement those methods to include the debugging behavior:

```c++
class DebugEvaluator : public BeforeAfterEvaluator {
	DebugState _state;

public:
	// Override the desired function
	virtual void before() override;
	virtual void after() override;

	virtual evaluate(VariableDeclaration &expression) override;
}

void DebugEvaluator::evaluate(VariableDeclaration &expression) {
	before(&expression);
	_super->evaluate(expression);
	after(&expression);
}
```


#### Discussion

This is by far the most flexible method, and the one that offers the best tradeoff in terms of ease-of-use and flexibility. However, it requires a great amount of setup effort in order to make it easy to add new subclasses, and therefore it is only worth it for projects that plan to use visitor composition extensively.

Applications
-------

This visitor design pattern has a myriad of applications. The main benefit is that it allows to extend the functionality of an intepreting engine without needing to change the previous processings. It permits the addition of both semantic power to the language (e.g. by creating a type checking extension, or an importing system) and extralinguistic tools (such as the debugging mechanism) with minimal risk to the existing processing core of the language.

**Further investigation is necessary**, but this technique could lead to a way of **incrementally designing a language**, wherein a language implementation could grow incrementally and iteratively in parallel to its design and specification, safely. It is not hard to imagine the benefits of having the most atomic parts of a language implemented first, and more visitor extensions are added as more complex features are introduced to the language.

As mentioned previously, this idea of a fully modular language has been developed in several academic works where the use of monads was suggested [@jlsthesis]. This approach, when applied specifically to Visitor-based interpreters, allows similar levels of flexibility while maintaining the approachability that a design pattern requires.
