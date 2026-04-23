function _gmlvm_infix_bp(_op) {
    switch (_op) {
        case "||":            return [1, 2];
        case "&&":            return [3, 4];
        case "??":            return [3, 4];
        case "==": case "!=":
        case "<":  case ">":
        case "<=": case ">=": return [5, 6];
        case "|":             return [7, 8];
        case "^":             return [9, 10];
        case "&":             return [11, 12];
        case "<<": case ">>": return [13, 14];
        case "+":  case "-":  return [15, 16];
        case "*":  case "/":
        case "%":             return [17, 18];
    }
    return [-1, -1];   // not an infix op
}

function _gmlvm_prefix_bp(_op) {
    switch (_op) {
        case "!": case "-":
        case "++": case "--":
        case "~":             return 11;
    }
    return -1;
}

function _gmlvm_parse_primary(_tokens, _pos) {
    var _t = _gmlvm_tok(_tokens, _pos);
    var _line = _t.line;
    var _col = _t.column;

    // parenthesised sub-expression  ( expr )
    if (_t.type == "paren" && _t.value == "(") {
        var _res = gmlvm_parse_expression(_tokens, _pos + 1);
        var _node = _res[0];
        var _p    = _res[1];
        var _close = _gmlvm_tok(_tokens, _p);
        if (_close.type == "paren" && _close.value == ")") _p++;
        return _gmlvm_parse_postfix(_tokens, _p, _node);
    }

    // prefix unary:  !expr  -expr  ++expr  --expr  ~expr
    if (_t.type == "operator" && _gmlvm_prefix_bp(_t.value) > 0) {
        var _op  = _t.value;
        var _res = _gmlvm_parse_primary(_tokens, _pos + 1);
        return [new gmlvm_unary_op_node(_op, _res[0], _line, _col), _res[1]];
    }

    // number literal
    if (_t.type == "number") {
        return [new gmlvm_number_node(_t.value, _line, _col), _pos + 1];
    }

    // boolean keywords -> number (1 / 0)
    if (_t.type == "keyword" && (_t.value == "true" || _t.value == "false")) {
        return [new gmlvm_number_node(_t.value == "true" ? 1 : 0, _line, _col), _pos + 1];
    }

    // string literal
    if (_t.type == "string") {
        return [new gmlvm_string_node(_t.value, _line, _col), _pos + 1];
    }
	
	// template string literal
	if (_t.type == "template_string") {
	    return [new gmlvm_template_string_node(_t.parts, _line, _col), _pos + 1];
	}
	
	// Map literal: [? key: value, ... ]
	if (_t.type == "map_open") {
	    _pos++;
	    var _fields = [];
    
	    var _next = _gmlvm_tok(_tokens, _pos);
	    if (_next.type == "bracket" && _next.value == "]") {
	        _pos++;
	        return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_map_node([], _line, _col));
	    }
    
	    while (true) {
	        var _key_tok = _gmlvm_tok(_tokens, _pos);
	        if (_key_tok.type == "bracket" && _key_tok.value == "]") {
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
	            return [new gmlvm_parse_error("Expected identifier or string as map key", _key_tok.line, _key_tok.column), _pos];
	        }
        
	        var _sep = _gmlvm_tok(_tokens, _pos);
	        if (!(_sep.type == "operator" && _sep.value == ":")) {
	            return [new gmlvm_parse_error("Expected ':' after map key", _sep.line, _sep.column), _pos];
	        }
	        _pos++;
        
	        var _vr = gmlvm_parse_expression(_tokens, _pos);
	        var _value = _vr[0];
	        _pos = _vr[1];
        
	        array_push(_fields, { key: _key, value: _value });
        
	        var _after = _gmlvm_tok(_tokens, _pos);
	        if (_after.type == "separator" && _after.value == ",") {
	            _pos++;
	            continue;
	        } else if (_after.type == "bracket" && _after.value == "]") {
	            _pos++;
	            break;
	        }
	    }
    
	    return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_map_node(_fields, _line, _col));
	}

	// List literal: [| item1, item2, ... ]
	if (_t.type == "list_open") {
	    _pos++;
	    var _items = [];
    
	    var _next = _gmlvm_tok(_tokens, _pos);
	    if (_next.type == "bracket" && _next.value == "]") {
	        _pos++;
	        return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_list_node([], _line, _col));
	    }
    
	    while (true) {
	        var _er = gmlvm_parse_expression(_tokens, _pos);
	        array_push(_items, _er[0]);
	        _pos = _er[1];
        
	        var _sep = _gmlvm_tok(_tokens, _pos);
	        if (_sep.type == "separator" && _sep.value == ",") {
	            _pos++;
	        } else if (_sep.type == "bracket" && _sep.value == "]") {
	            _pos++;
	            break;
	        } else {
	            break;
	        }
	    }
    
	    return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_list_node(_items, _line, _col));
	}

    // array literal: [ expr, expr, ... ]
    if (_t.type == "bracket" && _t.value == "[") {
        _pos++;
        var _elements = [];
        var _next = _gmlvm_tok(_tokens, _pos);
        
        if (_next.type == "bracket" && _next.value == "]") {
            return _gmlvm_parse_postfix(_tokens, _pos + 1, new gmlvm_array_node([], _line, _col));
        }
        
        while (true) {
            var _er = gmlvm_parse_expression(_tokens, _pos);
            array_push(_elements, _er[0]);
            _pos = _er[1];
            var _sep = _gmlvm_tok(_tokens, _pos);
            if (_sep.type == "separator" && _sep.value == ",") {
                _pos++;
            } else {
                break;
            }
        }
        var _close = _gmlvm_tok(_tokens, _pos);
        if (_close.type == "bracket" && _close.value == "]") _pos++;
        
        return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_array_node(_elements, _line, _col));
    }

    // struct literal: { key: value, key2, ... }
    if (_t.type == "brace" && _t.value == "{") {
        _pos++;
        var _fields = [];
        
        var _next = _gmlvm_tok(_tokens, _pos);
        if (_next.type == "brace" && _next.value == "}") {
            _pos++;
            return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_struct_node([], _line, _col));
        }
        
        while (true) {
            var _key_tok = _gmlvm_tok(_tokens, _pos);
            
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
                return [new gmlvm_parse_error("Expected identifier or string as struct key, got " + _key_tok.type, _key_tok.line, _key_tok.column), _pos];
            }
            
            var _value = undefined;
            var _sep = _gmlvm_tok(_tokens, _pos);
            
            if (_sep.type == "operator" && _sep.value == ":") {
                _pos++;
                var _vr = gmlvm_parse_expression(_tokens, _pos);
                _value = _vr[0];
                _pos = _vr[1];
            } else {
                _value = new gmlvm_var_node(_key, _key_tok.line, _key_tok.column);
            }
            
            array_push(_fields, { key: _key, value: _value });
            
            var _after = _gmlvm_tok(_tokens, _pos);
            if (_after.type == "separator" && _after.value == ",") {
                _pos++;
                var _after_comma = _gmlvm_tok(_tokens, _pos);
                if (_after_comma.type == "brace" && _after_comma.value == "}") {
                    _pos++;
                    break;
                }
                continue;
            } else if (_after.type == "brace" && _after.value == "}") {
                _pos++;
                break;
            } else {
                return [new gmlvm_parse_error("Expected ',' or '}' after struct field, got " + _after.type, _after.line, _after.column), _pos];
            }
        }
        
        return _gmlvm_parse_postfix(_tokens, _pos, new gmlvm_struct_node(_fields, _line, _col));
    }

    // new expression (constructor call)
    if (_t.type == "keyword" && _t.value == "new") {
        _pos++;
        
        var _ctor_tok = _gmlvm_tok(_tokens, _pos);
        if (_ctor_tok.type != "identifier") {
            return [new gmlvm_parse_error("Expected constructor name after 'new'", _ctor_tok.line, _ctor_tok.column), _pos];
        }
        var _ctor_name = _ctor_tok.value;
        _pos++;
        
        // Parse arguments
        var _args = [];
        var _open = _gmlvm_tok(_tokens, _pos);
        if (_open.type == "paren" && _open.value == "(") {
            _pos++;
            var _nt = _gmlvm_tok(_tokens, _pos);
            if (!(_nt.type == "paren" && _nt.value == ")")) {
                while (true) {
                    var _ar = gmlvm_parse_expression(_tokens, _pos);
                    array_push(_args, _ar[0]);
                    _pos = _ar[1];
                    var _sep = _gmlvm_tok(_tokens, _pos);
                    if (_sep.type == "separator" && _sep.value == ",") {
                        _pos++;
                    } else {
                        break;
                    }
                }
            }
            var _rp = _gmlvm_tok(_tokens, _pos);
            if (_rp.type == "paren" && _rp.value == ")") _pos++;
        }
        
        var _ctor_var = new gmlvm_var_node(_ctor_name, _ctor_tok.line, _ctor_tok.column);
        var _node = new gmlvm_new_node(_ctor_var, _args, _line, _col);
        
        return _gmlvm_parse_postfix(_tokens, _pos, _node);
    }

    // delete operator
    if (_t.type == "keyword" && _t.value == "delete") {
        _pos++;
        var _target_res = _gmlvm_parse_primary(_tokens, _pos);
        var _target = _target_res[0];
        _pos = _target_res[1];
        
        return [new gmlvm_delete_node(_target, _line, _col), _pos];
    }

    // function expression
    if (_t.type == "keyword" && _t.value == "function") {
        _pos++;
        
        var _name = "";
        var _next = _gmlvm_tok(_tokens, _pos);
        if (_next.type == "identifier") {
            _name = _next.value;
            _pos++;
        }
        
        var _params = [];
		var _param_defaults = {};
		var _open = _gmlvm_tok(_tokens, _pos);
		if (!(_open.type == "paren" && _open.value == "(")) {
		    return [new gmlvm_parse_error("Expected '(' in function declaration", _open.line, _open.column), _pos];
		}
		_pos++;

		var _close = _gmlvm_tok(_tokens, _pos);
		if (!(_close.type == "paren" && _close.value == ")")) {
		    while (true) {
		        var _p = _gmlvm_tok(_tokens, _pos);
		        if (_p.type == "identifier") {
		            var _param_name = _p.value;
		            array_push(_params, _param_name);
		            _pos++;
            
		            // Check for default value
		            var _eq = _gmlvm_tok(_tokens, _pos);
		            if (_eq.type == "operator" && _eq.value == "=") {
		                _pos++;
		                var _default_res = gmlvm_parse_expression(_tokens, _pos);
		                _param_defaults[$ _param_name] = _default_res[0];
		                _pos = _default_res[1];
		            }
		        } else {
		            break;
		        }
		        var _sep = _gmlvm_tok(_tokens, _pos);
		        if (_sep.type == "separator" && _sep.value == ",") {
		            _pos++;
		        } else {
		            break;
		        }
		    }
		}
		var _rp = _gmlvm_tok(_tokens, _pos);
		if (_rp.type == "paren" && _rp.value == ")") _pos++;
        
        // check for inheritance (:) and constructor keyword
        var _is_constructor = false;
        var _inherit = undefined;
        var _inherit_args = [];
        
        var _colon = _gmlvm_tok(_tokens, _pos);
        if (_colon.type == "operator" && _colon.value == ":") {
            _pos++;
            var _parent = _gmlvm_tok(_tokens, _pos);
            if (_parent.type == "identifier") {
                _inherit = _parent.value;
                _pos++;
                
                // Parse parent constructor arguments
                var _par_open = _gmlvm_tok(_tokens, _pos);
                if (_par_open.type == "paren" && _par_open.value == "(") {
                    _pos++;
                    var _nt = _gmlvm_tok(_tokens, _pos);
                    if (!(_nt.type == "paren" && _nt.value == ")")) {
                        while (true) {
                            var _ar = gmlvm_parse_expression(_tokens, _pos);
                            array_push(_inherit_args, _ar[0]);
                            _pos = _ar[1];
                            var _sep = _gmlvm_tok(_tokens, _pos);
                            if (_sep.type == "separator" && _sep.value == ",") {
                                _pos++;
                            } else {
                                break;
                            }
                        }
                    }
                    var _par_close = _gmlvm_tok(_tokens, _pos);
                    if (_par_close.type == "paren" && _par_close.value == ")") _pos++;
                }
            }
        }
        
        var _next2 = _gmlvm_tok(_tokens, _pos);
        if (_next2.type == "keyword" && _next2.value == "constructor") {
            _is_constructor = true;
            _pos++;
        }
        
        var _br = gmlvm_parse_block(_tokens, _pos);
        var _body = _br[0];
        _pos = _br[1];
        
        var _func_node = new gmlvm_function_node(_name, _params, _param_defaults, _body, _is_constructor, _inherit, _inherit_args, _line, _col);
        
        // function expressions dont get postfix handling (they cant be called immediately)
        return [_func_node, _pos];
    }

    // identifier - variable, with postfix handling
    if (_t.type == "identifier") {
        var _node = new gmlvm_var_node(_t.value, false, _line, _col);
        return _gmlvm_parse_postfix(_tokens, _pos + 1, _node);
    }

    // fallback - parse error
    return [new gmlvm_parse_error("Unexpected token: " + _t.type + " '" + string(_t.value) + "'", _line, _col), _pos];
}

