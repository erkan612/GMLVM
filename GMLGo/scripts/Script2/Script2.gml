





global.__gml_static_registry = {};
global.__gml_warnings = {
    undefined_binary_left: true,
    undefined_binary_right: true,
    undefined_unary: true,
    unknown_operator: true,
    cannot_call: true,
    parse_error: true
};
global.__gml_warning_collector = new gmlWarningCollector();

/// @func gmlWarningCollector()
/// @desc Creates a collector for parsing warnings
function gmlWarningCollector() constructor {
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

/// @func gml_check(code)
/// @desc Parses code and returns warnings without executing
/// @return {array} Array of warning structs
function gml_check(_code) {
    // Clear previous warnings
    global.__gml_warning_collector.Clear();
    
    // Parse the code
    var _tokens = gml_tokenize(_code);
    var _ast = gml_parse(_tokens);
    
    // Check if parsing returned an error
    if (is_struct(_ast) && struct_exists(_ast, "type") && _ast.type == "parse_error") {
        global.__gml_warning_collector.Add("parse_error", _ast.message, _ast.line, _ast.column);
    }
    
    return global.__gml_warning_collector.GetWarnings();
}

/// @func gml_check_to_string(code)
/// @desc Returns warnings as a formatted string
function gml_check_to_string(_code) {
    gml_check(_code);
    return global.__gml_warning_collector.ToString();
}

/// @func gml_has_warnings(code)
/// @desc Returns true if the code has any warnings
function gml_has_warnings(_code) {
    gml_check(_code);
    return global.__gml_warning_collector.HasWarnings();
}

/// @func gml_warnings_enable(category)
/// @desc Enables a specific warning category
function gml_warnings_enable(_category) {
    if (struct_exists(global.__gml_warnings, _category)) {
        global.__gml_warnings[$ _category] = true;
    }
}

/// @func gml_warnings_disable(category)
/// @desc Disables a specific warning category
function gml_warnings_disable(_category) {
    if (struct_exists(global.__gml_warnings, _category)) {
        global.__gml_warnings[$ _category] = false;
    }
}

/// @func gml_warnings_disable_all()
/// @desc Disables all warnings
function gml_warnings_disable_all() {
    var _names = struct_get_names(global.__gml_warnings);
    for (var _i = 0; _i < array_length(_names); _i++) {
        global.__gml_warnings[$ _names[_i]] = false;
    }
}

/// @func gml_warnings_enable_all()
/// @desc Enables all warnings
function gml_warnings_enable_all() {
    var _names = struct_get_names(global.__gml_warnings);
    for (var _i = 0; _i < array_length(_names); _i++) {
        global.__gml_warnings[$ _names[_i]] = true;
    }
}

/// @func gml_warn(category, message)
/// @desc Issues a warning if the category is enabled
function gml_warn(_category, _message) {
    if (struct_exists(global.__gml_warnings, _category)) {
        if (global.__gml_warnings[$ _category]) {
            show_debug_message("GML Warning [" + _category + "]: " + _message);
        }
    } else {
        // Unknown category - show anyway
        show_debug_message("GML Warning [" + _category + "]: " + _message);
    }
}

/// @func gml_warning(category, message, line, column)
/// @desc Issues a warning (parse-time or runtime)
function gml_warning(_category, _message, _line = -1, _column = -1) {
    // Add to collector
    global.__gml_warning_collector.Add(_category, _message, _line, _column);
    
    // Also show in console if warnings are enabled
    if (struct_exists(global.__gml_warnings, _category)) {
        if (global.__gml_warnings[$ _category]) {
            var _prefix = "GML Warning";
            if (_line >= 0) {
                _prefix += " [Line " + string(_line) + "]";
            }
            show_debug_message(_prefix + " [" + _category + "]: " + _message);
        }
    }
}

/// @func gml_tokenize(str)
/// @desc Converts a GML source string into an array of token structs.
/// @return {array}  Array of { type, value, line, column } structs.
function gml_tokenize(_src) {
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
                     "catch","finally","throw"];
    for (var _k = 0; _k < array_length(_kw_list); _k++) {
        ds_map_set(_keywords, _kw_list[_k], true);
    }

    while (_i <= _len) {
        var _ch = string_char_at(_src, _i);
        
        // Save starting position for this token
        var _start_line = _line;
        var _start_col = _col;

        // ── whitespace ───────────────────────────────────────────────
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

        // ── peek helper ──────────────────────────────────────────────
        var _ch2 = (_i + 1 <= _len) ? string_char_at(_src, _i + 1) : "";

        // ── single-line comment // ───────────────────────────────────
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

        // ── multi-line comment /* */ ─────────────────────────────────
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

        // ── hex number  0x… ─────────────────────────────────────────
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

        // ── decimal / integer number ─────────────────────────────────
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

        // ── string literal  "…" or '…' ─────────────────────────────────
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

        // ── identifier or keyword ────────────────────────────────────
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

        // ── multi-character operators ────────────────────────────────
        var _two = _ch + _ch2;
        switch (_two) {
            case "==": case "!=": case "<=": case ">=":
            case "&&": case "||": case "++": case "--":
            case "+=": case "-=": case "*=": case "/=": case "%=":
            case "<<": case ">>":
                array_push(_tokens, {
                    type: "operator",
                    value: _two,
                    line: _start_line,
                    column: _start_col
                });
                _i += 2; _col += 2;
                continue;
        }

        // ── single-char operators ────────────────────────────────────
        switch (_ch) {
            case "+": case "-": case "*": case "/":
            case "%": case "=": case "<": case ">":
            case "!": case "&": case "^": case "~":
                array_push(_tokens, {
                    type: "operator",
                    value: _ch,
                    line: _start_line,
                    column: _start_col
                });
                _i++; _col++;
                continue;
        }

        // ── parentheses ──────────────────────────────────────────────
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

        // ── braces ───────────────────────────────────────────────────
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

        // ── brackets ─────────────────────────────────────────────────
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

        // ── accessor / special single chars ──────────────────────────
        switch (_ch) {
            case ".": case "$": case "@":
            case "?": case "|": case "#":
                array_push(_tokens, {
                    type: "operator",
                    value: _ch,
                    line: _start_line,
                    column: _start_col
                });
                _i++; _col++;
                continue;
        }

        // ── separator ────────────────────────────────────────────────
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

        // ── colon ────────────────────────────────────────────────────
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

        // ── unknown — skip ────────────────────────────────────────────
        _i++; _col++;
    }

    ds_map_destroy(_keywords);
    return _tokens;
}

// ── precedence table (higher = tighter binding) ───────────────────
function _gml_infix_bp(_op) {
    switch (_op) {
        case "||":            return [1, 2];
        case "&&":            return [3, 4];
        case "==": case "!=":
        case "<":  case ">":
        case "<=": case ">=": return [5, 6];
        case "+":  case "-":  return [7, 8];
        case "*":  case "/":
        case "%":             return [9, 10];
    }
    return [-1, -1];   // not an infix op
}

/// @func _gml_prefix_bp(op)
/// @desc Returns binding power for prefix unary operators.
function _gml_prefix_bp(_op) {
    switch (_op) {
        case "!": case "-":
        case "++": case "--":
        case "~":             return 11;
    }
    return -1;
}

