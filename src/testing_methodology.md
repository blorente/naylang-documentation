Testing Methodology
=======

Testing and automated validation were important parts of the development of Naylang. Even though Grace had a complete specification, some of the general design approaches were not clear from the beginning, as is mentioned in the discussion about the [Abstract Syntax Tree](Abstract-Syntax-Tree). Therefore, there was a high probability that some or all parts of the system would have to be redesigned, which was what in fact ended up occurring. To mitigate the risk of these changes, the decision was made to have automatic unit testing with all the parts of the system that could be subject to change, so as to receive exact feedback about which parts of the system were affected by any change.

This decision has in fact proven to be of great value in the later stages of the project, since it makes a thousand-line project manageable.

Tests as an educational resource
------

Naylang aims to be more than just a Grace interpreter, but to also be an approachable FOSS [@freeopensourcesoftware] project for both potential collaborators and programming language students the same. Having a sufficiently big automated test suite is vital to make the project amiable to newcomers, for the following reasons:

- Automated tests provide **complete, synchronized documentation** of the system. Unlike written documentation or comments, automated tests do not get outdated and, if they are sufficiently atomic and well-named, provide working **specification and examples** of what a part of the system does and is supposed to be used. A newcomer to the project will find it very useful to dive into the test suite even before looking at the implementation code to find up-to-date explainations of a module and it's dependencies.

- Automated tests force the implementer to **modularize**. Unit testing requires that the dependencies of the project be minimized, so as to make testing each part individually as easy as possible. Therefore, TDD encourages a very decoupled design, which makes it easy to reason about each part separately [@modularisbetterforlearning].

- Automated tests make it **easy to make changes**. When a student or potential collaborator is planning to make changes, it can be daunting to modify any of the existing source code, in fear of a functionality regression. Automated tests aid with that, and encourage the programmer to make changes by reassuring the sense that any undesired changes in functionality will be immediately reported, and the amount of hidden bugs created will be minimal.

As an example, if newcomers wanted learn about how Naylang handles Assignment, they can just dive into the `Assignment_test.cpp` file to see how the Assignment class is initialized, or search for usages of the Assignment class in the `ExecutionEvaluator_test.cpp` file to see how it's consumed and evaluated, or even search it in `NaylangParserVisitor_test.cpp` to see how it's parsed. Then, if they wanted to extend Assignment to enforce some type checking, they could write their own test cases and add them to the aforementioned files, which would guide them in the parts of the system that have to be modified to add that capability, and notify them when they break some functionality.

Test-Driven Development (TDD)
------

Since the goal was to cover as much code as possible with test cases, the industry-standard practice of Test-Driven Development was used. According to TDD, for each new addition to the codebase, a failing test case must be added first. Then, enough code is written to pass the test case. Lastly, the code is refactored to meet coding standards, all the while keeping all the tests passing. This way, every part of code 

TDD may feel slow at first, but as the end of the project approached the critical parts of the project were covered in test cases, which provided with immense agility to develop extraneous features such as the frontends. 

As a result of following the TDD discipline, the length of the test code is very similar to that of the implementation code, a common occurrence in projects following this practice [@kethbecktddpractice].

The Framework
------

Naylang is a relatively small (less than 10.000 lines of code), threadless and lightweight project. Therefore, the testing framework choice was influenced mainly in favor of ease-of-use, instead of other features such as robustness or efficiency. With that end in mind, Catch [@catchcpp] presented itself as the perfect choice for the task, for the following reasons:

- **Catch is header only**, and therefore including it in the build system and Continuous Integration was as trivial as adding the header file to every test file.

- **Catch allows for test suites**, by providing two levels of separation (`TEST_CASE()` and `SECTION()`). This way, the test file for a particular component of the system (e.g. `GraceNumber_test.cpp`) usually contains a single `TEST_CASE()` comprised of several `SECTION()`s. That way, it's easy to identify the exact point of failure of a test. Some of the bigger files have more than one test case, where required (e.g. `NaylangParserVisitor_test.cpp`).