function _gmlvm_parse_postfix(_tokens, _pos, _node) {
    while (true) {
        var _next = _gmlvm_tok(_tokens, _pos);
        
        // Accessors: expr [@ index], expr [$ index], expr [# index], expr [? index]
        if (_next.type == "accessor") {
            var _kind = "bracket";
            var _accessor_type = _next.value;  // "[@", "[$", "[#", "[?"
            _pos++;
            
            var _ir = gmlvm_parse_expression(_tokens, _pos);
            var _index = _ir[0];
            _pos = _ir[1];
            
            var _close = _gmlvm_tok(_tokens, _pos);
            if (_close.type == "bracket" && _close.value == "]") _pos++;
            
            _node = new gmlvm_access_node(_node, _index, _accessor_type);
            continue;
        }
        
        // function call:  expr ( args... )
        //if (_next.type == "paren" && _next.value == "(") {
        //    var _args = [];
        //    var _p = _pos + 1;
        //    var _nt = _gmlvm_tok(_tokens, _p);
        //    if (!(_nt.type == "paren" && _nt.value == ")")) {
        //        while (true) {
        //            var _ar = gmlvm_parse_expression(_tokens, _p);
        //            array_push(_args, _ar[0]);
        //            _p = _ar[1];
        //            var _sep = _gmlvm_tok(_tokens, _p);
        //            if (_sep.type == "separator" && _sep.value == ",") {
        //                _p++;
        //            } else break;
        //        }
        //    }
        //    var _rp = _gmlvm_tok(_tokens, _p);
        //    if (_rp.type == "paren" && _rp.value == ")") _p++;
        //    _node = new gmlvm_call_node(_node, _args);
        //    _pos = _p;
        //    continue;
        //}
		if (_next.type == "paren" && _next.value == "(") {
		    var _line = _next.line;
		    var _col = _next.column;
		    var _args = [];
		    var _p = _pos + 1;
		    var _nt = _gmlvm_tok(_tokens, _p);
		    if (!(_nt.type == "paren" && _nt.value == ")")) {
		        while (true) {
		            var _ar = gmlvm_parse_expression(_tokens, _p);
		            array_push(_args, _ar[0]);
		            _p = _ar[1];
		            var _sep = _gmlvm_tok(_tokens, _p);
		            if (_sep.type == "separator" && _sep.value == ",") {
		                _p++;
		            } else break;
		        }
		    }
		    var _rp = _gmlvm_tok(_tokens, _p);
		    if (_rp.type == "paren" && _rp.value == ")") _p++;
		    _node = new gmlvm_call_node(_node, _args, _line, _col);
		    _pos = _p;
		    continue;
		}
        
        // Regular bracket access: expr [ index ]
        if (_next.type == "bracket" && _next.value == "[") {
            var _p = _pos + 1;
            var _ir = gmlvm_parse_expression(_tokens, _p);
            var _index = _ir[0];
            _p = _ir[1];
            var _close = _gmlvm_tok(_tokens, _p);
            if (_close.type == "bracket" && _close.value == "]") _p++;
            _node = new gmlvm_access_node(_node, _index, "bracket");
            _pos = _p;
            continue;
        }
        
        // bracket access:  expr [ index ]
        if (_next.type == "bracket" && _next.value == "[") {
            var _p = _pos + 1;
            var _ir = gmlvm_parse_expression(_tokens, _p);
            var _index = _ir[0];
            _p = _ir[1];
            var _close = _gmlvm_tok(_tokens, _p);
            if (_close.type == "bracket" && _close.value == "]") _p++;
            _node = new gmlvm_access_node(_node, _index, "bracket");
            _pos = _p;
            continue;
        }
        
        // dot access:  expr . identifier
        if (_next.type == "operator" && _next.value == ".") {
            _pos++;
            var _prop_tok = _gmlvm_tok(_tokens, _pos);
            if (_prop_tok.type == "identifier") {
                _pos++;
                _node = new gmlvm_access_node(_node, new gmlvm_string_node(_prop_tok.value), "dot");
            }
            continue;
        }
        
        // postfix increment/decrement:  expr++  expr--
        if (_next.type == "operator" 
        && (_next.value == "++" || _next.value == "--")) {
            _node = new gmlvm_postfix_op_node(_next.value, _node, _next.line, _next.column);
            _pos++;
            continue;
        }
        
        break;
    }
    
    return [_node, _pos];
}

