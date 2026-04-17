# GMLVM - GameMaker Language Virtual Machine

A complete, production-grade GML interpreter written entirely in GameMaker Language. Execute GML code dynamically at runtime with full language support.

## Features

- Complete GML syntax support - Variables, functions, constructors, static variables, closures
- Full control flow - `if`/`else`, `while`, `for`, `repeat`, `switch`/`case`, `break`/`continue`
- Error handling - `try`/`catch`/`finally`, `throw`
- Data structures - Arrays, structs, accessors (`.`, `[]`, `[$]`)
- Operators - Arithmetic, comparison, logical, bitwise, compound assignment
- Modern GML - `static` variables, `constructor` inheritance, closures
- Performance - AST caching for repeated execution
- Security - Sandboxing with function/variable blacklisting
- Developer tools - Configurable warnings, step-through debugger, static code analysis

## Installation

1. Download the latest GMLVM release
2. Import the downloaded `*.yymps` file using local package manager
3. Call `gmlvm_init()` once at game start

```gml
gmlvm_init();
```

## Quick Start

### Basic Execution

Execute a simple expression:

```gml
var result = gmlvm_run("2 + 3 * 4");
show_debug_message(result); // 14
```

Execute multiple statements and return a value:

```gml
var result = gmlvm_run(@"
    var x = 10;
    var y = 20;
    return x + y;
");
show_debug_message(result); // 30
```

### Using Custom Context

Provide `self` and `other` for the execution context:

```gml
var context = { health: 100, max_health: 100 };
var result = gmlvm_run(@"
    health -= 25;
    return health;
", context);
show_debug_message(result); // 75
```

### Caching for Repeated Execution

Parse once, execute many times for better performance:

```gml
// Parse once
var ast = gmlvm_parse(@"
    var result = 1;
    for (var i = 1; i <= 10; i++) {
        result *= i;
    }
    return result;
");

// Execute multiple times
var factorial10 = gmlvm_vm(ast);
show_debug_message(factorial10); // 3628800
```

Or use the built-in cached runner:

```gml
var result1 = gmlvm_run_cached(@"
    function expensive(n) {
        var sum = 0;
        for (var i = 0; i < n; i++) sum += i;
        return sum;
    }
    return expensive(1000);
");
```

## Core API

### Execution Functions

| Function | Description |
|----------|-------------|
| `gmlvm_run(code, self, other)` | Tokenize, parse, and execute GML code |
| `gmlvm_run_cached(code, self, other)` | Execute with AST caching |
| `gmlvm_parse(code)` | Parse code and return AST without executing |
| `gmlvm_vm(ast, self, other)` | Execute a pre-parsed AST |

### Warning System

Control runtime and parse-time warnings:

```gml
// Disable specific warnings
gmlvm_warnings_disable("undefined_binary_left");
gmlvm_warnings_disable("undefined_binary_right");

// Run code without undefined warnings
var result = gmlvm_run("var x; return x + 5;");

// Re-enable warnings
gmlvm_warnings_enable("undefined_binary_left");
gmlvm_warnings_enable("undefined_binary_right");

// Disable all warnings
gmlvm_warnings_disable_all();

// Enable all warnings
gmlvm_warnings_enable_all();
```

Available warning categories:
- `undefined_binary_left` - Left operand is undefined in binary operation
- `undefined_binary_right` - Right operand is undefined in binary operation
- `undefined_unary` - Operand is undefined in unary operation
- `unknown_operator` - Unknown operator encountered
- `cannot_call` - Attempting to call a non-function value
- `parse_error` - Parser errors

### Static Code Analysis

Check code for issues without executing:

```gml
var code = @"
    var x;
    var y = 10;
    return x + y;
";

// Check if code has warnings
if (gmlvm_has_warnings(code)) {
    show_debug_message("Code has issues!");
    show_debug_message(gmlvm_check_to_string(code));
}

// Get warnings as array
var warnings = gmlvm_check(code);
for (var i = 0; i < array_length(warnings); i++) {
    var w = warnings[i];
    show_debug_message($"[{w.category}] Line {w.line}: {w.message}");
}
```

## Advanced Features

### Functions and Closures

```gml
var result = gmlvm_run(@"
    function makeCounter() {
        var count = 0;
        return function() {
            count++;
            return count;
        };
    }
    
    var c1 = makeCounter();
    var c2 = makeCounter();
    
    return string(c1()) + ',' + string(c1()) + ',' + string(c2());
");
show_debug_message(result); // "1,2,1"
```

### Static Variables

```gml
var result = gmlvm_run(@"
    function nextId() {
        static id = 1000;
        return id++;
    }
    
    return string(nextId()) + ',' + string(nextId()) + ',' + string(nextId());
");
show_debug_message(result); // "1000,1001,1002"
```

### Constructors and Inheritance

