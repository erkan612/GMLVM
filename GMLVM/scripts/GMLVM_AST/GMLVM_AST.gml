function gmlvm_number_node(_value, _line = -1, _column = -1) constructor {
    type   = "number";
    value  = _value;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        return value;
    };
}

function gmlvm_string_node(_value, _line = -1, _column = -1) constructor {
    type   = "string";
    value  = _value;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        return value;
    };
}

function gmlvm_var_node(_name, _is_static = false, _line = -1, _column = -1) constructor {
    type      = "var";
    name      = _name;
    is_static = _is_static;
    line      = _line;
    column    = _column;
    
    Execute = function(_ctx) {
        if (name == "self") return _ctx.GetSelf();
        if (name == "other") return _ctx.GetOther();
        if (name == "global") { return global; }
        return _ctx.GetVar(name);
    };
}

function gmlvm_binary_op_node(_op, _left, _right, _line = -1, _column = -1) constructor {
    type   = "binary_op";
    op     = _op;
    left   = _left;
    right  = _right;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
	    var _l = gmlvm_vm_evaluate(left, _ctx);
	    var _r = gmlvm_vm_evaluate(right, _ctx);
    
	    // Handle undefined values
	    if (_l == undefined) {
	        gmlvm_warning("undefined_binary_left", "Left operand is undefined in binary op '" + op + "' at line " + string(line));
	        _l = 0;
	    }
	    if (_r == undefined) {
	        gmlvm_warning("undefined_binary_right", "Right operand is undefined in binary op '" + op + "' at line " + string(line));
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
	            gmlvm_warning("unknown_operator", "Unknown operator: " + op + " at line " + string(line));
	            return undefined;
	    }
	};
}

function gmlvm_unary_op_node(_op, _operand, _line = -1, _column = -1) constructor {
    type    = "unary_op";
    op      = _op;
    operand = _operand;
    line    = _line;
    column  = _column;
    
    Execute = function(_ctx) {
        var _val = gmlvm_vm_evaluate(operand, _ctx);
        
        // handle undefined values for increment/decrement
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

function gmlvm_block_node(_statements, _line = -1, _column = -1) constructor {
    type       = "block";
    statements = _statements;
    line       = _line;
    column     = _column;
    
    Execute = function(_ctx) {
        var _result = undefined;
        
        for (var _i = 0; _i < array_length(statements); _i++) {
            var _stmt = statements[_i];
            _result = gmlvm_vm_evaluate(_stmt, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                var _type = _result.type;
                if (_type == "return" || _type == "break" || _type == "continue" || _type == "exit") {
                    return _result;
                }
            }
        }
        
        return _result;
    };
}

function gmlvm_assign_node(_target, _value, _line = -1, _column = -1) constructor {
    type   = "assign";
    target = _target;
    value  = _value;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _val = undefined;
        if (value != undefined) {
            _val = gmlvm_vm_evaluate(value, _ctx);
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
            gmlvm_vm_set_access(target, _val, _ctx);
        }
        
        return _val;
    };
}

function gmlvm_compound_assign_node(_target, _op, _value, _line = -1, _column = -1) constructor {
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
	        _current = gmlvm_vm_get_access(target, _ctx);
	    }
    
	    if (_current == undefined) {
	        _current = 0;
	    }
    
	    var _r = gmlvm_vm_evaluate(value, _ctx);
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
	        case "&=": _new = _current & _r; break;
	        case "|=": _new = _current | _r; break;
	        case "^=": _new = _current ^ _r; break;
	        case "<<=": _new = _current << _r; break;
	        case ">>=": _new = _current >> _r; break;
	    }
    
	    if (target.type == "var") {
	        _ctx.SetVar(target.name, _new);
	    } else if (target.type == "access") {
	        gmlvm_vm_set_access(target, _new, _ctx);
	    }
    
	    return _new;
	};
}

function gmlvm_if_node(_cond, _then_block, _else_block) constructor {
    type       = "if";
    cond       = _cond;
    then_block = _then_block;
    else_block = _else_block;
    
    static Execute = function(_ctx) {
        var _c = gmlvm_vm_evaluate(cond, _ctx);
        
        if (_c) {
            return gmlvm_vm_evaluate(then_block, _ctx);
        } else if (else_block != undefined) {
            return gmlvm_vm_evaluate(else_block, _ctx);
        }
        
        return undefined;
    };
}

