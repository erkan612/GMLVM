function gmlvm_vm_get_access(_node, _ctx) {
    var _target = gmlvm_vm_evaluate(_node.target, _ctx);
    var _index = _node.index;
    
    if (_node.kind == "dot") {
        // dot access: target.property
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
        var _idx = gmlvm_vm_evaluate(_index, _ctx);
        if (is_array(_target)) {
            return _target[_idx];
        } else if (is_struct(_target)) {
            return _target[$ _idx];
        }
        return undefined;
    }
    
    return undefined;
}

function gmlvm_vm_set_access(_node, _value, _ctx) {
    var _target = gmlvm_vm_evaluate(_node.target, _ctx);
    var _index = _node.index;
    
    if (_node.kind == "dot") {
        var _prop = _index.value;
        if (is_struct(_target)) {
            _target[$ _prop] = _value;
        } else if (instance_exists(_target)) {
            variable_instance_set(_target, _prop, _value);
        }
    } else if (_node.kind == "bracket") {
        var _idx = gmlvm_vm_evaluate(_index, _ctx);
        if (is_array(_target)) {
            _target[_idx] = _value;
        } else if (is_struct(_target)) {
            _target[$ _idx] = _value;
        }
    }
}

function gmlvm_vm_call(_func, _args, _ctx) {
    // check if its framework's custom GML function
    if (is_struct(_func) && struct_exists(_func, "__gmlvm_type") && _func.__gmlvm_type == "function") {
        return gmlvm_vm_call_gmlvm_function(_func, _args, _ctx);
    }
    
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
                return undefined;
        }
    }
    
	// return if its just a value
	gmlvm_warning("cannot_call", "Cannot call value of type " + typeof(_func));
    return _func;
}

function gmlvm_vm_call_ext(_func, _args) {
    var _arg_array = [];
    for (var _i = 0; _i < array_length(_args); _i++) {
        _arg_array[_i] = _args[_i];
    }
    
    if (is_method(_func)) {
        return method_call(_func, _arg_array);
    } else {
        var _call_args = array_create(array_length(_args) + 1);
        _call_args[0] = _func;
        for (var _i = 0; _i < array_length(_args); _i++) {
            _call_args[_i + 1] = _args[_i];
        }
        return script_execute_ext(_func, _call_args);
    }
}