// ── parse a primary (leaf) expression with postfix handling ───────
function _gml_parse_primary(_tokens, _pos) {
    var _t = _gml_tok(_tokens, _pos);
    var _line = _t.line;
    var _col = _t.column;

    // ── parenthesised sub-expression  ( expr ) ───────────────────
    if (_t.type == "paren" && _t.value == "(") {
        var _res = gml_parse_expression(_tokens, _pos + 1);
        var _node = _res[0];
        var _p    = _res[1];
        var _close = _gml_tok(_tokens, _p);
        if (_close.type == "paren" && _close.value == ")") _p++;
        return _gml_parse_postfix(_tokens, _p, _node);
    }

    // ── prefix unary:  !expr  -expr  ++expr  --expr  ~expr ──────
    if (_t.type == "operator" && _gml_prefix_bp(_t.value) > 0) {
        var _op  = _t.value;
        var _res = _gml_parse_primary(_tokens, _pos + 1);
        return [new gmlUnaryOpNode(_op, _res[0], _line, _col), _res[1]];
    }

    // ── number literal ───────────────────────────────────────────
    if (_t.type == "number") {
        return [new gmlNumberNode(_t.value, _line, _col), _pos + 1];
    }

    // ── boolean keywords → number (1 / 0) ────────────────────────
    if (_t.type == "keyword" && (_t.value == "true" || _t.value == "false")) {
        return [new gmlNumberNode(_t.value == "true" ? 1 : 0, _line, _col), _pos + 1];
    }

    // ── string literal ────────────────────────────────────────────
    if (_t.type == "string") {
        return [new gmlStringNode(_t.value, _line, _col), _pos + 1];
    }

    // ── array literal: [ expr, expr, ... ] ───────────────────────
    if (_t.type == "bracket" && _t.value == "[") {
        _pos++;
        var _elements = [];
        var _next = _gml_tok(_tokens, _pos);
        
        if (_next.type == "bracket" && _next.value == "]") {
            return _gml_parse_postfix(_tokens, _pos + 1, new gmlArrayNode([], _line, _col));
        }
        
        while (true) {
            var _er = gml_parse_expression(_tokens, _pos);
            array_push(_elements, _er[0]);
            _pos = _er[1];
            var _sep = _gml_tok(_tokens, _pos);
            if (_sep.type == "separator" && _sep.value == ",") {
                _pos++;
            } else {
                break;
            }
        }
        var _close = _gml_tok(_tokens, _pos);
        if (_close.type == "bracket" && _close.value == "]") _pos++;
        
        return _gml_parse_postfix(_tokens, _pos, new gmlArrayNode(_elements, _line, _col));
    }

    // ── struct literal: { key: value, key2, ... } ────────────────
    if (_t.type == "brace" && _t.value == "{") {
        _pos++;
        var _fields = [];
        
        var _next = _gml_tok(_tokens, _pos);
        if (_next.type == "brace" && _next.value == "}") {
            _pos++;
            return _gml_parse_postfix(_tokens, _pos, new gmlStructNode([], _line, _col));
        }
        
        while (true) {
            var _key_tok = _gml_tok(_tokens, _pos);
            
            if (_key_tok.type == "brace" && _key_tok.value == "}") {
                _pos++;
                break;
            }
            
            var _key = "";
            if (_key_tok.type == "identifier") {
                _key = _key_tok.value;
                _pos++;
            } else if (_key_tok.type == "string") {
                _key = _key_tok.value;
                _pos++;
            } else {
                // Error - return parse error
                return [new gmlParseError("Expected identifier or string as struct key, got " + _key_tok.type, _key_tok.line, _key_tok.column), _pos];
            }
            
            var _value = undefined;
            var _sep = _gml_tok(_tokens, _pos);
            
            if (_sep.type == "operator" && _sep.value == ":") {
                _pos++;
                var _vr = gml_parse_expression(_tokens, _pos);
                _value = _vr[0];
                _pos = _vr[1];
            } else {
                _value = new gmlVarNode(_key, _key_tok.line, _key_tok.column);
            }
            
            array_push(_fields, { key: _key, value: _value });
            
            var _after = _gml_tok(_tokens, _pos);
            if (_after.type == "separator" && _after.value == ",") {
                _pos++;
                var _after_comma = _gml_tok(_tokens, _pos);
                if (_after_comma.type == "brace" && _after_comma.value == "}") {
                    _pos++;
                    break;
                }
                continue;
            } else if (_after.type == "brace" && _after.value == "}") {
                _pos++;
                break;
            } else {
                return [new gmlParseError("Expected ',' or '}' after struct field, got " + _after.type, _after.line, _after.column), _pos];
            }
        }
        
        return _gml_parse_postfix(_tokens, _pos, new gmlStructNode(_fields, _line, _col));
    }

    // ── new expression (constructor call) ─────────────────────────
    if (_t.type == "keyword" && _t.value == "new") {
        _pos++;
        
        var _ctor_tok = _gml_tok(_tokens, _pos);
        if (_ctor_tok.type != "identifier") {
            return [new gmlParseError("Expected constructor name after 'new'", _ctor_tok.line, _ctor_tok.column), _pos];
        }
        var _ctor_name = _ctor_tok.value;
        _pos++;
        
        // Parse arguments
        var _args = [];
        var _open = _gml_tok(_tokens, _pos);
        if (_open.type == "paren" && _open.value == "(") {
            _pos++;
            var _nt = _gml_tok(_tokens, _pos);
            if (!(_nt.type == "paren" && _nt.value == ")")) {
                while (true) {
                    var _ar = gml_parse_expression(_tokens, _pos);
                    array_push(_args, _ar[0]);
                    _pos = _ar[1];
                    var _sep = _gml_tok(_tokens, _pos);
                    if (_sep.type == "separator" && _sep.value == ",") {
                        _pos++;
                    } else {
                        break;
                    }
                }
            }
            var _rp = _gml_tok(_tokens, _pos);
            if (_rp.type == "paren" && _rp.value == ")") _pos++;
        }
        
        var _ctor_var = new gmlVarNode(_ctor_name, _ctor_tok.line, _ctor_tok.column);
        var _node = new gmlNewNode(_ctor_var, _args, _line, _col);
        
        return _gml_parse_postfix(_tokens, _pos, _node);
    }

    // ── function expression ───────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "function") {
        _pos++;
        
        var _name = "";
        var _next = _gml_tok(_tokens, _pos);
        if (_next.type == "identifier") {
            _name = _next.value;
            _pos++;
        }
        
        var _open = _gml_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
            return [new gmlParseError("Expected '(' in function declaration", _open.line, _open.column), _pos];
        }
        _pos++;
        
        var _params = [];
        var _close = _gml_tok(_tokens, _pos);
        if (!(_close.type == "paren" && _close.value == ")")) {
            while (true) {
                var _p = _gml_tok(_tokens, _pos);
                if (_p.type == "identifier") {
                    array_push(_params, _p.value);
                    _pos++;
                } else {
                    break;
                }
                var _sep = _gml_tok(_tokens, _pos);
                if (_sep.type == "separator" && _sep.value == ",") {
                    _pos++;
                } else {
                    break;
                }
            }
        }
        var _rp = _gml_tok(_tokens, _pos);
        if (_rp.type == "paren" && _rp.value == ")") _pos++;
        
        // Check for inheritance (:) and constructor keyword
        var _is_constructor = false;
        var _inherit = undefined;
        var _inherit_args = [];
        
        // FIRST: Check for inheritance colon (BEFORE constructor keyword)
        var _colon = _gml_tok(_tokens, _pos);
        if (_colon.type == "operator" && _colon.value == ":") {
            _pos++;
            var _parent = _gml_tok(_tokens, _pos);
            if (_parent.type == "identifier") {
                _inherit = _parent.value;
                _pos++;
                
                // Parse parent constructor arguments
                var _par_open = _gml_tok(_tokens, _pos);
                if (_par_open.type == "paren" && _par_open.value == "(") {
                    _pos++;
                    var _nt = _gml_tok(_tokens, _pos);
                    if (!(_nt.type == "paren" && _nt.value == ")")) {
                        while (true) {
                            var _ar = gml_parse_expression(_tokens, _pos);
                            array_push(_inherit_args, _ar[0]);
                            _pos = _ar[1];
                            var _sep = _gml_tok(_tokens, _pos);
                            if (_sep.type == "separator" && _sep.value == ",") {
                                _pos++;
                            } else {
                                break;
                            }
                        }
                    }
                    var _par_close = _gml_tok(_tokens, _pos);
                    if (_par_close.type == "paren" && _par_close.value == ")") _pos++;
                }
            }
        }
        
        // SECOND: Check for constructor keyword
        var _next2 = _gml_tok(_tokens, _pos);
        if (_next2.type == "keyword" && _next2.value == "constructor") {
            _is_constructor = true;
            _pos++;
        }
        
        var _br = gml_parse_block(_tokens, _pos);
        var _body = _br[0];
        _pos = _br[1];
        
        var _func_node = new gmlFunctionNode(_name, _params, _body, _is_constructor, _inherit, _inherit_args, _line, _col);
        
        // Function expressions don't get postfix handling (they can't be called immediately)
        return [_func_node, _pos];
    }

    // ── identifier — variable, with postfix handling ──────────────
    if (_t.type == "identifier") {
        var _node = new gmlVarNode(_t.value, _line, _col);
        return _gml_parse_postfix(_tokens, _pos + 1, _node);
    }

    // ── fallback - parse error ────────────────────────────────────
    return [new gmlParseError("Unexpected token: " + _t.type + " '" + string(_t.value) + "'", _line, _col), _pos];
}

/// @func _gml_parse_postfix(tokens, pos, node)
/// @desc Handles function calls, array/dot access, postfix ++/-- after a primary.
function _gml_parse_postfix(_tokens, _pos, _node) {
    while (true) {
        var _next = _gml_tok(_tokens, _pos);
        
        // function call:  expr ( args... )
        if (_next.type == "paren" && _next.value == "(") {
            var _args = [];
            var _p = _pos + 1;
            var _nt = _gml_tok(_tokens, _p);
            if (!(_nt.type == "paren" && _nt.value == ")")) {
                while (true) {
                    var _ar = gml_parse_expression(_tokens, _p);
                    array_push(_args, _ar[0]);
                    _p = _ar[1];
                    var _sep = _gml_tok(_tokens, _p);
                    if (_sep.type == "separator" && _sep.value == ",") {
                        _p++;
                    } else break;
                }
            }
            var _rp = _gml_tok(_tokens, _p);
            if (_rp.type == "paren" && _rp.value == ")") _p++;
            _node = new gmlCallNode(_node, _args);
            _pos = _p;
            continue;
        }
        
        // bracket access:  expr [ index ]
        if (_next.type == "bracket" && _next.value == "[") {
            var _p = _pos + 1;
            var _ir = gml_parse_expression(_tokens, _p);
            var _index = _ir[0];
            _p = _ir[1];
            var _close = _gml_tok(_tokens, _p);
            if (_close.type == "bracket" && _close.value == "]") _p++;
            _node = new gmlAccessNode(_node, _index, "bracket");
            _pos = _p;
            continue;
        }
        
        // dot access:  expr . identifier
        if (_next.type == "operator" && _next.value == ".") {
            _pos++;
            var _prop_tok = _gml_tok(_tokens, _pos);
            if (_prop_tok.type == "identifier") {
                _pos++;
                _node = new gmlAccessNode(_node, new gmlStringNode(_prop_tok.value), "dot");
            }
            continue;
        }
        
        // postfix increment/decrement:  expr++  expr--
        if (_next.type == "operator" 
        && (_next.value == "++" || _next.value == "--")) {
            _node = new gmlPostfixOpNode(_next.value, _node, _next.line, _next.column);
            _pos++;
            continue;
        }
        
        break;
    }
    
    return [_node, _pos];
}

// ── main Pratt expression parser ─────────────────────────────────
function gml_parse_expression(_tokens, _start_index) {
    // Parse a primary on the left
    var _res  = _gml_parse_primary(_tokens, _start_index);
    var _left = _res[0];
    var _pos  = _res[1];

    // Climb infix operators as long as their binding power >= min_bp.
    // Outer loop uses min_bp = 0 so all infix ops are candidates.
    while (true) {
        var _t  = _gml_tok(_tokens, _pos);
        var _bp = _gml_infix_bp(_t.value);
        if (_bp[0] < 0) break;       // not an infix op we handle
        var _l_bp = _bp[0];
        var _r_bp = _bp[1];          // right operand min binding power
        _pos++;                      // consume operator token
        var _rr    = gml_parse_expression_bp(_tokens, _pos, _r_bp);
        var _right = _rr[0];
        _pos       = _rr[1];
        _left      = new gmlBinaryOpNode(_t.value, _left, _right);
    }

    return [_left, _pos];
}

