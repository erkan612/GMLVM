/*********************************************************************************************
*                                        MIT License                                         *
*--------------------------------------------------------------------------------------------*
* Copyright (c) 2026 erkan612                                                                *
*                                                                                            *
* Permission is hereby granted, free of charge, to any person obtaining a copy of this       *
* software and associated documentation files (the "Software"), to deal in the Software      *
* without restriction, including without limitation the rights to use, copy, modify, merge,  *
* publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons *
* to whom the Software is furnished to do so, subject to the following conditions:           *
*                                                                                            *
* The above copyright notice and this permission notice shall be included in all copies or   *
* substantial portions of the Software.                                                      *
*                                                                                            *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,        *
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR   *
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE  *
* FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       *
* OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     *
* DEALINGS IN THE SOFTWARE.                                                                  *
**********************************************************************************************
*--------------------------------------------------------------------------------------------*
*   					***********************************************                      *
*   			         ██████╗ ███╗   ███╗██╗    ██╗   ██╗███╗   ███╗		                 *
*   			        ██╔════╝ ████╗ ████║██║    ██║   ██║████╗ ████║		                 *
*   			        ██║  ███╗██╔████╔██║██║    ██║   ██║██╔████╔██║		                 *
*   			        ██║   ██║██║╚██╔╝██║██║    ╚██╗ ██╔╝██║╚██╔╝██║		                 *
*   			        ╚██████╔╝██║ ╚═╝ ██║███████╗╚████╔╝ ██║ ╚═╝ ██║		                 *
*   			         ╚═════╝ ╚═╝     ╚═╝╚══════╝ ╚═══╝  ╚═╝     ╚═╝		                 *
*   						       GameMaker Virtual Machine								 *
*   						           Version 1.0.0										 *
*   																                         *
*   						            by erkan612					                         *
*   						=======================================	                         *
*   									A GML Interpreter									 *
*   						              for GameMaker				                         *
*   						=======================================	                         *
*   					***********************************************                      *
*********************************************************************************************/

function gmlvm_init() {
	global.__gmlvm_last_error = undefined;
	global.__gmlvm_static_registry = {};
	global.__gmlvm_warnings = { // TODO: add more warnings
	    undefined_binary_left: true,
	    undefined_binary_right: true,
	    undefined_unary: true,
	    unknown_operator: true,
	    cannot_call: true,
	    parse_error: true
	};
	global.__gmlvm_warning_collector = new gmlvm_warning_collector();
	global.__gmlvm_ast_cache = new gmlvm_cache();
	global.__gmlvm_call_stack = [ ];
	global.__gmlvm_error_formatter = gmlvm_error_formatter;
}

function gmlvm_push_call_stack(_name, _line) {
    array_push(global.__gmlvm_call_stack, {
        name: _name,
        line: _line
    });
}

function gmlvm_pop_call_stack() {
    if (array_length(global.__gmlvm_call_stack) > 0) {
        array_pop(global.__gmlvm_call_stack);
    }
}

