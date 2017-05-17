\newpage

Debugging
------

As previously mentioned, Naylang implements a set of debug commands similar to that of GDB. More precisely, the set of commands whose functionality is replicated is `run`, `continue`, `next` (step over), `step` (step into), `break` and `print`. The list of commands and an explaination of their uses is listed in the [Frontends](Frontends) section.

The debugging mechanisms described are implemented using the [Modular Visitor Pattern](Modular Visitor Pattern). Specifically, since the debugger needs only to interject in the `ExecutionEvaluation` function calls, the [Direct Subclass Pattern](Direct Subclass Pattern) was used.

In addition to that, a controler was created (`Debugger`) to act as an adaption layer between the extended evaluatio and the frontend.

### Before-After Stateful Debugging

The debugger uses a _before-after_ stateful execution pattern. In general, the debugger behaves exactly the same as the `ExecutionEvaluator`, **except** for when a pause in the execution is required, in which case the execution must block and request commands until a command is provided that resumes execution (e.g. `continue` or `next`). A pause can happen either because a breakpoint is reached, or the execution was paused in the instruction before and a step instruction was executed (e.g. `step` will execute an instruction and block again).

The extension of the evaluation must only handle the cases where a pause is necessary. In these cases, two calls are added before and after the call to the regular evaluation. Either function can block if the conditions demand so. When they do, they request commands from the frontend until the conditions are met to resume exection.

```c++
void DebugEvaluator::evaluate(VariableDeclaration &expression) {
	// Call to the debug mechanism
	beginDebug(expression);
	DebugState prevState = _state;
	// Call superclass to handle regular evaluation
	ExecutionEvaluator::evaluate(expression);
	// Call to the debug mechanism
	endDebug(expression, prevState);
}
```

To handle all the possible cases and commands, the debugger holds a `state` field, which determines the behavior of a certain `debug()` call. Therefore, the `debug()` functions are also resposible for handling automatic state transitions in the debugger, that is, transitions that do not require user interaction. The possible debug states are the following:

```c++
enum DebugState {
    CONTINUE,
    STOP,
    STEP_IN,
    STEP_OVER,
    STEP_OVER_SKIP
};
```

And the debug functions handle a relatively small set of cases:

```c++
void ExecutionEvaluator::beginDebug(Statement *node) {
    if (_state == STEP_OVER)
        _state = CONTINUE;
    _debugger->debug(node);
}

void ExecutionEvaluator::endDebug(Statement *node, DebugState prevState) {
    if (!node->stoppable())
        return;
    if (prevState == STEP_OVER)
        _state = STOP;
    if (_state == STEP_IN)
        _state = STOP;
}
```



The state can also be changed with external commands such as `continue`, which changes the state unconditionally to `CONTINUE`, or by the controller because of breakpoints. These transitions will be explained later.

