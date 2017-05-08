Methods and Dispatch
------

One of the advantages of Grace is that it integrates native methods and user-defined methods seamlessly in it's syntax. As a consequence, the implementation must be able to handle both types of methods indistinctly from each other. Hence, the `Method` class was created. This class represents a container for everything that is needed to define a Grace method, namely, a list of **formal parameters** in the form of **declarations**, and a list of **statements** that conforms the **body** of the method. The canonical name of a method is used in determining which of an object's methods to use, and not in the execution of the method itself. Hence, it is not necessary to include it in the representation. Since Grace blocks are lambda expressions, it is also possible to instantiate a `Method` from a `Block`:

```c++
class Method {
  std::vector<DeclarationPtr> _params;
  std::vector<StatementPtr> _code;
public:
  Method(BlockPtr code);
  Method(const std::vector<DeclarationPtr> &params, const std::vector<StatementPtr> &body);
  // ...
};
```

### Dispatch

Since every method has to belong to an object, the best way to implement dispatch is to have objects dispatch their own methods. Since user-defined methods contain their code in the AST representation, an object needs an evaluator to evaluate the code, and thus it must be passed as a parameter. In addition, the **effective parameter** values must be precalculated and passed as Grace object, not AST nodes:

```c++
virtual GraceObjectPtr dispatch(
  const std::string &methodName,
  ExecutionEvaluator &eval,
  const std::vector<GraceObjectPtr> &paramValues);
```

The object then retrieves the correct `Method`, forms a `MethodRequest` with the parameters, and calls `respond()` on the desired method, returning the value if applicable.

### Self-evaluation

The only responsibility of `Method`s is to be able to `respond()` to requests made by objects. A `MethodRequest` is in charge of holding the **effective parameters** for that particular method call.

```c++
virtual GraceObjectPtr respond(
  ExecutionEvaluator &context,
  GraceObject &self,
  MethodRequest &request);
```

How this method is implemented is up to each subclass of `Method`. Native methods, for example, will contain C++ code that emulates the desired behavior of the subprogram. `Method` counts with a default implementation of `respond()`, which is used for user-defined methods, and uses the given context to evaluate every line of the method body:

```c++
GraceObjectPtr Method::respond(
  ExecutionEvaluator &context, GraceObject &self, MethodRequest &request) {

    // Create the scope where the parameters are to be instantiated
    GraceObjectPtr closure = make_obj<GraceClosure>();

    // Instantiate every parameter in the closure
    for (int i = 0; i < request.params().size(); i++) {
        closure->setField(params()[i]->name(), request.params()[i]);
    }

    // Set the closure as the new scope, with the old scope as a parent
    GraceObjectPtr oldScope = context.currentScope();
    context.setScope(closure);

    // Evaluate every node of the method body
    for (auto node : _code) {
        node->accept(context);
    }

    // Get return value (if any)
    GraceObjectPtr ret = context.partial();
    if (ret == closure) {
        // The return value hasen't changed. Return Done.
        ret = make_obj<GraceDoneDef>();
    }

    // Restore the old scope
    context.setScope(oldScope);
    return ret;
}
```

### Native methods

Native methods are a special case of `Method`s in that they are implemented using native C++ code. Most of these operations correspond to the operations necessary to handle native types (such as the `+` operator for numbers). Native methods do not require a context to be evaluated, and therefore they define a simpler interface for the subclasses to use, for conveniance.

```c++
class NativeMethod : public Method {
public:
  // Pure abstract method to be implemented by subclasses
  virtual GraceObjectPtr respond(
    GraceObject &self, MethodRequest &request) = 0;

  // Note that subclasses can still override this implementation
  virtual GraceObjectPtr respond(
    ExecutionEvaluator &context, GraceObject &self, MethodRequest &request) {
    return respond(self, request);
  }
};
```

Each native method is a subclass of `NativeMethod`, and implements it's functionality in the body of the overriden `respond()` method. For convenience, each subclass of GraceObject that implements native types defines them inside it's header, as inner classes. This is specially useful when a method requires access to the internal structure of an object, since inner classes have access to them by default.