```gml
var result = gmlvm_run(@"
    function Animal(name) constructor {
        self.name = name;
        
        self.speak = function() {
            return name + ' makes a sound';
        };
    }
    
    function Dog(name, breed) : Animal(name) constructor {
        self.breed = breed;
        
        self.speak = function() {
            return name + ' barks!';
        };
    }
    
    var dog = new Dog('Rex', 'German Shepherd');
    return dog.name + ' the ' + dog.breed + ': ' + dog.speak();
");
show_debug_message(result); // "Rex the German Shepherd: Rex barks!"
```

### Try/Catch Error Handling

```gml
var result = gmlvm_run(@"
    try {
        throw 'Something went wrong!';
    } catch (e) {
        return 'Caught: ' + e;
    } finally {
        show_debug_message('Cleanup complete');
    }
");
show_debug_message(result); // "Caught: Something went wrong!"
```

### Switch Statement

```gml
var result = gmlvm_run(@"
    var grade = 'B';
    var message;
    
    switch (grade) {
        case 'A':
            message = 'Excellent!';
            break;
        case 'B':
            message = 'Good job!';
            break;
        case 'C':
            message = 'Fair';
            break;
        default:
            message = 'Needs improvement';
    }
    
    return message;
");
show_debug_message(result); // "Good job!"
```

### Array and Struct Literals

```gml
var result = gmlvm_run(@"
    var arr = [1, 2, 3, 4, 5];
    var obj = {
        name: 'Player',
        stats: {
            hp: 100,
            mp: 50
        }
    };
    
    return obj.name + ' HP: ' + string(obj.stats.hp);
");
show_debug_message(result); // "Player HP: 100"
```

## Sandbox Security

Restrict access to specific functions, objects, or variables:

```gml
// Create sandbox
var sandbox = new gmlvm_sandbox();

// Blacklist dangerous functions
sandbox.BanFunction("game_end");
sandbox.BanFunction("room_goto");
sandbox.BanFunction("instance_destroy");

// Blacklist sensitive objects
sandbox.BanObject("obj_player");
sandbox.BanObject("obj_save_manager");

// Blacklist sensitive variables
sandbox.BanVariable("global.saveData");

// Run untrusted code safely
var result = gmlvm_run_sandboxed(@"
    // This will throw an error - game_end is banned
    game_end();
", sandbox);

if (is_struct(result) && result.type == "runtime_error") {
    show_debug_message("Blocked dangerous operation!");
}
```

## Debugger

Step through code execution with the built-in debugger:

```gml
// Enable debugger
global.__gmlvm_debugger.Enable();

// Set breakpoints
global.__gmlvm_debugger.SetBreakpoint(5);  // Break on line 5

// Step modes
global.__gmlvm_debugger.StepInto();
global.__gmlvm_debugger.StepOver();
global.__gmlvm_debugger.StepOut();
global.__gmlvm_debugger.Continue();

// Get current state
var state = global.__gmlvm_debugger.GetState();
show_debug_message($"Line: {state.current_line}, Depth: {state.call_depth}");

// Disable debugger
global.__gmlvm_debugger.Disable();
```

## Error Handling

GMLVM returns error objects that can be inspected:

```gml
var result = gmlvm_run(@"
    var x;
    return x + 5;  // x is undefined
");

// Check if result is an error
if (is_struct(result)) {
    if (result.type == "parse_error") {
        show_debug_message($"Parse Error at line {result.line}: {result.message}");
    } else if (result.type == "runtime_error") {
        show_debug_message($"Runtime Error at line {result.line}: {result.message}");
    }
}
```

## Complete Example: In-Game Console

```gml
// Create Event
console_history = [];
console_sandbox = new gmlvm_sandbox();
console_sandbox.BanFunction("game_end");
console_sandbox.BanFunction("room_goto");

// When user enters a command
function console_execute(command) {
    // Check for warnings first
    if (gmlvm_has_warnings(command)) {
        var warnings = gmlvm_check_to_string(command);
        array_push(console_history, $"Warnings: {warnings}");
    }
    
    // Execute safely
    var result = gmlvm_run_sandboxed(command, console_sandbox, self);
    
    // Handle result
    if (is_struct(result) && result.type == "runtime_error") {
        array_push(console_history, $"Error: {result.message}");
    } else {
        array_push(console_history, string(result));
    }
}

// Example commands
console_execute("health = 100; return 'Health set to 100'");
console_execute("return health * 2");
console_execute("function heal(amount) { health += amount; return health; } heal(25)");
```

## Performance Considerations

- Use `gmlvm_parse()` and `gmlvm_vm()` for code that runs repeatedly
- Use `gmlvm_run_cached()` to automatically cache ASTs
- Disable warnings in production with `gmlvm_warnings_disable_all()`
- Consider sandboxing only for untrusted user input

## Limitations

- Maximum 8 arguments for native GameMaker function calls (use `gmlvm_vm_call_ext` for more)
- Static variables inside doubly-nested closures may not initialize correctly (edge case)
- Debugger provides hooks but requires manual implementation of the debugging interface
