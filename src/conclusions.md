
Conclusion
=======

Having reached the end of the development period for this project, it is necessary to review the results obtained and compare them with the proposed objectives.

This chapter explains the main challenges faced when implementing Naylang, a review of which goals were accomplished, which were not, and a brief summary of future work that would move the project forward.

Challenges
------

This section details the main roadblocks for the development of Naylang. Fortunately, many of these roadblocks were overcomed and served as a learning experience.

### Modern C++

The language chosen for this project was modern C++ (C++14). Having worked with previous versions of C++ (C++98) extensively before, it seemed that this language choice was the best one. However, the newer versions of C++ proved to be substantially different from the older ones, which introduced a great deal of additional difficulty to the development cycle as the new features had to be learned in parallel to implementing the code. Often, a wrong choice of feature (such as using owning pointers where shared pointers were due) meant that a substantial part of the codebase had to be rewritten or reaconditioned to use the new class.

As a result, more than half of this project's debugging time was spent wrestling with the new features instead of fixing actual bugs.

### Abstract Representation

The Grace specification offers very sparce information on the desired behavior of certain operations (such as the assignment operator), specially with regards to their structure and their place in the syntax. That being the case, forming a representation of the Abstract Syntax Tree required several iterations and a great deal of guesswork.

For instance, the first approach was to introduce arithmetic and logic operators explicitly to the abstract syntax, which had to later be discarded in favor of the current _request_-based approach.

Needless to say, these iterations proved to be very costly on development time, since rewriting the entire abstract representation is a simple but long process, specially when the tests had also to be rewritten.

### Requests and Method Dispatch Model

This issue ties with the previos one in that it results from the particularities of the Grace language. Since methods are part of objects and can contain either custom Grace code or native code, the closures and structure of method definitions and requests was difficult to implement. Luckily, extensive research of Kernan facilitated a starting point for the architecture, but it was nevertheless a long iterative process until a complete solution was found.

### Debugger Decoupling

The problem of integrating debugging mechanisms in Naylang _without_ modifying the core evaluation model led to some research on the field and, eventually, the Modular Visitor Pattern described earlier.

Goal review
------

Following is a review of the goals described in the introduction, detailing which ones were achieved, and which ones were not.

### Implementation Goals

Naylang set out to be an interpreter and debugger for a _subset_ of Grace, enough to teach the basic concepts of Computer Science to inexperienced students.

While it is indeed a fully-fledged debugger and it accepts a substantial subset of Grace, many important features of the language were left out (such as the type system), which limits what a novice can achieve with the language.

### Education Goals

The other key goal of Naylang was to be **approachable** to any student learning about language implementation or any future contributors to the project. In this objective Naylang has excelled, featuring extensive and descriptive test coverage that acts as documentation for the project, and great modularity in its components.

Future work
------

Even though the work done in Naylang was fairly satisfactory, there are still many areas that could be greatly improved with future work. The completion of these tasks would make Naylang a useful tool for Computer Science education.

### Modular Visitor

The Modular Visitor Pattern is probably the area that deserves the most attention in further developments, since it shows the potential to introduce **great flexibility** in the development of intepreters, and even new languages. If the potential it shows is fulfilled, even the development of custom 'à la carte' languages would become a much easier task, accomplished by recombining evaluation modules developed by different third parties.

### Language features

Many of the features of Grace were left unimplemented in Naylang. While Naylang will not strive for feature-completeness in Grace, it should implement some of its most important features for education, such as the class and type systems.

However, by not embedding these features directly into the core evaluation, the possibility arises to **use Naylang as a research project** for the viability of the Modular Visitor Pattern, as the new language features can be added using it.

### Web Frontend

One of the faults in Naylang's use in an educational setting is the **distribution of the executables** to target users. For novice programmers, the source compilation process and the unfriendly interface could result discouraging at first.

A possible solution to that problem would be to get rid of distributing executables altogether, and have a web-based interface to interact with Naylang from any browser. Some early work has been done with promising results, but due to time constraints the development of this interface was left out of the scope of the project.
