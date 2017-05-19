The Grace Programming Language
==========

Introduction
------

Grace is an open source educational programming language, aimed to help the novice programmer understand the base concepts of Computer Science and Software Engineering [@gracepapersoftwareengineering]. To that aim, Grace is designed to provide an intuitive and extremely flexible syntax while maintaining the standards of commercial-grade programming languages [@gracespec].

Key Features
------

Grace is aimed towards providing a solid introductions to the basic concepts of programming. Therefore, the following features are all designed to facilitate the use of Grace in an academic setting.

### Support for multiple teaching paradigms

Different teaching entities have different curricula when teaching novices. For instance, one institution might prefer to start with a declarative approach and focus on teaching students the basics of functional programming, while another one might want to start with a more imperative approach.

Despite being imperative at it's core, Grace provides sufficient tools to teach any curriculum, since methods are intuitively named and can be easily composed. In addition to that, lambda calculus is embedded in the language, with every block being a lambda function and accept arguments [@gracefunctionalandimperative].

### Safety

Similar to other approachable high-level languages such as Python or JavaScript, Grace is garbage-collected, so that the novice programmer does not have to worry about manually managing object lifetimes. Furthermore, Grace has no mechanisms to directly manipulate memory, which provides a safe environment for beginners to learn.

### Gradual typing

Grace is gradually typed, which means that the programmer may choose the degree of type checking that is to be performed. This flexibility is atomic at the statement level, which means that any declaration may or may not be typed. For instance, we might have all of the following in the same code:

```
var x := 5              // x is inferred to be a Number, a native type of Grace
var y : Number := 6     // y is declared as a Number, a native type of Grace
var z : Rational := 7.0 // z is declared as a Rational, a user-defined type
                          // which may or may not inherit from Number
```

This mechanism brings to instructors the tools to teach types at the beginning of a course, leave them until the end, or explain them at the moment they deem appropriate.

However, this mechanism is not within the scope of the project and for the moment Naylang will only have a dynamic typing mechanism similar to JavaScript, as is explained in [Object Model](Object Model)

### Multi-part method signatures

Method signatures have a few particularities in Grace. Firstly, a method signature can have multiple parts. A part is a Unicode string followed by a parameter list. That way, methods with much more intuitive names can be formed:

```
method substringFrom(first)to(last) {
    // Return a substring of the caller object from index "first" to index "last"
}
"hello".substringFrom(2)to(4) // Would return "llo"
```

This way there is a more direct correlation between the mental model of the student and the code.

To differentiate between methods, Grace uses the arity of each of the parts to construct a _canonical name_ for the method. A canonical name is not more than the concatenation of each of the parts, substituting the parameter names for underscores. That way, the canonical name of the method above would be `substringFrom(_)to(_)`.

Two methods are different if and only if their canonical names are different. For example, `substringFrom(_)to(_)` is different from `substringFromto(_,_)`. As it is obvious, this mechanism imposes a differentiation by arity, and not by parameter types. Therefore, we could have this situation:

```
method substringFrom(first : Rational)to(last : Rational) {
    // Code
}

method substringFrom(first : Integer)to(last : Integer) {
    // Code
}
```

In this case, the second method is considered to be the same as the first, and it will cause a _shadowing error_ for conflicting names. This design decision stems directly from the gradual typing, since there is no way to discern objects that are dynamically typed, and any object may be dynamically typed at any point. As a side effect, this method makes request dispatch considerably simpler.

### Lexically scoped, single namespace

Grace has a single namespace for convenience, since novice projects will rarely be so large that they require separation of namespaces. It is also lexically scoped, so the declarations in a block are accessible to that scope and every scope inside it, but not to any outer scopes.

### Lineups

Collections in Grace are represented as Lineups, which are completely polymorphic lists of objects that implement the Iterable interface.

### Object-based inheritance

Everything in Grace is an object. Therefore, the inheritance model is more based on extending existing objects instead of instantiating particular classes. In fact, classes in Grace are no more than factory methods that return an object with a predefined set of methods and fields.

Unfortunately, this mechanism is also out of the scope of the project and will be left for future releases.

Subset of Grace in a Page
------

As mentioned earlier, some features of the language will be left out of the interpreter for now, and therefore we must define the subset of the language that Naylang will be able to interpret. Following is an excerpt from the official documentation [@grace_in_one_page], which provides examples of the features of the language covered:

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
