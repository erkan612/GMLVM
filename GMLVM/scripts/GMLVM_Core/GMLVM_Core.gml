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
*   						 GameMaker Immediate Mode UI Library	                         *
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
	global.__gmlvm_debugger = new gmlvm_debugger();
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

function gmlvm_parse_error(_message, _line, _column) constructor {
    type    = "parse_error";
    message = _message;
    line    = _line;
    column  = _column;
    
    static toString = function() {
        return "Parse Error at line " + string(line) + ", column " + string(column) + ": " + message;
    };
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

function gmlvm_run_cached(_code, _self = self, _other = other) {
    var _ast = gmlvm_parse_cached(_code);
    return gmlvm_vm(_ast, _self, _other);
}

function gmlvm_run(_code, _self = self, _other = other) {
    var _processed = gmlvm_preprocess(_code);
    var _tokens = gmlvm_tokenize(_processed);
    var _ast = gmlvm_parse(_tokens);
    return gmlvm_vm(_ast, _self, _other);
}

function gmlvm_tokenize_only(_code) {
    var _processed = gmlvm_preprocess(_code);
    return gmlvm_tokenize(_processed);
}

function gmlvm_parse_only(_code) {
    var _processed = gmlvm_preprocess(_code);
    var _tokens = gmlvm_tokenize(_processed);
    return gmlvm_parse(_tokens);
}

function gmlvm_preprocess(_code) {
    var _macros = ds_map_create();
    var _lines = string_split(_code, "\n");
    var _processed_code = "";
    
    // First pass: collect all macros
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
    
    // Expand macro values (resolve nested macros)
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
    
    // Second pass: process lines and replace macros
    for (var _i = 0; _i < array_length(_lines); _i++) {
        var _line = _lines[_i];
        var _trimmed = string_trim(_line);
        
        // Skip macro definitions and region directives
        if (string_pos("#macro", _trimmed) == 1) continue;
        if (string_pos("#region", _trimmed) == 1) continue;
        if (string_pos("#endregion", _trimmed) == 1) continue;
        
        // Replace macros
        var _processed_line = _line;
        for (var _j = 0; _j < array_length(_macro_names); _j++) {
            var _name = _macro_names[_j];
            var _value = _macros[? _name];
            _processed_line = string_replace_all(_processed_line, _name, _value);
        }
        
        _processed_code += _processed_line + "\n";
    }
    
    ds_map_destroy(_macros);
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