/*
todo; add do/until and with statements
*/

gmlvm_init();

show_debug_message("=== Basic Arithmetic and Precedence ===");
var _test1 = gmlvm_run(@"
return 2 + 3 * 4;
");
show_debug_message("1. Arithmetic precedence: " + string(_test1) + " (expected 14)");

var _test2 = gmlvm_run(@"
return (2 + 3) * 4;
");
show_debug_message("2. Parentheses: " + string(_test2) + " (expected 20)");

var _test3 = gmlvm_run(@"
return 10 / 3;
");
show_debug_message("3. Division: " + string(_test3) + " (expected 3.33...)");

var _test4 = gmlvm_run(@"
return 10 % 3;
");
show_debug_message("4. Modulo: " + string(_test4) + " (expected 1)");

show_debug_message("=== String Operations ===");
var _test5 = gmlvm_run(@"
return 'Hello' + ' ' + 'World';
");
show_debug_message("5. String concatenation: " + string(_test5) + " (expected Hello World)");

var _test6 = gmlvm_run(@"
var name = 'Player';
return 'Welcome, ' + name + '!';
");
show_debug_message("6. String with variable: " + string(_test6) + " (expected Welcome, Player!)");

show_debug_message("=== Comparison and Logical OperatorsComparison and Logical Operators ===");
var _test7 = gmlvm_run(@"
return 5 > 3;
");
show_debug_message("7. Greater than: " + string(_test7) + " (expected 1)");

var _test8 = gmlvm_run(@"
return 5 == 5 && 3 < 10;
");
show_debug_message("8. Logical AND: " + string(_test8) + " (expected 1)");

var _test9 = gmlvm_run(@"
return 5 == 3 || 10 > 5;
");
show_debug_message("9. Logical OR: " + string(_test9) + " (expected 1)");

var _test10 = gmlvm_run(@"
return !(5 == 3);
");
show_debug_message("10. Logical NOT: " + string(_test10) + " (expected 1)");

show_debug_message("=== If/Else Statements ===");
var _test11 = gmlvm_run(@"
var x = 15;
if (x > 10) {
    return 'big';
} else {
    return 'small';
}
");
show_debug_message("11. If/Else true branch: " + string(_test11) + " (expected big)");

var _test12 = gmlvm_run(@"
var x = 5;
if (x > 10) {
    return 'big';
} else {
    return 'small';
}
");
show_debug_message("12. If/Else false branch: " + string(_test12) + " (expected small)");

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
show_debug_message("13. Else-if chain: " + string(_test13) + " (expected B)");

show_debug_message("=== While Loops ===");
var _test14 = gmlvm_run(@"
var sum = 0;
var i = 1;
while (i <= 5) {
    sum += i;
    i += 1;
}
return sum;
");
show_debug_message("14. While loop sum: " + string(_test14) + " (expected 15)");

var _test15 = gmlvm_run(@"
var i = 10;
var result = '';
while (i > 0) {
    result += string(i) + ' ';
    i -= 2;
}
return result;
");
show_debug_message("15. While countdown: " + string(_test15) + " (expected 10 8 6 4 2 )");

show_debug_message("=== For Loops ===");
var _test16 = gmlvm_run(@"
var sum = 0;
for (var i = 1; i <= 5; i++) {
    sum += i;
}
return sum;
");
show_debug_message("16. For loop sum: " + string(_test16) + " (expected 15)");

var _test17 = gmlvm_run(@"
var result = '';
for (var i = 0; i < 5; i++) {
    result += string(i) + ',';
}
return result;
");
show_debug_message("17. For loop string: " + string(_test17) + " (expected 0,1,2,3,4,)");

var _test18 = gmlvm_run(@"
for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 2; j++) {
        // nested loop
    }
}
return i * j;
");
show_debug_message("18. Nested loops: " + string(_test18) + " (expected 6)");

show_debug_message("=== Break and Continue ===");
var _test19 = gmlvm_run(@"
var sum = 0;
for (var i = 1; i <= 10; i++) {
    if (i == 6) break;
    sum += i;
}
return sum;
");
show_debug_message("19. Break: " + string(_test19) + " (expected 15)");

var _test20 = gmlvm_run(@"
var sum = 0;
for (var i = 1; i <= 5; i++) {
    if (i == 3) continue;
    sum += i;
}
return sum;
");
show_debug_message("20. Continue: " + string(_test20) + " (expected 12)");

show_debug_message("=== Arrays ===");
var _test21 = gmlvm_run(@"
var arr = [10, 20, 30, 40, 50];
return arr[2];
");
show_debug_message("21. Array access: " + string(_test21) + " (expected 30)");

var _test22 = gmlvm_run(@"
var arr = [1, 2, 3];
arr[1] = 99;
return arr[0] + arr[1] + arr[2];
");
show_debug_message("22. Array assignment: " + string(_test22) + " (expected 103)");

var _test23 = gmlvm_run(@"
var arr = [];
for (var i = 0; i < 5; i++) {
    arr[i] = i * 10;
}
return arr[3];
");
show_debug_message("23. Array in loop: " + string(_test23) + " (expected 30)");

show_debug_message("=== Structs ===");
var _test24 = gmlvm_run(@"
var player = {
    name: 'Hero',
    hp: 100,
    max_hp: 100
};
return player.name;
");
show_debug_message("24. Struct property access: " + string(_test24) + " (expected Hero)");

var _test25 = gmlvm_run(@"
var player = { name: 'Hero', hp: 100 };
player.hp -= 20;
return player.hp;
");
show_debug_message("25. Struct property modification: " + string(_test25) + " (expected 80)");

var _test26 = gmlvm_run(@"
var obj = {
    x: 10,
    y: 20
};
return obj.x + obj.y;
");
show_debug_message("26. Struct shorthand: " + string(_test26) + " (expected 30)");

show_debug_message("=== Functions ===");
var _test27 = gmlvm_run(@"
function greet(name) {
    return 'Hello, ' + name + '!';
}
return greet('World');
");
show_debug_message("27. Function call: " + string(_test27) + " (expected Hello, World!)");

var _test28 = gmlvm_run(@"
function factorial(n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}
return factorial(5);
");
show_debug_message("28. Recursion: " + string(_test28) + " (expected 120)");

var _test29 = gmlvm_run(@"
function makeAdder(x) {
    return function(y) {
        return x + y;
    };
}
var add5 = makeAdder(5);
return add5(10);
");
show_debug_message("29. Closure: " + string(_test29) + " (expected 15)");

show_debug_message("=== Switch Statement ===");
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
show_debug_message("30. Switch case: " + string(_test30) + " (expected red)");

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
show_debug_message("31. Switch fallthrough: " + string(_test31) + " (expected BC)");

show_debug_message("=== Try/Catch/Throw ===");
var _test32 = gmlvm_run(@"
try {
    throw 'oops';
} catch (e) {
    return 'Caught: ' + e;
}
");
show_debug_message("32. Try/Catch: " + string(_test32) + " (expected Caught: oops)");

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
show_debug_message("33. Try/Catch/Finally: " + string(_test33) + " (expected ACD)");

show_debug_message("=== Constructors ===");
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
show_debug_message("34. Constructor with method: " + string(_test34) + " (expected 5)");

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
show_debug_message("35. Constructor inheritance: " + string(_test35) + " (expected Rex the German Shepherd: Rex barks!)");

show_debug_message("=== Static Variables (Advanced) ===");
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
show_debug_message("36. Static counter: " + string(_test36) + " (expected 1000,1001,1002)");

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
show_debug_message("37. Static accumulator: " + string(_test37) + " (expected 30)");

show_debug_message("=== Edge Cases ===");
var _test38 = gmlvm_run(@"
return;
");
show_debug_message("38. Empty return: " + string(_test38) + " (expected undefined)");

var _test39 = gmlvm_run(@"
var x;
return x;
");
show_debug_message("39. Uninitialized variable: " + string(_test39) + " (expected undefined)");

var _test40 = gmlvm_run(@"
return 1 + undefined;
");
show_debug_message("40. Undefined in arithmetic: " + string(_test40) + " (expected 1)");

show_debug_message("=== Others ===");
// Test array increment
var _test41 = gmlvm_run(@"
var testArray = [ 2 ];
testArray[0]++;
return testArray;
");
show_debug_message("41. Array increment: " + string(_test41[0]) + " (expected 3)");

// Test struct property increment
var _test42 = gmlvm_run(@"
var obj = { value: 5 };
obj.value++;
return obj.value;
");
show_debug_message("42. Struct property increment: " + string(_test42) + " (expected 6)");

// Test do/until
var _test43 = gmlvm_run(@"
var i = 0;
var sum = 0;
do {
    sum += i;
    i++;
} until (i > 5);
return sum;
");
show_debug_message("43. Do/Until loop: " + string(_test43) + " (expected 15)");

// Test do/until executes at least once
var _test44 = gmlvm_run(@"
var count = 0;
do {
    count++;
} until (true);
return count;
");
show_debug_message("44. Do/Until executes once: " + string(_test44) + " (expected 1)");

// Test break in do/until
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
show_debug_message("45. Break in do/until: " + string(_test45) + " (expected 3)");

// Test continue in do/until
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
show_debug_message("46. Continue in do/until: " + string(_test46) + " (expected 9)");

show_debug_message("=== Ternary Operator ===");
var _test47 = gmlvm_run(@"
var x = 10;
return x > 5 ? 'big' : 'small';
");
show_debug_message("47. Ternary true: " + string(_test47) + " (expected big)");

var _test48 = gmlvm_run(@"
var x = 3;
return x > 5 ? 'big' : 'small';
");
show_debug_message("48. Ternary false: " + string(_test48) + " (expected small)");

show_debug_message("=== With Statement ===");
var _test49 = gmlvm_run(@"
var obj = { value: 10 };
with (obj) {
    value *= 2;
}
return obj.value;
");
show_debug_message("49. With struct: " + string(_test49) + " (expected 20)");

show_debug_message("=== Compound Assignment ===");
var _test50 = gmlvm_run(@"
var arr = [5];
arr[0] += 10;
return arr[0];
");
show_debug_message("50. Array compound assign: " + string(_test50) + " (expected 15)");

var _test51 = gmlvm_run(@"
var obj = { val: 3 };
obj.val *= 4;
return obj.val;
");
show_debug_message("51. Struct compound assign: " + string(_test51) + " (expected 12)");

show_debug_message("=== Delete Operator ===");
var _test52 = gmlvm_run(@"
var obj = { a: 1, b: 2, c: 3 };
delete obj.b;
return struct_exists(obj, 'b');
");
show_debug_message("52. Delete struct property: " + string(_test52) + " (expected 0)");

var _test53 = gmlvm_run(@"
var arr = [10, 20, 30];
delete arr[1];
return string(arr[0]) + ',' + string(arr[1]);
");
show_debug_message("53. Delete array element: " + string(_test53) + " (expected 10,30)");

show_debug_message("=== Instanceof Operator ===");
var _test54 = gmlvm_run(@"
function Animal() constructor {}
function Dog() : Animal() constructor {}
var d = new Dog();
return is_instanceof(d, Dog);
");
show_debug_message("54. is_instanceof direct: " + string(_test54) + " (expected 1)");

var _test55 = gmlvm_run(@"
function Animal() constructor {}
function Dog() : Animal() constructor {}
var d = new Dog();
return is_instanceof(d, Animal);
");
show_debug_message("55. is_instanceof parent: " + string(_test55) + " (expected 1)");

var _test55b = gmlvm_run(@"
function Animal() constructor {}
function Dog() : Animal() constructor {}
var d = new Dog();
return instanceof(d);
");
show_debug_message("55b. instanceof string: " + string(_test55b) + " (expected Dog)");

show_debug_message("=== Typeof Operator ===");
var _test56 = gmlvm_run(@"
return typeof(42);
");
show_debug_message("56. Typeof number: " + string(_test56) + " (expected number)");

var _test57 = gmlvm_run(@"
return typeof('hello');
");
show_debug_message("57. Typeof string: " + string(_test57) + " (expected string)");

var _test58 = gmlvm_run(@"
return typeof([1,2,3]);
");
show_debug_message("58. Typeof array: " + string(_test58) + " (expected array)");

var _test59 = gmlvm_run(@"
return typeof({ x: 10 });
");
show_debug_message("59. Typeof struct: " + string(_test59) + " (expected struct)");

var _test60 = gmlvm_run(@"
function test() {}
return typeof(test);
");
show_debug_message("60. Typeof function: " + string(_test60) + " (expected method)");

show_debug_message("=== Bitwise Operators ===");
var _test61 = gmlvm_run(@"
return 5 & 3;
");
show_debug_message("61. Bitwise AND: " + string(_test61) + " (expected 1)");

var _test62 = gmlvm_run(@"
return 5 | 3;
");
show_debug_message("62. Bitwise OR: " + string(_test62) + " (expected 7)");

var _test63 = gmlvm_run(@"
return 5 ^ 3;
");
show_debug_message("63. Bitwise XOR: " + string(_test63) + " (expected 6)");

var _test64 = gmlvm_run(@"
return ~5;
");
show_debug_message("64. Bitwise NOT: " + string(_test64) + " (expected -6)");

var _test65 = gmlvm_run(@"
return 1 << 3;
");
show_debug_message("65. Left shift: " + string(_test65) + " (expected 8)");

var _test66 = gmlvm_run(@"
return 16 >> 2;
");
show_debug_message("66. Right shift: " + string(_test66) + " (expected 4)");

var _test67 = gmlvm_run(@"
var x = 5;
x &= 3;
return x;
");
show_debug_message("67. Bitwise AND assign: " + string(_test67) + " (expected 1)");

// Test bitwise operators with simpler expressions
var _test_bitwise = gmlvm_run(@"
var a = 5;
var b = 3;
return a & b;
");
show_debug_message("Bitwise AND simple: " + string(_test_bitwise) + " (expected 1)");

show_debug_message("=== Nullish Operators ===");
var _test68 = gmlvm_run(@"
var x = undefined;
return x ?? 42;
");
show_debug_message("68. Nullish coalesce undefined: " + string(_test68) + " (expected 42)");

var _test69 = gmlvm_run(@"
var x = 10;
return x ?? 42;
");
show_debug_message("69. Nullish coalesce defined: " + string(_test69) + " (expected 10)");

var _test70 = gmlvm_run(@"
var x = undefined;
x ?= 100;
return x;
");
show_debug_message("70. Nullish assign undefined: " + string(_test70) + " (expected 100)");

var _test71 = gmlvm_run(@"
var x = 50;
x ?= 100;
return x;
");
show_debug_message("71. Nullish assign defined: " + string(_test71) + " (expected 50)");


