function gmlvm_create_error(_type, _message, _line, _column, _token_length) {
    if (_token_length == undefined) _token_length = 1;
    
    var _stack = [];
    if (struct_exists(global, "__gmlvm_call_stack")) {
        var _call_stack = global.__gmlvm_call_stack;
        for (var i = array_length(_call_stack) - 1; i >= 0; i--) {
            array_push(_stack, _call_stack[i]);
        }
    }
    
    array_push(_stack, {
        name: "<script>",
        line: _line,
        column: _column
    });
    
    return {
        type: _type,
        message: _message,
        line: _line,
        column: _column,
        token_length: _token_length,
        source: "",
        source_name: "<script>",
        stack_trace: _stack,
        
        toString: function() {
            var _output = "\n";
            var _box_width = 68;
            
            // top border
            _output += "╔" + string_repeat("═", _box_width - 2) + "╗\n";
            
            // header
            var _header = "  GMLVM " + ((type == "parse_error") ? "Parse Error" : "Runtime Error") + "  ";
            var _header_padding = _box_width - string_length(_header) - 2;
            var _left_pad = floor(_header_padding / 2);
            var _right_pad = _header_padding - _left_pad;
            _output += "║" + string_repeat(" ", _left_pad) + _header + string_repeat(" ", _right_pad) + "║\n";
            
            // separator
            _output += "╠" + string_repeat("═", _box_width - 2) + "╣\n";
            
            // error type and message
            var _error_type_str = "  [" + ((type == "parse_error") ? "ParseError" : "RuntimeError") + "] " + message;
            var _msg_lines = string_wrap(_error_type_str, _box_width - 6);
            for (var i = 0; i < array_length(_msg_lines); i++) {
                _output += "║  " + string_pad_right(_msg_lines[i], _box_width - 6) + "  ║\n";
            }
            _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
            
            // location
            if (line >= 0) {
                var _loc_str = "at line " + string(line);
                if (column >= 0) _loc_str += ", column " + string(column);
                if (source_name != "") _loc_str += " in \"" + source_name + "\"";
                _output += "║  " + string_pad_right(_loc_str, _box_width - 6) + "  ║\n";
                _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
            }
            
            // source context
            if (source != "" && line >= 0) {
                var _lines = string_split(source, "\n");
                var _start = max(0, line - 3);
                var _end = min(array_length(_lines), line + 2);
                
                for (var i = _start; i < _end; i++) {
                    var _line_num = string(i + 1);
                    var _prefix = (i == line - 1) ? "> " : "  ";
                    var _line_content = _lines[i];
                    
                    _line_content = string_replace_all(_line_content, "\r", "");
                    
                    var _display_line = _prefix + string_pad_left(_line_num, 3) + " | " + _line_content;
                    
                    var _max_len = _box_width - 6;
                    if (string_length(_display_line) > _max_len) {
                        _display_line = string_copy(_display_line, 1, _max_len - 3) + "...";
                    }
                    
                    _output += "║  " + string_pad_right(_display_line, _max_len) + "  ║\n";
                    
                    if (i == line - 1 && column >= 0) {
                        var _indent = string_length(_prefix) + 3 + 3; // prefix + line num + " | "
                        var _underline = string_repeat(" ", _indent + column - 1) + string_repeat("^", token_length);
                        if (string_length(_underline) > _max_len) {
                            _underline = string_copy(_underline, 1, _max_len);
                        }
                        _output += "║  " + string_pad_right(_underline, _max_len) + "  ║\n";
                    }
                }
                _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
            }
            
            // explanation
            var _explanation = "";
            if (string_pos("not defined", message) > 0 || string_pos("does not exist", message) > 0) {
                if (string_pos("Function", message) > 0 || string_pos("function", message) > 0) {
                    _explanation = "The function '" + extract_name(message) + "' is not defined in this scope.";
                } else if (string_pos("Variable", message) > 0) {
                    _explanation = "The variable '" + extract_name(message) + "' is not defined in this scope.";
                } else {
                    _explanation = "The identifier '" + extract_name(message) + "' could not be found.";
                }
            } else if (string_pos("Cannot call", message) > 0) {
                _explanation = "You are trying to call something that is not a function.";
            } else if (string_pos("out of bounds", message) > 0) {
                _explanation = "The index you are trying to access is outside the valid range.";
            } else if (string_pos("read-only", message) > 0) {
                _explanation = "This property cannot be modified.";
            } else if (string_pos("Sandbox", message) > 0) {
                _explanation = "This operation is restricted by the sandbox security settings.";
            } else {
                _explanation = message;
            }
            
            if (_explanation != "") {
                var _exp_lines = string_wrap(_explanation, _box_width - 6);
                for (var i = 0; i < array_length(_exp_lines); i++) {
                    _output += "║  " + string_pad_right(_exp_lines[i], _box_width - 6) + "  ║\n";
                }
                _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
            }
            
            // stack trace
            if (array_length(stack_trace) > 0) {
                _output += "║  Stack trace (most recent first):" + string_repeat(" ", _box_width - 38) + "  ║\n";
                var _count = min(array_length(stack_trace), 5);
                for (var i = 0; i < _count; i++) {
                    var _frame = stack_trace[i];
                    var _frame_str = "  at " + _frame.name;
                    if (_frame.line >= 0) {
                        _frame_str += " (line " + string(_frame.line);
                        if (_frame.column >= 0) _frame_str += ", column " + string(_frame.column);
                        _frame_str += ")";
                    }
                    if (string_length(_frame_str) > _box_width - 6) {
                        _frame_str = string_copy(_frame_str, 1, _box_width - 9) + "...";
                    }
                    _output += "║  " + string_pad_right(_frame_str, _box_width - 6) + "  ║\n";
                }
                if (array_length(stack_trace) > 5) {
                    var _remaining = array_length(stack_trace) - 5;
                    var _rem_str = "... and " + string(_remaining) + " more frame(s)";
                    _output += "║  " + string_pad_right(_rem_str, _box_width - 6) + "  ║\n";
                }
                _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
            }
            
            // bottom border
            _output += "╚" + string_repeat("═", _box_width - 2) + "╝";
            
            return _output;
        }
    };
}

function extract_name(_msg) {
    var _start = string_pos("'", _msg);
    if (_start == 0) return "unknown";
    _start++;
    var _end = string_pos("'", string_copy(_msg, _start, string_length(_msg)));
    if (_end == 0) return "unknown";
    return string_copy(_msg, _start, _end - 1);
}