function gmlvm_while_node(_cond, _body, _line = -1, _column = -1) constructor {
    type = "while";
    cond = _cond;
    body = _body;
    line = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _result = undefined;
        
        while (gmlvm_vm_evaluate(cond, _ctx)) {
            _result = gmlvm_vm_evaluate(body, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "break") {
                    // Break exits the loop, return the last value (not the interrupt)
                    return undefined;
                } else if (_result.type == "continue") {
                    continue;
                } else if (_result.type == "return") {
                    return _result;
                } else if (_result.type == "exit") {
                    return _result;
                }
            }
        }
        
        return _result;
    };
}

function gmlvm_for_node(_init, _cond, _step, _body, _line = -1, _column = -1) constructor {
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
            gmlvm_vm_evaluate(init, _ctx);
        }
        
        while (true) {
            if (cond != undefined) {
                if (!gmlvm_vm_evaluate(cond, _ctx)) {
                    break;
                }
            }
            
            _result = gmlvm_vm_evaluate(body, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "break") {
                    _result = undefined;
                    break;
                } else if (_result.type == "continue") {
                    // Continue to step
                } else if (_result.type == "return") {
                    return _result;
                } else if (_result.type == "exit") {
                    return _result;
                }
            }
            
            if (step != undefined) {
                gmlvm_vm_evaluate(step, _ctx);
            }
        }
        
        return _result;
    };
}

