\newpage

Memory Management
------

Grace is a garbage-collected language [@gracespecgarbagecollection], and therefore there must be some mechanism to automatically control memory consumption during the evaluation. 

### Reference-counting

The first proposed solution to this problem was to have reference-counted objects, so that when an object would be referenced by either the evaluator or one of the objects in the subscopes of the evaluator. That way, every object accesible from the evaluator would have at least one reference to it, and would get destroyed when it went out of scope.

In this implementation, a factory function can be defined to create objects. With the help of C++ templates, a single static function is sufficient to instatiate any subclass of GraceObject.

```c++
template <typename T, typename... Args>
static std::shared_ptr<T> make_obj(Args&&...args) {
    return std::shared_ptr<T>{new T{std::forward<Args>(args)...}};
}
```

This function can be called from anywhere in the project (usually the evaluators and test cases), and the function will know which arguments the class constructor needs.

```c++
auto num = make_obj<GraceNumber>(5.0);
```

This implementation was sufficiently functional and easy to implement to facilitate the development of the evaluator and the object model. However, reference-counting as a memore management strategy has a number of fatal flaws, the worse of them being the _circular reference problem_ [@circularreferenceproblem]. When reference-counting objects, it is possible to form cycles in the reference graph. If such a cycle were to form, then the objects inside the cycle would always have at least one other object referencing them, and thus would never get deallocated.

### Heap and ObjectFactory classes

The next step was to use one of the well-researched memory management algorithms. With that in mind a Heap class was created to simulate a real dynamic memory store, and implement garbage collection over that structure. The Heap would have the responsibility of controlling the lifetime of an object or, as it is said in C++, _owning_ that object's memory lifespan.

It is the responsibility of the Heap to manage an object's memory, but this management should be transparent to the type of the object itself. The Heap should only store GraceObjects, without worrying about the type of object it is. Therefore, including object factory methods in the Heap would be unadvisable. Instead, a façade was created to aid in the object creation process, called ObjectFactory. The responsibility of this class is to provide a useful interface for the evaluator to create objects of any type wihtout interacting with the Heap directly. As an added benefit, this implementation of ObjectFactory could keep the interface for object creation described above, so that minimal existing code modifications were needed.

### Integration

In order to integrate the newly created Heap with the evaluation engine, some minor changes need to be made.

Since now the Heap is managing the memory, the evaluator can stop using reference-counted pointers to reference objects. Instead, it only needs raw pointers to memory managed by the Heap. The same happens with the pointers held by GraceObjects. Since every object reference uses the GraceObjectPtr wrapper, this change is as simple as changing the implementation of the wrapper:

```c++
// What was
typedef std::shared_ptr<GraceObject> GraceObjectPtr;

// Is now
typedef GraceObject* GraceObjectPtr;
```

Since the interface provided by `std::shared_ptr<>` is similar to that of raw pointers, most of the code that used GraceObjectPtrs will remain untouched.

The second change to integrate the Heap into the project is to have each evaluator hold an instance of Heap. There should be only one instance of an execution evaluator per programming session, and therefore it is reasonable that every instance of the evaluator will have an instance of the Heap.

// TODO: Add UML diagram

### Garbage Collection Algorithm

In order to implement garbage collection in the Heap, an appropriate algorithm had to be selected from the myriad of options available. When reviewing the different possibilities, the focus was set on finding the simplest algorithm that could manage memory without memory leaks. This criteria was informed by the desire of making Naylang a learning exercise, and not a commercial-grade interpreter. As a result, the **Mark and Sweep** garbage collection algorithm was selected [@markandsweep], since it is the most straightforward to implement.

In this algorithm, the Heap must hold references to all objects created in a list. Every time memory liberation is necessary, the Heap traverses all the objects accessible by the current scope of the evaluator with a regular graph search. Whenever it reaches an object that was not reached before, it marks it as "accesible". After that, every node that is not marked as accessible is deemed destroyable, and it's memory is deallocated.

Since this implementation of the Heap only simulates the storage of the objects, and does not make claims about it's continuity, heap fragmentation cannot happen. Therefore, no strategy is needed to defragment the memory.

Note that the Heap is implemented in such a way that the garbage-collection functionality is blocking and synchronous, and thus it can be called at any point in the evaluator. This would enable, for example, to implement an extension of the evaluator to include garbage collection triggers at key points of the exection, using the [Modular Visitor Pattern](Modular Visitor Pattern).

### Implementation

//TODO: DO