//function gmlvm_create_error(_type, _message, _line, _column, _source_name = "<script>") {
//    return {
//        type: _type,
//        message: _message,
//        line: _line,
//        column: _column,
//        source: "",
//        source_name: _source_name,
//        stack_trace: [],
//        
//        toString: function() {
//		    var _output = "";
//		    var _box_width = 68;
//    
//		    // top border
//		    _output += "╔" + string_repeat("═", _box_width - 2) + "╗\n";
//    
//		    // header
//		    var _header = "  GMLVM " + ((type == "parse_error") ? "Parse Error" : "Runtime Error") + "  ";
//		    var _header_padding = _box_width - string_length(_header) - 2;
//		    var _left_pad = floor(_header_padding / 2);
//		    var _right_pad = _header_padding - _left_pad;
//		    _output += "║" + string_repeat(" ", _left_pad) + _header + string_repeat(" ", _right_pad) + "║\n";
//    
//		    // separator
//		    _output += "╠" + string_repeat("═", _box_width - 2) + "╣\n";
//    
//		    // rrror type and message
//			var _error_type_str = "[" + ((type == "parse_error") ? "ParseError" : "RuntimeError") + "] " + message;
//			var _msg_lines = string_wrap(_error_type_str, _box_width - 6);
//			for (var i = 0; i < array_length(_msg_lines); i++) {
//			    _output += "║  " + string_pad_right(_msg_lines[i], _box_width - 6) + "  ║\n";
//			}
//			_output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
//    
//		    // location
//		    if (line >= 0) {
//		        var _loc_str = "  at line " + string(line);
//		        if (column >= 0) _loc_str += ", column " + string(column);
//		        if (source_name != "") _loc_str += " in \"" + source_name + "\"";
//		        _output += "║ " + string_pad_right(_loc_str, _box_width - 4) + " ║\n";
//		        _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
//		    }
//    
//		    // source context
//			if (source != "" && line >= 0) {
//			    var _lines = string_split(source, "\n");
//			    var _start = max(0, line - 3);
//			    var _end = min(array_length(_lines), line + 2);
//    
//			    for (var i = _start; i < _end; i++) {
//			        var _line_num = string(i + 1);
//			        var _prefix = (i == line - 1) ? "> " : "  ";
//			        var _line_content = _lines[i];
//        
//			        _line_content = string_replace_all(_line_content, "\r", "");
//        
//			        var _display_line = _prefix + string_pad_left(_line_num, 3) + " | " + _line_content;
//        
//			        var _max_len = _box_width - 6;
//			        if (string_length(_display_line) > _max_len) {
//			            _display_line = string_copy(_display_line, 1, _max_len - 3) + "...";
//			        }
//        
//			        _output += "║  " + string_pad_right(_display_line, _max_len) + "  ║\n";
//        
//			        if (i == line - 1 && column >= 0) {
//			            var _indent = string_length(_prefix) + 3 + 3; // prefix + line num + " | "
//			            var _indicator = string_repeat(" ", _indent + column - 1) + "^";
//			            if (string_length(_indicator) > _max_len) {
//			                _indicator = string_repeat(" ", _indent) + "^";
//			            }
//			            _output += "║  " + string_pad_right(_indicator, _max_len) + "  ║\n";
//			        }
//			    }
//			    _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
//			}
//    
//		    // hint
//		    var _hint = "";
//		    if (string_pos("not defined", message) > 0 || string_pos("does not exist", message) > 0) {
//		        if (string_pos("Function", message) > 0 || string_pos("function", message) > 0) {
//		            _hint = "  Hint: Make sure the function exists and is spelled correctly.";
//		        } else {
//		            _hint = "  Hint: Check for typos or declare the variable first.";
//		        }
//		    } else if (string_pos("Cannot call", message) > 0) {
//		        _hint = "  Hint: Make sure the function exists and is spelled correctly.";
//		    } else if (string_pos("out of bounds", message) > 0) {
//		        _hint = "  Hint: Check array/list index bounds before accessing.";
//		    }
//    
//		    if (_hint != "") {
//		        _output += "║ " + string_pad_right(_hint, _box_width - 4) + " ║\n";
//		        _output += "║" + string_repeat(" ", _box_width - 2) + "║\n";
//		    }
//    
//		    // bottom border
//		    _output += "╚" + string_repeat("═", _box_width - 2) + "╝";
//    
//		    return _output;
//		}
//    };
//}

function string_pad_right(_str, _len) {
    var _str_len = string_length(_str);
    if (_str_len >= _len) return _str;
    return _str + string_repeat(" ", _len - _str_len);
}

function string_pad_left(_str, _len) {
    var _str_len = string_length(_str);
    if (_str_len >= _len) return _str;
    return string_repeat(" ", _len - _str_len) + _str;
}

function string_wrap(_str, _width) {
    var _words = string_split(_str, " ");
    var _lines = [];
    var _current = "";
    
    for (var i = 0; i < array_length(_words); i++) {
        var _word = _words[i];
        if (string_length(_current) + string_length(_word) + 1 <= _width) {
            if (_current != "") _current += " ";
            _current += _word;
        } else {
            if (_current != "") array_push(_lines, _current);
            _current = _word;
        }
    }
    if (_current != "") array_push(_lines, _current);
    
    return _lines;
}

function gmlvm_print_error(_error) {
    if (is_struct(_error) && struct_exists(_error, "toString")) {
        show_debug_message(_error.toString());
    } else {
        show_debug_message("GMLVM Error: " + string(_error));
    }
}