function gmlvm_parse_expression(_tokens, _start_index) {
    var _res  = _gmlvm_parse_primary(_tokens, _start_index);
    var _left = _res[0];
    var _pos  = _res[1];

    // Climb infix operators
    while (true) {
        var _t  = _gmlvm_tok(_tokens, _pos);
        
        // Check if this is ?? operator (two tokens)
        var _t2 = _gmlvm_tok(_tokens, _pos + 1);
        if (_t.value == "?" && _t2.value == "?") {
            // This is ??, not ternary - handled in binary op climbing
        }
        
        var _bp = [-1, -1];
        if (_t.value == "instanceof") {
            _bp = [5, 6];
        } else if (_t.value == "??") {
            _bp = [3, 4];
        } else {
            _bp = _gmlvm_infix_bp(_t.value);
        }
        
        if (_bp[0] < 0) break;
        var _l_bp = _bp[0];
        var _r_bp = _bp[1];
        _pos++;
        var _rr    = gmlvm_parse_expression_bp(_tokens, _pos, _r_bp);
        var _right = _rr[0];
        _pos       = _rr[1];
        
        if (_t.value == "??") {
            _left = new gmlvm_nullish_coalesce_node(_left, _right, _t.line, _t.column);
        } else {
            _left = new gmlvm_binary_op_node(_t.value, _left, _right, _t.line, _t.column);
        }
    }
    
    // Handle ternary operator - ONLY if it's a single ?, not ??
    var _t = _gmlvm_tok(_tokens, _pos);
    var _t2 = _gmlvm_tok(_tokens, _pos + 1);
    
    if (_t.type == "operator" && _t.value == "?" && _t2.value != "?") {
        _pos++;
        var _true_res = gmlvm_parse_expression(_tokens, _pos);
        var _true_expr = _true_res[0];
        _pos = _true_res[1];
        
        var _colon = _gmlvm_tok(_tokens, _pos);
        if (!(_colon.type == "operator" && _colon.value == ":")) {
            gmlvm_warning("parse_error", "Expected ':' in ternary expression", _colon.line, _colon.column);
            return [_left, _pos];
        }
        _pos++;
        
        var _false_res = gmlvm_parse_expression(_tokens, _pos);
        var _false_expr = _false_res[0];
        _pos = _false_res[1];
        
        _left = new gmlvm_ternary_node(_left, _true_expr, _false_expr, _t.line, _t.column);
    }

    return [_left, _pos];
}