/// @func  gml_parse_expression_bp(tokens, pos, min_bp)
/// @desc  Internal: parse expression stopping when infix bp < min_bp.
function gml_parse_expression_bp(_tokens, _start, _min_bp) {
    var _res  = _gml_parse_primary(_tokens, _start);
    var _left = _res[0];
    var _pos  = _res[1];

    while (true) {
        var _t  = _gml_tok(_tokens, _pos);
        var _bp = _gml_infix_bp(_t.value);
        if (_bp[0] < _min_bp) break;
        var _r_bp = _bp[1];
        _pos++;
        var _rr    = gml_parse_expression_bp(_tokens, _pos, _r_bp);
        var _right = _rr[0];
        _pos       = _rr[1];
        _left      = new gmlBinaryOpNode(_t.value, _left, _right);
    }

    return [_left, _pos];
}

/// @func  gml_parse_statement(tokens, pos)
/// @desc  Parse a single statement. Returns [node, new_pos].
function gml_parse_statement(_tokens, _pos) {
    var _t = _gml_tok(_tokens, _pos);

    // ── empty statement (just a semicolon) ────────────────────────
    if (_t.type == "separator" && _t.value == ";") {
        return [undefined, _pos + 1];
    }
	
	// ── try statement ──────────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "try") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _tr = gml_parse_statement(_tokens, _pos);
        var _try_block = _tr[0]; _pos = _tr[1];
        
        var _catch_var = "";
        var _catch_block = undefined;
        var _finally_block = undefined;
        
        var _next = _gml_tok(_tokens, _pos);
        if (_next.type == "keyword" && _next.value == "catch") {
            _pos++;
            var _open = _gml_tok(_tokens, _pos);
            if (_open.type == "paren" && _open.value == "(") {
                _pos++;
                var _var_tok = _gml_tok(_tokens, _pos);
                if (_var_tok.type == "identifier") {
                    _catch_var = _var_tok.value;
                    _pos++;
                }
                var _close = _gml_tok(_tokens, _pos);
                if (_close.type == "paren" && _close.value == ")") _pos++;
            }
            var _cr = gml_parse_statement(_tokens, _pos);
            _catch_block = _cr[0]; _pos = _cr[1];
        }
        
        _next = _gml_tok(_tokens, _pos);
        if (_next.type == "keyword" && _next.value == "finally") {
            _pos++;
            var _fr = gml_parse_statement(_tokens, _pos);
            _finally_block = _fr[0]; _pos = _fr[1];
        }
        
        return [new gmlTryNode(_try_block, _catch_var, _catch_block, _finally_block, _line, _col), _pos];
    }

    // ── throw statement ────────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "throw") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _er = gml_parse_expression(_tokens, _pos);
        var _expr = _er[0]; _pos = _er[1];
        
        var _sc = _gml_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        
        return [new gmlThrowNode(_expr, _line, _col), _pos];
    }
	
	// ── static declaration ─────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "static") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _stmts = [];
        
        while (true) {
            var _name_tok = _gml_tok(_tokens, _pos);
            if (_name_tok.type != "identifier") break;
            var _var_name = _name_tok.value;
            _pos++;
            
            var _init = undefined;
            var _eq = _gml_tok(_tokens, _pos);
            if (_eq.type == "operator" && _eq.value == "=") {
                _pos++;
                var _er = gml_parse_expression(_tokens, _pos);
                _init = _er[0];
                _pos = _er[1];
            }
            
            // For static variables, we need a special initialization node
            // that only sets the value if it doesn't already exist
            array_push(_stmts, new gmlStaticInitNode(_var_name, _init, _line, _col));
            
            var _comma = _gml_tok(_tokens, _pos);
            if (_comma.type == "separator" && _comma.value == ",") {
                _pos++;
            } else {
                break;
            }
        }
        
        var _sc = _gml_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        
        if (array_length(_stmts) == 1) {
            return [_stmts[0], _pos];
        }
        return [new gmlBlockNode(_stmts, _line, _col), _pos];
    }
	
	// ── var declaration ────────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "var") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _stmts = [];
        
        while (true) {
            var _name_tok = _gml_tok(_tokens, _pos);
            if (_name_tok.type != "identifier") break;
            var _var_name = _name_tok.value;
            _pos++;
            
            var _init = undefined;
            var _eq = _gml_tok(_tokens, _pos);
            if (_eq.type == "operator" && _eq.value == "=") {
                _pos++;
                var _er = gml_parse_expression(_tokens, _pos);
                _init = _er[0];
                _pos = _er[1];
            }
            
            var _var_node = new gmlVarNode(_var_name, _line, _col);
            array_push(_stmts, new gmlAssignNode(_var_node, _init, _line, _col));
            
            var _comma = _gml_tok(_tokens, _pos);
            if (_comma.type == "separator" && _comma.value == ",") {
                _pos++;
            } else {
                break;
            }
        }
        
        var _sc = _gml_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        
        if (array_length(_stmts) == 1) {
            return [_stmts[0], _pos];
        }
        return [new gmlBlockNode(_stmts, _line, _col), _pos];
    }

    // ── if statement ──────────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "if") {
        _pos++;
        var _open = _gml_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
            show_debug_message("Parse error: expected '(' after 'if'");
			gml_warning("parse_error", "Expected '(' after 'if' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        var _cr = gml_parse_expression(_tokens, _pos);
        var _cond = _cr[0]; _pos = _cr[1];
        var _close = _gml_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _tr = gml_parse_statement(_tokens, _pos);
        var _then_block = _tr[0]; _pos = _tr[1];
        
        var _else_block = undefined;
        var _save_pos = _pos;
        var _else_tok = _gml_tok(_tokens, _pos);
        if (_else_tok.type == "keyword" && _else_tok.value == "else") {
            _pos++;
            var _er = gml_parse_statement(_tokens, _pos);
            _else_block = _er[0]; _pos = _er[1];
        }
        
        return [new gmlIfNode(_cond, _then_block, _else_block), _pos];
    }

    // ── while statement ───────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "while") {
        _pos++;
        var _open = _gml_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gml_warning("parse_error", "Expected '(' after 'while' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        var _cr = gml_parse_expression(_tokens, _pos);
        var _cond = _cr[0]; _pos = _cr[1];
        var _close = _gml_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _br = gml_parse_statement(_tokens, _pos);
        var _body = _br[0]; _pos = _br[1];
        
        return [new gmlWhileNode(_cond, _body), _pos];
    }

    // ── for statement ─────────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "for") {
        _pos++;
        var _open = _gml_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gml_warning("parse_error", "Expected '(' after 'for' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        
        // init (statement or empty)
        var _init = undefined;
        var _semi1 = _gml_tok(_tokens, _pos);
        if (!(_semi1.type == "separator" && _semi1.value == ";")) {
            // Parse init as expression, but handle var declarations specially
            if (_semi1.type == "keyword" && _semi1.value == "var") {
                var _ir = gml_parse_statement(_tokens, _pos);
                _init = _ir[0]; _pos = _ir[1];
            } else {
                var _ir = gml_parse_expression(_tokens, _pos);
                _init = _ir[0]; _pos = _ir[1];
            }
            var _sc = _gml_tok(_tokens, _pos);
            if (_sc.type == "separator" && _sc.value == ";") _pos++;
        } else {
            _pos++;
        }
        
        // cond (expression or empty)
        var _cond = undefined;
        var _semi2 = _gml_tok(_tokens, _pos);
        if (!(_semi2.type == "separator" && _semi2.value == ";")) {
            var _cr = gml_parse_expression(_tokens, _pos);
            _cond = _cr[0]; _pos = _cr[1];
            var _sc = _gml_tok(_tokens, _pos);
            if (_sc.type == "separator" && _sc.value == ";") _pos++;
        } else {
            _pos++;
        }
        
        // step (expression or empty)
        var _step = undefined;
        var _close = _gml_tok(_tokens, _pos);
        if (!(_close.type == "paren" && _close.value == ")")) {
            var _sr = gml_parse_expression(_tokens, _pos);
            _step = _sr[0]; _pos = _sr[1];
        }
        var _rp = _gml_tok(_tokens, _pos);
        if (_rp.type == "paren" && _rp.value == ")") _pos++;
        
        var _br = gml_parse_statement(_tokens, _pos);
        var _body = _br[0]; _pos = _br[1];
        
        return [new gmlForNode(_init, _cond, _step, _body), _pos];
    }

    // ── repeat statement ──────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "repeat") {
        _pos++;
        var _open = _gml_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
            show_debug_message("Parse error: expected '(' after 'repeat'");
            return [undefined, _pos];
        }
        _pos++;
        var _cr = gml_parse_expression(_tokens, _pos);
        var _count = _cr[0]; _pos = _cr[1];
        var _close = _gml_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _br = gml_parse_statement(_tokens, _pos);
        var _body = _br[0]; _pos = _br[1];
        return [new gmlRepeatNode(_count, _body), _pos];
    }

    // ── switch statement ──────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "switch") {
        _pos++;
        var _open = _gml_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gml_warning("parse_error", "Expected '(' after 'switch' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        var _er = gml_parse_expression(_tokens, _pos);
        var _expr = _er[0]; _pos = _er[1];
        var _close = _gml_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _ob = _gml_tok(_tokens, _pos);
        if (!(_ob.type == "brace" && _ob.value == "{")) {
			gml_warning("parse_error", "Expected '{' after 'switch' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        
        var _cases = [];
        
        while (true) {
            var _ct = _gml_tok(_tokens, _pos);
            if (_ct.type == "brace" && _ct.value == "}") {
                _pos++;
                break;
            }
            
            var _case_value = undefined;
            if (_ct.type == "keyword" && _ct.value == "case") {
                _pos++;
                var _vr = gml_parse_expression(_tokens, _pos);
                _case_value = _vr[0]; _pos = _vr[1];
            } else if (_ct.type == "keyword" && _ct.value == "default") {
                _pos++;
                _case_value = "default";
            } else {
				gml_warning("parse_error", "Parse error: expected 'case' or 'default', got " + _ct.type);
                break;
            }
            
            var _colon = _gml_tok(_tokens, _pos);
            if (_colon.type == "operator" && _colon.value == ":") _pos++;
            
            var _body_stmts = [];
            while (true) {
                var _nt = _gml_tok(_tokens, _pos);
                if (_nt.type == "eof") break;
                if (_nt.type == "brace" && _nt.value == "}") break;
                if (_nt.type == "keyword" && (_nt.value == "case" || _nt.value == "default")) break;
                
                var _sr = gml_parse_statement(_tokens, _pos);
                if (_sr[0] != undefined) {
                    array_push(_body_stmts, _sr[0]);
                }
                _pos = _sr[1];
            }
            
            array_push(_cases, {
                value: _case_value,
                body: new gmlBlockNode(_body_stmts)
            });
        }
        
        return [new gmlSwitchNode(_expr, _cases), _pos];
    }

    // ── return statement ──────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "return") {
        _pos++;
        var _value = undefined;
        var _next = _gml_tok(_tokens, _pos);
        if (!(_next.type == "separator" && _next.value == ";")) {
            var _er = gml_parse_expression(_tokens, _pos);
            _value = _er[0]; _pos = _er[1];
        }
        var _sc = _gml_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        return [new gmlReturnNode(_value), _pos];
    }

    // ── break statement ───────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "break") {
        _pos++;
        var _sc = _gml_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        return [new gmlBreakNode(), _pos];
    }

    // ── continue statement ────────────────────────────────────────
    if (_t.type == "keyword" && _t.value == "continue") {
        _pos++;
        var _sc = _gml_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        return [new gmlContinueNode(), _pos];
    }

    // ── block:  { stmt* } ─────────────────────────────────────────
    if (_t.type == "brace" && _t.value == "{") {
        return gml_parse_block(_tokens, _pos);
    }

    // ── function declaration (statement form) ─────────────────────
    if (_t.type == "keyword" && _t.value == "function") {
        var _fr = _gml_parse_primary(_tokens, _pos);
        var _func_node = _fr[0];
        _pos = _fr[1];
        
        // if it has a name, it's a declaration that assigns to a variable
        if (_func_node.name != "") {
            return [new gmlAssignNode(new gmlVarNode(_func_node.name), _func_node), _pos];
        }
        return [_func_node, _pos];
    }

    // ── expression statement (assignment, call, etc.) ─────────────
    var _er = gml_parse_expression(_tokens, _pos);
    var _node = _er[0]; _pos = _er[1];

    // check for assignment:  expr = expr
    var _nx = _gml_tok(_tokens, _pos);
    if (_nx.type == "operator") {
        var _op = _nx.value;
        if (_op == "=") {
            _pos++;
            var _vr = gml_parse_expression(_tokens, _pos);
            _node = new gmlAssignNode(_node, _vr[0]);
            _pos  = _vr[1];
        }
        else if (_op == "+=" || _op == "-=" || _op == "*=" || _op == "/=" || _op == "%=") {
            _pos++;
            var _vr = gml_parse_expression(_tokens, _pos);
            _node = new gmlCompoundAssignNode(_node, _op, _vr[0]);
            _pos  = _vr[1];
        }
    }

    // consume optional semicolon
    var _sc2 = _gml_tok(_tokens, _pos);
    if (_sc2.type == "separator" && _sc2.value == ";") _pos++;

    return [_node, _pos];
}