- **Allows for exception-assertions** (named `REQUEST_THROWS()` and `REQUEST_THROWS_WITH()`), in addition to regular truthy assertions (named `REQUEST()`). For a language interpreter, many of the runtime errors occur when the language user inputs an invalid statement, and therefore are out of the hands of the implementor. It is imperative to provide graceful error handling to as many of these faults as possible, and therefore it is also necessary to test them. This exception-assertions provide the tools to test the runtime errors correctly.

- **Test cases are debuggable**, meaning that, since all Catch constructs are macros, the content of test cases themselves is easily debuggable with most industrial-grade debuggers, namely GDB. The project takes advantage of this feature by writing a failing test case every time a bug is found by manual testing. This way **as many debug passes as needed** can be done **without having to reproduce the bug** by hand each time, which considerably reduces debugging time.

Note that, from this point forward, `TEST_CASE()` refers to a construct in the framework, while "test case" refers to a logical set of one or more assertions about the code, which will usually be included inside a `SECTION()`.

Testing the Abstract Syntax Tree
------

The Abstract Syntax Tree was the first thing implemented, and thus it was the component where most of the up-front decisions about the testing methodology were made. Luckily, the nodes themselves are little more than information containers, and thus their testing is straightforward, with most of the test files following a similar pattern. A typical test file for a node contains a single test case with the name of the node, and several sections divided in two categories: 

- **Constructor tests** provide examples and descriptions of what data a node expects to receive and in what order.

- **Accessor tests** indicating what data can be accessed of each node type, and how.

Following is one of the more complicated examples:

```c++
TEST_CASE("ImplicitRequestNode Expressions", "[Requests]") {

	// Initialization common to all sections
    auto five = make_node<NumberLiteral>(5.0);
    auto xDecl = make_node<VariableDeclaration>("x");

    // Constructor sections
    SECTION("A ImplicitRequestNode has a target identifier name, parameter expressions and no reciever") {
        REQUIRE_NOTHROW(ImplicitRequestNode req("myMethod", {five}););
    }

    SECTION("An ImplicitRequestNode with an empty parameter list can request variable values or parametereless methods") {
        REQUIRE_NOTHROW(ImplicitRequestNode variableReq("x"););
        REQUIRE_NOTHROW(ImplicitRequestNode methodReq("myMethod"););
    }

    // Accessor sections
    SECTION("A ImplicitRequestNode can return the identifier name and parameter expressions") {
        ImplicitRequestNode req("myMethod", {five});
        REQUIRE(req.identifier() == "myMethod");
        REQUIRE(req.params() == std::vector<ExpressionPtr>{five});
    }
}
```

As mentioned above, the nodes do not have any internal logic to speak of, and are little more than data objects [@dataobjectpattern]. Therefore, these two types of tests are sufficient.

Testing the Evaluation
------

The evaluator was one of the more complicated parts of the system to test, since it's closely tied to both the object model and the abstract representation of the language. In addition to that, it is very useful to be able to make assertions about the internal state of the evaluator after evaluating a node, which goes against the standard practice of testing an object's interface, and not it's internal state. This problem required an extension of the Evaluator to be able to make queries about and modify it's internal state (namely, the current scope and the partial result), which later proved useful when implementing user-defined method evaluation.

The test structure of the evaluator is probably one of the lengthiest ones in the project, since the evaluation of every node has to be tested, and some nodes need more than one test case such as Requests, which can be either field or method requests. Therefore, the evaluator test file contains several test cases:

- **Particular Nodes** tests the evaluation of every node in the AST, with at least a section for each node class.

- **Environment** tests the scope changes and object creation of the evaluator. 

- **Native Methods** and **Non-Native Methods** test the evaluation of methods by creating a placeholder object and requesting a method from it.


Testing the Objects
-----

