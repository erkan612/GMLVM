function gmlvm_test_runner() constructor {
    tests = [];
    passed = 0;
    failed = 0;
    current_category = "";
    
    Category = function(_name) {
        current_category = _name;
        show_debug_message("");
        show_debug_message("=== " + _name + " ===");
    };
    
    Assert = function(_name, _result, _expected) {
        var _passed = false;
        
        if (is_real(_result) && is_real(_expected)) {
            _passed = (abs(_result - _expected) < 0.001);
        } else {
            _passed = (_result == _expected);
        }
        
        var _test = {
            category: current_category,
            name: _name,
            result: _result,
            expected: _expected,
            passed: _passed
        };
        
        array_push(tests, _test);
        
        if (_passed) {
            passed++;
            show_debug_message("  ✓ " + _name + ": " + string(_result));
        } else {
            failed++;
            show_debug_message("  ✗ " + _name + ": " + string(_result) + " (expected " + string(_expected) + ")");
        }
    };
    
    AssertArray = function(_name, _result, _index, _expected) {
        var _value = _result;
        if (is_array(_result)) {
            _value = _result[_index];
        }
        
        var _passed = false;
        if (is_real(_value) && is_real(_expected)) {
            _passed = (abs(_value - _expected) < 0.001);
        } else {
            _passed = (_value == _expected);
        }
        
        var _test = {
            category: current_category,
            name: _name,
            result: _value,
            expected: _expected,
            passed: _passed
        };
        
        array_push(tests, _test);
        
        if (_passed) {
            passed++;
            show_debug_message("  ✓ " + _name + ": " + string(_value));
        } else {
            failed++;
            show_debug_message("  ✗ " + _name + ": " + string(_value) + " (expected " + string(_expected) + ")");
        }
    };
    
	Summary = function() {
	    show_debug_message("");
	    show_debug_message("╔══════════════════════════════════════════════════════════════════╗");
	    show_debug_message("║                         TEST SUMMARY                             ║");
	    show_debug_message("╠══════════════════════════════════════════════════════════════════╣");
    
	    var _total_str = "  Total:  " + string(array_length(tests));
	    show_debug_message("║" + string_pad_right(_total_str, 66) + "║");
    
	    var _passed_str = "  Passed: " + string(passed);
	    show_debug_message("║" + string_pad_right(_passed_str, 66) + "║");
    
	    var _failed_str = "  Failed: " + string(failed);
	    show_debug_message("║" + string_pad_right(_failed_str, 66) + "║");
    
	    show_debug_message("╠══════════════════════════════════════════════════════════════════╣");
    
	    if (failed == 0) {
	        show_debug_message("║                        ALL TESTS PASSED!                         ║");
	    } else {
	        show_debug_message("║  Failed tests:                                                   ║");
        
	        var _shown = 0;
	        for (var i = 0; i < array_length(tests); i++) {
	            var t = tests[i];
	            if (!t.passed) {
	                var _line = "    - " + t.name;
                
	                if (string_length(_line) > 50) {
	                    _line = string_copy(_line, 1, 47) + "...";
	                }
                
	                show_debug_message("║  " + string_pad_right(_line, 64) + "║");
                
	                var _detail = "      got: " + string_short(t.result) + ", expected: " + string_short(t.expected);
	                if (string_length(_detail) > 60) {
	                    _detail = string_copy(_detail, 1, 57) + "...";
	                }
	                show_debug_message("║  " + string_pad_right(_detail, 64) + "║");
                
	                _shown++;
	                if (_shown >= 5) break;
	            }
	        }
        
	        var _remaining = failed - _shown;
	        if (_remaining > 0) {
	            var _rem_str = "    ... and " + string(_remaining) + " more";
	            show_debug_message("║  " + string_pad_right(_rem_str, 64) + "║");
	        }
	    }
    
	    show_debug_message("╚══════════════════════════════════════════════════════════════════╝");
	    show_debug_message("");
	};
}