/// @func  gml_parse_block(tokens, pos)
/// @desc  Parse a brace-delimited block { stmt* }. Returns [gmlBlockNode, new_pos].
function gml_parse_block(_tokens, _pos) {
    var _stmts = [];
    // expect opening brace
    var _ob = _gml_tok(_tokens, _pos);
    if (_ob.type == "brace" && _ob.value == "{") _pos++;

    while (true) {
        var _t = _gml_tok(_tokens, _pos);
        if (_t.type == "eof") break;
        if (_t.type == "brace" && _t.value == "}") { _pos++; break; }
        
        var _sr = gml_parse_statement(_tokens, _pos);
        if (_sr[0] != undefined) {
            array_push(_stmts, _sr[0]);
        }
        if (_sr[1] == _pos) { _pos++; continue; }
        _pos = _sr[1];
    }

    return [new gmlBlockNode(_stmts), _pos];
}

/// @func  gml_parse(tokens)
/// @desc  Top-level entry point. Parses the entire token stream.
/// @return {gmlBlockNode}
function gml_parse(_tokens) {
    var _stmts = [];
    var _pos   = 0;
    var _len   = array_length(_tokens);

    while (_pos < _len) {
        var _t = _gml_tok(_tokens, _pos);
        if (_t.type == "eof") break;
        
        var _sr = gml_parse_statement(_tokens, _pos);
        if (_sr[0] != undefined) {
            array_push(_stmts, _sr[0]);
        }
        if (_sr[1] == _pos) { _pos++; continue; }
        _pos = _sr[1];
    }

    return new gmlBlockNode(_stmts);
}

// ── Statement AST Nodes ────────────────────────────────────────────

//function gmlCompoundAssignNode(_target, _op, _value) constructor {
//    type   = "compound_assign";
//    target = _target;   // gmlVarNode or gmlAccessNode
//    op     = _op;       // "+=", "-=", "*=", "/=", etc.
//    value  = _value;    // expression node
//}
//
//function gmlIfNode(_cond, _then_block, _else_block) constructor {
//    type       = "if";
//    cond       = _cond;
//    then_block = _then_block;
//    else_block = _else_block;
//}
//
//function gmlWhileNode(_cond, _body) constructor {
//    type = "while";
//    cond = _cond;
//    body = _body;
//}
//
//function gmlForNode(_init, _cond, _step, _body) constructor {
//    type = "for";
//    init = _init;   // statement node or undefined
//    cond = _cond;   // expression node or undefined
//    step = _step;   // expression node or undefined
//    body = _body;   // statement node (usually a block)
//}
//
//function gmlRepeatNode(_count, _body) constructor {
//    type  = "repeat";
//    count = _count;
//    body  = _body;
//}
//
//function gmlSwitchNode(_expr, _cases) constructor {
//    type  = "switch";
//    expr  = _expr;
//    cases = _cases;   // array of { value, body } structs
//}
//
//function gmlReturnNode(_value) constructor {
//    type  = "return";
//    value = _value;
//}
//
//function gmlBreakNode() constructor {
//    type = "break";
//}
//
//function gmlContinueNode() constructor {
//    type = "continue";
//}
//
//function gmlFunctionNode(_name, _params, _body) constructor {
//    type   = "function";
//    name   = _name;
//    params = _params;   // array of parameter names
//    body   = _body;     // gmlBlockNode
//}
//
//function gmlArrayNode(_elements) constructor {
//    type     = "array";
//    elements = _elements;
//}
//
//function gmlStructNode(_fields) constructor {
//    type   = "struct";
//    fields = _fields;   // array of { key, value } structs
//}
//
//function gmlAccessNode(_target, _index, _kind) constructor {
//    type   = "access";
//    target = _target;
//    index  = _index;    // expression node (or string node for dot)
//    kind   = _kind;     // "bracket", "dot", "dollar", "at"
//}

/// @func gmlInterrupt(type, value)
/// @desc Creates an interrupt for control flow (return, break, continue)
function gmlInterrupt(_type, _value = undefined) constructor {
    type  = _type;   // "return", "break", "continue"
    value = _value;
}

