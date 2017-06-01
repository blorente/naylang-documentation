
The Grace Programming Language
==========

Introduction
------

Grace is an open source educational programming language, aimed to help the novice programmer understand the base concepts of Computer Science and Software Engineering [@gracepapersoftwareengineering]. To that aim, Grace is designed to provide an intuitive and extremely flexible syntax while maintaining the standards of commercial-grade programming languages [@gracedifficulty].

Key Features
------

Grace is aimed towards providing a solid introduction to the basic concepts of programming. Therefore, the following features are all designed to facilitate the use of Grace in an academic setting.

### Support for multiple teaching paradigms

Different teaching entities have different curricula when teaching novices. For instance, one institution might prefer to start with a declarative approach and focus on teaching students the basics of functional programming, while another one might want to start with a more imperative system.

Despite being imperative at it's core, Grace provides sufficient tools to teach any curriculum, since methods are intuitively named and can be easily composed. In addition to that, lambda calculus is embedded in the language, with every block being a lambda function and accept arguments [@gracefunctionalandimperative].

### Safety

Similar to other approachable high-level languages such as Python or JavaScript, Grace is garbage-collected, so that the novice programmer does not have to worry about manually managing object lifetimes. Furthermore, Grace has no mechanisms to directly manipulate memory, which provides a safe environment for beginners to learn.

### Gradual typing

Grace is gradually typed, which means that the programmer may choose the degree of type checking that is to be performed. This flexibility is atomic at the statement level, which means that any object or method declaration may or may not be typed. For instance, we might have all of the following in the same file:

```
var x := 5 // x is inferred to be a Number, a native type of Grace.
var y : Number := 6	// y is declared as a Number, a native type of Grace
var z : Rational := 7.0	// z is declared as a Rational, 
						// a user-defined type which may or may not 
						// inherit from Number
```

This mechanism brings instructors the tools necessary to teach types at the beginning of a course, leave them until the end, or explain them at the moment they deem appropriate.

However, this mechanism is not within the scope of the project and for the moment Naylang will only have a dynamic typing mechanism similar to JavaScript, as is explained later in this document.

### Object Model

Simirarly to other interpreted languages such as JavaScript or Ruby, everything is an object in Grace. A generic object can have constant or variable _fields_ that point to other objects, and methods that store user-defined or native subroutines. An object's fields are accessible to any subscope inside that object. Particularly they can be used and assigned to in methods.

```
object {
	def base = "Hi";
	var times := 4;
	def objField = object {
		def innerField = true;
	};
	method repeatBase {
		var i := 0;
		ver res := "";
		while {i < times} do {
			res := res ++ base;
			i := i + 1;
		}
		return res;
	}
}
```

Native types are implemented as objects with no fields and a series of predefined methods (such as the boolean "_or_", `||(_)`).

### Multi-part method signatures

Method signatures have a few particularities in Grace. Firstly, a method signature can have multiple **parts**. A **part** is a Unicode string followed by a formal parameter list. That way, methods with much more intuitive names can be formed:

```
// Declaration
method substringOf(str)from(first)to(last) {
    // Method body
}

// Request (call)
substringOf("Hello")from(2)to(5); // Would return "llo"
```

This way there is a more direct correlation between the mental model of the student and the code.

To differentiate between methods, Grace uses the **arity** of each of the parts to construct a _canonical name_ for the method. A canonical name is nothing more than the concatenation of each of the parts, substituting the parameter names with underscores. That way, the canonical name of the method above would be `substringFrom(_)to(_)`.

Two methods are different if and only if their canonical names are different. For example, `substringFrom(_)to(_)` is different from `substringFromto(_,_)`. As it is obvious, this mechanism imposes a **differentiation by arity**, and **not by parameter types**. Therefore, we could have this situation:

```
method substringOf(str)from(first : Rational)to(last : Rational) {
    // Code
}

method substringOf(str)from(first : Integer)to(last : Integer) {
    // Code
}
```

In this case, the second method's signature is considered to be **the same** as the first method's, and it will cause a _shadowing error_[^shadowing] for conflicting names. This design decision stems directly from the gradual typing, since there is no way to discern objects that are dynamically typed, and any object may be dynamically typed at any point. As a side effect, this method makes request dispatch considerably simpler, as is explained in [Methods and Dispatch](#methods-and-dispatch)

### Lexically scoped, single namespace

Grace has a single namespace for convenience, since novice projects will rarely be so large that they require separation of namespaces. It is also lexically scoped, so the declarations in a block are accessible to that scope and every scope inside it, but not to any outer scopes.

### Lineups

Collections in Grace are represented as Lineups, which are completely polymorphic lists of objects that implement the Iterable interface. As the spec says, the common trait of Lineups is that they implement the `Iterable` interface. In the case of Naylang, since no inheritance or type system is needed yet, no such interface has been implemented. Rather, the `GraceIterable` native type has been created.

### Object-based inheritance

Everything in Grace is an object. Therefore, the inheritance model is more based on extending existing objects instead of instantiating particular classes. In fact, classes in Grace are no more than factory methods that return an object with a predefined set of methods and fields.

Unfortunately, this mechanism is also **out of the scope of the project** and will be left for future releases.

Subset of Grace in a Page
------

As mentioned earlier, some features of the language will be left out of the interpreter for now, and therefore we must define the subset of the language that Naylang will be able to interpret. Following is an excerpt from the official documentation [@grace_in_one_page], which provides examples of the features of the language implemented in Naylang:

```
// Literals
4;
4 + 5; // Number literals and operators
true && false; // Boolean literals and operators
"Hello" ++ " World"; // String literals and operators
["a", 6, true]; // Lineups

// Declarations
var empty; // Uninitialized variable declaration
var x := true; // Initialized variable declaration
def y = 6; // Constant declaration
method add(a)to(b) { // Method declaration
	return a + b;
}

// Object constructor
def obj = object {
	var size := 3;
	def arity = 1;
	method sizeTimesArity {
		return size * arity;
	}
};

// Lambda blocks
def str = "Block";
{ j ->
	j.substringFrom(2)to(5);
}.apply(str);

// Control structures
var i := 0;
while {i < 20} { // While
	if (i % 2 == 0) then { // If-then-else structure
		print "even";
	} else {
		print "odd";
	}
    i := i + 1; // Assignment
}
```

[^shadowing]: http://gracelang.org/documents/grace-spec-0.7.0.html#declarations