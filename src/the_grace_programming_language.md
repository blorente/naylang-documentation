The Grace Programming Language
==========

Introduction
------

Grace is an open source educational programming language, aimed to help the novice programmer understand the base concepts of Computer Science and Software Engineering. To that aim, Grace is designed to provide an intuitive and extremely flexible syntax while maintaining the standards of commercial-grade programming languages.

Key Features
------

### Support for multiple teaching paradigms

Different teaching entities have different curricula when teaching novices. For instance, one institution might prefer to start with a declarative approach and focus on teaching students the basics of functional programming, while another one might want to start with a more imperative approach.

Despite being imperative at it's core, Grace provides sufficient tools to teach any curriculum, since methods are intuitively named and can be easily composed. In addition to that, lambda calculus is embedded in the language, with every block being a lambda function and accept arguments.

### Safety and flexibility

Similar to other approachable high-level languages such as Python or JavaScript, Grace is garbage-collected, so that the novice programmer does not have to worry about manually managing object lifetimes. Furthermore, Grace has no mechanisms to directly manipulate memory, which provides a safe environment for beginners to learn.

### Gradual typing

Grace is gradually typed, which means that the programmer may choose the degree of static typing that is to be performed. This flexibility is atomic at the statement level, and therefore any declaration may or may not be typed. For instance, we might have all of the following in the same code:

```
var x := 5              // x is inferred to be a Number, a native type of Grace
var y : Number := 6     // y is declared as a Number, a native type of Grace
var z : Rational := 7.0 // z is declared as a Rational, a user-defined type
                          // which may or may not inherit from Number
```

This mechanism brings to instructors the tools to teach types at the beginning of a course, leave them until the end, or explain them at the moment they deem appropriate.

However, this mechanism is not within the scope of the project, and for the moment Naylang will only have a dynamic typing mechanism, similar to JavaScript.

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

Everything in Grace is an object. Therefore, the inheritance model is more based on extending existing objects instead of instantiating particular classes. In fact, classes in Grace are no more than factory methods [@factory] that return an object with a predefined set of methods and fields.

Unfortunately, this mechanism is also out of the scope of the project and will be left for future releases.

Subset of Grace in a Page
------

As mentioned earlier, some features of the language will be left out of the interpreter for now, and therefore we must define the subset of the language that Naylang will be able to interpret. Following is an excerpt from the official documentation [@grace_in_one_page], which provides examples of the features of the language covered:

```
print "Hello World!"

// Comments & Layout
// comment to end of line

// Definitions and Variables
def one = 1 // constant
def two = 2 // constant with types

var y // variable, uninitialized
var x := 4 // variable, dynamically typed

//Literals
1 // Decimal number literals
true  // Boolean literals
"Hello World!"
"1 + 2 = {1 + 2}" // Strings with interpolation
{ j -> print(j)} // Blocks (Lambdas) with parameters
[1, "two", true] // Lineups (Totally polymorphic collections)

// Requests
self // self request
x // implicit receiver named request, no arguments (reads variables and constants)
print "Hello world" // implicit receiver named request
"Hello".size // explicit name request
"abcdefghi".substringFrom(3)to(6) // multipart request
1 + 2 * 3 // operators
!false // unary prefix operatiors!   Can't do that in Smalltalk.
"ab" ++ "cd" // string concatenation is ++
(true || false) && true // only precedence for + - * /
x := 22 // assignment request
{ j -> print(j)}.apply("Hello");


// Control Structures
if (x == 22) then {print "YES"}              // if statements
  elseif {x == 23} then {print "Maybe"}
  else {print "...nope..."}

for (2 .. 4) do { j -> print(j) } // ".." makes a range from Numbers

x := 10
while {x < 20} do { // note need a {block} here
  print(x)
  x:= x + 3
}

// Switching & Matching
match (x) // Switch or Case statement
  case { 0 -> print "zero" }   // literals
  case { n : Number -> print "Number {n}" }  // type matches
  case { s : String -> print "String {s}" }
  case { _ -> print "who knows?" }     // catch all


// Methods
// Grace methods can be at the "top level"
method pi {3.141592634} //simple method
method + (other) { other + self } // binary operator
method prefix- {print "bing!"} //prefix unary operator
method from(n) steps(s) { //multiple names
  print "from {n} steps {s}"
  return s
}

// Objects
def fergus = object {  //make a new object
  def colour is readable = "Tabby"
  def name is readable = "Fergus"
  var miceEaten := 0
  method eatMouse {miceEaten := miceEaten + 1}
  method miaow {print "{name}({colour}) has eaten {miceEaten} mice"}
}

fergus.eatMouse
fergus.miaow
```