function gmlvm_repeat_node(_count, _body) constructor {
    type  = "repeat";
    count = _count;
    body  = _body;
    
    static Execute = function(_ctx) {
        var _result = undefined;
        var _c = gmlvm_vm_evaluate(count, _ctx);
        
        for (var _i = 0; _i < _c; _i++) {
            _result = gmlvm_vm_evaluate(body, _ctx);
            
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

function gmlvm_switch_node(_expr, _cases, _line = -1, _column = -1) constructor {
    type  = "switch";
    expr  = _expr;
    cases = _cases;
    line  = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _val = gmlvm_vm_evaluate(expr, _ctx);
        var _result = undefined;
        var _matched = false;
        
        for (var _i = 0; _i < array_length(cases); _i++) {
            var _case = cases[_i];
            var _case_val = _case.value;
            
            if (!_matched) {
                if (_case_val == "default") {
                    _matched = true;
                } else {
                    var _cv = gmlvm_vm_evaluate(_case_val, _ctx);
                    if (_cv == _val) {
                        _matched = true;
                    }
                }
            }
            
            if (_matched) {
                _result = gmlvm_vm_evaluate(_case.body, _ctx);
                
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

function gmlvm_return_node(_value) constructor {
    type  = "return";
    value = _value;
    
    static Execute = function(_ctx) {
        var _val = undefined;
        if (value != undefined) {
            _val = gmlvm_vm_evaluate(value, _ctx);
        }
        return new gmlvm_interrupt("return", _val);
    };
}

function gmlvm_break_node() constructor {
    type = "break";
    
    static Execute = function(_ctx) {
        return new gmlvm_interrupt("break");
    };
}

function gmlvm_continue_node() constructor {
    type = "continue";
    
    static Execute = function(_ctx) {
        return new gmlvm_interrupt("continue");
    };
}

function gmlvm_array_node(_elements, _line = -1, _column = -1) constructor {
    type     = "array";
    elements = _elements;
    line     = _line;
    column   = _column;
    
    static Execute = function(_ctx) {
        var _arr = [];
        for (var _i = 0; _i < array_length(elements); _i++) {
            _arr[_i] = gmlvm_vm_evaluate(elements[_i], _ctx);
        }
        return _arr;
    };
}

function gmlvm_struct_node(_fields, _line = -1, _column = -1) constructor {
    type   = "struct";
    fields = _fields;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _struct = {};
        for (var _i = 0; _i < array_length(fields); _i++) {
            var _field = fields[_i];
            var _key = _field.key;
            var _val = gmlvm_vm_evaluate(_field.value, _ctx);
            _struct[$ _key] = _val;
        }
        return _struct;
    };
}

function gmlvm_access_node(_target, _index, _kind) constructor {
    type   = "access";
    target = _target;
    index  = _index;
    kind   = _kind;   // "bracket", "dot", "[@", "[$", "[#", "[?"
    
    static Execute = function(_ctx) {
        return gmlvm_vm_get_access(self, _ctx);
    };
}

function gmlvm_call_node(_callee, _args, _line = -1, _column = -1) constructor {
    type   = "call";
    callee = _callee;
    args   = _args;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _func = gmlvm_vm_evaluate(callee, _ctx);
        
        var _arg_values = [];
        for (var _i = 0; _i < array_length(args); _i++) {
            _arg_values[_i] = gmlvm_vm_evaluate(args[_i], _ctx);
        }
        
        return gmlvm_vm_call(_func, _arg_values, _ctx);
    };
}

function gmlvm_function_node(_name, _params, _param_defaults, _body, _is_constructor = false, _inherit = undefined, _inherit_args = undefined, _line = -1, _column = -1) constructor {
    type            = "function";
    name            = _name;
    params          = _params;
    param_defaults  = _param_defaults;
    body            = _body;
    is_constructor  = _is_constructor;
    inherit         = _inherit;
    inherit_args    = _inherit_args;
    line            = _line;
    column          = _column;
    
    Execute = function(_ctx) {
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
            __gmlvm_type: "function",
            __gmlvm_name: name,
            __gmlvm_params: params,
            __gmlvm_param_defaults: param_defaults,
            __gmlvm_body: body,
            __gmlvm_is_constructor: is_constructor,
            __gmlvm_inherit: inherit,
            __gmlvm_inherit_args: inherit_args,
            __gmlvm_statics: _func_statics,
            __gmlvm_captured_locals: _captured_locals,
            __gmlvm_self: _captured_self,
            __gmlvm_other: _captured_other,
            __gmlvm_instance_id: string(current_time) + "_" + string(random(1000000))
        };
        
        return _func;
    };
}

function gmlvm_try_node(_try_block, _catch_var, _catch_block, _finally_block, _line = -1, _column = -1) constructor {
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
        
        try {
            _result = gmlvm_vm_evaluate(try_block, _ctx);
        } catch (_err) {
            _error = _err;
            _caught = true;
            
            if (catch_block != undefined) {
                _ctx.PushScope();
                if (catch_var != "") {
                    _ctx.locals[$ catch_var] = _error;
                }
                _result = gmlvm_vm_evaluate(catch_block, _ctx);
                _ctx.PopScope();
            }
        } finally {
            if (finally_block != undefined) {
                gmlvm_vm_evaluate(finally_block, _ctx);
            }
        }
        
        if (_caught && catch_block == undefined) {
            throw _error;
        }
        
        return _result;
    };
}

function gmlvm_throw_node(_expr, _line = -1, _column = -1) constructor {
    type   = "throw";
    expr   = _expr;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _val = gmlvm_vm_evaluate(expr, _ctx);
        throw _val;
    };
}

function gmlvm_new_node(_constructor, _args, _line = -1, _column = -1) constructor {
    type        = "new";
    constructor = _constructor;
    args        = _args;
    line        = _line;
    column      = _column;
    
    static Execute = function(_ctx) {
        var _ctor = gmlvm_vm_evaluate(constructor, _ctx);
        
        var _arg_values = [];
        for (var _i = 0; _i < array_length(args); _i++) {
            _arg_values[_i] = gmlvm_vm_evaluate(args[_i], _ctx);
        }
        
        if (!is_struct(_ctor) || !struct_exists(_ctor, "__gmlvm_type") || _ctor.__gmlvm_type != "function") {
            return {};
        }
        
        var _is_constructor = _ctor.__gmlvm_is_constructor;
        _ctor.__gmlvm_is_constructor = true;
        
        var _instance = gmlvm_vm_call_gmlvm_function(_ctor, _arg_values, _ctx);
        
        _ctor.__gmlvm_is_constructor = _is_constructor;
        
        return _instance;
    };
}

function gmlvm_static_init_node(_name, _value, _line = -1, _column = -1) constructor {
    type   = "static_init";
    name   = _name;
    value  = _value;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        _ctx.MarkStatic(name);
        
        if (!struct_exists(_ctx.statics, name)) {
            var _val = undefined;
            if (value != undefined) {
                _val = gmlvm_vm_evaluate(value, _ctx);
            }
            _ctx.statics[$ name] = _val;
        }
        return _ctx.statics[$ name];
    };
}

function gmlvm_postfix_op_node(_op, _operand, _line = -1, _column = -1) constructor {
    type    = "postfix_op";
    op      = _op;
    operand = _operand;
    line    = _line;
    column  = _column;
    
    Execute = function(_ctx) {
        var _val = gmlvm_vm_evaluate(operand, _ctx);
        
        if (_val == undefined) {
            _val = 0;
        }
        
        var _old_val = _val;
        var _new_val = (op == "++") ? _val + 1 : _val - 1;
        
        if (operand.type == "var") {
            _ctx.SetVar(operand.name, _new_val);
        }
        else if (operand.type == "access") {
            gmlvm_vm_set_access(operand, _new_val, _ctx);
        }
        
        return _old_val;
    };
}

