//function gmlvm_vm_get_access(_node, _ctx) {
//    var _target = gmlvm_vm_evaluate(_node.target, _ctx);
//    var _index = _node.index;
//    var _kind = _node.kind;
//    
//    // Dot access
//    if (_kind == "dot") {
//        var _prop = _index.value;
//		
//		if (_target == global) {
//			if (variable_global_exists(_prop)) {
//				return variable_global_get(_prop);
//			}
//			else {
//				return undefined;
//			}
//		}
//		
//        if (is_struct(_target)) {
//            return _target[$ _prop];
//        } else if (instance_exists(_target)) {
//            if (_prop == "id") return _target;
//            if (_prop == "x") return _target.x;
//            if (_prop == "y") return _target.y;
//            if (variable_instance_exists(_target, _prop)) {
//                return variable_instance_get(_target, _prop);
//            }
//        }
//        return undefined;
//    }
//    
//    // Bracket and accessor access
//    var _idx = gmlvm_vm_evaluate(_index, _ctx);
//    
//    // Array accessor [@]
//    if (_kind == "[@") {
//        if (is_array(_target)) {
//            return _target[_idx];
//        }
//        return undefined;
//    }
//    
//    // Struct accessor [$]
//    if (_kind == "[$") {
//        if (is_struct(_target)) {
//            return _target[$ _idx];
//        }
//        return undefined;
//    }
//    
//    // Map accessor [?]
//	if (_kind == "[?") {
//	    return ds_map_find_value(_target, _idx);
//	}
//
//	// List accessor [|]
//	if (_kind == "[|") {
//	    return ds_list_find_value(_target, _idx);
//	}
//    
//    // Grid accessor [#]
//    if (_kind == "[#") {
//        // Grid access is typically 2D: grid[# x, y]
//        if (is_array(_idx)) {
//            var _x = _idx[0];
//            var _y = _idx[1];
//            if (ds_exists(_target, ds_type_grid)) {
//                return ds_grid_get(_target, _x, _y);
//            }
//        }
//        return undefined;
//    }
//    
//    // Regular bracket - guess type
//    if (is_array(_target)) {
//        return _target[_idx];
//    } else if (is_struct(_target)) {
//        return _target[$ _idx];
//    } else if (ds_exists(_target, ds_type_map)) {
//        return ds_map_find_value(_target, _idx);
//    } else if (instance_exists(_target)) {
//        var _prop = string(_idx);
//        if (variable_instance_exists(_target, _prop)) {
//            return variable_instance_get(_target, _prop);
//        }
//    }
//    
//    return undefined;
//}

