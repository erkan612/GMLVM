function gmlvm_sandbox() constructor {
    // blacklists
    blacklist_functions = ds_map_create();
    blacklist_objects   = ds_map_create();
    blacklist_variables = ds_map_create();
    blacklist_assets    = ds_map_create();
    blacklist_strings   = ds_map_create();
    
    // whitelists
    whitelist_functions = ds_map_create();
    whitelist_objects   = ds_map_create();
    whitelist_variables = ds_map_create();
    whitelist_assets    = ds_map_create();
    
    // settings
    use_whitelist_mode = false;			// false = blacklist mode, true = whitelist mode
    max_execution_time = 100;			// Maximum execution time in milliseconds (approximate)
    max_loop_iterations = 10000;		// Maximum loop iterations
    max_recursion_depth = 100;			// Maximum function recursion depth
    max_memory_allocations = 1000;		// Maximum number of ds_*/array/struct creations
    allow_file_access = false;			// Allow file operations
    allow_network_access = false;		// Allow network operations
    allow_instance_creation = true;		// Allow creating instances
    allow_instance_destruction = false; // Allow destroying instances (dangerous!)
    allow_room_changes = false;			// Allow room_goto and related functions
    allow_game_end = false;				// Allow game_end
    allow_debug_output = true;			// Allow show_debug_message
    
    // statistics
    execution_time = 0;
    loop_iterations = 0;
    recursion_depth = 0;
    memory_allocations = 0;
    start_time = 0;
    
    // blacklist methods
    static BanFunction = function(_func_name) {
        blacklist_functions[? _func_name] = true;
    };
    
    static BanObject = function(_obj_name) {
        blacklist_objects[? _obj_name] = true;
    };
    
    static BanVariable = function(_var_name) {
        blacklist_variables[? _var_name] = true;
    };
    
    static BanAsset = function(_asset_name) {
        blacklist_assets[? _asset_name] = true;
    };
    
    static BanString = function(_pattern) {
        blacklist_strings[? _pattern] = true;
    };
    
    // whitelist methods
    static AllowFunction = function(_func_name) {
        whitelist_functions[? _func_name] = true;
    };
    
    static AllowObject = function(_obj_name) {
        whitelist_objects[? _obj_name] = true;
    };
    
    static AllowVariable = function(_var_name) {
        whitelist_variables[? _var_name] = true;
    };
    
    static AllowAsset = function(_asset_name) {
        whitelist_assets[? _asset_name] = true;
    };
    
    // convenience methods
    static BanAllFileFunctions = function() {
        BanFunction("file_*");
        BanFunction("file_text_*");
        BanFunction("file_bin_*");
        BanFunction("directory_*");
        BanFunction("zip_*");
        allow_file_access = false;
    };
    
    static BanAllNetworkFunctions = function() {
        BanFunction("http_*");
        BanFunction("network_*");
        BanFunction("tcp_*");
        BanFunction("udp_*");
        BanFunction("socket_*");
        allow_network_access = false;
    };
    
    static BanAllInstanceDestruction = function() {
        BanFunction("instance_destroy");
        BanFunction("instance_destroy_all");
        BanFunction("room_instance_clear");
        allow_instance_destruction = false;
    };
    
    static BanAllRoomChanges = function() {
        BanFunction("room_goto");
        BanFunction("room_next");
        BanFunction("room_previous");
        BanFunction("room_restart");
        allow_room_changes = false;
    };
    
    static BanAllDSFunctions = function() {
        BanFunction("ds_*");
    };
    
    static BanAllSurfaceFunctions = function() {
        BanFunction("surface_*");
    };
    
    static BanAllShaderFunctions = function() {
        BanFunction("shader_*");
    };
    
    static BanAllParticleFunctions = function() {
        BanFunction("part_*");
    };
    
    static BanAllPhysicsFunctions = function() {
        BanFunction("phy_*");
    };
    
    static SetWhitelistMode = function(_enabled) {
        use_whitelist_mode = _enabled;
    };
    
    // presets
    static PresetStrict = function() {
        // Most restrictive - only basic math and string operations
        SetWhitelistMode(true);
        AllowFunction("sqrt");
        AllowFunction("sin");
        AllowFunction("cos");
        AllowFunction("tan");
        AllowFunction("abs");
        AllowFunction("round");
        AllowFunction("floor");
        AllowFunction("ceil");
        AllowFunction("random");
        AllowFunction("string");
        AllowFunction("real");
        AllowFunction("show_debug_message");
        max_loop_iterations = 1000;
        max_memory_allocations = 100;
        allow_instance_creation = false;
    };
    
    static PresetModding = function() {
        // For game modding - allows gameplay but not system changes
        BanAllFileFunctions();
        BanAllNetworkFunctions();
        BanAllRoomChanges();
        BanFunction("game_end");
        BanFunction("game_restart");
        max_loop_iterations = 10000;
        max_memory_allocations = 1000;
        allow_instance_creation = true;
        allow_instance_destruction = false;
    };
    
    static PresetDebug = function() {
        // For debugging - allows almost everything
        allow_file_access = true;
        allow_network_access = true;
        allow_instance_creation = true;
        allow_instance_destruction = true;
        allow_room_changes = true;
        allow_debug_output = true;
        max_loop_iterations = 100000;
    };
    
    // check methods
    static IsFunctionAllowed = function(_func_name) {
        if (use_whitelist_mode) {
            // Check exact match
            if (ds_map_exists(whitelist_functions, _func_name)) return true;
            // Check wildcards
            var _keys = ds_map_keys_to_array(whitelist_functions);
            for (var _i = 0; _i < array_length(_keys); _i++) {
                var _pattern = _keys[_i];
                if (string_pos("*", _pattern) > 0) {
                    var _regex = string_replace_all(_pattern, "*", ".*");
                    if (string_match(_func_name, _regex)) return true;
                }
            }
            return false;
        } else {
            // Blacklist mode
            if (ds_map_exists(blacklist_functions, _func_name)) return false;
            // Check wildcards
            var _keys = ds_map_keys_to_array(blacklist_functions);
            for (var _i = 0; _i < array_length(_keys); _i++) {
                var _pattern = _keys[_i];
                if (string_pos("*", _pattern) > 0) {
                    var _regex = string_replace_all(_pattern, "*", ".*");
                    if (string_match(_func_name, _regex)) return false;
                }
            }
            return true;
        }
    };
    
    static IsObjectAllowed = function(_obj_name) {
        if (use_whitelist_mode) {
            return ds_map_exists(whitelist_objects, _obj_name);
        } else {
            return !ds_map_exists(blacklist_objects, _obj_name);
        }
    };
    
    static IsVariableAllowed = function(_var_name) {
        if (use_whitelist_mode) {
            return ds_map_exists(whitelist_variables, _var_name);
        } else {
            return !ds_map_exists(blacklist_variables, _var_name);
        }
    };
    
    // runtime checks
    static CheckFunction = function(_func) {
        if (is_real(_func)) {
            var _name = script_get_name(_func);
            if (!IsFunctionAllowed(_name)) {
                throw "Sandbox: Function '" + _name + "' is not allowed";
            }
        }
    };
    
    static CheckVariable = function(_name) {
        if (!IsVariableAllowed(_name)) {
            throw "Sandbox: Variable '" + _name + "' is not allowed";
        }
    };
    
    static CheckLoopIteration = function() {
        loop_iterations++;
        if (loop_iterations > max_loop_iterations) {
            throw "Sandbox: Maximum loop iterations (" + string(max_loop_iterations) + ") exceeded";
        }
    };
    
    static CheckRecursionDepth = function() {
        recursion_depth++;
        if (recursion_depth > max_recursion_depth) {
            throw "Sandbox: Maximum recursion depth (" + string(max_recursion_depth) + ") exceeded";
        }
    };
    
    static CheckMemoryAllocation = function() {
        memory_allocations++;
        if (memory_allocations > max_memory_allocations) {
            throw "Sandbox: Maximum memory allocations (" + string(max_memory_allocations) + ") exceeded";
        }
    };
    
    static StartTimer = function() {
        start_time = current_time;
    };
    
    static CheckTimeout = function() {
        if (current_time - start_time > max_execution_time) {
            throw "Sandbox: Execution time exceeded (" + string(max_execution_time) + "ms)";
        }
    };
    
    // reset
    static Reset = function() {
        loop_iterations = 0;
        recursion_depth = 0;
        memory_allocations = 0;
        execution_time = 0;
    };
    
    // cleanup
    static Destroy = function() {
        ds_map_destroy(blacklist_functions);
        ds_map_destroy(blacklist_objects);
        ds_map_destroy(blacklist_variables);
        ds_map_destroy(blacklist_assets);
        ds_map_destroy(blacklist_strings);
        ds_map_destroy(whitelist_functions);
        ds_map_destroy(whitelist_objects);
        ds_map_destroy(whitelist_variables);
        ds_map_destroy(whitelist_assets);
    };
}

function string_match(_str, _pattern) {
    var _pattern_parts = string_split(_pattern, "*");
    var _pos = 1;
    
    for (var _i = 0; _i < array_length(_pattern_parts); _i++) {
        var _part = _pattern_parts[_i];
        if (_part == "") continue;
        
        var _found = string_pos(_part, _str);
        if (_found == 0) return false;
        _pos = _found + string_length(_part);
        _str = string_delete(_str, 1, _pos - 1);
    }
    
    return true;
}

function gmlvm_run_sandboxed(_code, _sandbox, _self = self, _other = other) {
    global.__gmlvm_current_sandbox = _sandbox;
    
    _sandbox.Reset();
    _sandbox.StartTimer();
    
    var _result = undefined;
    try {
        _result = gmlvm_run(_code, _self, _other);
    } catch (_err) {
        _result = new gmlvm_runtime_error(_err, -1, -1);
    }
    
    _sandbox.execution_time = current_time - _sandbox.start_time;
    global.__gmlvm_current_sandbox = undefined;
    
    return _result;
}