/// @func gmlVMContext(_self, _other)
/// @desc Holds runtime state during VM execution
function gmlVMContext(_self, _other) constructor {
    self_inst  = _self;      // current "self" (instance or struct)
    other_inst = _other;     // current "other"
    
    locals     = {};         // local variables (var)
    statics    = {};         // static variables
    static_names = {};  // Track which variables are static
    globals    = global;     // reference to global scope
    
    // Scope stack for nested blocks
    scope_stack = [];
    
    // ───────────────────────────────────────────────────────────────
    /// @func PushScope()
    /// @desc Pushes current locals to stack and creates new locals
    static PushScope = function() {
        array_push(scope_stack, locals);
        locals = {};
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func PopScope()
    /// @desc Restores previous locals from stack
    static PopScope = function() {
        if (array_length(scope_stack) > 0) {
            locals = array_pop(scope_stack);
        }
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func GetVar(name)
    /// @desc Looks up variable in: locals → statics → self → global
    static GetVar = function(_name) {
        // Check locals
        if (struct_exists(locals, _name)) {
            return locals[$ _name];
        }
        
        // Check statics (if marked as static or if it exists there)
        if (struct_exists(static_names, _name) || struct_exists(statics, _name)) {
            if (struct_exists(statics, _name)) {
                return statics[$ _name];
            }
            return undefined;
        }
        
        // Check self (instance or struct)
        if (is_struct(self_inst)) {
            if (struct_exists(self_inst, _name)) {
                return self_inst[$ _name];
            }
        } else if (instance_exists(self_inst)) {
            if (variable_instance_exists(self_inst, _name)) {
                return variable_instance_get(self_inst, _name);
            }
        }
        
        // Check global
        if (variable_global_exists(_name)) {
            return variable_global_get(_name);
        }
        
        // Check for built-in constants/functions
        var _builtin = gml_vm_builtin(_name);
        if (_builtin.found) {
            return _builtin.value;
        }
        
        return undefined;
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func SetVar(name, value)
    /// @desc Sets variable in appropriate scope
    static SetVar = function(_name, _value) {
        // Check if it exists in locals
        if (struct_exists(locals, _name)) {
            locals[$ _name] = _value;
            return;
        }
        
        // Check if it exists in statics
        if (struct_exists(statics, _name)) {
            statics[$ _name] = _value;
            return;
        }
        
        // Check self
        if (is_struct(self_inst)) {
            self_inst[$ _name] = _value;
            return;
        } else if (instance_exists(self_inst)) {
            variable_instance_set(self_inst, _name, _value);
            return;
        }
        
        // Check global
        if (variable_global_exists(_name)) {
            variable_global_set(_name, _value);
            return;
        }
        
        // Doesn't exist anywhere - create as local
        locals[$ _name] = _value;
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func SetStatic(name, value)
    /// @desc Sets a static variable
    static SetStatic = function(_name, _value) {
        statics[$ _name] = _value;
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func GetSelf()
    /// @desc Returns current self
    static GetSelf = function() {
        return self_inst;
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func GetOther()
    /// @desc Returns current other
    static GetOther = function() {
        return other_inst;
    };
	
    // ───────────────────────────────────────────────────────────────
    /// @func MarkStatic(name)
    /// @desc Marks a variable as static
    static MarkStatic = function(_name) {
        static_names[$ _name] = true;
    };
    
    // ───────────────────────────────────────────────────────────────
    /// @func IsStatic(name)
    /// @desc Checks if a variable is static
    static IsStatic = function(_name) {
        return struct_exists(static_names, _name);
    };
}

/// @func gml_vm_builtin(name)
/// @desc Checks if name is a built-in constant or function
//function gml_vm_builtin(_name) {
//    static _found = false;
//    static _value = undefined;
//    
//    _found = true;
//    
//    // Keywords
//    switch (_name) {
//        case "true":      _value = true;      return { found: _found, value: _value };
//        case "false":     _value = false;     return { found: _found, value: _value };
//        case "undefined": _value = undefined; return { found: _found, value: _value };
//        case "self":      _value = -1;        return { found: _found, value: _value };
//        case "other":     _value = -2;        return { found: _found, value: _value };
//        case "all":       _value = -3;        return { found: _found, value: _value };
//        case "noone":     _value = -4;        return { found: _found, value: _value };
//        case "global":    _value = global;    return { found: _found, value: _value };
//    }
//    
//    // Math constants
//    switch (_name) {
//        case "pi": _value = pi; return { found: _found, value: _value };
//    }
//    
//    // Color constants
//    switch (_name) {
//        case "c_white":   _value = c_white;   return { found: _found, value: _value };
//        case "c_black":   _value = c_black;   return { found: _found, value: _value };
//        case "c_red":     _value = c_red;     return { found: _found, value: _value };
//        case "c_green":   _value = c_green;   return { found: _found, value: _value };
//        case "c_blue":    _value = c_blue;    return { found: _found, value: _value };
//        case "c_yellow":  _value = c_yellow;  return { found: _found, value: _value };
//        case "c_aqua":    _value = c_aqua;    return { found: _found, value: _value };
//        case "c_fuchsia": _value = c_fuchsia; return { found: _found, value: _value };
//        case "c_gray":    _value = c_gray;    return { found: _found, value: _value };
//        case "c_grey":    _value = c_grey;    return { found: _found, value: _value };
//    }
//    
//    _found = false;
//    return { found: _found, value: undefined };
//}

function gmlNumberNode(_value, _line = -1, _column = -1) constructor {
    type   = "number";
    value  = _value;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        return value;
    };
}

function gmlStringNode(_value, _line = -1, _column = -1) constructor {
    type   = "string";
    value  = _value;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        return value;
    };
}

function gmlVarNode(_name, _is_static = false, _line = -1, _column = -1) constructor {
    type      = "var";
    name      = _name;
    is_static = _is_static;
    line      = _line;
    column    = _column;
    
    Execute = function(_ctx) {
        if (name == "self") return _ctx.GetSelf();
        if (name == "other") return _ctx.GetOther();
        return _ctx.GetVar(name);
    };
}

// ── Binary Operator Node ──────────────────────────────────────────
function gmlBinaryOpNode(_op, _left, _right, _line = -1, _column = -1) constructor {
    type   = "binary_op";
    op     = _op;
    left   = _left;
    right  = _right;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _l = gml_vm_evaluate(left, _ctx);
        var _r = gml_vm_evaluate(right, _ctx);
        
        // Handle undefined values
        if (_l == undefined) {
            gml_warning("undefined_binary_left", "Left operand is undefined in binary op '" + op + "' at line " + string(line));
            _l = 0;
        }
        if (_r == undefined) {
            gml_warning("undefined_binary_right", "Right operand is undefined in binary op '" + op + "' at line " + string(line));
            _r = 0;
        }
        
        switch (op) {
            case "+":  
                if (is_string(_l) || is_string(_r)) {
                    return string(_l) + string(_r);
                }
                return _l + _r;
            case "-":  return _l - _r;
            case "*":  return _l * _r;
            case "/":  return _l / _r;
            case "%":  return _l % _r;
            case "==": return _l == _r;
            case "!=": return _l != _r;
            case "<":  return _l < _r;
            case ">":  return _l > _r;
            case "<=": return _l <= _r;
            case ">=": return _l >= _r;
            case "&&": return _l && _r;
            case "||": return _l || _r;
            case "<<": return _l << _r;
            case ">>": return _l >> _r;
            case "&":  return _l & _r;
            case "|":  return _l | _r;
            case "^":  return _l ^ _r;
            default:
                gml_warning("unknown_operator", "Unknown operator: " + op + " at line " + string(line));
                return undefined;
        }
    };
}

function gmlUnaryOpNode(_op, _operand, _line = -1, _column = -1) constructor {
    type    = "unary_op";
    op      = _op;
    operand = _operand;
    line    = _line;
    column  = _column;
    
    Execute = function(_ctx) {
        var _val = gml_vm_evaluate(operand, _ctx);
        
        // Handle undefined values for increment/decrement
        if (_val == undefined) {
            _val = 0;
        }
        
        switch (op) {
            case "!": return !_val;
            case "-": return -_val;
            case "~": return ~_val;
            case "++":  // Prefix increment
                if (operand.type == "var") {
                    var _new = _val + 1;
                    _ctx.SetVar(operand.name, _new);
                    return _new;
                }
                return _val + 1;
            case "--":  // Prefix decrement
                if (operand.type == "var") {
                    var _new = _val - 1;
                    _ctx.SetVar(operand.name, _new);
                    return _new;
                }
                return _val - 1;
            default:
                return undefined;
        }
    };
}

// ── Block Node ────────────────────────────────────────────────────
function gmlBlockNode(_statements, _line = -1, _column = -1) constructor {
    type       = "block";
    statements = _statements;
    line       = _line;
    column     = _column;
    
    Execute = function(_ctx) {
        var _result = undefined;
        
        for (var _i = 0; _i < array_length(statements); _i++) {
            var _stmt = statements[_i];
            _result = gml_vm_evaluate(_stmt, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                var _type = _result.type;
                if (_type == "return" || _type == "break" || _type == "continue") {
                    return _result;
                }
            }
        }
        
        return _result;
    };
}

// ── Assign Node ───────────────────────────────────────────────────
function gmlAssignNode(_target, _value, _line = -1, _column = -1) constructor {
    type   = "assign";
    target = _target;
    value  = _value;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _val = undefined;
        if (value != undefined) {
            _val = gml_vm_evaluate(value, _ctx);
        } else {
            // Variable declared without initializer - leave as undefined
            _val = undefined;
        }
        
        if (target.type == "var") {
            if (target.is_static) {
                _ctx.SetStatic(target.name, _val);
            } else {
                _ctx.SetVar(target.name, _val);
            }
        } else if (target.type == "access") {
            gml_vm_set_access(target, _val, _ctx);
        }
        
        return _val;
    };
}

// ── Compound Assign Node ──────────────────────────────────────────
function gmlCompoundAssignNode(_target, _op, _value, _line = -1, _column = -1) constructor {
    type   = "compound_assign";
    target = _target;
    op     = _op;
    value  = _value;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _current = undefined;
        
        if (target.type == "var") {
            _current = _ctx.GetVar(target.name);
        } else if (target.type == "access") {
            _current = gml_vm_get_access(target, _ctx);
        }
        
        // Handle undefined
        if (_current == undefined) {
            _current = 0;
        }
        
        var _r = gml_vm_evaluate(value, _ctx);
        if (_r == undefined) {
            _r = 0;
        }
        
        var _new = _current;
        
        switch (op) {
            case "+=": _new = _current + _r; break;
            case "-=": _new = _current - _r; break;
            case "*=": _new = _current * _r; break;
            case "/=": _new = _current / _r; break;
            case "%=": _new = _current % _r; break;
        }
        
        if (target.type == "var") {
            _ctx.SetVar(target.name, _new);
        } else if (target.type == "access") {
            gml_vm_set_access(target, _new, _ctx);
        }
        
        return _new;
    };
}

// ── If Node ───────────────────────────────────────────────────────
function gmlIfNode(_cond, _then_block, _else_block) constructor {
    type       = "if";
    cond       = _cond;
    then_block = _then_block;
    else_block = _else_block;
    
    static Execute = function(_ctx) {
        var _c = gml_vm_evaluate(cond, _ctx);
        
        if (_c) {
            return gml_vm_evaluate(then_block, _ctx);
        } else if (else_block != undefined) {
            return gml_vm_evaluate(else_block, _ctx);
        }
        
        return undefined;
    };
}

// ── While Node ────────────────────────────────────────────────────
function gmlWhileNode(_cond, _body, _line = -1, _column = -1) constructor {
    type = "while";
    cond = _cond;
    body = _body;
    line = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _result = undefined;
        
        while (gml_vm_evaluate(cond, _ctx)) {
            _result = gml_vm_evaluate(body, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "break") {
                    // Break exits the loop, return the last value (not the interrupt)
                    return undefined;
                } else if (_result.type == "continue") {
                    continue;
                } else if (_result.type == "return") {
                    return _result;
                }
            }
        }
        
        return _result;
    };
}

// ── For Node ──────────────────────────────────────────────────────
function gmlForNode(_init, _cond, _step, _body, _line = -1, _column = -1) constructor {
    type = "for";
    init = _init;
    cond = _cond;
    step = _step;
    body = _body;
    line = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _result = undefined;
        
        if (init != undefined) {
            gml_vm_evaluate(init, _ctx);
        }
        
        while (true) {
            if (cond != undefined) {
                if (!gml_vm_evaluate(cond, _ctx)) {
                    break;
                }
            }
            
            _result = gml_vm_evaluate(body, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "break") {
                    _result = undefined;
                    break;
                } else if (_result.type == "continue") {
                    // Continue to step
                } else if (_result.type == "return") {
                    return _result;
                }
            }
            
            if (step != undefined) {
                gml_vm_evaluate(step, _ctx);
            }
        }
        
        return _result;
    };
}