function gmlvm_vm_get_access(_node, _ctx) {
    var _target = gmlvm_vm_evaluate(_node.target, _ctx);
    var _index = _node.index;
    var _kind = _node.kind;
    
    if (_kind == "dot") {
        var _prop = _index.value;
        
        if (_target == global) {
            if (variable_global_exists(_prop)) {
                return variable_global_get(_prop);
            }
            throw gmlvm_create_error(
                "runtime_error",
                "Global variable '" + _prop + "' not defined",
                _node.line,
                _node.column
            );
        }
        
        if (is_struct(_target)) {
            if (struct_exists(_target, _prop)) {
                return _target[$ _prop];
            }
            
            if (_prop == "id" && struct_exists(_target, "id")) {
                return _target.id;
            }
            if (_prop == "x" && struct_exists(_target, "x")) {
                return _target.x;
            }
            if (_prop == "y" && struct_exists(_target, "y")) {
                return _target.y;
            }
            
            throw gmlvm_create_error(
                "runtime_error",
                "Property '" + _prop + "' does not exist on struct",
                _node.line,
                _node.column
            );
        }
        
        if (instance_exists(_target)) {
            if (_prop == "id") return _target;
            if (_prop == "x") return _target.x;
            if (_prop == "y") return _target.y;
            if (_prop == "object_index") return _target.object_index;
            if (_prop == "sprite_index") return _target.sprite_index;
            if (_prop == "image_index") return _target.image_index;
            if (_prop == "image_alpha") return _target.image_alpha;
            if (_prop == "image_angle") return _target.image_angle;
            if (_prop == "image_blend") return _target.image_blend;
            if (_prop == "image_xscale") return _target.image_xscale;
            if (_prop == "image_yscale") return _target.image_yscale;
            if (_prop == "mask_index") return _target.mask_index;
            if (_prop == "solid") return _target.solid;
            if (_prop == "persistent") return _target.persistent;
            if (_prop == "depth") return _target.depth;
            if (_prop == "layer") return _target.layer;
            if (_prop == "alarm") return _target.alarm;
            if (_prop == "direction") return _target.direction;
            if (_prop == "speed") return _target.speed;
            if (_prop == "friction") return _target.friction;
            if (_prop == "gravity") return _target.gravity;
            if (_prop == "gravity_direction") return _target.gravity_direction;
            if (_prop == "hspeed") return _target.hspeed;
            if (_prop == "vspeed") return _target.vspeed;
            if (_prop == "bbox_left") return _target.bbox_left;
            if (_prop == "bbox_right") return _target.bbox_right;
            if (_prop == "bbox_top") return _target.bbox_top;
            if (_prop == "bbox_bottom") return _target.bbox_bottom;
            if (_prop == "path_index") return _target.path_index;
            if (_prop == "path_position") return _target.path_position;
            if (_prop == "path_speed") return _target.path_speed;
            if (_prop == "path_scale") return _target.path_scale;
            if (_prop == "path_orientation") return _target.path_orientation;
            if (_prop == "path_endaction") return _target.path_endaction;
            
            if (variable_instance_exists(_target, _prop)) {
                return variable_instance_get(_target, _prop);
            }
            
            throw gmlvm_create_error(
                "runtime_error",
                "Variable '" + _prop + "' not defined on instance",
                _node.line,
                _node.column
            );
        }
        
        if (_target == undefined) {
            throw gmlvm_create_error(
                "runtime_error",
                "Cannot access property '" + _prop + "' on undefined value",
                _node.line,
                _node.column
            );
        }
        
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot access property '" + _prop + "' on " + typeof(_target),
            _node.line,
            _node.column
        );
    }
    
    var _idx = gmlvm_vm_evaluate(_index, _ctx);
    
    if (_kind == "[@") {
        if (is_array(_target)) {
            if (_idx < 0 || _idx >= array_length(_target)) {
                throw gmlvm_create_error(
                    "runtime_error",
                    "Array index " + string(_idx) + " out of bounds (length: " + string(array_length(_target)) + ")",
                    _node.line,
                    _node.column
                );
            }
            return _target[_idx];
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use array accessor [@] on non-array value (got " + typeof(_target) + ")",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[$") {
        if (is_struct(_target)) {
            var _key = string(_idx);
            if (struct_exists(_target, _key)) {
                return _target[$ _key];
            }
            throw gmlvm_create_error(
                "runtime_error",
                "Struct key '" + _key + "' does not exist",
                _node.line,
                _node.column
            );
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use struct accessor [$] on non-struct value (got " + typeof(_target) + ")",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[?") {
        if (ds_exists(_target, ds_type_map)) {
            if (!ds_map_exists(_target, _idx)) {
                return undefined;
            }
            return ds_map_find_value(_target, _idx);
        }
        if (is_real(_target)) {
            if (ds_exists(_target, ds_type_map)) {
                if (!ds_map_exists(_target, _idx)) {
                    return undefined;
                }
                return ds_map_find_value(_target, _idx);
            }
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use map accessor [?] on non-map value",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[|") {
        if (ds_exists(_target, ds_type_list)) {
            if (_idx < 0 || _idx >= ds_list_size(_target)) {
                throw gmlvm_create_error(
                    "runtime_error",
                    "List index " + string(_idx) + " out of bounds (size: " + string(ds_list_size(_target)) + ")",
                    _node.line,
                    _node.column
                );
            }
            return ds_list_find_value(_target, _idx);
        }
        if (is_real(_target)) {
            if (ds_exists(_target, ds_type_list)) {
                if (_idx < 0 || _idx >= ds_list_size(_target)) {
                    throw gmlvm_create_error(
                        "runtime_error",
                        "List index " + string(_idx) + " out of bounds",
                        _node.line,
                        _node.column
                    );
                }
                return ds_list_find_value(_target, _idx);
            }
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use list accessor [|] on non-list value",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[#") {
        if (is_array(_idx)) {
            var _x = _idx[0];
            var _y = _idx[1];
            if (ds_exists(_target, ds_type_grid)) {
                if (_x < 0 || _x >= ds_grid_width(_target) || _y < 0 || _y >= ds_grid_height(_target)) {
                    throw gmlvm_create_error(
                        "runtime_error",
                        "Grid index (" + string(_x) + ", " + string(_y) + ") out of bounds",
                        _node.line,
                        _node.column
                    );
                }
                return ds_grid_get(_target, _x, _y);
            }
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use grid accessor [#] - invalid grid or coordinates",
            _node.line,
            _node.column
        );
    }
    
    if (is_array(_target)) {
        if (_idx < 0 || _idx >= array_length(_target)) {
            throw gmlvm_create_error(
                "runtime_error",
                "Array index " + string(_idx) + " out of bounds (length: " + string(array_length(_target)) + ")",
                _node.line,
                _node.column
            );
        }
        return _target[_idx];
    }
    
    if (is_struct(_target)) {
        var _key = string(_idx);
        if (struct_exists(_target, _key)) {
            return _target[$ _key];
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Struct key '" + _key + "' does not exist",
            _node.line,
            _node.column
        );
    }
    
    if (ds_exists(_target, ds_type_map)) {
        if (!ds_map_exists(_target, _idx)) {
            return undefined;
        }
        return ds_map_find_value(_target, _idx);
    }
    
    if (ds_exists(_target, ds_type_list)) {
        if (_idx < 0 || _idx >= ds_list_size(_target)) {
            throw gmlvm_create_error(
                "runtime_error",
                "List index " + string(_idx) + " out of bounds",
                _node.line,
                _node.column
            );
        }
        return ds_list_find_value(_target, _idx);
    }
    
    if (instance_exists(_target)) {
        var _prop = string(_idx);
        if (variable_instance_exists(_target, _prop)) {
            return variable_instance_get(_target, _prop);
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Variable '" + _prop + "' not defined on instance",
            _node.line,
            _node.column
        );
    }
    
    throw gmlvm_create_error(
        "runtime_error",
        "Cannot access index on value of type " + typeof(_target),
        _node.line,
        _node.column
    );
}

//function gmlvm_vm_set_access(_node, _value, _ctx) {
//    var _target = gmlvm_vm_evaluate(_node.target, _ctx);
//    var _index = _node.index;
//    var _kind = _node.kind;
//    
//    if (_kind == "dot") {
//        var _prop = _index.value;
//		
//		if (_target == global) {
//			variable_global_set(_prop, _value);
//			return;
//		}
//		
//        if (is_struct(_target)) {
//            _target[$ _prop] = _value;
//        } else if (instance_exists(_target)) {
//            variable_instance_set(_target, _prop, _value);
//        }
//        return;
//    }
//    
//    var _idx = gmlvm_vm_evaluate(_index, _ctx);
//    
//    if (_kind == "[@") {
//        if (is_array(_target)) {
//            _target[_idx] = _value;
//        }
//    } else if (_kind == "[$") {
//        if (is_struct(_target)) {
//            _target[$ _idx] = _value;
//        }
//    } else if (_kind == "[?") {
//	    ds_map_set(_target, _idx, _value);
//	} else if (_kind == "[|") {
//	    ds_list_set(_target, _idx, _value);
//	} else if (_kind == "[#") {
//        if (is_array(_idx) && ds_exists(_target, ds_type_grid)) {
//            ds_grid_set(_target, _idx[0], _idx[1], _value);
//        }
//    } else {
//        if (is_array(_target)) {
//            _target[_idx] = _value;
//        } else if (is_struct(_target)) {
//            _target[$ _idx] = _value;
//        } else if (ds_exists(_target, ds_type_map)) {
//            ds_map_set(_target, _idx, _value);
//        } else if (instance_exists(_target)) {
//            variable_instance_set(_target, string(_idx), _value);
//        }
//    }
//}

function gmlvm_vm_set_access(_node, _value, _ctx) {
    var _target = gmlvm_vm_evaluate(_node.target, _ctx);
    var _index = _node.index;
    var _kind = _node.kind;
    
    if (_kind == "dot") {
        var _prop = _index.value;
        
        if (_target == global) {
            variable_global_set(_prop, _value);
            return;
        }
        
        if (is_struct(_target)) {
            _target[$ _prop] = _value;
            return;
        }
        
        if (instance_exists(_target)) {
            if (_prop == "id" || _prop == "object_index" || 
                _prop == "bbox_left" || _prop == "bbox_right" || 
                _prop == "bbox_top" || _prop == "bbox_bottom") {
                throw gmlvm_create_error(
                    "runtime_error",
                    "Cannot assign to read-only property '" + _prop + "'",
                    _node.line,
                    _node.column
                );
            }
            
            variable_instance_set(_target, _prop, _value);
            return;
        }
        
        if (_target == undefined) {
            throw gmlvm_create_error(
                "runtime_error",
                "Cannot set property '" + _prop + "' on undefined value",
                _node.line,
                _node.column
            );
        }
        
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot set property '" + _prop + "' on " + typeof(_target),
            _node.line,
            _node.column
        );
    }
    
    var _idx = gmlvm_vm_evaluate(_index, _ctx);
    
    if (_kind == "[@") {
	    if (is_array(_target)) {
	        if (_idx >= array_length(_target)) {
	            for (var _i = array_length(_target); _i <= _idx; _i++) {
	                _target[_i] = undefined;
	            }
	        }
	        _target[_idx] = _value;
	        return;
	    }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use array accessor [@] on non-array value (got " + typeof(_target) + ")",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[$") {
        if (is_struct(_target)) {
            var _key = string(_idx);
            _target[$ _key] = _value;
            return;
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use struct accessor [$] on non-struct value (got " + typeof(_target) + ")",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[?") {
        if (ds_exists(_target, ds_type_map)) {
            ds_map_set(_target, _idx, _value);
            return;
        }
        if (is_real(_target)) {
            if (ds_exists(_target, ds_type_map)) {
                ds_map_set(_target, _idx, _value);
                return;
            }
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use map accessor [?] on non-map value",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[|") {
        if (ds_exists(_target, ds_type_list)) {
            if (_idx < 0 || _idx >= ds_list_size(_target)) {
                throw gmlvm_create_error(
                    "runtime_error",
                    "List index " + string(_idx) + " out of bounds (size: " + string(ds_list_size(_target)) + ")",
                    _node.line,
                    _node.column
                );
            }
            ds_list_set(_target, _idx, _value);
            return;
        }
        if (is_real(_target)) {
            if (ds_exists(_target, ds_type_list)) {
                if (_idx < 0 || _idx >= ds_list_size(_target)) {
                    throw gmlvm_create_error(
                        "runtime_error",
                        "List index " + string(_idx) + " out of bounds",
                        _node.line,
                        _node.column
                    );
                }
                ds_list_set(_target, _idx, _value);
                return;
            }
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use list accessor [|] on non-list value",
            _node.line,
            _node.column
        );
    }
    
    if (_kind == "[#") {
        if (is_array(_idx) && array_length(_idx) >= 2) {
            var _x = _idx[0];
            var _y = _idx[1];
            if (ds_exists(_target, ds_type_grid)) {
                if (_x < 0 || _x >= ds_grid_width(_target) || _y < 0 || _y >= ds_grid_height(_target)) {
                    throw gmlvm_create_error(
                        "runtime_error",
                        "Grid index (" + string(_x) + ", " + string(_y) + ") out of bounds",
                        _node.line,
                        _node.column
                    );
                }
                ds_grid_set(_target, _x, _y, _value);
                return;
            }
        }
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot use grid accessor [#] - invalid grid or coordinates",
            _node.line,
            _node.column
        );
    }
    
    if (is_array(_target)) {
	    if (_idx >= array_length(_target)) {
	        for (var _i = array_length(_target); _i <= _idx; _i++) {
	            _target[_i] = undefined;
	        }
	    }
	    _target[_idx] = _value;
        return;
    }
    
    if (is_struct(_target)) {
        var _key = string(_idx);
        _target[$ _key] = _value;
        return;
    }
    
    if (ds_exists(_target, ds_type_map)) {
        ds_map_set(_target, _idx, _value);
        return;
    }
    
    if (ds_exists(_target, ds_type_list)) {
        if (_idx < 0 || _idx >= ds_list_size(_target)) {
            throw gmlvm_create_error(
                "runtime_error",
                "List index " + string(_idx) + " out of bounds",
                _node.line,
                _node.column
            );
        }
        ds_list_set(_target, _idx, _value);
        return;
    }
    
    if (instance_exists(_target)) {
        var _prop = string(_idx);
        
        if (_prop == "id" || _prop == "object_index" || 
            _prop == "bbox_left" || _prop == "bbox_right" || 
            _prop == "bbox_top" || _prop == "bbox_bottom") {
            throw gmlvm_create_error(
                "runtime_error",
                "Cannot assign to read-only property '" + _prop + "'",
                _node.line,
                _node.column
            );
        }
        
        variable_instance_set(_target, _prop, _value);
        return;
    }
    
    if (_target == undefined) {
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot set index on undefined value",
            _node.line,
            _node.column
        );
    }
    
    throw gmlvm_create_error(
        "runtime_error",
        "Cannot set index on value of type " + typeof(_target),
        _node.line,
        _node.column
    );
}

//function gmlvm_vm_call(_func, _args, _ctx) {
//    // check if its framework's custom GML function
//    if (is_struct(_func) && struct_exists(_func, "__gmlvm_type") && _func.__gmlvm_type == "function") {
//        return gmlvm_vm_call_gmlvm_function(_func, _args, _ctx);
//    }
//    
//    if (is_method(_func) || is_real(_func)) {
//        var _arg_count = array_length(_args);
//        
//        switch (_arg_count) {
//            case 0:  return _func();
//            case 1:  return _func(_args[0]);
//            case 2:  return _func(_args[0], _args[1]);
//            case 3:  return _func(_args[0], _args[1], _args[2]);
//            case 4:  return _func(_args[0], _args[1], _args[2], _args[3]);
//            case 5:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4]);
//            case 6:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5]);
//            case 7:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6]);
//            case 8:  return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7]);
//            default:
//                return undefined;
//        }
//    }
//    
//	// return if its just a value
//	gmlvm_warning("cannot_call", "Cannot call value of type " + typeof(_func));
//    return _func;
//}

function gmlvm_vm_call(_func, _args, _ctx) {
    if (_func == undefined) {
        throw gmlvm_create_error(
            "runtime_error",
            "Cannot call undefined value as function",
            -1, -1
        );
    }
    
    // check if its framework's custom GML function
    if (is_struct(_func) && struct_exists(_func, "__gmlvm_type") && _func.__gmlvm_type == "function") {
        return gmlvm_vm_call_gmlvm_function(_func, _args, _ctx);
    }
    
    if (is_method(_func) || is_real(_func)) {
        var _arg_count = array_length(_args);
        var _current_self = _ctx.GetSelf();
        
        // If we have an instance as self, call the function in its context
        if (instance_exists(_current_self) || is_struct(_current_self)) {
            var _result;
            with (_current_self) {
                switch (_arg_count) {
                    case 0:  _result = _func(); break;
                    case 1:  _result = _func(_args[0]); break;
                    case 2:  _result = _func(_args[0], _args[1]); break;
                    case 3:  _result = _func(_args[0], _args[1], _args[2]); break;
                    case 4:  _result = _func(_args[0], _args[1], _args[2], _args[3]); break;
                    case 5:  _result = _func(_args[0], _args[1], _args[2], _args[3], _args[4]); break;
                    case 6:  _result = _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5]); break;
                    case 7:  _result = _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6]); break;
                    case 8:  _result = _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7]); break;
                    default: _result = undefined;
                }
            }
            return _result;
        } else {
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
                default: return undefined;
            }
        }
    }
    
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
	    _self_inst.gmlvm_constructor = _func;
    
	    var _evaluated_args = [];
	    for (var _i = 0; _i < array_length(_args); _i++) {
	        _evaluated_args[_i] = _args[_i];
	    }
    
	    if (_inherit != undefined) {
	        var _parent_ctor = _caller_ctx.GetVar(_inherit);
	        if (is_struct(_parent_ctor) && struct_exists(_parent_ctor, "__gmlvm_type") && _parent_ctor.__gmlvm_type == "function") {
	            _func.gmlvm_parent = _parent_ctor;
            
	            var _parent_args = [];
            
	            if (array_length(_inherit_args) > 0) {
	                var _temp_ctx = new gmlvm_vm_context(_self_inst, _caller_ctx.GetSelf());
	                for (var _i = 0; _i < array_length(_params); _i++) {
	                    var _param_name = _params[_i];
	                    var _value = (_i < array_length(_evaluated_args)) ? _evaluated_args[_i] : 0;
	                    _temp_ctx.locals[$ _param_name] = _value;
	                }
                
	                for (var _i = 0; _i < array_length(_inherit_args); _i++) {
	                    _parent_args[_i] = gmlvm_vm_evaluate(_inherit_args[_i], _temp_ctx);
	                }
	            } else {
	                for (var _i = 0; _i < array_length(_evaluated_args); _i++) {
	                    _parent_args[_i] = _evaluated_args[_i];
	                }
	            }
            
	            var _parent_was_constructor = _parent_ctor.__gmlvm_is_constructor;
	            _parent_ctor.__gmlvm_is_constructor = true;
	            var _parent_instance = gmlvm_vm_call_gmlvm_function(_parent_ctor, _parent_args, _caller_ctx);
	            _parent_ctor.__gmlvm_is_constructor = _parent_was_constructor;
            
	            if (is_struct(_parent_instance)) {
	                var _saved_constructor = _self_inst.gmlvm_constructor;
                
	                var _names = struct_get_names(_parent_instance);
	                for (var _i = 0; _i < array_length(_names); _i++) {
	                    var _n = _names[_i];
	                    _self_inst[$ _n] = _parent_instance[$ _n];
	                }
                
	                _self_inst.gmlvm_constructor = _saved_constructor;
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
	        // Check for default value
	        if (struct_exists(_func, "__gmlvm_param_defaults") && struct_exists(_func.__gmlvm_param_defaults, _param_name)) {
	            var _default_node = _func.__gmlvm_param_defaults[$ _param_name];
	            _value = gmlvm_vm_evaluate(_default_node, _caller_ctx);
	        } else {
	            _value = 0;
	        }
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
	    } else if (_result.type == "exit") {
	        return undefined;
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

function gmlvm_vm_builtin(_name) { // TODO: add more built in
    static _found = false;
    static _value = undefined;
    
    _found = true;
    
    // constants
	// core
    if (_name == "pointer_null") { _value = pointer_null; return { found: _found, value: _value }; }
    if (_name == "pointer_invalid") { _value = pointer_invalid; return { found: _found, value: _value }; }
    if (_name == "NaN") { _value = NaN; return { found: _found, value: _value }; }
    if (_name == "infinity") { _value = infinity; return { found: _found, value: _value }; }
    
    // color
    if (_name == "c_aqua")    { _value = c_aqua;    return { found: _found, value: _value }; }
    if (_name == "c_black")   { _value = c_black;   return { found: _found, value: _value }; }
    if (_name == "c_blue")    { _value = c_blue;    return { found: _found, value: _value }; }
    if (_name == "c_dkgray")  { _value = c_dkgray;  return { found: _found, value: _value }; }
    if (_name == "c_fuchsia") { _value = c_fuchsia; return { found: _found, value: _value }; }
    if (_name == "c_gray")    { _value = c_gray;    return { found: _found, value: _value }; }
    if (_name == "c_green")   { _value = c_green;   return { found: _found, value: _value }; }
    if (_name == "c_lime")    { _value = c_lime;    return { found: _found, value: _value }; }
    if (_name == "c_ltgray")  { _value = c_ltgray;  return { found: _found, value: _value }; }
    if (_name == "c_maroon")  { _value = c_maroon;  return { found: _found, value: _value }; }
    if (_name == "c_navy")    { _value = c_navy;    return { found: _found, value: _value }; }
    if (_name == "c_olive")   { _value = c_olive;   return { found: _found, value: _value }; }
    if (_name == "c_orange")  { _value = c_orange;  return { found: _found, value: _value }; }
    if (_name == "c_purple")  { _value = c_purple;  return { found: _found, value: _value }; }
    if (_name == "c_red")     { _value = c_red;     return { found: _found, value: _value }; }
    if (_name == "c_silver")  { _value = c_silver;  return { found: _found, value: _value }; }
    if (_name == "c_teal")    { _value = c_teal;    return { found: _found, value: _value }; }
    if (_name == "c_white")   { _value = c_white;   return { found: _found, value: _value }; }
    if (_name == "c_yellow")  { _value = c_yellow;  return { found: _found, value: _value }; }
    
    // keyboard
    if (_name == "vk_anykey")   { _value = vk_anykey;   return { found: _found, value: _value }; }
    if (_name == "vk_nokey")    { _value = vk_nokey;    return { found: _found, value: _value }; }
    if (_name == "vk_left")     { _value = vk_left;     return { found: _found, value: _value }; }
    if (_name == "vk_right")    { _value = vk_right;    return { found: _found, value: _value }; }
    if (_name == "vk_up")       { _value = vk_up;       return { found: _found, value: _value }; }
    if (_name == "vk_down")     { _value = vk_down;     return { found: _found, value: _value }; }
    if (_name == "vk_enter")    { _value = vk_enter;    return { found: _found, value: _value }; }
    if (_name == "vk_escape")   { _value = vk_escape;   return { found: _found, value: _value }; }
    if (_name == "vk_space")    { _value = vk_space;    return { found: _found, value: _value }; }
    if (_name == "vk_shift")    { _value = vk_shift;    return { found: _found, value: _value }; }
    if (_name == "vk_control")  { _value = vk_control;  return { found: _found, value: _value }; }
    if (_name == "vk_alt")      { _value = vk_alt;      return { found: _found, value: _value }; }
    if (_name == "vk_backspace"){ _value = vk_backspace;return { found: _found, value: _value }; }
    if (_name == "vk_tab")      { _value = vk_tab;      return { found: _found, value: _value }; }
    if (_name == "vk_delete")   { _value = vk_delete;   return { found: _found, value: _value }; }
    if (_name == "vk_insert")   { _value = vk_insert;   return { found: _found, value: _value }; }
    if (_name == "vk_home")     { _value = vk_home;     return { found: _found, value: _value }; }
    if (_name == "vk_end")      { _value = vk_end;      return { found: _found, value: _value }; }
    if (_name == "vk_pause")    { _value = vk_pause;    return { found: _found, value: _value }; }
    if (_name == "vk_printscreen") { _value = vk_printscreen; return { found: _found, value: _value }; }
    if (_name == "vk_f1")       { _value = vk_f1;       return { found: _found, value: _value }; }
    if (_name == "vk_f2")       { _value = vk_f2;       return { found: _found, value: _value }; }
    if (_name == "vk_f3")       { _value = vk_f3;       return { found: _found, value: _value }; }
    if (_name == "vk_f4")       { _value = vk_f4;       return { found: _found, value: _value }; }
    if (_name == "vk_f5")       { _value = vk_f5;       return { found: _found, value: _value }; }
    if (_name == "vk_f6")       { _value = vk_f6;       return { found: _found, value: _value }; }
    if (_name == "vk_f7")       { _value = vk_f7;       return { found: _found, value: _value }; }
    if (_name == "vk_f8")       { _value = vk_f8;       return { found: _found, value: _value }; }
    if (_name == "vk_f9")       { _value = vk_f9;       return { found: _found, value: _value }; }
    if (_name == "vk_f10")      { _value = vk_f10;      return { found: _found, value: _value }; }
    if (_name == "vk_f11")      { _value = vk_f11;      return { found: _found, value: _value }; }
    if (_name == "vk_f12")      { _value = vk_f12;      return { found: _found, value: _value }; }
    if (_name == "vk_numpad0")  { _value = vk_numpad0;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad1")  { _value = vk_numpad1;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad2")  { _value = vk_numpad2;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad3")  { _value = vk_numpad3;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad4")  { _value = vk_numpad4;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad5")  { _value = vk_numpad5;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad6")  { _value = vk_numpad6;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad7")  { _value = vk_numpad7;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad8")  { _value = vk_numpad8;  return { found: _found, value: _value }; }
    if (_name == "vk_numpad9")  { _value = vk_numpad9;  return { found: _found, value: _value }; }
    if (_name == "vk_multiply") { _value = vk_multiply; return { found: _found, value: _value }; }
    if (_name == "vk_add")      { _value = vk_add;      return { found: _found, value: _value }; }
    if (_name == "vk_subtract") { _value = vk_subtract; return { found: _found, value: _value }; }
    if (_name == "vk_decimal")  { _value = vk_decimal;  return { found: _found, value: _value }; }
    if (_name == "vk_divide")   { _value = vk_divide;   return { found: _found, value: _value }; }
    if (_name == "vk_lshift")   { _value = vk_lshift;   return { found: _found, value: _value }; }
    if (_name == "vk_rshift")   { _value = vk_rshift;   return { found: _found, value: _value }; }
    if (_name == "vk_lcontrol") { _value = vk_lcontrol; return { found: _found, value: _value }; }
    if (_name == "vk_rcontrol") { _value = vk_rcontrol; return { found: _found, value: _value }; }
    if (_name == "vk_lalt")     { _value = vk_lalt;     return { found: _found, value: _value }; }
    if (_name == "vk_ralt")     { _value = vk_ralt;     return { found: _found, value: _value }; }
    
    // mouse
    if (_name == "mb_left")     { _value = mb_left;     return { found: _found, value: _value }; }
    if (_name == "mb_right")    { _value = mb_right;    return { found: _found, value: _value }; }
    if (_name == "mb_middle")   { _value = mb_middle;   return { found: _found, value: _value }; }
    if (_name == "mb_any")      { _value = mb_any;      return { found: _found, value: _value }; }
    if (_name == "mb_none")     { _value = mb_none;     return { found: _found, value: _value }; }
    
    // audio
    if (_name == "audio_falloff_exponent_distance") { _value = audio_falloff_exponent_distance; return { found: _found, value: _value }; }
    if (_name == "audio_falloff_inverse_distance") { _value = audio_falloff_inverse_distance; return { found: _found, value: _value }; }
    if (_name == "audio_falloff_linear_distance") { _value = audio_falloff_linear_distance; return { found: _found, value: _value }; }
    if (_name == "audio_falloff_none") { _value = audio_falloff_none; return { found: _found, value: _value }; }
    if (_name == "audio_mono") { _value = audio_mono; return { found: _found, value: _value }; }
    if (_name == "audio_stereo") { _value = audio_stereo; return { found: _found, value: _value }; }
    if (_name == "audio_3d") { _value = audio_3d; return { found: _found, value: _value }; }
    
    // draw
    if (_name == "pr_pointlist") { _value = pr_pointlist; return { found: _found, value: _value }; }
    if (_name == "pr_linelist") { _value = pr_linelist; return { found: _found, value: _value }; }
    if (_name == "pr_linestrip") { _value = pr_linestrip; return { found: _found, value: _value }; }
    if (_name == "pr_trianglelist") { _value = pr_trianglelist; return { found: _found, value: _value }; }
    if (_name == "pr_trianglestrip") { _value = pr_trianglestrip; return { found: _found, value: _value }; }
    if (_name == "pr_trianglefan") { _value = pr_trianglefan; return { found: _found, value: _value }; }
    
    // blend mode
    if (_name == "bm_normal") { _value = bm_normal; return { found: _found, value: _value }; }
    if (_name == "bm_add") { _value = bm_add; return { found: _found, value: _value }; }
    if (_name == "bm_subtract") { _value = bm_subtract; return { found: _found, value: _value }; }
    if (_name == "bm_max") { _value = bm_max; return { found: _found, value: _value }; }
    
    // unit
    if (_name == "gm_unit_seconds") { _value = time_source_units_seconds; return { found: _found, value: _value }; }
    if (_name == "gm_unit_frames") { _value = time_source_units_frames; return { found: _found, value: _value }; }
	
    // physics
    // physics: debug render flags
    if (_name == "phy_debug_render_aabb") { _value = phy_debug_render_aabb; return { found: _found, value: _value }; }
    if (_name == "phy_debug_render_collision_pairs") { _value = phy_debug_render_collision_pairs; return { found: _found, value: _value }; }
    if (_name == "phy_debug_render_coms") { _value = phy_debug_render_coms; return { found: _found, value: _value }; }
    if (_name == "phy_debug_render_core_shapes") { _value = phy_debug_render_core_shapes; return { found: _found, value: _value }; }
    if (_name == "phy_debug_render_joints") { _value = phy_debug_render_joints; return { found: _found, value: _value }; }
    if (_name == "phy_debug_render_obb") { _value = phy_debug_render_obb; return { found: _found, value: _value }; }
    if (_name == "phy_debug_render_shapes") { _value = phy_debug_render_shapes; return { found: _found, value: _value }; }
    
    // particle sys
    // particle sys: shape types
    if (_name == "ps_shape_ellipse") { _value = ps_shape_ellipse; return { found: _found, value: _value }; }
    if (_name == "ps_shape_line") { _value = ps_shape_line; return { found: _found, value: _value }; }
    if (_name == "ps_shape_rectangle") { _value = ps_shape_rectangle; return { found: _found, value: _value }; }
    if (_name == "ps_shape_diamond") { _value = ps_shape_diamond; return { found: _found, value: _value }; }
    
    // particle sys: distribution types
    if (_name == "ps_distr_linear") { _value = ps_distr_linear; return { found: _found, value: _value }; }
    if (_name == "ps_distr_gaussian") { _value = ps_distr_gaussian; return { found: _found, value: _value }; }
    if (_name == "ps_distr_invgaussian") { _value = ps_distr_invgaussian; return { found: _found, value: _value }; }
    
    // shader matrix
    if (_name == "matrix_view") { _value = matrix_view; return { found: _found, value: _value }; }
    if (_name == "matrix_projection") { _value = matrix_projection; return { found: _found, value: _value }; }
    if (_name == "matrix_world") { _value = matrix_world; return { found: _found, value: _value }; }
    
    // culling modes
    if (_name == "cull_noculling") { _value = cull_noculling; return { found: _found, value: _value }; }
    if (_name == "cull_clockwise") { _value = cull_clockwise; return { found: _found, value: _value }; }
    if (_name == "cull_counterclockwise") { _value = cull_counterclockwise; return { found: _found, value: _value }; }
    
    // event
    if (_name == "ev_create") { _value = ev_create; return { found: _found, value: _value }; }
    if (_name == "ev_destroy") { _value = ev_destroy; return { found: _found, value: _value }; }
    if (_name == "ev_step") { _value = ev_step; return { found: _found, value: _value }; }
    if (_name == "ev_alarm") { _value = ev_alarm; return { found: _found, value: _value }; }
    if (_name == "ev_draw") { _value = ev_draw; return { found: _found, value: _value }; }
    if (_name == "ev_keyboard") { _value = ev_keyboard; return { found: _found, value: _value }; }
    if (_name == "ev_mouse") { _value = ev_mouse; return { found: _found, value: _value }; }
    if (_name == "ev_collision") { _value = ev_collision; return { found: _found, value: _value }; }
    if (_name == "ev_other") { _value = ev_other; return { found: _found, value: _value }; }
    if (_name == "ev_gui") { _value = ev_gui; return { found: _found, value: _value }; }
    if (_name == "ev_gesture") { _value = ev_gesture; return { found: _found, value: _value }; }
    if (_name == "ev_cleanup") { _value = ev_cleanup; return { found: _found, value: _value }; }
    
    // alarm
    if (_name == "alarm_0") { _value = 0; return { found: _found, value: _value }; }
    if (_name == "alarm_1") { _value = 1; return { found: _found, value: _value }; }
    if (_name == "alarm_2") { _value = 2; return { found: _found, value: _value }; }
    if (_name == "alarm_3") { _value = 3; return { found: _found, value: _value }; }
    if (_name == "alarm_4") { _value = 4; return { found: _found, value: _value }; }
    if (_name == "alarm_5") { _value = 5; return { found: _found, value: _value }; }
    if (_name == "alarm_6") { _value = 6; return { found: _found, value: _value }; }
    if (_name == "alarm_7") { _value = 7; return { found: _found, value: _value }; }
    if (_name == "alarm_8") { _value = 8; return { found: _found, value: _value }; }
    if (_name == "alarm_9") { _value = 9; return { found: _found, value: _value }; }
    if (_name == "alarm_10") { _value = 10; return { found: _found, value: _value }; }
    if (_name == "alarm_11") { _value = 11; return { found: _found, value: _value }; }
    
    // function overrides
    //if (_name == "sqrt") { _value = sqrt; return { found: _found, value: _value }; }
    //if (_name == "sin") { _value = sin; return { found: true, value: _value }; }
    //if (_name == "cos") { _value = cos; return { found: true, value: _value }; }
    //if (_name == "tan") { _value = tan; return { found: true, value: _value }; }
    //if (_name == "power") { _value = power; return { found: true, value: _value }; }
    //if (_name == "abs") { _value = abs; return { found: true, value: _value }; }
    //if (_name == "round") { _value = round; return { found: true, value: _value }; }
    //if (_name == "floor") { _value = floor; return { found: true, value: _value }; }
    //if (_name == "ceil") { _value = ceil; return { found: true, value: _value }; }
    //if (_name == "random") { _value = random; return { found: true, value: _value }; }
    //if (_name == "irandom") { _value = irandom; return { found: true, value: _value }; }
    //if (_name == "string") { _value = string; return { found: true, value: _value }; }
    //if (_name == "real") { _value = real; return { found: true, value: _value }; }
    //if (_name == "is_string") { _value = is_string; return { found: true, value: _value }; }
    //if (_name == "is_real") { _value = is_real; return { found: true, value: _value }; }
    //if (_name == "is_array") { _value = is_array; return { found: true, value: _value }; }
    //if (_name == "is_struct") { _value = is_struct; return { found: true, value: _value }; }
    //if (_name == "array_length") { _value = array_length; return { found: true, value: _value }; }
    //if (_name == "struct_get_names") { _value = struct_get_names; return { found: true, value: _value }; }
    //if (_name == "struct_exists") { _value = struct_exists; return { found: true, value: _value }; }
    //if (_name == "show_debug_message") { _value = show_debug_message; return { found: true, value: _value }; }
    //if (_name == "struct_remove") { _value = struct_remove; return { found: true, value: _value }; }
    //if (_name == "array_delete") { _value = array_delete; return { found: true, value: _value }; }
    //if (_name == "is_bool") { _value = is_bool; return { found: true, value: _value }; }
    //if (_name == "is_method") { _value = is_method; return { found: true, value: _value }; }
    if (_name == "instanceof") {
	    _value = function(_struct) {
	        if (!is_struct(_struct)) return undefined;
        
	        // Check for gmlvm_constructor property
	        if (struct_exists(_struct, "gmlvm_constructor")) {
	            var _ctor = _struct.gmlvm_constructor;
	            if (is_struct(_ctor) && struct_exists(_ctor, "__gmlvm_name")) {
	                return _ctor.__gmlvm_name;
	            }
	        }
        
	        // Fallback - check if it's a plain struct
	        return "struct";
	    };
	    return { found: true, value: _value };
	}
	if (_name == "is_instanceof") {
	    _value = function(_struct, _constructor) {
	        if (!is_struct(_struct)) return false;
	        if (!is_struct(_constructor)) return false;
        
	        if (!struct_exists(_constructor, "__gmlvm_type")) return false;
	        if (_constructor.__gmlvm_type != "function") return false;
        
	        if (struct_exists(_struct, "gmlvm_constructor")) {
	            var _ctor = _struct.gmlvm_constructor;
	            if (_ctor == _constructor) return true;
            
	            while (struct_exists(_ctor, "gmlvm_parent")) {
	                _ctor = _ctor.gmlvm_parent;
	                if (_ctor == _constructor) return true;
	            }
	        }
	        return false;
	    };
	    return { found: true, value: _value };
	}
	if (_name == "typeof") {
	    _value = function(_val) {
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
	        if (is_bool(_val)) return "number";  // GML treats bool as number
        
	        return "unknown";
	    };
	    return { found: true, value: _value };
	}
	
    // Try asset index
    _value = real(asset_get_index(_name));
    if (_value >= 0) {
        return { found: true, value: _value };
    }
    
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
        
        // doesnt exist anywhere - create in self
	    if (is_struct(self_inst)) {
	        self_inst[$ _name] = _value;
	    } else if (instance_exists(self_inst)) {
	        variable_instance_set(self_inst, _name, _value);
	    } else {
	        locals[$ _name] = _value; // fallback to local if no 'self' provided
	    }
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

function gmlvm_vm_evaluate(_node, _ctx) {
    if (_node == undefined) {
        return undefined;
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

//function gmlvm_vm(_ast, _self = self, _other = other) {
//    var _ctx = new gmlvm_vm_context(_self, _other);
//	
//	if (instance_exists(_self) || is_struct(_self)) {
//        var _result;
//        with (_self) {
//            _result = gmlvm_vm(_ast, id, _other);
//        }
//        return _result;
//    } else {
//        return gmlvm_vm(_ast, _self, _other);
//    }
//}

//function gmlvm_vm(_ast, _self = self, _other = other) {
//    var _ctx = new gmlvm_vm_context(_self, _other);
//    
//    try {
//        var _result = gmlvm_vm_evaluate(_ast, _ctx);
//        
//        // unwrap return interrupt
//        if (is_struct(_result) && struct_exists(_result, "type")) {
//            if (_result.type == "return") {
//                return _result.value;
//            }
//        }
//        
//        return _result;
//    } catch (_err) {
//        show_debug_message("VM Runtime Error: " + string(_err));
//        return undefined;
//    }
//}

/*
function gmlvm_vm(_ast, _self = self, _other = other) {
    if (object_exists(_self) || is_struct(_self)) {
        var _result;
        with (_self) {
            var _ctx = new gmlvm_vm_context(id, _other);
            try {
                _result = gmlvm_vm_evaluate(_ast, _ctx);
                
                if (is_struct(_result) && struct_exists(_result, "type")) {
                    if (_result.type == "return") {
                        _result = _result.value;
                    }
                }
            } catch (_err) {
                show_debug_message("VM Runtime Error: " + string(_err));
                _result = undefined;
            }
        }
        return _result;
    }
    
    var _ctx = new gmlvm_vm_context(_self, _other);
    try {
        var _result = gmlvm_vm_evaluate(_ast, _ctx);
        
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
}*/

//function gmlvm_vm(_ast, _self = self, _other = other) {
//    // If _self is an instance, run the entire VM in that instance's context
//    if (instance_exists(_self) || is_struct(_self)) {
//        var _result;
//        with (_self) {
//            var _ctx = new gmlvm_vm_context(id, _other);
//            try {
//                _result = gmlvm_vm_evaluate(_ast, _ctx);
//                
//                if (is_struct(_result) && struct_exists(_result, "type")) {
//                    if (_result.type == "return") {
//                        _result = _result.value;
//                    }
//                }
//            } catch (_err) {
//                show_debug_message("VM Runtime Error: " + string(_err));
//                _result = undefined;
//            }
//        }
//        return _result;
//    }
//    
//    // For structs or no instance, just run normally
//    var _ctx = new gmlvm_vm_context(_self, _other);
//    try {
//        var _result = gmlvm_vm_evaluate(_ast, _ctx);
//        
//        if (is_struct(_result) && struct_exists(_result, "type")) {
//            if (_result.type == "return") {
//                return _result.value;
//            }
//        }
//        
//        return _result;
//    } catch (_err) {
//        show_debug_message("VM Runtime Error: " + string(_err));
//        return undefined;
//    }
//}

function gmlvm_vm(_ast, _self = self, _other = other) {
    if (instance_exists(_self) || is_struct(_self)) {
        var _result;
        with (_self) {
            var _ctx = new gmlvm_vm_context(id, _other);
            _result = gmlvm_vm_evaluate(_ast, _ctx);
            
            if (is_struct(_result) && struct_exists(_result, "type")) {
                if (_result.type == "return") {
                    _result = _result.value;
                } else if (_result.type == "exit") {
                    _result = undefined;
                }
            }
        }
        return _result;
    }
    
    var _ctx = new gmlvm_vm_context(_self, _other);
    var _result = gmlvm_vm_evaluate(_ast, _ctx);
    
    if (is_struct(_result) && struct_exists(_result, "type")) {
        if (_result.type == "return") {
            return _result.value;
        } else if (_result.type == "exit") {
            return undefined;
        }
    }
    
    return _result;
}