function string_short(_val) {
    if (_val == undefined) return "undefined";
    var _str = string(_val);
    _str = string_replace_all(_str, "\n", "\\n");
    _str = string_replace_all(_str, "\r", "");
    if (string_length(_str) > 30) {
        _str = string_copy(_str, 1, 27) + "...";
    }
    return _str;
}

function RunTests() {
	var runner = new gmlvm_test_runner();

	runner.Category("Basic Arithmetic and Precedence");

	var _test1 = gmlvm_run(@"
	    return 2 + 3 * 4;
	");
	runner.Assert("1. Arithmetic precedence", _test1, 14);

	var _test2 = gmlvm_run(@"
	    return (2 + 3) * 4;
	");
	runner.Assert("2. Parentheses", _test2, 20);

	var _test3 = gmlvm_run(@"
	    return 10 / 3;
	");
	runner.Assert("3. Division", _test3, 10/3);

	var _test4 = gmlvm_run(@"
	    return 10 % 3;
	");
	runner.Assert("4. Modulo", _test4, 1);

	runner.Category("String Operations");

	var _test5 = gmlvm_run(@"
	    return 'Hello' + ' ' + 'World';
	");
	runner.Assert("5. String concatenation", _test5, "Hello World");

	var _test6 = gmlvm_run(@"
	    var name = 'Player';
	    return 'Welcome, ' + name + '!';
	");
	runner.Assert("6. String with variable", _test6, "Welcome, Player!");

	runner.Category("Comparison and Logical Operators");

	var _test7 = gmlvm_run(@"
	    return 5 > 3;
	");
	runner.Assert("7. Greater than", _test7, 1);

	var _test8 = gmlvm_run(@"
	    return 5 == 5 && 3 < 10;
	");
	runner.Assert("8. Logical AND", _test8, 1);

	var _test9 = gmlvm_run(@"
	    return 5 == 3 || 10 > 5;
	");
	runner.Assert("9. Logical OR", _test9, 1);

	var _test10 = gmlvm_run(@"
	    return !(5 == 3);
	");
	runner.Assert("10. Logical NOT", _test10, 1);

	runner.Category("If/Else Statements");

	var _test11 = gmlvm_run(@"
	    var x = 15;
	    if (x > 10) {
	        return 'big';
	    } else {
	        return 'small';
	    }
	");
	runner.Assert("11. If/Else true branch", _test11, "big");

	var _test12 = gmlvm_run(@"
	    var x = 5;
	    if (x > 10) {
	        return 'big';
	    } else {
	        return 'small';
	    }
	");
	runner.Assert("12. If/Else false branch", _test12, "small");

	var _test13 = gmlvm_run(@"
	    var score = 85;
	    var grade;
	    if (score >= 90) {
	        grade = 'A';
	    } else if (score >= 80) {
	        grade = 'B';
	    } else if (score >= 70) {
	        grade = 'C';
	    } else {
	        grade = 'F';
	    }
	    return grade;
	");
	runner.Assert("13. Else-if chain", _test13, "B");

	runner.Category("While Loops");

	var _test14 = gmlvm_run(@"
	    var sum = 0;
	    var i = 1;
	    while (i <= 5) {
	        sum += i;
	        i += 1;
	    }
	    return sum;
	");
	runner.Assert("14. While loop sum", _test14, 15);

	var _test15 = gmlvm_run(@"
	    var i = 10;
	    var result = '';
	    while (i > 0) {
	        result += string(i) + ' ';
	        i -= 2;
	    }
	    return result;
	");
	runner.Assert("15. While countdown", _test15, "10 8 6 4 2 ");

	runner.Category("For Loops");

	var _test16 = gmlvm_run(@"
	    var sum = 0;
	    for (var i = 1; i <= 5; i++) {
	        sum += i;
	    }
	    return sum;
	");
	runner.Assert("16. For loop sum", _test16, 15);

	var _test17 = gmlvm_run(@"
	    var result = '';
	    for (var i = 0; i < 5; i++) {
	        result += string(i) + ',';
	    }
	    return result;
	");
	runner.Assert("17. For loop string", _test17, "0,1,2,3,4,");

	var _test18 = gmlvm_run(@"
	    for (var i = 0; i < 3; i++) {
	        for (var j = 0; j < 2; j++) {
	            // nested loop
	        }
	    }
	    return i * j;
	");
	runner.Assert("18. Nested loops", _test18, 6);

	runner.Category("Break and Continue");

	var _test19 = gmlvm_run(@"
	    var sum = 0;
	    for (var i = 1; i <= 10; i++) {
	        if (i == 6) break;
	        sum += i;
	    }
	    return sum;
	");
	runner.Assert("19. Break", _test19, 15);

	var _test20 = gmlvm_run(@"
	    var sum = 0;
	    for (var i = 1; i <= 5; i++) {
	        if (i == 3) continue;
	        sum += i;
	    }
	    return sum;
	");
	runner.Assert("20. Continue", _test20, 12);

	runner.Category("Arrays");

	var _test21 = gmlvm_run(@"
	    var arr = [10, 20, 30, 40, 50];
	    return arr[2];
	");
	runner.Assert("21. Array access", _test21, 30);

	var _test22 = gmlvm_run(@"
	    var arr = [1, 2, 3];
	    arr[1] = 99;
	    return arr[0] + arr[1] + arr[2];
	");
	runner.Assert("22. Array assignment", _test22, 103);

	var _test23 = gmlvm_run(@"
	    var arr = [];
	    for (var i = 0; i < 5; i++) {
	        arr[i] = i * 10;
	    }
	    return arr[3];
	");
	runner.Assert("23. Array in loop", _test23, 30);

	runner.Category("Structs");

	var _test24 = gmlvm_run(@"
	    var player = {
	        name: 'Hero',
	        hp: 100,
	        max_hp: 100
	    };
	    return player.name;
	");
	runner.Assert("24. Struct property access", _test24, "Hero");

	var _test25 = gmlvm_run(@"
	    var player = { name: 'Hero', hp: 100 };
	    player.hp -= 20;
	    return player.hp;
	");
	runner.Assert("25. Struct property modification", _test25, 80);

	var _test26 = gmlvm_run(@"
	    var obj = {
	        x: 10,
	        y: 20
	    };
	    return obj.x + obj.y;
	");
	runner.Assert("26. Struct shorthand", _test26, 30);

	runner.Category("Functions");

	var _test27 = gmlvm_run(@"
	    function greet(name) {
	        return 'Hello, ' + name + '!';
	    }
	    return greet('World');
	");
	runner.Assert("27. Function call", _test27, "Hello, World!");

	var _test28 = gmlvm_run(@"
	    function factorial(n) {
	        if (n <= 1) return 1;
	        return n * factorial(n - 1);
	    }
	    return factorial(5);
	");
	runner.Assert("28. Recursion", _test28, 120);

	var _test29 = gmlvm_run(@"
	    function makeAdder(x) {
	        return function(y) {
	            return x + y;
	        };
	    }
	    var add5 = makeAdder(5);
	    return add5(10);
	");
	runner.Assert("29. Closure", _test29, 15);

	runner.Category("Switch Statement");

	var _test30 = gmlvm_run(@"
	    var fruit = 'apple';
	    var result;
	    switch (fruit) {
	        case 'banana':
	            result = 'yellow';
	            break;
	        case 'apple':
	            result = 'red';
	            break;
	        case 'grape':
	            result = 'purple';
	            break;
	        default:
	            result = 'unknown';
	    }
	    return result;
	");
	runner.Assert("30. Switch case", _test30, "red");

	var _test31 = gmlvm_run(@"
	    var value = 5;
	    var result = '';
	    switch (value) {
	        case 1:
	            result += 'A';
	            break;
	        case 5:
	            result += 'B';
	            // fallthrough intentional
	        case 6:
	            result += 'C';
	            break;
	        default:
	            result += 'D';
	    }
	    return result;
	");
	runner.Assert("31. Switch fallthrough", _test31, "BC");

	runner.Category("Try/Catch/Throw");

	var _test32 = gmlvm_run(@"
	    try {
	        throw 'oops';
	    } catch (e) {
	        return 'Caught: ' + e;
	    }
	");
	runner.Assert("32. Try/Catch", _test32, "Caught: oops");

	var _test33 = gmlvm_run(@"
	    var result = '';
	    try {
	        result += 'A';
	        throw 'error';
	        result += 'B';
	    } catch (e) {
	        result += 'C';
	    } finally {
	        result += 'D';
	    }
	    return result;
	");
	runner.Assert("33. Try/Catch/Finally", _test33, "ACD");

	runner.Category("Constructors");

	var _test34 = gmlvm_run(@"
	    function Vector2(x, y) constructor {
	        self.x = x;
	        self.y = y;
        
	        self.length = function() {
	            return sqrt(x * x + y * y);
	        };
	    }
	    var v = new Vector2(3, 4);
	    return v.length();
	");
	runner.Assert("34. Constructor with method", _test34, 5);

	var _test35 = gmlvm_run(@"
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
    
	    var d = new Dog('Rex', 'German Shepherd');
	    return d.name + ' the ' + d.breed + ': ' + d.speak();
	");
	runner.Assert("35. Constructor inheritance", _test35, "Rex the German Shepherd: Rex barks!");

	runner.Category("Static Variables (Advanced)");

	var _test36 = gmlvm_run(@"
	    function createId() {
	        static nextId = 1000;
	        return nextId++;
	    }
	    var a = createId();
	    var b = createId();
	    var c = createId();
	    return string(a) + ',' + string(b) + ',' + string(c);
	");
	runner.Assert("36. Static counter", _test36, "1000,1001,1002");

	var _test37 = gmlvm_run(@"
	    function accumulator(start) {
	        static total = 0;
	        total += start;
	        return total;
	    }
	    accumulator(5);
	    accumulator(10);
	    return accumulator(15);
	");
	runner.Assert("37. Static accumulator", _test37, 30);

	runner.Category("Edge Cases");

	var _test38 = gmlvm_run(@"
	    return;
	");
	runner.Assert("38. Empty return", _test38, undefined);

	var _test39 = gmlvm_run(@"
	    var x;
	    return x;
	");
	runner.Assert("39. Uninitialized variable", _test39, undefined);

	var _test40 = gmlvm_run(@"
	    return 1 + undefined;
	");
	runner.Assert("40. Undefined in arithmetic", _test40, 1);

	runner.Category("Others");

	var _test41 = gmlvm_run(@"
	    var testArray = [ 2 ];
	    testArray[0]++;
	    return testArray;
	");
	runner.AssertArray("41. Array increment", _test41, 0, 3);

	var _test42 = gmlvm_run(@"
	    var obj = { value: 5 };
	    obj.value++;
	    return obj.value;
	");
	runner.Assert("42. Struct property increment", _test42, 6);

	var _test43 = gmlvm_run(@"
	    var i = 0;
	    var sum = 0;
	    do {
	        sum += i;
	        i++;
	    } until (i > 5);
	    return sum;
	");
	runner.Assert("43. Do/Until loop", _test43, 15);

	var _test44 = gmlvm_run(@"
	    var count = 0;
	    do {
	        count++;
	    } until (true);
	    return count;
	");
	runner.Assert("44. Do/Until executes once", _test44, 1);

	var _test45 = gmlvm_run(@"
	    var i = 0;
	    var sum = 0;
	    do {
	        if (i == 3) break;
	        sum += i;
	        i++;
	    } until (i > 10);
	    return sum;
	");
	runner.Assert("45. Break in do/until", _test45, 3);

	var _test46 = gmlvm_run(@"
	    var i = 0;
	    var sum = 0;
	    do {
	        i++;
	        if (i % 2 == 0) continue;
	        sum += i;
	    } until (i >= 5);
	    return sum;
	");
	runner.Assert("46. Continue in do/until", _test46, 9);

	runner.Category("Ternary Operator");

	var _test47 = gmlvm_run(@"
	    var x = 10;
	    return x > 5 ? 'big' : 'small';
	");
	runner.Assert("47. Ternary true", _test47, "big");

	var _test48 = gmlvm_run(@"
	    var x = 3;
	    return x > 5 ? 'big' : 'small';
	");
	runner.Assert("48. Ternary false", _test48, "small");

	runner.Category("With Statement");

	var _test49 = gmlvm_run(@"
	    var obj = { value: 10 };
	    with (obj) {
	        value *= 2;
	    }
	    return obj.value;
	");
	runner.Assert("49. With struct", _test49, 20);

	runner.Category("Compound Assignment");

	var _test50 = gmlvm_run(@"
	    var arr = [5];
	    arr[0] += 10;
	    return arr[0];
	");
	runner.Assert("50. Array compound assign", _test50, 15);

	var _test51 = gmlvm_run(@"
	    var obj = { val: 3 };
	    obj.val *= 4;
	    return obj.val;
	");
	runner.Assert("51. Struct compound assign", _test51, 12);

	runner.Category("Delete Operator");

	var _test52 = gmlvm_run(@"
	    var obj = { a: 1, b: 2, c: 3 };
	    delete obj.b;
	    return struct_exists(obj, 'b');
	");
	runner.Assert("52. Delete struct property", _test52, 0);

	var _test53 = gmlvm_run(@"
	    var arr = [10, 20, 30];
	    delete arr[1];
	    return string(arr[0]) + ',' + string(arr[1]);
	");
	runner.Assert("53. Delete array element", _test53, "10,30");

	runner.Category("Instanceof Operator");

	var _test54 = gmlvm_run(@"
	    function Animal() constructor {}
	    function Dog() : Animal() constructor {}
	    var d = new Dog();
	    return is_instanceof(d, Dog);
	");
	runner.Assert("54. is_instanceof direct", _test54, 1);

	var _test55 = gmlvm_run(@"
	    function Animal() constructor {}
	    function Dog() : Animal() constructor {}
	    var d = new Dog();
	    return is_instanceof(d, Animal);
	");
	runner.Assert("55. is_instanceof parent", _test55, 1);

	var _test55b = gmlvm_run(@"
	    function Animal() constructor {}
	    function Dog() : Animal() constructor {}
	    var d = new Dog();
	    return instanceof(d);
	");
	runner.Assert("55b. instanceof string", _test55b, "Dog");

	runner.Category("Typeof Operator");

	var _test56 = gmlvm_run(@"
	    return typeof(42);
	");
	runner.Assert("56. Typeof number", _test56, "number");

	var _test57 = gmlvm_run(@"
	    return typeof('hello');
	");
	runner.Assert("57. Typeof string", _test57, "string");

	var _test58 = gmlvm_run(@"
	    return typeof([1,2,3]);
	");
	runner.Assert("58. Typeof array", _test58, "array");

	var _test59 = gmlvm_run(@"
	    return typeof({ x: 10 });
	");
	runner.Assert("59. Typeof struct", _test59, "struct");

	var _test60 = gmlvm_run(@"
	    function test() {}
	    return typeof(test);
	");
	runner.Assert("60. Typeof function", _test60, "method");

	runner.Category("Bitwise Operators");

	var _test61 = gmlvm_run(@"
	    return 5 & 3;
	");
	runner.Assert("61. Bitwise AND", _test61, 1);

	var _test62 = gmlvm_run(@"
	    return 5 | 3;
	");
	runner.Assert("62. Bitwise OR", _test62, 7);

	var _test63 = gmlvm_run(@"
	    return 5 ^ 3;
	");
	runner.Assert("63. Bitwise XOR", _test63, 6);

	var _test64 = gmlvm_run(@"
	    return ~5;
	");
	runner.Assert("64. Bitwise NOT", _test64, -6);

	var _test65 = gmlvm_run(@"
	    return 1 << 3;
	");
	runner.Assert("65. Left shift", _test65, 8);

	var _test66 = gmlvm_run(@"
	    return 16 >> 2;
	");
	runner.Assert("66. Right shift", _test66, 4);

	var _test67 = gmlvm_run(@"
	    var x = 5;
	    x &= 3;
	    return x;
	");
	runner.Assert("67. Bitwise AND assign", _test67, 1);

	runner.Category("Nullish Operators");

	var _test68 = gmlvm_run(@"
	    var x = undefined;
	    return x ?? 42;
	");
	runner.Assert("68. Nullish coalesce undefined", _test68, 42);

	var _test69 = gmlvm_run(@"
	    var x = 10;
	    return x ?? 42;
	");
	runner.Assert("69. Nullish coalesce defined", _test69, 10);

	var _test70 = gmlvm_run(@"
	    var x = undefined;
	    x ?= 100;
	    return x;
	");
	runner.Assert("70. Nullish assign undefined", _test70, 100);

	var _test71 = gmlvm_run(@"
	    var x = 50;
	    x ?= 100;
	    return x;
	");
	runner.Assert("71. Nullish assign defined", _test71, 50);

	runner.Category("With Statement on Instances");

	var wakeup = string(Object2);
	var _test72 = gmlvm_run(@"
	    var inst = instance_create_depth(0, 0, 0, Object2);
	    inst.value = 42;
    
	    result = 0;
	    with (inst) {
	        other.result = value * 2;
	    }
    
	    instance_destroy(inst);
	    return result;
	");
	runner.Assert("72. With on instance", _test72, 84);

	var _test73 = gmlvm_run(@"
	    var inst = instance_create_depth(0, 0, 0, Object2);
    
	    var result = '';
	    with (Object2) {
	        result += 'A';
	    }
    
	    instance_destroy(inst);
	    return result;
	");
	runner.Assert("73. With on object", _test73, "A");

	var _test74 = gmlvm_run(@"
	    var inst1 = instance_create_depth(0, 0, 0, Object2);
	    var inst2 = instance_create_depth(0, 0, 0, Object2);
	    var inst3 = instance_create_depth(0, 0, 0, Object2);
    
	    var count = 0;
	    with (Object2) {
	        count++;
	    }
	    return count;
	");
	runner.Assert("74. With on object (multiple)", _test74, 3);

	runner.Category("Global Dot Operator");

	var _test75 = gmlvm_run(@"
	    global.test_var = 42;
	    return global.test_var;
	");
	runner.Assert("75. Global dot access", _test75, 42);

	var _test76 = gmlvm_run(@"
	    global.obj = { value: 100 };
	    return global.obj.value;
	");
	runner.Assert("76. Global dot nested", _test76, 100);

	runner.Category("Self and Other in With");

	var _test77 = gmlvm_run(@"
	    var obj = { value: 10 };
	    var result = 0;
	    with (obj) {
	        self.new_value = 20;
	        result = value;
	    }
	    return result;
	");
	runner.Assert("77. Self in with (struct)", _test77, 10);

	var _test78 = gmlvm_run(@"
	    _x = 5;
	    var inner = { y: 10 };
	    var result = 0;
	    with (inner) {
	        result = other._x + self.y;
	    }
	    return result;
	");
	runner.Assert("78. Other in with", _test78, 15);

	var _test79 = gmlvm_run(@"
	    var inst = instance_create_depth(0, 0, 0, Object2);
	    inst.value = 30;
	    outer_value = 40;
	    var result = 0;
	    with (inst) {
	        result = value + other.outer_value;
	    }
	    instance_destroy(inst);
	    return result;
	");
	runner.Assert("79. Other with instance", _test79, 70);

	runner.Category("Accessors");

	var _test80 = gmlvm_run(@"
	    var arr = [10, 20, 30];
	    return arr[@ 1];
	");
	runner.Assert("80. Array accessor", _test80, 20);

	var _test81 = gmlvm_run(@"
	    var obj = { a: 100, b: 200 };
	    return obj[$ 'b'];
	");
	runner.Assert("81. Struct accessor", _test81, 200);

	var _test82 = gmlvm_run(@"
	    var map = ds_map_create();
	    ds_map_set(map, 'key', 42);
	    var val = map[? 'key'];
	    ds_map_destroy(map);
	    return val;
	");
	runner.Assert("82. Map accessor", _test82, 42);

	runner.Category("Macros");

	var _test83 = gmlvm_run(@"
	    #macro WIDTH 640
	    #macro HEIGHT 480
	    #macro TITLE 'Game'
	    return WIDTH;
	");
	runner.Assert("83. Macro number", _test83, 640);

	var _test84 = gmlvm_run(@"
	    #macro PI 3.14159
	    #macro TAU (PI * 2)
	    return TAU;
	");
	runner.Assert("84. Macro expression", _test84, 3.14159 * 2);

	runner.Category("Enums");

	var _test85 = gmlvm_run(@"
	    enum Color {
	        Red,
	        Green,
	        Blue
	    }
	    return Color.Red;
	");
	runner.Assert("85. Enum first value", _test85, 0);

	var _test86 = gmlvm_run(@"
	    enum Color {
	        Red,
	        Green,
	        Blue
	    }
	    return Color.Blue;
	");
	runner.Assert("86. Enum auto increment", _test86, 2);

	var _test87 = gmlvm_run(@"
	    enum Values {
	        A = 10,
	        B = 20,
	        C = 30
	    }
	    return Values.B;
	");
	runner.Assert("87. Enum explicit values", _test87, 20);

	runner.Category("Var Multiple Declarations");

	var _test88 = gmlvm_run(@"
	    var a = 1, b = 2, c = 3;
	    return a + b + c;
	");
	runner.Assert("88. Var multiple", _test88, 6);

	runner.Category("Optional Arguments");

	var _test89 = gmlvm_run(@"
	    function greet(name = 'Guest') {
	        return 'Hello, ' + name;
	    }
	    return greet();
	");
	runner.Assert("90. Optional arg default", _test89, "Hello, Guest");

	var _test90 = gmlvm_run(@"
	    function greet(name = 'Guest') {
	        return 'Hello, ' + name;
	    }
	    return greet('Alice');
	");
	runner.Assert("91. Optional arg override", _test90, "Hello, Alice");

	var _test91 = gmlvm_run(@"
	    function add(a, b = 10) {
	        return a + b;
	    }
	    return add(5);
	");
	runner.Assert("92. Optional arg second param", _test91, 15);

	runner.Category("Template Strings");

	var _test93 = gmlvm_run(@"
	    var name = 'Alice';
	    return $'Hello {name}!';
	");
	runner.Assert("93. Template string", _test93, "Hello Alice!");

	var _test94 = gmlvm_run(@"
	    var x = 10;
	    var y = 20;
	    return $'{x} + {y} = {x + y}';
	");
	runner.Assert("94. Template string expressions", _test94, "10 + 20 = 30");

	runner.Category("Multi-line Strings");

	var _test95 = gmlvm_run(@"
	    var text = @'Line 1
Line 2
Line 3';
	    return text;
	");
	runner.Assert("95. Multi-line string", _test95, "Line 1\nLine 2\nLine 3");

	var _test96 = gmlvm_run(@"
	    var text = @'He said ''Hello'' to me';
	    return text;
	");
	runner.Assert("96. Multi-line with quotes", _test96, "He said 'Hello' to me");

	runner.Category("DS Map/List Literals");

	var _test97 = gmlvm_run(@"
	    var map = ds_map_create();
	    map[? 'name'] = 'Alice';
	    return map[? 'name'];
	");
	runner.Assert("97. Map literal", _test97, "Alice");

	var _test98 = gmlvm_run(@"
	    var list = ds_list_create();
	    ds_list_add(list, 10);
	    ds_list_add(list, 20);
	    return list[| 1];
	");
	runner.Assert("98. List literal", _test98, 20);

	runner.Category("Exit Statement");

	var _test99 = gmlvm_run(@"
	    var result = 0;
	    exit;
	    result = 42;
	    return result;
	");
	runner.Assert("99. Exit statement", _test99, undefined);

	var _test100 = gmlvm_run(@"
	    function foo() {
	        exit;
	        return 42;
	    }
	    return foo();
	");
	runner.Assert("100. Exit in function", _test100, undefined);

	runner.Summary();
}