// ── Repeat Node ───────────────────────────────────────────────────
function gmlRepeatNode(_count, _body) constructor {
    type  = "repeat";
    count = _count;
    body  = _body;
    
    static Execute = function(_ctx) {
        var _result = undefined;
        var _c = gml_vm_evaluate(count, _ctx);
        
        for (var _i = 0; _i < _c; _i++) {
            _result = gml_vm_evaluate(body, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "break") {
                    break;
                } else if (_result.type == "continue") {
                    continue;
                } else if (_result.type == "return") {
                    return _result;
                }
            }
        }
        
        return _result;
    };
}

// ── Switch Node ───────────────────────────────────────────────────
function gmlSwitchNode(_expr, _cases, _line = -1, _column = -1) constructor {
    type  = "switch";
    expr  = _expr;
    cases = _cases;
    line  = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _val = gml_vm_evaluate(expr, _ctx);
        var _result = undefined;
        var _matched = false;
        
        for (var _i = 0; _i < array_length(cases); _i++) {
            var _case = cases[_i];
            var _case_val = _case.value;
            
            if (!_matched) {
                if (_case_val == "default") {
                    _matched = true;
                } else {
                    var _cv = gml_vm_evaluate(_case_val, _ctx);
                    if (_cv == _val) {
                        _matched = true;
                    }
                }
            }
            
            if (_matched) {
                _result = gml_vm_evaluate(_case.body, _ctx);
                
                if (is_struct(_result) && struct_exists(_result, "type")) {
                    if (_result.type == "break") {
                        break;
                    } else if (_result.type == "return") {
                        return _result;
                    }
                }
            }
        }
        
        // Don't return the interrupt
        if (is_struct(_result) && struct_exists(_result, "type") && _result.type == "break") {
            return undefined;
        }
        
        return _result;
    };
}

// ── Return Node ───────────────────────────────────────────────────
function gmlReturnNode(_value) constructor {
    type  = "return";
    value = _value;
    
    static Execute = function(_ctx) {
        var _val = undefined;
        if (value != undefined) {
            _val = gml_vm_evaluate(value, _ctx);
        }
        return new gmlInterrupt("return", _val);
    };
}

// ── Break Node ────────────────────────────────────────────────────
function gmlBreakNode() constructor {
    type = "break";
    
    static Execute = function(_ctx) {
        return new gmlInterrupt("break");
    };
}

// ── Continue Node ─────────────────────────────────────────────────
function gmlContinueNode() constructor {
    type = "continue";
    
    static Execute = function(_ctx) {
        return new gmlInterrupt("continue");
    };
}

function gmlArrayNode(_elements, _line = -1, _column = -1) constructor {
    type     = "array";
    elements = _elements;
    line     = _line;
    column   = _column;
    
    static Execute = function(_ctx) {
        var _arr = [];
        for (var _i = 0; _i < array_length(elements); _i++) {
            _arr[_i] = gml_vm_evaluate(elements[_i], _ctx);
        }
        return _arr;
    };
}

function gmlStructNode(_fields, _line = -1, _column = -1) constructor {
    type   = "struct";
    fields = _fields;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _struct = {};
        for (var _i = 0; _i < array_length(fields); _i++) {
            var _field = fields[_i];
            var _key = _field.key;
            var _val = gml_vm_evaluate(_field.value, _ctx);
            _struct[$ _key] = _val;
        }
        return _struct;
    };
}

// ── Access Node ───────────────────────────────────────────────────
function gmlAccessNode(_target, _index, _kind) constructor {
    type   = "access";
    target = _target;
    index  = _index;
    kind   = _kind;   // "bracket", "dot"
    
    static Execute = function(_ctx) {
        return gml_vm_get_access(self, _ctx);
    };
}

function gmlCallNode(_callee, _args, _line = -1, _column = -1) constructor {
    type   = "call";
    callee = _callee;
    args   = _args;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        // Evaluate callee - this will return the function struct
        var _func = gml_vm_evaluate(callee, _ctx);
        
        // Evaluate arguments
        var _arg_values = [];
        for (var _i = 0; _i < array_length(args); _i++) {
            _arg_values[_i] = gml_vm_evaluate(args[_i], _ctx);
        }
        
        // Call the function
        return gml_vm_call(_func, _arg_values, _ctx);
    };
}

function gmlFunctionNode(_name, _params, _body, _is_constructor = false, _inherit = undefined, _inherit_args = undefined, _line = -1, _column = -1) constructor {
    type           = "function";
    name           = _name;
    params         = _params;
    body           = _body;
    is_constructor = _is_constructor;
    inherit        = _inherit;
    inherit_args   = _inherit_args;
    line           = _line;
    column         = _column;
    
    Execute = function(_ctx) {
        // Capture the current locals for closure
        var _captured_locals = {};
        var _names = struct_get_names(_ctx.locals);
        for (var _i = 0; _i < array_length(_names); _i++) {
            var _n = _names[_i];
            _captured_locals[$ _n] = _ctx.locals[$ _n];
        }
        
        var _func_statics = {};
        var _captured_self = _ctx.GetSelf();
        var _captured_other = _ctx.GetOther();
        
        var _func = {
            __gml_type: "function",
            __gml_name: name,
            __gml_params: params,
            __gml_body: body,
            __gml_is_constructor: is_constructor,
            __gml_inherit: inherit,
            __gml_inherit_args: inherit_args,
            __gml_statics: _func_statics,
            __gml_captured_locals: _captured_locals,
            __gml_self: _captured_self,
            __gml_other: _captured_other,
            __gml_instance_id: string(current_time) + "_" + string(random(1000000))
        };
        
        return _func;
    };
}

/// @func gml_vm_get_access(node, ctx)
/// @desc Gets value from an access node (dot or bracket)
function gml_vm_get_access(_node, _ctx) {
    var _target = gml_vm_evaluate(_node.target, _ctx);
    var _index = _node.index;
    
    if (_node.kind == "dot") {
        // Dot access: target.property
        var _prop = _index.value;  // index is a string node
        if (is_struct(_target)) {
            return _target[$ _prop];
        } else if (instance_exists(_target)) {
            if (variable_instance_exists(_target, _prop)) {
                return variable_instance_get(_target, _prop);
            }
        }
        return undefined;
    } else if (_node.kind == "bracket") {
        // Bracket access: target[index]
        var _idx = gml_vm_evaluate(_index, _ctx);
        if (is_array(_target)) {
            return _target[_idx];
        } else if (is_struct(_target)) {
            return _target[$ _idx];
        }
        return undefined;
    }
    
    return undefined;
}

/// @func gml_vm_set_access(node, value, ctx)
/// @desc Sets value via an access node
function gml_vm_set_access(_node, _value, _ctx) {
    var _target = gml_vm_evaluate(_node.target, _ctx);
    var _index = _node.index;
    
    if (_node.kind == "dot") {
        var _prop = _index.value;
        if (is_struct(_target)) {
            _target[$ _prop] = _value;
        } else if (instance_exists(_target)) {
            variable_instance_set(_target, _prop, _value);
        }
    } else if (_node.kind == "bracket") {
        var _idx = gml_vm_evaluate(_index, _ctx);
        if (is_array(_target)) {
            _target[_idx] = _value;
        } else if (is_struct(_target)) {
            _target[$ _idx] = _value;
        }
    }
}

/// @func gml_vm_call(func, args, ctx)
/// @desc Calls a function with arguments
function gml_vm_call(_func, _args, _ctx) {
    // Check if it's our custom GML function
    if (is_struct(_func) && struct_exists(_func, "__gml_type") && _func.__gml_type == "function") {
        return gml_vm_call_gml_function(_func, _args, _ctx);
    }
    
    // Check if it's a native GameMaker function or script
    if (is_method(_func) || is_real(_func)) {
        var _arg_count = array_length(_args);
        
        switch (_arg_count) {
            case 0:  return _func();
            case 1:  return _func(_args[0]);
            case 2:  return _func(_args[0], _args[1]);
            case 3:  return _func(_args[0], _args[1], _args[2]);
            case 4:  return _func(_args[0], _args[1], _args[2], _args[3]);
            case 5:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4]);
            case 6:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5]);
            case 7:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6]);
            case 8:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7]);
            default:
                // For more arguments, use a different approach
                return undefined;
        }
    }
    
    // If it's just a value, return it (GML allows this for some reason)
	gml_warning("cannot_call", "Cannot call value of type " + typeof(_func));
    return _func;
}

/// @func gml_vm_call_ext(func, args)
/// @desc Calls a function with arbitrary number of arguments
function gml_vm_call_ext(_func, _args) {
    var _arg_array = [];
    for (var _i = 0; _i < array_length(_args); _i++) {
        _arg_array[_i] = _args[_i];
    }
    
    // Use method_call for methods, script_execute_ext for scripts
    if (is_method(_func)) {
        return method_call(_func, _arg_array);
    } else {
        // Build argument array with function first
        var _call_args = array_create(array_length(_args) + 1);
        _call_args[0] = _func;
        for (var _i = 0; _i < array_length(_args); _i++) {
            _call_args[_i + 1] = _args[_i];
        }
        return script_execute_ext(_func, _call_args);
    }
}

