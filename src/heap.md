\newpage

Memory Management
------

Grace is a garbage-collected language [^gracespecgarbagecollection], and therefore there must be some mechanism to automatically control memory consumption during the evaluation.

This section details such mechanisms, and their implementation and evolution throughout the development of Naylang.

### Reference-counting

The first solution to this problem was to have reference-counted objects, so that when an object would be referenced by one of the objects in the subscopes of the evaluator they would remain in memory. That way, every object accesible from the evaluator would have at least one reference to it, and would get destroyed when it went out of scope.

In this implementation, a factory function was be defined to create objects. With the help of C++ template metaprogramming, a single static function is sufficient to instatiate any subclass of `GraceObject`.

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

This implementation was sufficiently functional and easy to implement to facilitate the development of the evaluator and the object model. However, reference-counting as a memory management strategy has a number of fatal flaws, the worse of them being the _circular reference problem_ [@circularreferenceproblem]. When reference-counting objects, it is possible to form cycles in the reference graph. If such a cycle were to form, then the objects inside the cycle would always have at least one other object referencing them, and thus would never get deallocated.

### Heap and ObjectFactory classes

The next step was to use one of the well-researched memory management algorithms. With that in mind a `Heap` class was created to simulate a real dynamic memory store, and implement garbage collection over that structure. The Heap would have the responsibility of controlling the lifetime of an object or, as it is said in C++, _owning_ that object's memory lifespan.

It is the responsibility of the `Heap` to manage an object's memory, but this management should be transparent to the type of the object itself. The Heap should only store `GraceObject`s, without worrying about the type of object it is. Therefore, including object factory methods in the `Heap` would be unadvisable. Instead, a façade was created to aid in the object creation process, called `ObjectFactory`. The responsibility of this class is to provide a useful interface for the evaluator to create objects of any type wihtout interacting with the Heap directly. As an added benefit, this implementation of `ObjectFactory` could keep the interface for object creation described above, so that minimal existing code modifications were needed.

### Integration

In order to integrate the newly created `Heap` with the evaluation engine, some minor changes need to be made.

Since now the `Heap` is managing the memory, the evaluator can stop using reference-counted pointers to reference objects. Instead, it only needs raw pointers to memory managed by the `Heap`. The same happens with the pointers held by `GraceObject`s. Since every object reference uses the `GraceObjectPtr` wrapper, this change is as simple as changing the implementation of the wrapper:

```c++
// What was
typedef std::shared_ptr<GraceObject> GraceObjectPtr;

// Is now
typedef GraceObject* GraceObjectPtr;
```

Since the interface provided by `std::shared_ptr<>` is similar to that of raw pointers, most of the code that used `GraceObjectPtr`s will remain untouched.

The second change to integrate the `Heap` into the project is to have each evaluator hold an instance of `Heap`. There should be only one instance of an `ExecutionEvaluator` per programming session, and therefore it is reasonable that every instance of the evaluator will have an instance of the `Heap`.

Lastly, the `GraceObject` class needs to be extended to allow the retrieval of all the fields to ease traversal, and to include a `accessible` flag so that the algorithm knows which objects to delete.

```c++
class GraceObject {
protected:
    std::map<std::string, GraceObjectPtr> _fields;
    // ...

public:
    bool _accessible;
  	// ...

  	const std::map<GraceObjectPtr> &fields();
};
```

### Garbage Collection Algorithm

In order to implement garbage collection in the `Heap`, an appropriate algorithm had to be selected from the myriad of options available. When reviewing the different possibilities, the focus was set on finding the simplest algorithm that could manage memory without memory leaks. This criteria was informed by the desire of making Naylang a learning exercise, and not a commercial-grade interpreter. As a result, the **Mark and Sweep** garbage collection algorithm was selected [@markandsweep], since it is the most straightforward to implement.

In this algorithm, the `Heap` must hold references to all objects created in a list. Every time memory liberation is necessary, the `Heap` traverses all the objects accessible by the current scope of the evaluator with a depth-first marked graph search. Whenever it reaches an object that was not reached before, it marks it as "accesible". After that, every node that is not marked as accessible is deemed destroyable, and it's memory is deallocated.

Since this implementation of the `Heap` only _simulates_ the storage of the objects, and does not make claims about it's continuity, heap fragmentation cannot happen. Therefore, no strategy is needed to defragment the memory.

