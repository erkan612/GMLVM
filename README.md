# GMLVM - A GML Interpreter for GameMaker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GameMaker](https://img.shields.io/badge/GameMaker-green.svg)](https://www.yoyogames.com/gamemaker)

A complete **GML interpreter** written in pure GML, allowing you to dynamically load and execute GameMaker Language code at runtime. Perfect for modding support, live-coding, scripting, and runtime code evaluation.

## Features

- **Complete Language Support**: Implements virtually all GML language features
- **Runtime Execution**: Parse and execute GML code dynamically
- **Instance-Aware**: Full integration with GameMaker's instance system
- **Preprocessor**: Supports `#macro` with nested expansion
- **No External Dependencies**: Pure GML implementation

## Supported Features

### Core Language
- Variables and scoping (`var`, instance variables, globals)
- Arithmetic, comparison, and logical operators
- Bitwise operators (`&`, `|`, `^`, `~`, `<<`, `>>`)
- Nullish coalescing (`??`) and assignment (`?=`)
- Ternary operator (`?:`)
- Compound assignments (`+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`)
- Postfix increment/decrement (`++`, `--`)

### Control Flow
- `if`/`else` statements
- `while` loops
- `for` loops
- `repeat` loops
- `do`/`until` loops
- `switch` statements (with fallthrough)
- `break`, `continue`, `return`, `exit`

### Data Types
- Numbers and strings
- Arrays and array literals
- Structs and struct literals
- `ds_map` and `ds_list` with accessors
- Accessors: `[@]`, `[$]`, `[?]`, `[|]`, `[#]`
- Template strings (`$"Hello {name}!"`)
- Multi-line strings (`@"line1\nline2"`)

### Functions
- Function declarations and calls
- Optional arguments with defaults
- Closures
- Recursion
- Constructors with inheritance
- Static variables
- `new` operator

### Advanced Features
- `with` statement (instances, objects, structs, `all`)
- `delete` operator
- `try`/`catch`/`finally`/`throw`
- Enums (auto-incrementing and explicit values)
- `typeof()` function
- `instanceof()` and `is_instanceof()` functions
- Preprocessor macros (`#macro` with nested expansion)
- `#region`/`#endregion` directives (stripped)

## Quick Start

### Basic Usage

```gml
// Initialize the interpreter (call once)
gmlvm_init();

// Execute GML code
var result = gmlvm_run(@"
    var x = 10;
    var y = 20;
    return x + y;
");
show_debug_message(result); // 30
```

### Running on an Instance

```gml
// Create event
gmlvm_init();
create_ast = gmlvm_parse_only(@"
    spd = 5;
    hp = 100;
");

// Step event
step_ast = gmlvm_parse_only(@"
    if (keyboard_check(ord('W'))) y -= spd;
    if (keyboard_check(ord('A'))) x -= spd;
    if (place_meeting(x, y, obj_wall)) show_debug_message('Collision!');
");

// Execute on the instance
gmlvm_vm(create_ast, self);
gmlvm_vm(step_ast, self);
```

## API Reference

### Core Functions

| Function | Description |
|----------|-------------|
| `gmlvm_init()` | Initialize the interpreter |
| `gmlvm_run(code, [self], [other])` | Parse and execute GML code |
| `gmlvm_parse_only(code)` | Parse code and return AST |
| `gmlvm_tokenize_only(code)` | Tokenize code and return tokens |
| `gmlvm_preprocess(code)` | Expand macros and return processed code |
| `gmlvm_vm(ast, [self], [other])` | Execute a parsed AST |

### Warning Control

| Function | Description |
|----------|-------------|
| `gmlvm_check(code)` | Check code for warnings |
| `gmlvm_has_warnings(code)` | Returns true if code has warnings |
| `gmlvm_warnings_enable(category)` | Enable specific warning category |
| `gmlvm_warnings_disable(category)` | Disable specific warning category |

### Sandbox (Security)

```gml
var sandbox = new gmlvm_sandbox();
sandbox.BanFunction("instance_destroy");
sandbox.BanVariable("global.secret");

gmlvm_run_sandboxed(code, sandbox, self);
```

## Example: Dynamic Player Controller

**oPlayer_Create.gml**
```gml
spd = 5;
hp = 100;
max_hp = 100;
```

**oPlayer_Step.gml**
```gml
// Movement
if (keyboard_check(ord("W"))) y -= spd;
if (keyboard_check(ord("A"))) x -= spd;
if (keyboard_check(ord("S"))) y += spd;
if (keyboard_check(ord("D"))) x += spd;

// Collision with enemies
with (obj_enemy) {
    if (place_meeting(x, y, other)) {
        other.hp -= 10;
        instance_destroy();
    }
}

// Death check
if (hp <= 0) {
    instance_destroy();
}
```

## Advanced Examples

### Constructors and Inheritance

```gml
var result = gmlvm_run(@"
    function Animal(name) constructor {
        self.name = name;
    }
    
    function Dog(name, breed) : Animal(name) constructor {
        self.breed = breed;
        
        self.bark = function() {
            return name + ' says woof!';
        };
    }
    
    var dog = new Dog('Rex', 'German Shepherd');
    return dog.bark();
");
// Returns: "Rex says woof!"
```

### Macros

```gml
var result = gmlvm_run(@"
    #macro WIDTH 640
    #macro HEIGHT 480
    #macro SCREEN_SIZE (WIDTH * HEIGHT)
    
    return SCREEN_SIZE;
");
// Returns: 307200
```

### Enums

```gml
var result = gmlvm_run(@"
    enum GameState {
        MENU,
        PLAYING = 10,
        PAUSED,
        GAME_OVER
    }
    
    return GameState.PAUSED;
");
// Returns: 11
```

### Template Strings

```gml
var result = gmlvm_run(@"
    var player = 'Alice';
    var score = 1000;
    
    return $'Player: {player} | Score: {score}';
");
// Returns: "Player: Alice | Score: 1000"
```

## Known Limitations

- `other` inside `with` statements on instances can only access instance variables, not outer local variables
- Some GameMaker built-in functions might fail
- Asset indices may need to be "woken up" before use (e.g., `wakeup = string(Object2);`)

## Testing

The interpreter has been thoroughly tested with **100+ test cases** covering all major language features. Tests include:

- Arithmetic precedence and operations
- String operations and template strings
- Control flow (if/else, loops, switch)
- Functions (calls, recursion, closures)
- Constructors and inheritance
- Arrays, structs, and accessors
- Bitwise and nullish operators
- Macros and enums
- Try/catch/throw
- With statements on instances and objects

## Use Cases

- **Modding Support**: Allow players to write custom scripts
- **Live Coding**: Modify game behavior without recompiling
- **Scriptable Objects**: Create data-driven game entities
- **Debug Console**: Execute arbitrary GML at runtime
- **Procedural Generation**: Generate and execute code dynamically
- **Educational Tools**: Teach GML programming in-game

---

Created by [erkan612](https://github.com/erkan612)