function gmlvm_parse_expression_bp(_tokens, _start, _min_bp) {
    var _res  = _gmlvm_parse_primary(_tokens, _start);
    var _left = _res[0];
    var _pos  = _res[1];

    while (true) {
        var _t  = _gmlvm_tok(_tokens, _pos);
        
        var _bp = [-1, -1];
        if (_t.value == "instanceof") {
            _bp = [5, 6];
        } else if (_t.value == "??") {
            _bp = [3, 4];
        } else {
            _bp = _gmlvm_infix_bp(_t.value);
        }
        
        if (_bp[0] < _min_bp) break;
        var _r_bp = _bp[1];
        _pos++;
        
        var _rr    = gmlvm_parse_expression_bp(_tokens, _pos, _r_bp);
        var _right = _rr[0];
        _pos       = _rr[1];
        
        if (_t.value == "??") {
            _left = new gmlvm_nullish_coalesce_node(_left, _right, _t.line, _t.column);
        } else {
            _left = new gmlvm_binary_op_node(_t.value, _left, _right, _t.line, _t.column);
        }
    }

    return [_left, _pos];
}

function gmlvm_parse_statement(_tokens, _pos) {
    var _t = _gmlvm_tok(_tokens, _pos);

    // empty statement (just a semicolon)
    if (_t.type == "separator" && _t.value == ";") {
        return [undefined, _pos + 1];
    }
	
	// enum declaration
	if (_t.type == "keyword" && _t.value == "enum") {
	    var _line = _t.line;
	    var _col = _t.column;
	    _pos++;
    
	    var _name_tok = _gmlvm_tok(_tokens, _pos);
	    var _enum_name = "";
	    if (_name_tok.type == "identifier") {
	        _enum_name = _name_tok.value;
	        _pos++;
	    }
    
	    var _open = _gmlvm_tok(_tokens, _pos);
	    if (!(_open.type == "brace" && _open.value == "{")) {
	        gmlvm_warning("parse_error", "Expected '{' after enum name", _open.line, _open.column);
	        return [undefined, _pos];
	    }
	    _pos++;
    
	    var _fields = [];
	    var _counter = 0;
    
	    while (true) {
	        var _next = _gmlvm_tok(_tokens, _pos);
	        if (_next.type == "brace" && _next.value == "}") {
	            _pos++;
	            break;
	        }
        
	        if (_next.type == "identifier") {
	            var _field_name = _next.value;
	            _pos++;
            
	            var _value = undefined;
	            var _eq = _gmlvm_tok(_tokens, _pos);
	            if (_eq.type == "operator" && _eq.value == "=") {
	                _pos++;
	                var _er = gmlvm_parse_expression(_tokens, _pos);
	                _value = _er[0];
	                _pos = _er[1];
	            } else {
	                _value = new gmlvm_number_node(_counter, _line, _col);
	            }
            
	            array_push(_fields, { key: _field_name, value: _value });
            
	            // Update counter if value is a number literal
	            if (_value.type == "number") {
	                _counter = _value.value + 1;
	            } else {
	                _counter++;
	            }
            
	            var _comma = _gmlvm_tok(_tokens, _pos);
	            if (_comma.type == "separator" && _comma.value == ",") {
	                _pos++;
	            }
	        } else {
	            break;
	        }
	    }
    
	    // Create enum as a struct and assign to variable
	    var _enum_struct = new gmlvm_struct_node(_fields, _line, _col);
	    var _var_node = new gmlvm_var_node(_enum_name, _line, _col);
	    var _assign_node = new gmlvm_assign_node(_var_node, _enum_struct, _line, _col);
    
	    return [_assign_node, _pos];
	}
	
	// exit statement
	if (_t.type == "keyword" && _t.value == "exit") {
	    var _line = _t.line;
	    var _col = _t.column;
	    _pos++;
    
	    var _sc = _gmlvm_tok(_tokens, _pos);
	    if (_sc.type == "separator" && _sc.value == ";") _pos++;
    
	    return [new gmlvm_exit_node(_line, _col), _pos];
	}
	
	// try statement
    if (_t.type == "keyword" && _t.value == "try") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _tr = gmlvm_parse_statement(_tokens, _pos);
        var _try_block = _tr[0]; _pos = _tr[1];
        
        var _catch_var = "";
        var _catch_block = undefined;
        var _finally_block = undefined;
        
        var _next = _gmlvm_tok(_tokens, _pos);
        if (_next.type == "keyword" && _next.value == "catch") {
            _pos++;
            var _open = _gmlvm_tok(_tokens, _pos);
            if (_open.type == "paren" && _open.value == "(") {
                _pos++;
                var _var_tok = _gmlvm_tok(_tokens, _pos);
                if (_var_tok.type == "identifier") {
                    _catch_var = _var_tok.value;
                    _pos++;
                }
                var _close = _gmlvm_tok(_tokens, _pos);
                if (_close.type == "paren" && _close.value == ")") _pos++;
            }
            var _cr = gmlvm_parse_statement(_tokens, _pos);
            _catch_block = _cr[0]; _pos = _cr[1];
        }
        
        _next = _gmlvm_tok(_tokens, _pos);
        if (_next.type == "keyword" && _next.value == "finally") {
            _pos++;
            var _fr = gmlvm_parse_statement(_tokens, _pos);
            _finally_block = _fr[0]; _pos = _fr[1];
        }
        
        return [new gmlvm_try_node(_try_block, _catch_var, _catch_block, _finally_block, _line, _col), _pos];
    }

    // throw statement
    if (_t.type == "keyword" && _t.value == "throw") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _er = gmlvm_parse_expression(_tokens, _pos);
        var _expr = _er[0]; _pos = _er[1];
        
        var _sc = _gmlvm_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        
        return [new gmlvm_throw_node(_expr, _line, _col), _pos];
    }
	
	// static declaration
    if (_t.type == "keyword" && _t.value == "static") {
        var _line = _t.line;
        var _col = _t.column;
        _pos++;
        
        var _stmts = [];
        
        while (true) {
            var _name_tok = _gmlvm_tok(_tokens, _pos);
            if (_name_tok.type != "identifier") break;
            var _var_name = _name_tok.value;
            _pos++;
            
            var _init = undefined;
            var _eq = _gmlvm_tok(_tokens, _pos);
            if (_eq.type == "operator" && _eq.value == "=") {
                _pos++;
                var _er = gmlvm_parse_expression(_tokens, _pos);
                _init = _er[0];
                _pos = _er[1];
            }
            
            array_push(_stmts, new gmlvm_static_init_node(_var_name, _init, _line, _col));
            
            var _comma = _gmlvm_tok(_tokens, _pos);
            if (_comma.type == "separator" && _comma.value == ",") {
                _pos++;
            } else {
                break;
            }
        }
        
        var _sc = _gmlvm_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        
        if (array_length(_stmts) == 1) {
            return [_stmts[0], _pos];
        }
        return [new gmlvm_block_node(_stmts, _line, _col), _pos];
    }
	
	// var declaration
	if (_t.type == "keyword" && _t.value == "var") {
	    var _line = _t.line;
	    var _col = _t.column;
	    _pos++;
    
	    var _stmts = [];
    
	    while (true) {
	        var _name_tok = _gmlvm_tok(_tokens, _pos);
	        if (_name_tok.type != "identifier") break;
	        var _var_name = _name_tok.value;
	        _pos++;
        
	        var _init = undefined;
	        var _eq = _gmlvm_tok(_tokens, _pos);
	        if (_eq.type == "operator" && _eq.value == "=") {
	            _pos++;
	            var _er = gmlvm_parse_expression(_tokens, _pos);
	            _init = _er[0];
	            _pos = _er[1];
	        }
        
	        var _var_node = new gmlvm_var_node(_var_name, _line, _col);
	        array_push(_stmts, new gmlvm_assign_node(_var_node, _init, _line, _col));
        
	        var _comma = _gmlvm_tok(_tokens, _pos);
	        if (_comma.type == "separator" && _comma.value == ",") {
	            _pos++;
	        } else {
	            break;
	        }
	    }
    
	    var _sc = _gmlvm_tok(_tokens, _pos);
	    if (_sc.type == "separator" && _sc.value == ";") _pos++;
    
	    if (array_length(_stmts) == 1) {
	        return [_stmts[0], _pos];
	    }
	    return [new gmlvm_block_node(_stmts, _line, _col), _pos];
	}

    // if statement
    if (_t.type == "keyword" && _t.value == "if") {
        _pos++;
        var _open = _gmlvm_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gmlvm_warning("parse_error", "Expected '(' after 'if' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        var _cr = gmlvm_parse_expression(_tokens, _pos);
        var _cond = _cr[0]; _pos = _cr[1];
        var _close = _gmlvm_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _tr = gmlvm_parse_statement(_tokens, _pos);
        var _then_block = _tr[0]; _pos = _tr[1];
        
        var _else_block = undefined;
        var _save_pos = _pos;
        var _else_tok = _gmlvm_tok(_tokens, _pos);
        if (_else_tok.type == "keyword" && _else_tok.value == "else") {
            _pos++;
            var _er = gmlvm_parse_statement(_tokens, _pos);
            _else_block = _er[0]; _pos = _er[1];
        }
        
        return [new gmlvm_if_node(_cond, _then_block, _else_block), _pos];
    }

    // while statement
    if (_t.type == "keyword" && _t.value == "while") {
        _pos++;
        var _open = _gmlvm_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gmlvm_warning("parse_error", "Expected '(' after 'while' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        var _cr = gmlvm_parse_expression(_tokens, _pos);
        var _cond = _cr[0]; _pos = _cr[1];
        var _close = _gmlvm_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _br = gmlvm_parse_statement(_tokens, _pos);
        var _body = _br[0]; _pos = _br[1];
        
        return [new gmlvm_while_node(_cond, _body), _pos];
    }
	
	// do/until statement
	if (_t.type == "keyword" && _t.value == "do") {
	    var _line = _t.line;
	    var _col = _t.column;
	    _pos++;
    
	    var _br = gmlvm_parse_statement(_tokens, _pos);
	    var _body = _br[0]; _pos = _br[1];
    
	    var _until_tok = _gmlvm_tok(_tokens, _pos);
	    if (!(_until_tok.type == "keyword" && _until_tok.value == "until")) {
	        gmlvm_warning("parse_error", "Expected 'until' after 'do' body at line " + string(_line));
	        return [undefined, _pos];
	    }
	    _pos++;
    
	    var _open = _gmlvm_tok(_tokens, _pos);
	    if (!(_open.type == "paren" && _open.value == "(")) {
	        gmlvm_warning("parse_error", "Expected '(' after 'until' at line " + string(_line));
	        return [undefined, _pos];
	    }
	    _pos++;
    
	    var _cr = gmlvm_parse_expression(_tokens, _pos);
	    var _cond = _cr[0]; _pos = _cr[1];
    
	    var _close = _gmlvm_tok(_tokens, _pos);
	    if (_close.type == "paren" && _close.value == ")") _pos++;
    
	    var _sc = _gmlvm_tok(_tokens, _pos);
	    if (_sc.type == "separator" && _sc.value == ";") _pos++;
    
	    return [new gmlvm_do_until_node(_cond, _body, _line, _col), _pos];
	}

    // for statement
    if (_t.type == "keyword" && _t.value == "for") {
        _pos++;
        var _open = _gmlvm_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gmlvm_warning("parse_error", "Expected '(' after 'for' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        
        // init (statement or empty)
        var _init = undefined;
        var _semi1 = _gmlvm_tok(_tokens, _pos);
        if (!(_semi1.type == "separator" && _semi1.value == ";")) {
            // parse init as expression, but handle var declarations specially
            if (_semi1.type == "keyword" && _semi1.value == "var") {
                var _ir = gmlvm_parse_statement(_tokens, _pos);
                _init = _ir[0]; _pos = _ir[1];
            } else {
                var _ir = gmlvm_parse_expression(_tokens, _pos);
                _init = _ir[0]; _pos = _ir[1];
            }
            var _sc = _gmlvm_tok(_tokens, _pos);
            if (_sc.type == "separator" && _sc.value == ";") _pos++;
        } else {
            _pos++;
        }
        
        // cond (expression or empty)
        var _cond = undefined;
        var _semi2 = _gmlvm_tok(_tokens, _pos);
        if (!(_semi2.type == "separator" && _semi2.value == ";")) {
            var _cr = gmlvm_parse_expression(_tokens, _pos);
            _cond = _cr[0]; _pos = _cr[1];
            var _sc = _gmlvm_tok(_tokens, _pos);
            if (_sc.type == "separator" && _sc.value == ";") _pos++;
        } else {
            _pos++;
        }
        
        // step (expression or empty)
        var _step = undefined;
        var _close = _gmlvm_tok(_tokens, _pos);
        if (!(_close.type == "paren" && _close.value == ")")) {
            var _sr = gmlvm_parse_expression(_tokens, _pos);
            _step = _sr[0]; _pos = _sr[1];
        }
        var _rp = _gmlvm_tok(_tokens, _pos);
        if (_rp.type == "paren" && _rp.value == ")") _pos++;
        
        var _br = gmlvm_parse_statement(_tokens, _pos);
        var _body = _br[0]; _pos = _br[1];
        
        return [new gmlvm_for_node(_init, _cond, _step, _body), _pos];
    }

    // repeat statement
    if (_t.type == "keyword" && _t.value == "repeat") {
        _pos++;
        var _open = _gmlvm_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
            return [undefined, _pos];
        }
        _pos++;
        var _cr = gmlvm_parse_expression(_tokens, _pos);
        var _count = _cr[0]; _pos = _cr[1];
        var _close = _gmlvm_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _br = gmlvm_parse_statement(_tokens, _pos);
        var _body = _br[0]; _pos = _br[1];
        return [new gmlvm_repeat_node(_count, _body), _pos];
    }

    // switch statement
    if (_t.type == "keyword" && _t.value == "switch") {
        _pos++;
        var _open = _gmlvm_tok(_tokens, _pos);
        if (!(_open.type == "paren" && _open.value == "(")) {
			gmlvm_warning("parse_error", "Expected '(' after 'switch' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        var _er = gmlvm_parse_expression(_tokens, _pos);
        var _expr = _er[0]; _pos = _er[1];
        var _close = _gmlvm_tok(_tokens, _pos);
        if (_close.type == "paren" && _close.value == ")") _pos++;
        
        var _ob = _gmlvm_tok(_tokens, _pos);
        if (!(_ob.type == "brace" && _ob.value == "{")) {
			gmlvm_warning("parse_error", "Expected '{' after 'switch' at line " + string(_t.line));
            return [undefined, _pos];
        }
        _pos++;
        
        var _cases = [];
        
        while (true) {
            var _ct = _gmlvm_tok(_tokens, _pos);
            if (_ct.type == "brace" && _ct.value == "}") {
                _pos++;
                break;
            }
            
            var _case_value = undefined;
            if (_ct.type == "keyword" && _ct.value == "case") {
                _pos++;
                var _vr = gmlvm_parse_expression(_tokens, _pos);
                _case_value = _vr[0]; _pos = _vr[1];
            } else if (_ct.type == "keyword" && _ct.value == "default") {
                _pos++;
                _case_value = "default";
            } else {
				gmlvm_warning("parse_error", "Parse error: expected 'case' or 'default', got " + _ct.type);
                break;
            }
            
            var _colon = _gmlvm_tok(_tokens, _pos);
            if (_colon.type == "operator" && _colon.value == ":") _pos++;
            
            var _body_stmts = [];
            while (true) {
                var _nt = _gmlvm_tok(_tokens, _pos);
                if (_nt.type == "eof") break;
                if (_nt.type == "brace" && _nt.value == "}") break;
                if (_nt.type == "keyword" && (_nt.value == "case" || _nt.value == "default")) break;
                
                var _sr = gmlvm_parse_statement(_tokens, _pos);
                if (_sr[0] != undefined) {
                    array_push(_body_stmts, _sr[0]);
                }
                _pos = _sr[1];
            }
            
            array_push(_cases, {
                value: _case_value,
                body: new gmlvm_block_node(_body_stmts)
            });
        }
        
        return [new gmlvm_switch_node(_expr, _cases), _pos];
    }
	
	// with statement
	if (_t.type == "keyword" && _t.value == "with") {
	    var _line = _t.line;
	    var _col = _t.column;
	    _pos++;
    
	    var _open = _gmlvm_tok(_tokens, _pos);
	    if (!(_open.type == "paren" && _open.value == "(")) {
	        gmlvm_warning("parse_error", "Expected '(' after 'with'", _open.line, _open.column);
	        return [undefined, _pos];
	    }
	    _pos++;
    
	    var _er = gmlvm_parse_expression(_tokens, _pos);
	    var _target = _er[0]; _pos = _er[1];
    
	    var _close = _gmlvm_tok(_tokens, _pos);
	    if (_close.type == "paren" && _close.value == ")") _pos++;
    
	    var _br = gmlvm_parse_statement(_tokens, _pos);
	    var _body = _br[0]; _pos = _br[1];
    
	    return [new gmlvm_with_node(_target, _body, _line, _col), _pos];
	}

    // return statement
    if (_t.type == "keyword" && _t.value == "return") {
        _pos++;
        var _value = undefined;
        var _next = _gmlvm_tok(_tokens, _pos);
        if (!(_next.type == "separator" && _next.value == ";")) {
            var _er = gmlvm_parse_expression(_tokens, _pos);
            _value = _er[0]; _pos = _er[1];
        }
        var _sc = _gmlvm_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        return [new gmlvm_return_node(_value), _pos];
    }

    // break statement
    if (_t.type == "keyword" && _t.value == "break") {
        _pos++;
        var _sc = _gmlvm_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        return [new gmlvm_break_node(), _pos];
    }

    // continue statement
    if (_t.type == "keyword" && _t.value == "continue") {
        _pos++;
        var _sc = _gmlvm_tok(_tokens, _pos);
        if (_sc.type == "separator" && _sc.value == ";") _pos++;
        return [new gmlvm_continue_node(), _pos];
    }

    // block:  { stmt* }
    if (_t.type == "brace" && _t.value == "{") {
        return gmlvm_parse_block(_tokens, _pos);
    }

    // function declaration (statement form)
    if (_t.type == "keyword" && _t.value == "function") {
        var _fr = _gmlvm_parse_primary(_tokens, _pos);
        var _func_node = _fr[0];
        _pos = _fr[1];
        
        // if it has a name, it's a declaration that assigns to a variable
        if (_func_node.name != "") {
            return [new gmlvm_assign_node(new gmlvm_var_node(_func_node.name), _func_node), _pos];
        }
        return [_func_node, _pos];
    }

    // expression statement (assignment, call, etc.)
    var _er = gmlvm_parse_expression(_tokens, _pos);
    var _node = _er[0]; _pos = _er[1];

    // check for assignment:  expr = expr
	var _nx = _gmlvm_tok(_tokens, _pos);
	if (_nx.type == "operator") {
	    var _op = _nx.value;
	    if (_op == "=") {
	        _pos++;
	        var _vr = gmlvm_parse_expression(_tokens, _pos);
	        _node = new gmlvm_assign_node(_node, _vr[0]);
	        _pos  = _vr[1];
	    }
	    else if (_op == "?=") {
	        _pos++;
	        var _vr = gmlvm_parse_expression(_tokens, _pos);
	        _node = new gmlvm_nullish_assign_node(_node, _vr[0]);
	        _pos  = _vr[1];
	    }
	    else if (_op == "+=" || _op == "-=" || _op == "*=" || _op == "/=" || _op == "%=" ||
	             _op == "&=" || _op == "|=" || _op == "^=" || _op == "<<=" || _op == ">>=") {
	        _pos++;
	        var _vr = gmlvm_parse_expression(_tokens, _pos);
	        _node = new gmlvm_compound_assign_node(_node, _op, _vr[0]);
	        _pos  = _vr[1];
	    }
	}

    // consume optional semicolon
    var _sc2 = _gmlvm_tok(_tokens, _pos);
    if (_sc2.type == "separator" && _sc2.value == ";") _pos++;

    return [_node, _pos];
}

function gmlvm_parse_block(_tokens, _pos) {
    var _stmts = [];
    // expect opening brace
    var _ob = _gmlvm_tok(_tokens, _pos);
    if (_ob.type == "brace" && _ob.value == "{") _pos++;

    while (true) {
        var _t = _gmlvm_tok(_tokens, _pos);
        if (_t.type == "eof") break;
        if (_t.type == "brace" && _t.value == "}") { _pos++; break; }
        
        var _sr = gmlvm_parse_statement(_tokens, _pos);
        if (_sr[0] != undefined) {
            array_push(_stmts, _sr[0]);
        }
        if (_sr[1] == _pos) { _pos++; continue; }
        _pos = _sr[1];
    }

    return [new gmlvm_block_node(_stmts), _pos];
}

function gmlvm_parse(_tokens, _source_code = "", _source_name = "<script>") {
    var _stmts = [];
    var _pos   = 0;
    var _len   = array_length(_tokens);

    while (_pos < _len) {
        var _t = _gmlvm_tok(_tokens, _pos);
        if (_t.type == "eof") break;
        
        var _sr = gmlvm_parse_statement(_tokens, _pos);
        if (_sr[0] != undefined) {
            array_push(_stmts, _sr[0]);
        }
        if (_sr[1] == _pos) { _pos++; continue; }
        _pos = _sr[1];
    }
	
    var _ast = new gmlvm_block_node(_stmts);
    _ast.source_code = _source_code;
    _ast.source_name = _source_name;
	return _ast;
}

function gmlvm_parse_cached(_code) {
    var _cached = global.__gmlvm_ast_cache.Get(_code);
    if (_cached != undefined) {
        return _cached;
    }
    
    var _tokens = gmlvm_tokenize(_code);
    var _ast = gmlvm_parse(_tokens);
    global.__gmlvm_ast_cache.Set(_code, _ast);
    
    return _ast;
}

function gmlvm_parse_only(_code, _source_name = "<script>") {
    var _processed = gmlvm_preprocess(_code);
    var _tokens = gmlvm_tokenize(_processed);
	
    return gmlvm_parse(_tokens, _processed, _source_name);
}