function gmlvm_error_formatter() constructor {
    show_full_stack = true;
    show_source_context = true;
    max_stack_depth = 10;
    context_lines = 2;
    
    static FormatError = function(_error, _source_code = "", _source_name = "<script>") {
        var _err_type = "Runtime Error";
        var _err_msg = string(_error);
        var _line = -1;
        var _column = -1;
        
        if (is_struct(_error)) {
            if (struct_exists(_error, "type")) {
                if (_error.type == "parse_error") {
                    _err_type = "Parse Error";
                    _err_msg = _error.message;
                    _line = _error.line;
                    _column = _error.column;
                } else if (_error.type == "runtime_error") {
                    _err_type = "Runtime Error";
                    _err_msg = _error.message;
                    _line = _error.line;
                    _column = _error.column;
                }
            }
        }
        
        if (_line == -1) {
            var _match = string_match_extract(_err_msg, "at line (\\d+)");
            if (_match != "") _line = real(_match);
        }
        
        var _output = "\n";
        _output += "──────────────────────────────────────────────────────────────────\n";
        _output += "GMLVM " + _err_type + ": " + _err_msg + "\n";
        _output += "──────────────────────────────────────────────────────────────────\n";
        
        _output += "  File: " + _source_name + "\n";
        if (_line >= 0) {
            _output += "  Line: " + string(_line);
            if (_column >= 0) _output += ", Column: " + string(_column);
            _output += "\n\n";
        }
        
        if (show_source_context && _source_code != "" && _line >= 0) {
            _output += FormatSourceContext(_source_code, _line, _column) + "\n";
        }
        
        if (show_full_stack) {
            _output += "  Stack:\n";
            _output += FormatStackTrace() + "\n";
        }
        
        _output += "──────────────────────────────────────────────────────────────────";
        
        return _output;
    };
    
    static FormatSourceContext = function(_code, _line, _column) {
        var _lines = string_split(_code, "\n");
        var _output = "";
        
        var _start = max(0, _line - context_lines - 1);
        var _end = min(array_length(_lines), _line + context_lines);
        
        for (var i = _start; i < _end; i++) {
            var _prefix = "    ";
            if (i == _line - 1) {
                _prefix = "  > ";
            } else {
                _prefix = "    ";
            }
            
            _output += _prefix + string(i + 1) + " | " + _lines[i] + "\n";
            
            if (i == _line - 1 && _column >= 0) {
                _output += "    " + string_repeat(" ", string_length(string(i + 1)) + 3 + _column - 1);
                _output += "^\n";
            }
        }
        
        return _output;
    };
    
    static FormatStackTrace = function() {
        var _stack = global.__gmlvm_call_stack;
        if (_stack == undefined) return "    (no stack trace available)";
        
        var _output = "";
        var _count = min(array_length(_stack), max_stack_depth);
        
        for (var i = _count - 1; i >= 0; i--) {
            var _frame = _stack[i];
            _output += "    at " + _frame.name;
            if (_frame.line >= 0) {
                _output += " (line " + string(_frame.line) + ")";
            }
            _output += "\n";
        }
        
        if (array_length(_stack) > max_stack_depth) {
            _output += "    ... " + string(array_length(_stack) - max_stack_depth) + " more frames\n";
        }
        
        return _output;
    };
    
    static string_repeat = function(_str, _count) {
        var _result = "";
        for (var i = 0; i < _count; i++) _result += _str;
        return _result;
    };
    
    static string_match_extract = function(_str, _pattern) {
        var _pos = string_pos(_pattern, _str);
        if (_pos == 0) return "";
        
        return "";
    };
}

function gmlvm_warning_collector() constructor {
    warnings = [];
    
    static Add = function(_category, _message, _line = -1, _column = -1) {
        array_push(warnings, {
            category: _category,
            message: _message,
            line: _line,
            column: _column
        });
    };
    
    static Clear = function() {
        warnings = [];
    };
    
    static GetWarnings = function() {
        return warnings;
    };
    
    static GetCount = function() {
        return array_length(warnings);
    };
    
    static HasWarnings = function() {
        return array_length(warnings) > 0;
    };
    
    static ToString = function() {
        var _str = "";
        for (var _i = 0; _i < array_length(warnings); _i++) {
            var _w = warnings[_i];
            _str += "[" + _w.category + "] ";
            if (_w.line >= 0) {
                _str += "Line " + string(_w.line) + ": ";
            }
            _str += _w.message + "\n";
        }
        return _str;
    };
}

function gmlvm_check(_code) {
    global.__gmlvm_warning_collector.Clear();
    
    var _tokens = gmlvm_tokenize(_code);
    var _ast = gmlvm_parse(_tokens);
    
    if (is_struct(_ast) && struct_exists(_ast, "type") && _ast.type == "parse_error") {
        global.__gmlvm_warning_collector.Add("parse_error", _ast.message, _ast.line, _ast.column);
    }
    
    return global.__gmlvm_warning_collector.GetWarnings();
}

function gmlvm_check_to_string(_code) {
    gmlvm_check(_code);
    return global.__gmlvm_warning_collector.ToString();
}

function gmlvm_has_warnings(_code) {
    gmlvm_check(_code);
    return global.__gmlvm_warning_collector.HasWarnings();
}

