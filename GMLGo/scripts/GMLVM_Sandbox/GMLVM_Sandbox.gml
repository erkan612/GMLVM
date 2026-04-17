function gmlvm_sandbox() constructor {
    blacklist_functions = ds_map_create();
    blacklist_objects   = ds_map_create();
    blacklist_variables = ds_map_create();
    
    static BanFunction = function(_func_name) {
        blacklist_functions[? _func_name] = true;
    };
    
    static BanObject = function(_obj_name) {
        blacklist_objects[? _obj_name] = true;
    };
    
    static BanVariable = function(_var_name) {
        blacklist_variables[? _var_name] = true;
    };
    
    static IsFunctionBanned = function(_func_name) {
        return ds_map_exists(blacklist_functions, _func_name);
    };
    
    static IsObjectBanned = function(_obj_name) {
        return ds_map_exists(blacklist_objects, _obj_name);
    };
    
    static IsVariableBanned = function(_var_name) {
        return ds_map_exists(blacklist_variables, _var_name);
    };
    
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
    
    static Destroy = function() {
        ds_map_destroy(blacklist_functions);
        ds_map_destroy(blacklist_objects);
        ds_map_destroy(blacklist_variables);
    };
}

function gmlvm_run_sandboxed(_code, _sandbox, _self = self, _other = other) {
    global.__gmlvm_current_sandbox = _sandbox;
    
    var _result = undefined;
    try {
        _result = gmlvm_run(_code, _self, _other);
    } catch (_err) {
        _result = new gmlvm_runtime_error(_err, -1, -1);
    }
    
    global.__gmlvm_current_sandbox = undefined;
    return _result;
}