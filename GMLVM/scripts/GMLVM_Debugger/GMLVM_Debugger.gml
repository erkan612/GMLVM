function gmlvm_debugger() constructor {
    // Core state
    enabled = false;
    paused = false;
    breakpoints = ds_map_create();
    watch_expressions = ds_map_create();
    call_stack = [];
    
    // Current execution state
    current_node = undefined;
    current_line = -1;
    current_column = -1;
    current_file = "";
    current_function = "";
    current_scope = undefined;
    
    // Stepping control
    step_mode = "none";  // "none", "step_over", "step_into", "step_out", "step_line"
    step_depth = 0;
    step_target_line = -1;
    
    // Statistics
    call_depth = 0;
    nodes_executed = 0;
    start_time = 0;
    execution_time = 0;
    
    // Hooks (callbacks)
    on_break = undefined;      // function(node, line, file) - called when breakpoint hit
    on_step = undefined;       // function(node, line, file) - called on each step
    on_error = undefined;      // function(error, line, file) - called on runtime error
    on_trace = undefined;      // function(message) - called for trace output
    
    // UI state (for integration)
    ui_visible = false;
    ui_x = 10;
    ui_y = 10;
    ui_width = 400;
    ui_height = 300;
    
    // enable/disable
    static Enable = function() {
        enabled = true;
        paused = false;
        step_mode = "none";
        Trace("Debugger enabled");
    };
    
    static Disable = function() {
        enabled = false;
        paused = false;
        step_mode = "none";
        Trace("Debugger disabled");
    };
    
    static IsEnabled = function() {
        return enabled;
    };
    
    // breakpoints
    static SetBreakpoint = function(_file, _line, _condition = undefined) {
        var _key = string(_file) + ":" + string(_line);
        breakpoints[? _key] = {
            enabled: true,
            condition: _condition,
            hit_count: 0,
            file: _file,
            line: _line
        };
        Trace("Breakpoint set at " + _file + ":" + string(_line));
    };
    
    static RemoveBreakpoint = function(_file, _line) {
        var _key = string(_file) + ":" + string(_line);
        ds_map_delete(breakpoints, _key);
        Trace("Breakpoint removed at " + _file + ":" + string(_line));
    };
    
    static EnableBreakpoint = function(_file, _line) {
        var _key = string(_file) + ":" + string(_line);
        if (ds_map_exists(breakpoints, _key)) {
            var _bp = breakpoints[? _key];
            _bp.enabled = true;
            breakpoints[? _key] = _bp;
        }
    };
    
    static DisableBreakpoint = function(_file, _line) {
        var _key = string(_file) + ":" + string(_line);
        if (ds_map_exists(breakpoints, _key)) {
            var _bp = breakpoints[? _key];
            _bp.enabled = false;
            breakpoints[? _key] = _bp;
        }
    };
    
    static ClearBreakpoints = function() {
        ds_map_clear(breakpoints);
        Trace("All breakpoints cleared");
    };
    
    static GetBreakpoints = function() {
        var _result = [];
        var _keys = ds_map_keys_to_array(breakpoints);
        for (var _i = 0; _i < array_length(_keys); _i++) {
            array_push(_result, breakpoints[? _keys[_i]]);
        }
        return _result;
    };
    
    // watch expressions
    static AddWatch = function(_name, _expression) {
        watch_expressions[? _name] = {
            expression: _expression,
            value: undefined,
            last_eval: 0
        };
        Trace("Watch added: " + _name + " = " + _expression);
    };
    
    static RemoveWatch = function(_name) {
        ds_map_delete(watch_expressions, _name);
        Trace("Watch removed: " + _name);
    };
    
    static ClearWatches = function() {
        ds_map_clear(watch_expressions);
        Trace("All watches cleared");
    };
    
    static GetWatches = function() {
        return watch_expressions;
    };
    
    static EvaluateWatch = function(_name, _ctx) {
        var _watch = watch_expressions[? _name];
        if (_watch == undefined) return undefined;
        
        try {
            var _tokens = gmlvm_tokenize(_watch.expression);
            var _ast = gmlvm_parse_expression(_tokens, 0);
            var _value = gmlvm_vm_evaluate(_ast[0], _ctx);
            _watch.value = _value;
            _watch.last_eval = current_time;
            watch_expressions[? _name] = _watch;
            return _value;
        } catch (_err) {
            _watch.value = "<error: " + string(_err) + ">";
            watch_expressions[? _name] = _watch;
            return undefined;
        }
    };
    
    // stepping control
    static StepOver = function() {
        step_mode = "step_over";
        step_depth = call_depth;
        paused = false;
        Trace("Step over");
    };
    
    static StepInto = function() {
        step_mode = "step_into";
        paused = false;
        Trace("Step into");
    };
    
    static StepOut = function() {
        step_mode = "step_out";
        step_depth = call_depth;
        paused = false;
        Trace("Step out");
    };
    
    static StepLine = function() {
        step_mode = "step_line";
        step_target_line = current_line + 1;
        paused = false;
        Trace("Step line");
    };
    
    static Continue = function() {
        step_mode = "none";
        paused = false;
        Trace("Continue execution");
    };
    
    static Pause = function() {
        paused = true;
        step_mode = "none";
        Trace("Execution paused");
    };
    
    // breakpoint evaluation
    static ShouldBreak = function(_node, _ctx) {
	    show_debug_message("DEBUGGER: ShouldBreak check, line=" + string(struct_exists(_node, "line") ? _node.line : -1));
		
        if (!enabled) return false;
        if (paused) return true;
        
        if (paused) {
            OnBreak(_node, _ctx);
            return true;
        }
        
        switch (step_mode) {
            case "step_into":
                step_mode = "none";
                OnBreak(_node, _ctx);
                return true;
                
            case "step_over":
                if (call_depth <= step_depth) {
                    step_mode = "none";
                    OnBreak(_node, _ctx);
                    return true;
                }
                break;
                
            case "step_out":
                if (call_depth < step_depth) {
                    step_mode = "none";
                    OnBreak(_node, _ctx);
                    return true;
                }
                break;
                
            case "step_line":
                if (struct_exists(_node, "line") && _node.line == step_target_line) {
                    step_mode = "none";
                    OnBreak(_node, _ctx);
                    return true;
                }
                break;
        }
        
        if (struct_exists(_node, "line")) {
            var _file = struct_exists(_node, "file") ? _node.file : current_file;
            var _key = string(_file) + ":" + string(_node.line);
            
            if (ds_map_exists(breakpoints, _key)) {
                var _bp = breakpoints[? _key];
                if (_bp.enabled) {
                    _bp.hit_count++;
                    breakpoints[? _key] = _bp;
                    
                    if (_bp.condition != undefined) {
                        try {
                            var _tokens = gmlvm_tokenize(_bp.condition);
                            var _ast = gmlvm_parse_expression(_tokens, 0);
                            var _result = gmlvm_vm_evaluate(_ast[0], _ctx);
                            if (!_result) return false;
                        } catch (_err) {
                            // condition error - break anyway
                        }
                    }
                    
                    OnBreak(_node, _ctx);
                    return true;
                }
            }
        }
        
        return false;
    };
    
    // node tracking
    static OnNodeEnter = function(_node, _ctx) {
		show_debug_message("DEBUGGER: OnNodeEnter called!");  // Direct output
		
        current_node = _node;
        nodes_executed++;
        
        if (struct_exists(_node, "line")) {
            current_line = _node.line;
            current_column = struct_exists(_node, "column") ? _node.column : -1;
        }
        
        if (struct_exists(_node, "file")) {
            current_file = _node.file;
        }
        
        current_scope = _ctx;
        
        if (on_step != undefined) {
            on_step(_node, current_line, current_file);
        }
        
        if (nodes_executed % 100 == 0) {
            EvaluateAllWatches(_ctx);
        }
    };
    
    static OnCallEnter = function(_func_name) {
        call_depth++;
        current_function = _func_name;
        
        array_push(call_stack, {
            func: _func_name, 
            line: current_line,
            file: current_file,
            depth: call_depth
        });
        
        Trace("-> " + _func_name + "() at depth " + string(call_depth));
    };
    
    static OnCallExit = function() {
        if (array_length(call_stack) > 0) {
            var _frame = array_pop(call_stack);
            Trace("<- " + _frame.func + "() returned");
        }
        call_depth--;
        
        if (array_length(call_stack) > 0) {
            var _prev = call_stack[array_length(call_stack) - 1];
            current_function = _prev.func;
        } 
		else {
            current_function = "";
        }
        
        if (step_mode == "step_out" && call_depth <= step_depth) {
            step_mode = "none";
            paused = true;
        }
    };
    
    // break handling
    static OnBreak = function(_node, _ctx) {
        paused = true;
        
        Trace("BREAK at " + current_file + ":" + string(current_line) + 
              " in " + current_function + "()");
        
        EvaluateAllWatches(_ctx);
        
        if (on_break != undefined) {
            on_break(_node, current_line, current_file, call_stack, GetWatches());
        }
        
        // wait for user action (UI integration)
        while (paused && enabled) {
            // simplified
			break; // for now, break and return control
        }
    };
    
    static EvaluateAllWatches = function(_ctx) {
        var _names = ds_map_keys_to_array(watch_expressions);
        for (var _i = 0; _i < array_length(_names); _i++) {
            EvaluateWatch(_names[_i], _ctx);
        }
    };
    
    // error handling
    static OnRuntimeError = function(_error, _node) {
        var _line = struct_exists(_node, "line") ? _node.line : -1;
        var _file = struct_exists(_node, "file") ? _node.file : current_file;
        
        Trace("ERROR at " + _file + ":" + string(_line) + ": " + string(_error));
        
        if (on_error != undefined) {
            on_error(_error, _line, _file, call_stack);
        }
        
        paused = true; // auto break on error
    };
    
    // trace the output
    static Trace = function(_message) {
	    show_debug_message("[GMLVM] " + _message);  // Force direct output
	    if (on_trace != undefined) {
	        on_trace(_message);
	    }
    };
    
    // state queries
    static GetState = function() {
        return {
            enabled: enabled,
            paused: paused,
            current_line: current_line,
            current_column: current_column,
            current_file: current_file,
            current_function: current_function,
            call_depth: call_depth,
            call_stack: call_stack,
            node_type: is_struct(current_node) ? current_node.type : "none",
            nodes_executed: nodes_executed,
            execution_time: execution_time,
            step_mode: step_mode,
            breakpoint_count: ds_map_size(breakpoints),
            watch_count: ds_map_size(watch_expressions)
        };
    };
    
    static GetCallStack = function() {
        return call_stack;
    };
    
    static GetVariables = function(_ctx) {
        if (_ctx == undefined) _ctx = current_scope;
        if (_ctx == undefined) return {};
        
        var _vars = {};
        
        var _local_names = struct_get_names(_ctx.locals);
        for (var _i = 0; _i < array_length(_local_names); _i++) {
            var _n = _local_names[_i];
            _vars["local:" + _n] = _ctx.locals[$ _n];
        }
        
        var _self = _ctx.GetSelf();
        if (is_struct(_self)) {
            var _self_names = struct_get_names(_self);
            for (var _i = 0; _i < array_length(_self_names); _i++) {
                var _n = _self_names[_i];
                _vars["self:" + _n] = _self[$ _n];
            }
        } else if (instance_exists(_self)) {
            _vars[$ "self:id"] = _self;
            _vars[$ "self:x"] = _self.x;
            _vars[$ "self:y"] = _self.y;
        }
        
        return _vars;
    };
    
    // UI (might make an optional integration with GMUI later on)
    static ShowUI = function(_x, _y, _w, _h) {
        ui_x = _x;
        ui_y = _y;
        ui_width = _w;
        ui_height = _h;
        ui_visible = true;
    };
    
    static HideUI = function() {
        ui_visible = false;
    };
    
    // timing
    static StartTimer = function() {
        start_time = current_time;
    };
    
    static StopTimer = function() {
        execution_time = current_time - start_time;
        return execution_time;
    };
    
    static Reset = function() {
        nodes_executed = 0;
        call_depth = 0;
        call_stack = [];
        start_time = current_time;
    };
    
    // cleanup
    static Destroy = function() {
        ds_map_destroy(breakpoints);
        ds_map_destroy(watch_expressions);
    };
}