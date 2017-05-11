\newpage

Object Model
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
};
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
};
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
};
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
casting themselves into other types. Namely, we want the possiblity to,
for any given object, retrieve it as a native type at runtime. This is
accomplished via virtual methods in the base class, **which error by default**:

```c++
// GraceObject.h

// Each of these methods will throw a type exception called
virtual const GraceBoolean &asBoolean() const;
virtual const GraceNumber &asNumber() const;
virtual const GraceString &asString() const;
// ...
```

These functions are then overriden with a valid implementation in the subclasses that can return the appropriate value. For example, `GraceNumber` will provide an implementation for `asNumber()` so that when the evaluation expects a number from a generic object, it can be given. Of course, for types with just **one possible member in their classes** (such as `Done`) and objects that **do not need more data** than the base `GraceObject` provides (such as `UserObject`), no caster method is needed, and a boolean type checker method is sufficient. These methods return false in `GraceObject`, and are overriden to return true in the appropriate classes:

```c++
// GraceObject.h

// These methods return false by default
virtual bool isNumber() const;
virtual bool isClosure() const;
virtual bool isBlock() const;
// ...
```

This approach has two major benefits:

- It allows the evaluator to treat every object equally, except where a specific cast is necessary, such as the result of evaluating condition expression of an `if` statement, which must be a `GraceBoolean`. Therefore, the type checking is completely detached from the AST and, to an extent, the evaluator. The evaluator only has to worry about types when the language invarints require so.

- It scales very well. For instance, if a new native type arised that could be either a boolean or a number, it would be sufficient to implement both caster methods in an appropriate subclass.

Note that this model is used for runtime dynamic typing and, since Grace is a gradually-typed language, some of the type-checking work will have to be moved the the AST as the possibility of proper static typing is implemented.
