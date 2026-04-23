file_read = function(_path) {
    if (!file_exists(_path)) {
        return "";
    }

    var file = file_text_open_read(_path);
    var content = "";

    while (!file_text_eof(file)) {
        content += file_text_read_string(file);
        
        if (!file_text_eof(file)) {
            content += "\n";
        }

        file_text_readln(file);
    }

    file_text_close(file);

    return content;
};

gmlvm_init();

create_parse = gmlvm_parse_only(file_read("oTest_Create.gml"));
step_parse = gmlvm_parse_only(file_read("oTest_Step.gml"));
draw_parse = gmlvm_parse_only(file_read("oTest_Draw.gml"));

gmlvm_vm(create_parse, self);

RunTests();

/*
╔══════════════════════════════════════════════════════════════════╗
║                         TEST SUMMARY                             ║
╠══════════════════════════════════════════════════════════════════╣
║  Total:  100                                                     ║
║  Passed: 100                                                     ║
║  Failed: 0                                                       ║
╠══════════════════════════════════════════════════════════════════╣
║                        ALL TESTS PASSED!                         ║
╚══════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════╗
║                       GMLVM Runtime Error                        ║
╠══════════════════════════════════════════════════════════════════╣
║  [RuntimeError] Function 'find_enemy' is not defined             ║
║                                                                  ║
║  at line 4, column 14 in "<script>"                              ║
║                                                                  ║
║      2 | var spd = 5;                                            ║
║      3 | var hp = 100;                                           ║
║  >   4 | var target = find_enemy();                              ║
║                       ^^^^^^^^^^                                 ║
║      5 |                                                         ║
║      6 | // Bug: typo in variable name                           ║
║                                                                  ║
║  The function 'find_enemy' is not defined in this scope.         ║
║                                                                  ║
║  Stack trace (most recent first):                                ║
║    at <script> (line 4, column 14)                               ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════╗
║  GMLVM Runtime Error                                         ║
╠══════════════════════════════════════════════════════════════╣
║  [ErrorType] Error message                                   ║
║                                                              ║
║  at line 5, column 12 in "player_script"                     ║
║                                                              ║
║    3 | var spd = 5;                                          ║
║    4 | var hp = 100;                                         ║
║  > 5 | x += spd * unknown_var;                               ║
║              ^^^^^^^^^^^^                                    ║
║                                                              ║
║  Variable 'unknown_var' not defined                          ║
║                                                              ║
║  Stack trace (most recent first):                            ║
║    at update_position (line 12, column 3)                    ║
║    at step_event (line 25, column 1)                         ║
║    at main (line 30, column 1)                               ║
╚══════════════════════════════════════════════════════════════╝
*/

show_debug_message("=== Error Test ===");
var _testError = gmlvm_run(@"
var spd = 5;
var hp = 100;
var target = find_enemy();

// Bug: typo in variable name
x += spd * target.speedd;

if (hp < 0) {
    destroy();
}
");