function gmlvm_vm_call_gmlvm_function(_func, _args, _caller_ctx) {
    var _body = _func.__gmlvm_body;
    var _params = _func.__gmlvm_params;
    var _self_inst = _func.__gmlvm_self;
    var _is_constructor = _func.__gmlvm_is_constructor;
    var _inherit = _func.__gmlvm_inherit;
    var _inherit_args = _func.__gmlvm_inherit_args;
    
    if (_is_constructor) {
        _self_inst = {};
        
	    if (_is_constructor) {
	        _self_inst = {};
        
	        if (_inherit != undefined) {
	            var _parent_ctor = _caller_ctx.GetVar(_inherit);
	            if (is_struct(_parent_ctor) && struct_exists(_parent_ctor, "__gmlvm_type") && _parent_ctor.__gmlvm_type == "function") {
	                var _parent_args = _args;
                
	                var _parent_was_constructor = _parent_ctor.__gmlvm_is_constructor;
	                _parent_ctor.__gmlvm_is_constructor = true;
	                var _parent_instance = gmlvm_vm_call_gmlvm_function(_parent_ctor, _parent_args, _caller_ctx);
	                _parent_ctor.__gmlvm_is_constructor = _parent_was_constructor;
                
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
    
    var _func_ctx = new gmlvm_vm_context(_self_inst, _caller_ctx.GetSelf());
    
    if (struct_exists(_func, "__gmlvm_captured_locals")) {
        var _cap_names = struct_get_names(_func.__gmlvm_captured_locals);
        for (var _i = 0; _i < array_length(_cap_names); _i++) {
            var _n = _cap_names[_i];
            _func_ctx.locals[$ _n] = _func.__gmlvm_captured_locals[$ _n];
        }
    }
    
    if (!struct_exists(global, "__gmlvm_static_registry")) {
        global.__gmlvm_static_registry = {};
    }
    
    var _func_key = _func.__gmlvm_name;
    if (_func_key == "") {
        _func_key = "_anonymous_" + string(current_time) + "_" + string(random(1000000));
        _func.__gmlvm_name = _func_key;
    }
    
    if (struct_exists(_func, "__gmlvm_instance_id")) {
        _func_key = _func_key + "_" + string(_func.__gmlvm_instance_id);
    }
    
    if (!struct_exists(global.__gmlvm_static_registry, _func_key)) {
        global.__gmlvm_static_registry[$ _func_key] = {};
    }
    var _func_statics = global.__gmlvm_static_registry[$ _func_key];
    
    _func_ctx.statics = _func_statics;
    _func.__gmlvm_statics = _func_statics;
    
    for (var _i = 0; _i < array_length(_params); _i++) {
        var _param_name = _params[_i];
        var _value = undefined;
        if (_i < array_length(_args)) {
            _value = _args[_i];
        } else {
            _value = 0;
        }
        _func_ctx.locals[$ _param_name] = _value;
    }
    
    _func_ctx.locals[$ "argument"] = _args;
    _func_ctx.locals[$ "argument_count"] = array_length(_args);
    for (var _i = 0; _i < min(16, array_length(_args)); _i++) {
        _func_ctx.locals[$ "argument" + string(_i)] = _args[_i];
    }
    
    var _result = gmlvm_vm_evaluate(_body, _func_ctx);
    
    if (is_struct(_result) && struct_exists(_result, "type")) {
        if (_result.type == "return") {
            return _result.value;
        }
    }
    
    if (_is_constructor) {
        return _self_inst;
    }
    
    if (_result == undefined) {
        return 0;
    }
    
    return _result;
}

function gmlvm_vm_evaluate(_node, _ctx) {
    if (_node == undefined) {
        return undefined;
    }
    
    // debugger hook
    var _dbg = global.__gmlvm_debugger;
    _dbg.OnNodeEnter(_node);
    
    if (_dbg.ShouldBreak(_node)) { // TODO: implement the actual 'debugging'
        show_debug_message("DEBUGGER: Break at line " + string(_dbg.current_line));
		// TODO: ...
    }
    
    if (is_array(_node)) {
        var _result = undefined;
        for (var _i = 0; _i < array_length(_node); _i++) {
            _result = gmlvm_vm_evaluate(_node[_i], _ctx);
        }
        return _result;
    }
    
    if (struct_exists(_node, "Execute")) {
        return _node.Execute(_ctx);
    }
    
    return _node;
}

function gmlvm_vm(_ast, _self = self, _other = other) {
    var _ctx = new gmlvm_vm_context(_self, _other);
    
    try {
        var _result = gmlvm_vm_evaluate(_ast, _ctx);
        
        // unwrap return interrupt
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

function gmlvm_vm_builtin(_name) { // TODO: add more built in
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

function gmlvm_vm_context(_self, _other) constructor {
    self_inst  = _self;			// current "self" (instance or struct)
    other_inst = _other;		// current "other"
    
    locals     = {};			// local variables (var)
    statics    = {};			// static variables
    static_names = {};			// Track which variables are static
    globals    = global;		// reference to global scope
    
    scope_stack = [];			// scope stack for nested blocks
    
    static PushScope = function() {
        array_push(scope_stack, locals);
        locals = {};
    };
    
    static PopScope = function() {
        if (array_length(scope_stack) > 0) {
            locals = array_pop(scope_stack);
        }
    };
    
    static GetVar = function(_name) {
        if (struct_exists(locals, _name)) {
            return locals[$ _name];
        }
        
        if (struct_exists(static_names, _name) || struct_exists(statics, _name)) {
            if (struct_exists(statics, _name)) {
                return statics[$ _name];
            }
            return undefined;
        }
        
        if (is_struct(self_inst)) { // check self (instance or struct)
            if (struct_exists(self_inst, _name)) {
                return self_inst[$ _name];
            }
        } else if (instance_exists(self_inst)) {
            if (variable_instance_exists(self_inst, _name)) {
                return variable_instance_get(self_inst, _name);
            }
        }
        
        if (variable_global_exists(_name)) {
            return variable_global_get(_name);
        }
        
        var _builtin = gmlvm_vm_builtin(_name);
        if (_builtin.found) {
            return _builtin.value;
        }
        
        return undefined;
    };
    
    static SetVar = function(_name, _value) {
        if (struct_exists(locals, _name)) {
            locals[$ _name] = _value;
            return;
        }
        
        if (struct_exists(statics, _name)) {
            statics[$ _name] = _value;
            return;
        }
        
        if (is_struct(self_inst)) {
            self_inst[$ _name] = _value;
            return;
        } else if (instance_exists(self_inst)) {
            variable_instance_set(self_inst, _name, _value);
            return;
        }
        
        if (variable_global_exists(_name)) {
            variable_global_set(_name, _value);
            return;
        }
        
        // doesnt exist anywhere - create as local
        locals[$ _name] = _value;
    };
    
    static SetStatic = function(_name, _value) {
        statics[$ _name] = _value;
    };
    
    static GetSelf = function() {
        return self_inst;
    };
    
    static GetOther = function() {
        return other_inst;
    };
	
    static MarkStatic = function(_name) {
        static_names[$ _name] = true;
    };
    
    static IsStatic = function(_name) {
        return struct_exists(static_names, _name);
    };
}