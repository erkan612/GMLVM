function gmlvm_debugger() constructor {
    enabled = false;
    breakpoints = ds_map_create();
    current_node = undefined;
    current_line = -1;
    step_mode = "none";  // "none", "step_over", "step_into", "step_out"
    call_depth = 0;
    
    static Enable = function() {
        enabled = true;
    };
    
    static Disable = function() {
        enabled = false;
    };
    
    static SetBreakpoint = function(_line) {
        breakpoints[? string(_line)] = true;
    };
    
    static RemoveBreakpoint = function(_line) {
        ds_map_delete(breakpoints, string(_line));
    };
    
    static ClearBreakpoints = function() {
        ds_map_clear(breakpoints);
    };
    
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
    
    static ShouldBreak = function(_node) {
        if (!enabled) return false;
        
        // check breakpoints
        if (struct_exists(_node, "line")) {
            if (ds_map_exists(breakpoints, string(_node.line))) {
                return true;
            }
        }
        
        // check step mode
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
    
    static GetState = function() {
        return {
            current_line: current_line,
            call_depth: call_depth,
            node_type: is_struct(current_node) ? current_node.type : "none"
        };
    };
    
    static Destroy = function() {
        ds_map_destroy(breakpoints);
    };
}