Test files for object classes have two `TEST_CASE()`s defined in them, since objects have two responsibilities: To hold the relevant data of that type (e.g. a boolean value for GraceBoolean) and to implement the required native methods. Thus, a `TEST_CASE()` was defined for each of these responsibilites. Since native methods are defined as internal classes to the objects, it is natural to test them in the same file as the object.

```c++
TEST_CASE("Grace Boolean", "[GraceObjects]") {
    GraceBoolean bul(true);

    SECTION("A GraceBoolean can return it's raw boolean value") {
        REQUIRE(bul.value());
    }
    
    // ...
}

TEST_CASE("Predefined methods in GraceBoolean", "[GraceBoolean]") {

    SECTION("Not") {
        MethodRequest req("not");
        GraceBoolean::Not method;

        SECTION("Calling Not with self == GraceTrue returns GraceFalse") {
            GraceObjectPtr val = method.respond(*GraceTrue, req);
            REQUIRE(*GraceFalse == *val);
        }

        SECTION("Calling Not with self == GraceFalse returns GraceTrue") {
            GraceObjectPtr val = method.respond(*GraceFalse, req);
            REQUIRE(*GraceTrue == *val);
        }
    }

    // ...
}
```

Testing the Naylang Parser Visitor
------

The testing methodology for the parser was standardized rather quickly, with the aim of making writing additional tests as quick as possible. The job of the parser is to translate strings into AST nodes, so every test has a similar structure:

1. Form the input string as the valid Grace statement under test (e.g. `"var x := 3;"`).

2. Perform all the steps necessary to feed the input string into the parser. Since this process in ANTLRv4 is rather verbose and repetitive, it has been factored out into a function:

```c++
	GraceAST translate(std::string line) {
	    ANTLRInputStream stream(line);
	    GraceLexer lexer(&stream);
	    CommonTokenStream tokens(&lexer);
	    GraceParser parser(&tokens);
	    NaylangParserVisitor parserVisitor;

	    auto program = parser.program();
	    parserVisitor.visit(program);

	    auto AST = parserVisitor.AST();
	    return AST;
	}
```

3. Retrieve the AST resulting from the parsing process (e.g. `auto AST = translate("var x := 3;");`).

4. Use static casts [@staticcast] and assertions to validate the structure of the tree.

```c++
// Full example test case

SECTION("Assignments can have multiple requests and an identifier") {
	// Translation
    auto AST = translate("obj.val.x := 4;\n");

    // Conversion
    auto assign = static_cast<Assignment &>(*(AST[0]));
    auto scope = static_cast<ExplicitRequestNode &>(*assign.scope());
    auto obj = static_cast<ImplicitRequestNode &>(*scope.receiver());
    auto val = static_cast<NumberLiteral &>(*assign.value());

    // Validation
    REQUIRE(assign.field() == "x");
    REQUIRE(scope.identifier() == "val");
    REQUIRE(obj.identifier() == "obj");
    REQUIRE(val.value() == 4.0);
}
```

All of the test cases follow a similar structure, and are grouped in logical `TEST_CASE()`s, such as "Control Structures" or "Assignment". 

Integration testing
------

To test whether particular features of the language fit inside the grand scope of the project, a series of integration tests were developed. These tests are comprised of Grace source files, which for the moment have to be run by hand from the interpreter. The files are located in the `/examples` folder, and each of them is designed to test the full pipeline of a particular feature of the language, from parsing to AST construction and evaluation. For example, `Conditionals.grace` tests the `if () then {}` and `if () then {} else {}` constructs, while `Debugger.grace` is aimed to provide a good test case for the debugging mechanism.

Testing Frontends
------

Naylang does not feature any unit tests for the frontends, for several reasons. On the one hand, the frontends are not part of the core evaluation and debugging system, and thus are not as important for the prospect student to learn from. On the other hand, the frontends feature some of the shortest and most industry-standard code of the project, and thus it's design is deemed straightforward enough to not grant their inclusion in the test suite.

However, as more and more complicated frontends are added to the project, the possibility of including them in the test suite will be reconsidered.