/// @func gml_vm_call_gml_function(func_wrapper, args, caller_ctx)
/// @desc Executes a GML-defined function (from AST)
function gml_vm_call_gml_function(_func, _args, _caller_ctx) {
    var _body = _func.__gml_body;
    var _params = _func.__gml_params;
    var _self_inst = _func.__gml_self;
    var _is_constructor = _func.__gml_is_constructor;
    var _inherit = _func.__gml_inherit;
    var _inherit_args = _func.__gml_inherit_args;
    
    // For constructors, create a new struct
    if (_is_constructor) {
        _self_inst = {};
        
        // Handle inheritance
	    if (_is_constructor) {
	        _self_inst = {};
        
	        // Handle inheritance
	        if (_inherit != undefined) {
	            var _parent_ctor = _caller_ctx.GetVar(_inherit);
	            if (is_struct(_parent_ctor) && struct_exists(_parent_ctor, "__gml_type") && _parent_ctor.__gml_type == "function") {
	                // Use the arguments passed to this constructor for the parent
	                // The parent constructor expects certain arguments - pass all of them
	                var _parent_args = _args;  // Simply pass the same arguments
                
	                // Mark parent as constructor and call it
	                var _parent_was_constructor = _parent_ctor.__gml_is_constructor;
	                _parent_ctor.__gml_is_constructor = true;
	                var _parent_instance = gml_vm_call_gml_function(_parent_ctor, _parent_args, _caller_ctx);
	                _parent_ctor.__gml_is_constructor = _parent_was_constructor;
                
	                // Copy ALL parent properties to the new instance
	                if (is_struct(_parent_instance)) {
	                    var _names = struct_get_names(_parent_instance);
	                    for (var _i = 0; _i < array_length(_names); _i++) {
	                        var _n = _names[_i];
	                        _self_inst[$ _n] = _parent_instance[$ _n];
	                    }
	                }
	            }
	        }
	    }
    }
    
    // Create new context for function execution
    var _func_ctx = new gmlVMContext(_self_inst, _caller_ctx.GetSelf());
    
    // Merge captured locals (closure variables)
    if (struct_exists(_func, "__gml_captured_locals")) {
        var _cap_names = struct_get_names(_func.__gml_captured_locals);
        for (var _i = 0; _i < array_length(_cap_names); _i++) {
            var _n = _cap_names[_i];
            _func_ctx.locals[$ _n] = _func.__gml_captured_locals[$ _n];
        }
    }
    
    // Initialize global registry if it doesn't exist
    if (!struct_exists(global, "__gml_static_registry")) {
        global.__gml_static_registry = {};
    }
    
    // Create a unique key for this function instance
    var _func_key = _func.__gml_name;
    if (_func_key == "") {
        _func_key = "_anonymous_" + string(current_time) + "_" + string(random(1000000));
        _func.__gml_name = _func_key;
    }
    
    // For functions created inside other functions (closures), use instance ID
    // so each closure instance gets its own statics
    if (struct_exists(_func, "__gml_instance_id")) {
        _func_key = _func_key + "_" + string(_func.__gml_instance_id);
    }
    
    // Get or create statics for this function
    if (!struct_exists(global.__gml_static_registry, _func_key)) {
        global.__gml_static_registry[$ _func_key] = {};
    }
    var _func_statics = global.__gml_static_registry[$ _func_key];
    
    // Use these statics in the context
    _func_ctx.statics = _func_statics;
    _func.__gml_statics = _func_statics;
    
    // Bind parameters to locals
    for (var _i = 0; _i < array_length(_params); _i++) {
        var _param_name = _params[_i];
        var _value = undefined;
        if (_i < array_length(_args)) {
            _value = _args[_i];
        } else {
            _value = 0;  // Default for missing arguments
        }
        _func_ctx.locals[$ _param_name] = _value;
    }
    
    // Set up argument array
    _func_ctx.locals[$ "argument"] = _args;
    _func_ctx.locals[$ "argument_count"] = array_length(_args);
    for (var _i = 0; _i < min(16, array_length(_args)); _i++) {
        _func_ctx.locals[$ "argument" + string(_i)] = _args[_i];
    }
    
    // Execute function body
    var _result = gml_vm_evaluate(_body, _func_ctx);
    
    // Handle return interrupt
    if (is_struct(_result) && struct_exists(_result, "type")) {
        if (_result.type == "return") {
            return _result.value;
        }
    }
    
    // Constructors return the new instance
    if (_is_constructor) {
        return _self_inst;
    }
    
    // If result is undefined, return 0 (GML convention)
    if (_result == undefined) {
        return 0;
    }
    
    return _result;
}

/// @func gml_vm_evaluate(node, ctx)
/// @desc Evaluates an AST node in the given context
function gml_vm_evaluate(_node, _ctx) {
    if (_node == undefined) {
        return undefined;
    }
    
    // Debugger hook
    var _dbg = global.__gml_debugger;
    _dbg.OnNodeEnter(_node);
    
    if (_dbg.ShouldBreak(_node)) {
        show_debug_message("DEBUGGER: Break at line " + string(_dbg.current_line));
        // In a real implementation, you'd pause here and wait for user input
        // For now, just log and continue
    }
    
    // If it's an array, evaluate each and return last
    if (is_array(_node)) {
        var _result = undefined;
        for (var _i = 0; _i < array_length(_node); _i++) {
            _result = gml_vm_evaluate(_node[_i], _ctx);
        }
        return _result;
    }
    
    // Call the node's Execute method
    if (struct_exists(_node, "Execute")) {
        return _node.Execute(_ctx);
    }
    
    // Fallback - return the node itself
    return _node;
}

/// @func gml_vm(ast, _self, _other)
/// @desc Executes a parsed AST
function gml_vm(_ast, _self = self, _other = other) {
    var _ctx = new gmlVMContext(_self, _other);
    
    try {
        var _result = gml_vm_evaluate(_ast, _ctx);
        
        // Unwrap return interrupt
        if (is_struct(_result) && struct_exists(_result, "type")) {
            if (_result.type == "return") {
                return _result.value;
            }
        }
        
        return _result;
    } catch (_err) {
        show_debug_message("VM Runtime Error: " + string(_err));
        return undefined;
    }
}

/// @func gml_run(code, _self, _other)
/// @desc Tokenize, parse, and execute GML code
function gml_run(_code, _self = self, _other = other) {
    var _tokens = gml_tokenize(_code);
    var _ast = gml_parse(_tokens);
    return gml_vm(_ast, _self, _other);
}

/// @func gmlParseError(message, line, column)
/// @desc Creates a parse error object
function gmlParseError(_message, _line, _column) constructor {
    type    = "parse_error";
    message = _message;
    line    = _line;
    column  = _column;
    
    static toString = function() {
        return "Parse Error at line " + string(line) + ", column " + string(column) + ": " + message;
    };
}

/// @func gmlRuntimeError(message, line, column)
/// @desc Creates a runtime error object
function gmlRuntimeError(_message, _line, _column) constructor {
    type    = "runtime_error";
    message = _message;
    line    = _line;
    column  = _column;
    
    static toString = function() {
        return "Runtime Error at line " + string(line) + ", column " + string(column) + ": " + message;
    };
}

/// @func gmlCache()
/// @desc Creates a cache for parsed ASTs
function gmlCache() constructor {
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

// Global cache instance
global.__gml_ast_cache = new gmlCache();

/// @func gml_parse_cached(code)
/// @desc Parses code with caching
function gml_parse_cached(_code) {
    var _cached = global.__gml_ast_cache.Get(_code);
    if (_cached != undefined) {
        show_debug_message("gml_parse: Using cached AST");
        return _cached;
    }
    
    var _tokens = gml_tokenize(_code);
    var _ast = gml_parse(_tokens);
    global.__gml_ast_cache.Set(_code, _ast);
    
    return _ast;
}

/// @func gml_run_cached(code, _self, _other)
/// @desc Runs code with AST caching
function gml_run_cached(_code, _self = self, _other = other) {
    var _ast = gml_parse_cached(_code);
    return gml_vm(_ast, _self, _other);
}

/// @func gmlSandbox()
/// @desc Creates a sandbox for secure code execution
function gmlSandbox() constructor {
    blacklist_functions = ds_map_create();
    blacklist_objects   = ds_map_create();
    blacklist_variables = ds_map_create();
    
    // ───────────────────────────────────────────────────────────────
    static BanFunction = function(_func_name) {
        blacklist_functions[? _func_name] = true;
    };
    
    static BanObject = function(_obj_name) {
        blacklist_objects[? _obj_name] = true;
    };
    
    static BanVariable = function(_var_name) {
        blacklist_variables[? _var_name] = true;
    };
    
    // ───────────────────────────────────────────────────────────────
    static IsFunctionBanned = function(_func_name) {
        return ds_map_exists(blacklist_functions, _func_name);
    };
    
    static IsObjectBanned = function(_obj_name) {
        return ds_map_exists(blacklist_objects, _obj_name);
    };
    
    static IsVariableBanned = function(_var_name) {
        return ds_map_exists(blacklist_variables, _var_name);
    };
    
    // ───────────────────────────────────────────────────────────────
    static CheckFunction = function(_func) {
        if (is_real(_func)) {
            var _name = script_get_name(_func);
            if (IsFunctionBanned(_name)) {
                throw "Sandbox: Function '" + _name + "' is banned";
            }
        }
    };
    
    static CheckVariable = function(_name) {
        if (IsVariableBanned(_name)) {
            throw "Sandbox: Variable '" + _name + "' is banned";
        }
    };
    
    // ───────────────────────────────────────────────────────────────
    static Destroy = function() {
        ds_map_destroy(blacklist_functions);
        ds_map_destroy(blacklist_objects);
        ds_map_destroy(blacklist_variables);
    };
}

/// @func gml_run_sandboxed(code, sandbox, _self, _other)
/// @desc Runs code with sandbox restrictions
function gml_run_sandboxed(_code, _sandbox, _self = self, _other = other) {
    // Set current sandbox
    global.__gml_current_sandbox = _sandbox;
    
    var _result = undefined;
    try {
        _result = gml_run(_code, _self, _other);
    } catch (_err) {
        _result = new gmlRuntimeError(_err, -1, -1);
    }
    
    global.__gml_current_sandbox = undefined;
    return _result;
}

/// @func gmlDebugger()
/// @desc Creates a debugger for step-through execution
function gmlDebugger() constructor {
    enabled = false;
    breakpoints = ds_map_create();
    current_node = undefined;
    current_line = -1;
    step_mode = "none";  // "none", "step_over", "step_into", "step_out"
    call_depth = 0;
    
    // ───────────────────────────────────────────────────────────────
    static Enable = function() {
        enabled = true;
    };
    
    static Disable = function() {
        enabled = false;
    };
    
    // ───────────────────────────────────────────────────────────────
    static SetBreakpoint = function(_line) {
        breakpoints[? string(_line)] = true;
    };
    
    static RemoveBreakpoint = function(_line) {
        ds_map_delete(breakpoints, string(_line));
    };
    
    static ClearBreakpoints = function() {
        ds_map_clear(breakpoints);
    };
    
    // ───────────────────────────────────────────────────────────────
    static StepOver = function() {
        step_mode = "step_over";
    };
    
    static StepInto = function() {
        step_mode = "step_into";
    };
    
    static StepOut = function() {
        step_mode = "step_out";
    };
    
    static Continue = function() {
        step_mode = "none";
    };
    
    // ───────────────────────────────────────────────────────────────
    static ShouldBreak = function(_node) {
        if (!enabled) return false;
        
        // Check breakpoints
        if (struct_exists(_node, "line")) {
            if (ds_map_exists(breakpoints, string(_node.line))) {
                return true;
            }
        }
        
        // Check step mode
        switch (step_mode) {
            case "step_into":
                step_mode = "none";
                return true;
            case "step_over":
                if (call_depth == 0) {
                    step_mode = "none";
                    return true;
                }
                break;
        }
        
        return false;
    };
    
    // ───────────────────────────────────────────────────────────────
    static OnNodeEnter = function(_node) {
        current_node = _node;
        if (struct_exists(_node, "line")) {
            current_line = _node.line;
        }
    };
    
    static OnCallEnter = function() {
        call_depth++;
    };
    
    static OnCallExit = function() {
        call_depth--;
        if (step_mode == "step_out" && call_depth == 0) {
            step_mode = "none";
        }
    };
    
    // ───────────────────────────────────────────────────────────────
    static GetState = function() {
        return {
            current_line: current_line,
            call_depth: call_depth,
            node_type: is_struct(current_node) ? current_node.type : "none"
        };
    };
    
    // ───────────────────────────────────────────────────────────────
    static Destroy = function() {
        ds_map_destroy(breakpoints);
    };
}

global.__gml_debugger = new gmlDebugger();

function gmlTryNode(_try_block, _catch_var, _catch_block, _finally_block, _line = -1, _column = -1) constructor {
    type          = "try";
    try_block     = _try_block;
    catch_var     = _catch_var;
    catch_block   = _catch_block;
    finally_block = _finally_block;
    line          = _line;
    column        = _column;
    
    static Execute = function(_ctx) {
        var _result = undefined;
        var _error = undefined;
        var _caught = false;
        
        // Try block
        try {
            _result = gml_vm_evaluate(try_block, _ctx);
        } catch (_err) {
            _error = _err;
            _caught = true;
            
            // Execute catch block if present
            if (catch_block != undefined) {
                // Set the catch variable in a new scope
                _ctx.PushScope();
                if (catch_var != "") {
                    _ctx.locals[$ catch_var] = _error;
                }
                _result = gml_vm_evaluate(catch_block, _ctx);
                _ctx.PopScope();
            }
        } finally {
            // Execute finally block if present
            if (finally_block != undefined) {
                gml_vm_evaluate(finally_block, _ctx);
            }
        }
        
        // Rethrow if error wasn't caught
        if (_caught && catch_block == undefined) {
            throw _error;
        }
        
        return _result;
    };
}

function gmlThrowNode(_expr, _line = -1, _column = -1) constructor {
    type   = "throw";
    expr   = _expr;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _val = gml_vm_evaluate(expr, _ctx);
        throw _val;
    };
}