function gmlvm_do_until_node(_cond, _body, _line = -1, _column = -1) constructor {
    type   = "do_until";
    cond   = _cond;
    body   = _body;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _result = undefined;
        
        do {
            _result = gmlvm_vm_evaluate(body, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "break") {
                    return undefined;
                } else if (_result.type == "continue") {
                    continue;
                } else if (_result.type == "return") {
                    return _result;
                } else if (_result.type == "exit") {
                    return _result;
                }
            }
        } until (gmlvm_vm_evaluate(cond, _ctx));
        
        return _result;
    };
}

function gmlvm_ternary_node(_cond, _true_expr, _false_expr, _line = -1, _column = -1) constructor {
    type       = "ternary";
    cond       = _cond;
    true_expr  = _true_expr;
    false_expr = _false_expr;
    line       = _line;
    column     = _column;
    
    static Execute = function(_ctx) {
        var _c = gmlvm_vm_evaluate(cond, _ctx);
        if (_c) {
            return gmlvm_vm_evaluate(true_expr, _ctx);
        } else {
            return gmlvm_vm_evaluate(false_expr, _ctx);
        }
    };
}

function gmlvm_with_node(_target, _body, _line = -1, _column = -1) constructor {
    type   = "with";
    target = _target;
    body   = _body;
    line   = _line;
    column = _column;
  
    Execute = function(_ctx) {
	    var _target_val = gmlvm_vm_evaluate(target, _ctx);
	    var _result = undefined;
	    var _old_self = _ctx.GetSelf();
	    var _old_other = _ctx.GetOther();
  
	    if (_target_val == -3) { // all
	        with (all) {
	            _ctx.self_inst = id;
	            _ctx.other_inst = _old_self;
	            _result = gmlvm_vm_evaluate(body, _ctx);
	        }
	    }
	    else if (is_real(_target_val) && object_exists(_target_val)) {
	        var _inst_count = instance_number(_target_val);
	        for (var _i = 0; _i < _inst_count; _i++) {
	            var _inst = instance_find(_target_val, _i);
	            if (instance_exists(_inst)) {
	                _ctx.self_inst = _inst;
	                _ctx.other_inst = _old_self;
	                var _inst_result = gmlvm_vm_evaluate(body, _ctx);
              
	                if (is_struct(_inst_result) && struct_exists(_inst_result, "type")) {
	                    if (_inst_result.type == "break") {
	                        break;
	                    } else if (_inst_result.type == "continue") {
	                        continue;
	                    } else if (_inst_result.type == "return") {
	                        _ctx.self_inst = _old_self;
	                        _ctx.other_inst = _old_other;
	                        return _inst_result.value;
	                    }
	                } else {
	                    _result = _inst_result;
	                }
	            }
	        }
	    }
	    else if (instance_exists(_target_val)) {
	        _ctx.self_inst = _target_val;
	        _ctx.other_inst = _old_self;
	        _result = gmlvm_vm_evaluate(body, _ctx);
	    }
	    else if (is_struct(_target_val)) {
	        _ctx.self_inst = _target_val;
	        _ctx.other_inst = _old_self;
	        _result = gmlvm_vm_evaluate(body, _ctx);
	    }
  
	    _ctx.self_inst = _old_self;
	    _ctx.other_inst = _old_other;
  
	    if (is_struct(_result) && struct_exists(_result, "type")) {
	        if (_result.type == "return") {
	            return _result.value;
	        } else if (_result.type == "break" || _result.type == "continue") {
	            return undefined;
	        }
	    }
  
	    return _result;
	};
}

function gmlvm_typeof_node(_expr, _line = -1, _column = -1) constructor {
    type   = "typeof";
    expr   = _expr;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _val = gmlvm_vm_evaluate(expr, _ctx);
        
        if (_val == undefined) return "undefined";
        if (is_real(_val)) return "number";
        if (is_string(_val)) return "string";
        if (is_array(_val)) return "array";
        if (is_struct(_val)) {
            if (struct_exists(_val, "__gmlvm_type") && _val.__gmlvm_type == "function") {
                return "method";
            }
            return "struct";
        }
        if (is_method(_val)) return "method";
        if (is_bool(_val)) return "number";
        
        return "unknown";
    };
}