function gmlvm_warnings_enable(_category) {
    if (struct_exists(global.__gmlvm_warnings, _category)) {
        global.__gmlvm_warnings[$ _category] = true;
    }
}

function gmlvm_warnings_disable(_category) {
    if (struct_exists(global.__gmlvm_warnings, _category)) {
        global.__gmlvm_warnings[$ _category] = false;
    }
}

function gmlvm_warnings_disable_all() {
    var _names = struct_get_names(global.__gmlvm_warnings);
    for (var _i = 0; _i < array_length(_names); _i++) {
        global.__gmlvm_warnings[$ _names[_i]] = false;
    }
}

function gmlvm_warnings_enable_all() {
    var _names = struct_get_names(global.__gmlvm_warnings);
    for (var _i = 0; _i < array_length(_names); _i++) {
        global.__gmlvm_warnings[$ _names[_i]] = true;
    }
}

function gmlvm_warn(_category, _message) {
    if (struct_exists(global.__gmlvm_warnings, _category)) {
        if (global.__gmlvm_warnings[$ _category]) {
            show_debug_message("GML Warning [" + _category + "]: " + _message);
        }
    } else {
        // Unknown category - show anyway
        show_debug_message("GML Warning [" + _category + "]: " + _message);
    }
}

function gmlvm_warning(_category, _message, _line = -1, _column = -1) {
    global.__gmlvm_warning_collector.Add(_category, _message, _line, _column);
    
    if (struct_exists(global.__gmlvm_warnings, _category)) {
        if (global.__gmlvm_warnings[$ _category]) {
            var _prefix = "GML Warning";
            if (_line >= 0) {
                _prefix += " [Line " + string(_line) + "]";
            }
            show_debug_message(_prefix + " [" + _category + "]: " + _message);
        }
    }
}

function gmlvm_parse_error(_message, _line, _column, _token_value) {
    var _token_length = 1;
    if (_token_value != undefined) {
        _token_length = string_length(_token_value);
    }
    
    return gmlvm_create_error(
        "parse_error",
        _message,
        _line,
        _column,
        _token_length
    );
}

function gmlvm_runtime_error(_message, _line, _column) constructor {
    type    = "runtime_error";
    message = _message;
    line    = _line;
    column  = _column;
    
    static toString = function() {
        return "Runtime Error at line " + string(line) + ", column " + string(column) + ": " + message;
    };
}

function gmlvm_interrupt(_type, _value = undefined) constructor {
    type  = _type;   // "return", "break", "continue"
    value = _value;
}

function _gmlvm_tok(_tokens, _pos) {
    if (_pos >= array_length(_tokens)) {
        return { 
            type: "eof", 
            value: "", 
            line: -1, 
            column: -1 
        };
    }
    return _tokens[_pos];
}

