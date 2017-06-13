
Introduction
============

Naylang is an open source REPL interpreter [@abelson1996structure], runtime and debugger for the Grace programming language implemented in C++14.

It currently implements a subset of Grace described later, but as both the language and the interpreter evolves the project will strive for near feature-completeness.

Motivation
-------

Grace is a language aimed to help novice programmers get acquainted with the process of programming [@gracepapersoftwareengineering] [@gracefunctionalandimperative]. As such, it provides safety and flexibility in its design.

However, that flexibility comes at a cost, and most of the current implementations of Grace are opaque and obscure. Since the language is Open Source, most of its implementations are also Open Source, but this lack of clarity in the implementation makes them hard to extend and modify by third parties and contributors, severely damaging the growth opportunities of the language.

Objectives
-------

Naylang strives to be an exercise in interpreter construction not only for the creators, but also for any possible contributor. Therefore, the project focuses on the following goals:

- To provide a **solid** implementation of a **relevant subset** of the Grace language.
- To be as **approachable** as possible by both **end users**, namely first-time programmers, and **project collaborators**.
- To be itself a **teaching tool** to learn about one possible **implementation of a language** as flexible as Grace.

Methodology
-------

The project follows a Test Driven Development [@beck2003test] agile methodology, in which unit tests are written in parallel or even before the source code in very short iterations. This is the best approach for two reasons:

- It provides an easy way to verify which part of the code is working at all times, since tests strive for complete code coverage. Therefore, newcomers to the project will know where exactly their changes affect the software as a whole, which will allow them to make changes with more confidence.

- The tests themselves provide documentation that is always up-to-date and synchronized with the code. This, coupled with descriptive test names, provide a myriad of **working code examples**. Needless to say that this would result in vital insight gained at a much quicker pace by a student wanting to learn about interpreters.

The development of Naylang will be carried out in short iterations, usually less than a week long. This has the aim of exploring different architectural approaches to the problems that building an intepreter presents. This way, the benefit of complete test coverage is maximized by being able to completely redesign a subsystem without fear of a regression.

Tradeoffs
-------

Since Naylang is designed as a learning exercise, clarity of code and good software engineering practices will take precedence over performance in almost every case. More precisely, if there is a simple and robust yet naïve implementation of a part of the system, that will be selected instead of the more efficient one.

However, good software engineering practices demand that the architecture of the software has to be modular and loosely coupled. This, in addition to the test coverage mentioned earlier, will make the system extensible enough for anyone interested to modify the project. For instance, it will give them the ability to add a substitute any inefficient part of the system with a more efficient implementation.

In short, the project optimizes for **approachability** and **extensibility**, not for **execution time** or **memory usage**.

Structure of This Document
-------

The rest of this document describes the implementation and results of the project. It first introduces the reader to the Grace programming language and shows the research done about the state of the art as it pertains Naylang. Following that, the document presents a section about the implementation phase of the project, which details the structure and inner workings of the relevant components of the system. After that, two short chapters describe the modular visitor pattern and the testing methodology used in development. Lastly, the results of the research are presented, with an assesment of the state of the project.

The appendices cover a wide range of non-vital material, such as the Spanish translations of the introduction and conclusion and the grammars used for parsing.