function gmlvm_delete_node(_target, _line = -1, _column = -1) constructor {
    type   = "delete";
    target = _target;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        if (target.type == "var") {
            // Delete from locals if exists
            if (struct_exists(_ctx.locals, target.name)) {
                struct_remove(_ctx.locals, target.name);
                return true;
            }
            // Delete from self if exists
            var _self = _ctx.GetSelf();
            if (is_struct(_self) && struct_exists(_self, target.name)) {
                struct_remove(_self, target.name);
                return true;
            }
            return false;
        } else if (target.type == "access") {
            var _obj = gmlvm_vm_evaluate(target.target, _ctx);
            var _index = target.index;
            
            if (target.kind == "dot") {
                var _prop = _index.value;
                if (is_struct(_obj) && struct_exists(_obj, _prop)) {
                    struct_remove(_obj, _prop);
                    return true;
                }
            } else if (target.kind == "bracket") {
                var _idx = gmlvm_vm_evaluate(_index, _ctx);
                if (is_struct(_obj) && struct_exists(_obj, _idx)) {
                    struct_remove(_obj, string(_idx));
                    return true;
                } else if (is_array(_obj) && _idx >= 0 && _idx < array_length(_obj)) {
                    array_delete(_obj, _idx, 1);
                    return true;
                }
            }
        }
        return false;
    };
}

function gmlvm_instanceof_node(_left, _right, _line = -1, _column = -1) constructor {
    type   = "instanceof";
    left   = _left;
    right  = _right;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _obj = gmlvm_vm_evaluate(left, _ctx);
        var _constructor = gmlvm_vm_evaluate(right, _ctx);
        
        if (!is_struct(_obj)) return false;
        if (!is_struct(_constructor) || !struct_exists(_constructor, "__gmlvm_type") || _constructor.__gmlvm_type != "function") {
            return false;
        }
        
        // Check if _obj was created by _constructor or inherits from it
        // Simple implementation: check constructor chain
        if (struct_exists(_obj, "__constructor")) {
            var _ctor = _obj.__constructor;
            while (_ctor != undefined) {
                if (_ctor == _constructor) return true;
                _ctor = _ctor.__parent;
            }
        }
        
        return false;
    };
}

function gmlvm_nullish_coalesce_node(_left, _right, _line = -1, _column = -1) constructor {
    type   = "nullish_coalesce";
    left   = _left;
    right  = _right;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _l = gmlvm_vm_evaluate(left, _ctx);
        
        // Return left if it's not undefined or pointer_null
        if (_l != undefined) {
            return _l;
        }
        
        // Otherwise evaluate and return right
        return gmlvm_vm_evaluate(right, _ctx);
    };
}

function gmlvm_nullish_assign_node(_target, _value, _line = -1, _column = -1) constructor {
    type   = "nullish_assign";
    target = _target;
    value  = _value;
    line   = _line;
    column = _column;
    
    Execute = function(_ctx) {
        var _current = undefined;
        
        if (target.type == "var") {
            _current = _ctx.GetVar(target.name);
        } else if (target.type == "access") {
            _current = gmlvm_vm_get_access(target, _ctx);
        }
        
        // Only assign if current is undefined
        if (_current == undefined) {
            var _val = gmlvm_vm_evaluate(value, _ctx);
            
            if (target.type == "var") {
                _ctx.SetVar(target.name, _val);
            } else if (target.type == "access") {
                gmlvm_vm_set_access(target, _val, _ctx);
            }
            
            return _val;
        }
        
        return _current;
    };
}

function gmlvm_template_string_node(_parts, _line = -1, _column = -1) constructor {
    type   = "template_string";
    parts  = _parts;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _result = "";
        for (var _i = 0; _i < array_length(parts); _i++) {
            var _part = parts[_i];
            if (_part.type == "string") {
                _result += _part.value;
            } else {
                var _val = gmlvm_vm_evaluate(_part.value, _ctx);
                _result += string(_val);
            }
        }
        return _result;
    };
}

function gmlvm_map_node(_fields, _line = -1, _column = -1) constructor {
    type   = "map";
    fields = _fields;
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _map = ds_map_create();
        for (var _i = 0; _i < array_length(fields); _i++) {
            var _field = fields[_i];
            var _key = _field.key;
            var _val = gmlvm_vm_evaluate(_field.value, _ctx);
            ds_map_set(_map, _key, _val);
        }
        return _map;
    };
}

function gmlvm_list_node(_items, _line = -1, _column = -1) constructor {
    type  = "list";
    items = _items;
    line  = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        var _list = ds_list_create();
        for (var _i = 0; _i < array_length(items); _i++) {
            var _val = gmlvm_vm_evaluate(items[_i], _ctx);
            ds_list_add(_list, _val);
        }
        return _list;
    };
}

function gmlvm_exit_node(_line = -1, _column = -1) constructor {
    type   = "exit";
    line   = _line;
    column = _column;
    
    static Execute = function(_ctx) {
        return new gmlvm_interrupt("exit");
    };
}