function gmlvm_tokenize(_src) {
    var _len    = string_length(_src);
    var _tokens = [];
    var _i      = 1;
    var _line   = 1;
    var _col    = 1;

    // keyword lookup map
    var _keywords = ds_map_create();
    var _kw_list  = ["if","else","while","for","repeat","switch","case",
                     "default","break","continue","return","var","static",
                     "function","constructor","new","true","false","try",
                     "catch","finally","throw","do","until","with","delete",
					 "enum", "exit"];
    for (var _k = 0; _k < array_length(_kw_list); _k++) {
        ds_map_set(_keywords, _kw_list[_k], true);
    }

    while (_i <= _len) {
        var _ch = string_char_at(_src, _i);
        
        var _start_line = _line;
        var _start_col = _col;

        // Skip whitespace
        if (_ch == " " || _ch == "\t") {
            _i++; _col++;
            continue;
        }
        if (_ch == "\n") {
            _i++; _line++; _col = 1;
            continue;
        }
        if (_ch == "\r") {
            _i++;
            continue;
        }

        // peek helpers
        var _ch2 = (_i + 1 <= _len) ? string_char_at(_src, _i + 1) : "";
        var _ch3 = (_i + 2 <= _len) ? string_char_at(_src, _i + 2) : "";

        // Comments
        if (_ch == "/" && _ch2 == "/") {
            _i += 2; _col += 2;
            while (_i <= _len) {
                var _cc = string_char_at(_src, _i);
                _i++;
                if (_cc == "\n") {
                    _line++; _col = 1;
                    break;
                }
                _col++;
            }
            continue;
        }

        if (_ch == "/" && _ch2 == "*") {
            _i += 2; _col += 2;
            while (_i <= _len) {
                var _cc = string_char_at(_src, _i);
                _i++;
                if (_cc == "\n") {
                    _line++; _col = 1;
                } else {
                    _col++;
                }
                if (_cc == "*" && (_i <= _len) && string_char_at(_src, _i) == "/") {
                    _i++; _col++;
                    break;
                }
            }
            continue;
        }

		// Template string: $"Hello {name}!"
		if (_ch == "$" && (_ch2 == chr(34) || _ch2 == chr(39))) {
		    var _quote = _ch2;
		    _i += 2; _col += 2;
		    var _parts = [];  // Array of string parts and expression ASTs
    
		    var _current_str = "";
    
		    while (_i <= _len) {
		        var _sc = string_char_at(_src, _i);
        
		        if (_sc == "{") {
		            // Save current string part
		            if (_current_str != "") {
		                array_push(_parts, { type: "string", value: _current_str });
		                _current_str = "";
		            }
            
		            _i++; _col++;
		            var _expr_str = "";
		            var _brace_count = 1;
            
		            while (_i <= _len && _brace_count > 0) {
		                var _ec = string_char_at(_src, _i);
		                if (_ec == "{") _brace_count++;
		                else if (_ec == "}") _brace_count--;
                
		                if (_brace_count > 0) {
		                    _expr_str += _ec;
		                    _i++; _col++;
		                }
		            }
            
		            // Parse the expression into an AST
		            if (_expr_str != "") {
		                var _expr_tokens = gmlvm_tokenize(_expr_str);
		                var _expr_ast = gmlvm_parse_expression(_expr_tokens, 0);
		                array_push(_parts, { type: "expression", value: _expr_ast[0] });
		            }
            
		            if (_i <= _len) {
		                _i++; _col++; // Skip closing }
		            }
		        } else if (_sc == _quote) {
		            _i++; _col++;
		            break;
		        } else if (_sc == "\\") {
		            _i++; _col++;
		            if (_i > _len) break;
		            var _esc = string_char_at(_src, _i); _i++; _col++;
		            if (_esc == "n") _current_str += "\n";
		            else if (_esc == "t") _current_str += "\t";
		            else if (_esc == chr(34)) _current_str += chr(34);
		            else if (_esc == chr(39)) _current_str += chr(39);
		            else if (_esc == "\\") _current_str += "\\";
		            else if (_esc == "{") _current_str += "{";
		            else if (_esc == "}") _current_str += "}";
		            else _current_str += _esc;
		        } else if (_sc == "\n") {
		            _line++; _col = 1;
		            _current_str += _sc; _i++;
		        } else {
		            _current_str += _sc; _i++; _col++;
		        }
		    }
    
		    // Save final string part
		    if (_current_str != "") {
		        array_push(_parts, { type: "string", value: _current_str });
		    }
    
		    array_push(_tokens, {
		        type: "template_string",
		        parts: _parts,
		        line: _start_line,
		        column: _start_col
		    });
		    continue;
		}
		
		// Multi-line string: @"line1\nline2"
		if (_ch == "@" && (_ch2 == chr(34) || _ch2 == chr(39))) {
		    var _quote = _ch2;
		    _i += 2; _col += 2;
		    var _s = "";
    
		    while (_i <= _len) {
		        var _sc = string_char_at(_src, _i);
        
		        if (_sc == _quote) {
		            // Check if it's double quote escape ""
		            if (_i + 1 <= _len && string_char_at(_src, _i + 1) == _quote) {
		                _s += _quote;
		                _i += 2; _col += 2;
		            } else {
		                _i++; _col++;
		                break;
		            }
		        } else if (_sc == "\r") {
		            _i++;
		            // Skip \r
		        } else if (_sc == "\n") {
		            _s += "\n";
		            _line++; _col = 1;
		            _i++;
		        } else {
		            _s += _sc;
		            _i++; _col++;
		        }
		    }
    
		    array_push(_tokens, {
		        type: "string",
		        value: _s,
		        line: _start_line,
		        column: _start_col
		    });
		    continue;
		}
		
		// Accessors and map/list access: [@, [$, [#, [?, [|
		if (_ch == "[" && (_ch2 == "@" || _ch2 == "$" || _ch2 == "#" || _ch2 == "?" || _ch2 == "|")) {
		    var _accessor = _ch + _ch2;
		    array_push(_tokens, {
		        type: "accessor",
		        value: _accessor,
		        line: _start_line,
		        column: _start_col
		    });
		    _i += 2; _col += 2;
		    continue;
		}

        // Operators - unified handling
		if (_ch == "+" || _ch == "-" || _ch == "*" || _ch == "/" ||
		    _ch == "%" || _ch == "=" || _ch == "<" || _ch == ">" ||
		    _ch == "!" || _ch == "&" || _ch == "|" || _ch == "^" || _ch == "~" ||
		    _ch == "?") {  // Add ? here
    
		    var _three = _ch + _ch2 + _ch3;
		    var _two = _ch + _ch2;
    
		    // Check 3-character operators first
		    if (_three == "<<=" || _three == ">>=") {
		        array_push(_tokens, {
		            type: "operator",
		            value: _three,
		            line: _start_line,
		            column: _start_col
		        });
		        _i += 3; _col += 3;
		        continue;
		    }
    
		    // Check 2-character operators - ?? must be here!
		    switch (_two) {
		        case "==": case "!=": case "<=": case ">=":
		        case "&&": case "||": case "++": case "--":
		        case "+=": case "-=": case "*=": case "/=": case "%=":
		        case "<<": case ">>":
		        case "&=": case "|=": case "^=":
		        case "??": case "?=":  // These must be here
		            array_push(_tokens, {
		                type: "operator",
		                value: _two,
		                line: _start_line,
		                column: _start_col
		            });
		            _i += 2; _col += 2;
		            continue;
		    }
    
		    // Single character operator
		    array_push(_tokens, {
		        type: "operator",
		        value: _ch,
		        line: _start_line,
		        column: _start_col
		    });
		    _i++; _col++;
		    continue;
		}

        // hex number  0x...
        if (_ch == "0" && _ch2 == "x") {
            _i += 2; _col += 2;
            var _hex = "0x";
            while (_i <= _len) {
                var _hc = string_char_at(_src, _i);
                if ((_hc >= "0" && _hc <= "9")
                ||  (_hc >= "a" && _hc <= "f")
                ||  (_hc >= "A" && _hc <= "F")) {
                    _hex += _hc;
                    _i++; _col++;
                } else break;
            }
            array_push(_tokens, {
                type: "number",
                value: _hex,
                line: _start_line,
                column: _start_col
            });
            continue;
        }

        // decimal / integer number
        if ((_ch >= "0" && _ch <= "9")
        || (_ch == "." && _ch2 >= "0" && _ch2 <= "9")) {
            var _num    = "";
            var _has_dot = false;
            while (_i <= _len) {
                var _nc = string_char_at(_src, _i);
                if (_nc >= "0" && _nc <= "9") {
                    _num += _nc; _i++; _col++;
                } else if (_nc == "." && !_has_dot) {
                    _has_dot = true;
                    _num += _nc; _i++; _col++;
                } else break;
            }
            array_push(_tokens, {
                type: "number",
                value: real(_num),
                line: _start_line,
                column: _start_col
            });
            continue;
        }

        // string literal
        if (_ch == chr(34) || _ch == chr(39)) {
            var _quote = _ch;
            _i++; _col++;
            var _s = "";
            while (_i <= _len) {
                var _sc = string_char_at(_src, _i);
                if (_sc == "\\") {
                    _i++; _col++;
                    if (_i > _len) break;
                    var _esc = string_char_at(_src, _i); _i++; _col++;
                    if      (_esc == "n")       _s += "\n";
                    else if (_esc == "t")       _s += "\t";
                    else if (_esc == chr(34))   _s += chr(34);
                    else if (_esc == chr(39))   _s += chr(39);
                    else if (_esc == "\\")      _s += "\\";
                    else if (_esc == "r")       _s += "\r";
                    else                        _s += _esc;
                } else if (_sc == _quote) {
                    _i++; _col++;
                    break;
                } else if (_sc == "\n") {
                    _line++; _col = 1;
                    _s += _sc; _i++;
                } else {
                    _s += _sc; _i++; _col++;
                }
            }
            array_push(_tokens, {
                type: "string",
                value: _s,
                line: _start_line,
                column: _start_col
            });
            continue;
        }

        // identifier or keyword
        if ((_ch >= "a" && _ch <= "z")
        ||  (_ch >= "A" && _ch <= "Z")
        ||   _ch == "_") {
            var _id = "";
            while (_i <= _len) {
                var _ic = string_char_at(_src, _i);
                if ((_ic >= "a" && _ic <= "z")
                ||  (_ic >= "A" && _ic <= "Z")
                ||  (_ic >= "0" && _ic <= "9")
                ||   _ic == "_") {
                    _id += _ic; _i++; _col++;
                } else break;
            }
            
            var _token_type = ds_map_exists(_keywords, _id) ? "keyword" : "identifier";
            array_push(_tokens, {
                type: _token_type,
                value: _id,
                line: _start_line,
                column: _start_col
            });
            continue;
        }

        // parentheses
        if (_ch == "(" || _ch == ")") {
            array_push(_tokens, {
                type: "paren",
                value: _ch,
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // braces
        if (_ch == "{" || _ch == "}") {
            array_push(_tokens, {
                type: "brace",
                value: _ch,
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // brackets
        if (_ch == "[" || _ch == "]") {
            array_push(_tokens, {
                type: "bracket",
                value: _ch,
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // ternary operator
        if (_ch == "?") {
            array_push(_tokens, {
                type: "operator",
                value: "?",
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // separator
        if (_ch == "," || _ch == ";") {
            array_push(_tokens, {
                type: "separator",
                value: _ch,
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // colon
        if (_ch == ":") {
            array_push(_tokens, {
                type: "operator",
                value: ":",
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // dot
        if (_ch == ".") {
            array_push(_tokens, {
                type: "operator",
                value: ".",
                line: _start_line,
                column: _start_col
            });
            _i++; _col++;
            continue;
        }

        // unknown - skip
        _i++; _col++;
    }

    ds_map_destroy(_keywords);
    return _tokens;
}

function format_error_with_source(_err, _source, _source_name) {
    if (is_struct(_err) && struct_exists(_err, "type") && (_err.type == "runtime_error" || _err.type == "parse_error")) {
        _err.source = _source;
        _err.source_name = _source_name;
        return _err.toString();
    } else {
        var _error_msg = string(_err);
        if (is_struct(_err) && struct_exists(_err, "message")) {
            _error_msg = _err.message;
        }
        var _clean_err = gmlvm_create_error(
            "runtime_error",
            _error_msg,
            -1, -1,
            0
        );
        _clean_err.source = _source;
        _clean_err.source_name = _source_name;
        return _clean_err.toString();
    }
}

function gmlvm_run_cached(_code, _self = self, _other = other) {
    var _ast = gmlvm_parse_cached(_code);
    return gmlvm_vm(_ast, _self, _other);
}

//function gmlvm_run(_code, _self = self, _other = other) {
//    var _processed = gmlvm_preprocess(_code);
//    var _tokens = gmlvm_tokenize(_processed);
//    var _ast = gmlvm_parse(_tokens);
//	return gmlvm_vm(_ast, _self, _other);
//}

function gmlvm_run(_code, _self = self, _other = other, _source_name = "<script>") {
    var _processed = gmlvm_preprocess(_code);
    var _tokens = gmlvm_tokenize(_processed);
    var _ast = gmlvm_parse(_tokens, _processed, _source_name);
	
    global.__gmlvm_last_source = _processed;
    global.__gmlvm_last_source_name = _source_name;
    
    try {
        return gmlvm_vm(_ast, _self, _other);
    } catch (_err) {
        if (is_struct(_err) && struct_exists(_err, "type") && (_err.type == "runtime_error" || _err.type == "parse_error")) {
            _err.source = _processed;
            _err.source_name = _source_name;
			var _msg = _err.toString();
            show_debug_message(_msg);
            global.__gmlvm_last_error = _err;
        } else {
            var _clean_err = gmlvm_create_error(
                "runtime_error",
                string(_err),
                -1, -1
            );
            _clean_err.source = _processed;
            _clean_err.source_name = _source_name;
            var _msg = _clean_err.toString();
            show_debug_message(_msg);
            global.__gmlvm_last_error = _clean_err;
        }
        return undefined;
    }
}

function gmlvm_tokenize_only(_code) {
    var _processed = gmlvm_preprocess(_code);
    return gmlvm_tokenize(_processed);
}

function gmlvm_preprocess(_code) {
    var _macros = ds_map_create();
    var _lines = string_split(_code, "\n");
    var _processed_code = "";
    
    for (var _i = 0; _i < array_length(_lines); _i++) {
        var _line = _lines[_i];
        var _trimmed = string_trim(_line);
        
        if (string_pos("#macro", _trimmed) == 1) {
            var _parts = string_split(string_trim(string_delete(_trimmed, 1, 6)), " ");
            if (array_length(_parts) >= 2) {
                var _macro_name = _parts[0];
                var _macro_value = "";
                for (var _j = 1; _j < array_length(_parts); _j++) {
                    if (_macro_value != "") _macro_value += " ";
                    _macro_value += _parts[_j];
                }
                ds_map_set(_macros, _macro_name, _macro_value);
            }
        }
    }
    
    var _macro_names = ds_map_keys_to_array(_macros);
    var _changed = true;
    var _max_iterations = 10;
    var _iter = 0;
    
    while (_changed && _iter < _max_iterations) {
        _changed = false;
        _iter++;
        
        for (var _i = 0; _i < array_length(_macro_names); _i++) {
            var _name = _macro_names[_i];
            var _value = _macros[? _name];
            var _expanded = _value;
            
            for (var _j = 0; _j < array_length(_macro_names); _j++) {
                var _other_name = _macro_names[_j];
                if (_other_name != _name) {
                    var _other_value = _macros[? _other_name];
                    var _new_value = string_replace_all(_expanded, _other_name, _other_value);
                    if (_new_value != _expanded) {
                        _expanded = _new_value;
                        _changed = true;
                    }
                }
            }
            
            _macros[? _name] = _expanded;
        }
    }
    
    for (var _i = 0; _i < array_length(_lines); _i++) {
        var _line = _lines[_i];
        var _trimmed = string_trim(_line);
        
        if (string_pos("#macro", _trimmed) == 1) continue;
        if (string_pos("#region", _trimmed) == 1) continue;
        if (string_pos("#endregion", _trimmed) == 1) continue;
        
        var _processed_line = _line;
        for (var _j = 0; _j < array_length(_macro_names); _j++) {
            var _name = _macro_names[_j];
            var _value = _macros[? _name];
            _processed_line = string_replace_all(_processed_line, _name, _value);
        }
        
        _processed_code += _processed_line + "\n";
    }
    
    ds_map_destroy(_macros);
    _processed_code = string_replace_all(_processed_code, "\r", "");
    return _processed_code;
}

function gmlvm_cache() constructor {
    cache = ds_map_create();
    
    static Get = function(_code) {
        var _hash = string(real(string_hash_to_newline(_code)));
        if (ds_map_exists(cache, _hash)) {
            return cache[? _hash];
        }
        return undefined;
    };
    
    static Set = function(_code, _ast) {
        var _hash = string(real(string_hash_to_newline(_code)));
        cache[? _hash] = _ast;
    };
    
    static Clear = function() {
        ds_map_clear(cache);
    };
    
    static Destroy = function() {
        ds_map_destroy(cache);
    };
}