//function gmlStaticNode(_name, _value, _line = -1, _column = -1) constructor {
//    type   = "static";
//    name   = _name;
//    value  = _value;
//    line   = _line;
//    column = _column;
//    
//    Execute = function(_ctx) {
//        // Check if static already exists
//        if (!struct_exists(_ctx.statics, name)) {
//            var _val = undefined;
//            if (value != undefined) {
//                _val = gml_vm_evaluate(value, _ctx);
//            }
//            _ctx.statics[$ name] = _val;
//        }
//        return _ctx.statics[$ name];
//    };
//}{
//    type   = "static";
//    name   = _name;
//    value  = _value;
//    line   = _line;
//    column = _column;
//    
//    Execute = function(_ctx) {
//        var _val = undefined;
//        if (value != undefined) {
//            _val = gml_vm_evaluate(value, _ctx);
//        }
//        _ctx.SetStatic(name, _val);
//        return _val;
//    };
//}

function gmlNewNode(_constructor, _args, _line = -1, _column = -1) constructor {
    type        = "new";
    constructor = _constructor;
    args        = _args;
    line        = _line;
    column      = _column;
    
    static Execute = function(_ctx) {
        // Evaluate constructor function
        var _ctor = gml_vm_evaluate(constructor, _ctx);
        
        // Evaluate arguments
        var _arg_values = [];
        for (var _i = 0; _i < array_length(args); _i++) {
            _arg_values[_i] = gml_vm_evaluate(args[_i], _ctx);
        }
        
        // Check if it's a valid constructor
        if (!is_struct(_ctor) || !struct_exists(_ctor, "__gml_type") || _ctor.__gml_type != "function") {
            show_debug_message("VM Error: Cannot use 'new' on non-function value");
            return {};
        }
        
        // Force it to run as constructor
        var _is_constructor = _ctor.__gml_is_constructor;
        _ctor.__gml_is_constructor = true;
        
        // Call the function as constructor
        var _instance = gml_vm_call_gml_function(_ctor, _arg_values, _ctx);
        
        // Restore original setting
        _ctor.__gml_is_constructor = _is_constructor;
        
        return _instance;
    };
}

// ── peek / consume helpers ────────────────────────────────────────
function _gml_tok(_tokens, _pos) {
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

/// @func gml_vm_builtin(name)
/// @desc Checks if name is a built-in constant or function
function gml_vm_builtin(_name) {
    static _found = false;
    static _value = undefined;
    
    _found = true;
    
    // Keywords
    switch (_name) {
        case "true":      _value = true;      return { found: _found, value: _value };
        case "false":     _value = false;     return { found: _found, value: _value };
        case "undefined": _value = undefined; return { found: _found, value: _value };
        case "self":      _value = -1;        return { found: _found, value: _value };
        case "other":     _value = -2;        return { found: _found, value: _value };
        case "all":       _value = -3;        return { found: _found, value: _value };
        case "noone":     _value = -4;        return { found: _found, value: _value };
        case "global":    _value = global;    return { found: _found, value: _value };
    }
    
    // Math constants
    if (_name == "pi") {
        _value = pi;
        return { found: _found, value: _value };
    }
    
    // Math functions
    if (_name == "sqrt") { _value = sqrt; return { found: _found, value: _value }; }
	if (_name == "sin") { _value = sin; return { found: true, value: _value }; }
    if (_name == "cos") { _value = cos; return { found: true, value: _value }; }
    if (_name == "tan") { _value = tan; return { found: true, value: _value }; }
    if (_name == "power") { _value = power; return { found: true, value: _value }; }
    if (_name == "abs") { _value = abs; return { found: true, value: _value }; }
    if (_name == "round") { _value = round; return { found: true, value: _value }; }
    if (_name == "floor") { _value = floor; return { found: true, value: _value }; }
    if (_name == "ceil") { _value = ceil; return { found: true, value: _value }; }
    if (_name == "random") { _value = random; return { found: true, value: _value }; }
    if (_name == "irandom") { _value = irandom; return { found: true, value: _value }; }
    if (_name == "string") { _value = string; return { found: true, value: _value }; }
    if (_name == "real") { _value = real; return { found: true, value: _value }; }
    if (_name == "is_string") { _value = is_string; return { found: true, value: _value }; }
    if (_name == "is_real") { _value = is_real; return { found: true, value: _value }; }
    if (_name == "is_array") { _value = is_array; return { found: true, value: _value }; }
    if (_name == "is_struct") { _value = is_struct; return { found: true, value: _value }; }
    if (_name == "array_length") { _value = array_length; return { found: true, value: _value }; }
    if (_name == "struct_get_names") { _value = struct_get_names; return { found: true, value: _value }; }
    if (_name == "struct_exists") { _value = struct_exists; return { found: true, value: _value }; }
    if (_name == "show_debug_message") { _value = show_debug_message; return { found: true, value: _value }; }
    
    _found = false;
    return { found: _found, value: undefined };
}

//function gmlStaticAssignNode(_name, _value, _line = -1, _column = -1) constructor {
//    type   = "static_assign";
//    name   = _name;
//    value  = _value;
//    line   = _line;
//    column = _column;
//    
//    Execute = function(_ctx) {
//        var _val = undefined;
//        if (value != undefined) {
//            _val = gml_vm_evaluate(value, _ctx);
//        }
//        _ctx.SetStatic(name, _val);
//        return _val;
//    };
//}

function gmlStaticInitNode(_name, _value, _line = -1, _column = -1) constructor {
    type   = "static_init";
    name   = _name;
    value  = _value;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        // Mark this variable as static
        _ctx.MarkStatic(name);
        
        // Only set if the static doesn't already exist
        if (!struct_exists(_ctx.statics, name)) {
            var _val = undefined;
            if (value != undefined) {
                _val = gml_vm_evaluate(value, _ctx);
            }
            _ctx.statics[$ name] = _val;
        }
        return _ctx.statics[$ name];
    };
}

function gmlPostfixOpNode(_op, _operand, _line = -1, _column = -1) constructor {
    type    = "postfix_op";
    op      = _op;
    operand = _operand;
    line    = _line;
    column  = _column;
    
    Execute = function(_ctx) {
        var _val = gml_vm_evaluate(operand, _ctx);
        
        // Handle undefined
        if (_val == undefined) {
            _val = 0;
        }
        
        var _old_val = _val;
        
        if (operand.type == "var") {
            if (op == "++") {
                _ctx.SetVar(operand.name, _val + 1);
            } else {
                _ctx.SetVar(operand.name, _val - 1);
            }
        }
        
        // Postfix returns the OLD value
        return _old_val;
    };
}