Note that the Heap is implemented in such a way that the garbage-collection functionality is blocking and synchronous, and thus it can be called at any point in the evaluator. This would enable, for example, to implement an extension of the evaluator to include garbage collection triggers at key points of the exection, using the [Modular Visitor Pattern](#modular-visitor-pattern).

### Implementation

The internal design of the Heap class is vital to ensure that the objects are stored in an efficient manner, and that the garbage collection itself does not hinder the capabilities of the evaluator too greatly.

#### Object storage

The requirements for object storage in the Heap must be taken into consideration when selecting a data structure for object storage.

Of course, all objects must be **accessible at any point** in the execution, but this is accomplished with pointers returned at object creation and not by looking up in the Heap storage itself. Therefore, a structure with the possibility for fast lookup (such as an `std::map` [^stdmap]) is not necessary. Furthermore, it can be said that the **insertion order is not important**.

The mark and sweep algorithm needs to **traverse** the stored objects at least twice every time the garbage collection is triggered: Once to mark every object as not visited, and another time after the marking to check whether or not it is still accesible. Therefore, the storage must allow the possibility of traversal, but it does not need to be extremely efficient since a relatively small number of passes need to be made.

Lastly, the storage must allow to **delete elements at arbitrary locations**, since at any point any object can go out of scope and will need to be removed when the collector triggers. This is perhaps the most performance-intensive requirement, since several object deletions can be necessary for each pass.

The two first requirements make it clear that a linear storage (array, vector or linked list) is needed, and the last requirement pushes the decision strongly in favor of a linked list. Luckily, C++ already has an implementation of a doubly-linked list [^stdlist], which the `Heap` will be using.

With the container selected, the only remaining thing is to establish which of C++'s mechanisms will be used to hold the object's lifespan. The concept of _memory ownsership_ was introduced in a previous section, and it was established that the `Heap` is responsible for _owning_ the memory of all runtime objects. In modern C++, memory ownership is expressed by means of a _unique pointer_, that is, a smart pointer that has exactly one reference [@memoryownership]. The object that holds that reference is responsible for keeping the memory of the referenced object. When the container object goes out of scope or is destroyed, the destructor for the contained object is immediately called, liberating the memory [^stdunique_ptr]. In the case of Naylang, this menas that the object will be destroyed either when it is extracted from the list, or when the list itself is destroyed.

With this information, the `Heap` storage can be designed as a **linked list** of _cells_, wherein each _cell_ is a `unique_ptr` to an instance of one of the subclasses of `GraceObject`.

#### Mark and Sweep algorithm

The implementation of the algorithm itself is rather straightforward, since it is nothing more complicated than performing several traversals in the object storage:

```c++
void Heap::markAndSweep() {
	for (auto obj : _storage) {
		obj->_visited = false;
	}

	auto scope = _eval->currentScope();
	scope->_visited = true;
	visit(scope);

	int index = 0;
	std::vector<int> toDelete;
	for (auto obj : _storage) {		
		if (!obj->_visited) {
			toDelete.push_back(index);
		}
		index++;
	}

	for (auto ndx : toDelete) {
		_storage.erase(ndx);
	}
}

void Heap::visit(GraceObject* scope) {
	for (auto field : scope->fields()) {
		field->_visited = true;
		visit(field);
	}
}
```

#### Memory capacity and GC triggers

Ideally, the garbage-collection mechanism would be transparent to the evaluator, meaning that no explicit calls to the collection algorithm should be done from the evaluation engine. Rather, it is the `Heap` itself who must determine when to trigger the GC algorithm. To this end, the `Heap` is initialized with three values:

- An **absolute capacity**, which acts as a upper bound for the storage available. When the number of objects contained in the `Heap` reaches this value, any subsequent attempts to create objects will result in an error.

- A **trigger threshold**, which indicates the `Heap` when it needs to start triggering the garbage collection algorithm. When this number of stored objects is surpassed, the `Heap` will start triggering the garbage collection algorithm with every interval.

- The **object creation interval**. This value indicates how often garbage collection has to trigger once the threshold has been hit. For instance, if this value is `10` the garbage collection will trigger every tenth object inserted, if the threshold has been hit.

Therefore, this would be the code relevant to triggering the garbage collection:

```c++
void Heap::triggerGCIfNeeded() {
	if (_totalObjects >= _maxCapacity) {
		throw std::string{"Out of Memory"};
	}

	if (_nthObject == _interval) {
		if (_totalObjects >= _threshold) {
			markAndSweep();
		}
	}
}
```

Note that, even though objects may vary in size slightly, there are never degenerate differences in size, since even a big object with many fields has every one of the fields stored as a separate objects in the Heap, as is explained in Figure 5.8

![Heap Storage Model](images/borlean.png)




[^stdlist]: http://en.cppreference.com/w/cpp/container/list

[^stdmap]: http://en.cppreference.com/w/cpp/container/map

[^stdunique_ptr]: http://en.cppreference.com/w/cpp/memory/unique_ptr

[^gracespecgarbagecollection]: http://gracelang.org/documents/grace-spec-0.7.0.html#garbage-collection

