// gml_interpreter.gml
// GML Interpreter that runs in the same namespace
// Version 1.0

// Loop control state
global.gmlp_break_requested = false;
global.gmlp_continue_requested = false;

// Loop control using exceptions
global.gmlp_loop_control = undefined;

/// @function gmlp_run(script_string)
/// @description Executes a string of GML code in the current namespace
/// @param {string} script_string The GML code to execute
function gmlp_run(script_string) {
    show_debug_message("=== gmlp_run ===");
    show_debug_message("Script: " + script_string);
    gmlp_execute_script(script_string);
}

/// @function gmlp_execute_line(line)
/// @description Executes a single line of GML code
/// @param {string} line The line to execute
function gmlp_execute_line(line) {
    // Check for compound assignments (+=, -=, *=, /=)
    var compounds = ["+=", "-=", "*=", "/="];
    var op_assign_pos = -1;
    var op_type = "";
    
    for (var i = 0; i < array_length(compounds); i++) {
        var pos = gmlp_find_operator_outside_strings(line, compounds[i]);
        if (pos > 0) {
            op_assign_pos = pos;
            op_type = string_copy(compounds[i], 1, 1);
            break;
        }
    }
    
    if (op_assign_pos > 0) {
        // Compound assignment: var += value
        var var_name = string_trim(string_copy(line, 1, op_assign_pos - 1));
        var value_expr = string_trim(string_copy(line, op_assign_pos + 2, string_length(line) - (op_assign_pos + 1)));
        var value = gmlp_eval_expression(value_expr);
        
        var current = gmlp_get_variable(var_name);
        var new_value;
        switch (op_type) {
            case "+": new_value = current + value; break;
            case "-": new_value = current - value; break;
            case "*": new_value = current * value; break;
            case "/": new_value = current / value; break;
        }
        gmlp_set_variable(var_name, new_value);
        return;
    }
    
    // Check for simple assignment (var = value)
    var assign_pos = gmlp_find_operator_outside_strings(line, "=");
    if (assign_pos > 0) {
        var var_name = string_trim(string_copy(line, 1, assign_pos - 1));
        var value_expr = string_trim(string_copy(line, assign_pos + 1, string_length(line) - assign_pos));
        var value = gmlp_eval_expression(value_expr);
        gmlp_set_variable(var_name, value);
        return;
    }
    
    // Standalone expression
    gmlp_eval_expression(line);
}

/// @function gmlp_eval_expression(expr)
/// @description Evaluates an expression and returns its value
/// @param {string} expr The expression to evaluate
/// @returns {any} The evaluated value
function gmlp_eval_expression(expr) {
    expr = string_trim(expr);
    if (expr == "") return undefined;
    
    // Parse and evaluate with precedence
    var tokens = gmlp_tokenize(expr);
    var result = gmlp_parse_expression(tokens, 0);
    return result[0];
}

/// @function gmlp_parse_block(tokens, start_index)
/// @description Extracts tokens for a code block between { }
/// @param {array} tokens Array of all tokens
/// @param {real} start_index Index of the opening brace
/// @returns {array} [block_tokens, tokens_consumed]
function gmlp_parse_block(tokens, start_index) {
    if (start_index >= array_length(tokens)) {
        return [[], 0];
    }
    
    var token = tokens[start_index];
    if (token.type != "brace" || token.value != "{") {
        return [[], 0];
    }
    
    var block_tokens = [];
    var brace_count = 1;
    var i = start_index + 1;
    var consumed = 1;
    
    while (i < array_length(tokens) && brace_count > 0) {
        var t = tokens[i];
        
        if (t.type == "brace") {
            if (t.value == "{") brace_count++;
            else if (t.value == "}") {
                brace_count--;
                if (brace_count == 0) {
                    consumed++;
                    break;
                }
            }
        }
        
        array_push(block_tokens, t);
        consumed++;
        i++;
    }
    
    return [block_tokens, consumed];
}

/// @function gmlp_execute_block(block_tokens)
/// @description Executes a block of tokens as statements
/// @param {array} block_tokens Tokens representing the block body
/// @returns {any} The last evaluated value (or undefined)
function gmlp_execute_block(block_tokens) {
    show_debug_message("=== execute_block ===");
    show_debug_message("Block tokens: " + string(array_length(block_tokens)));
    var statements = gmlp_split_statements(block_tokens);
    show_debug_message("Statements to execute: " + string(array_length(statements)));
    var last_value = undefined;
    var i = 0;
    
    while (i < array_length(statements)) {
        var stmt_tokens = statements[i];
        if (array_length(stmt_tokens) == 0) {
            i++;
            continue;
        }
        
        // Check for if statement
        if (array_length(stmt_tokens) > 0 && stmt_tokens[0].type == "keyword" && stmt_tokens[0].value == "if") {
            var result = gmlp_execute_if(stmt_tokens, statements, i);
            last_value = result[0];
            i = result[1]; // Skip to after the if block
			
			// Propagate break/continue
			if (global.gmlp_loop_control != undefined) {
			    return last_value;
			}
            continue;
        }
		
		// Check for while statement
		if (array_length(stmt_tokens) > 0 && stmt_tokens[0].type == "keyword" && stmt_tokens[0].value == "while") {
		    var result = gmlp_execute_while(stmt_tokens, statements, i);
		    last_value = result[0];
		    i = result[1];
			
			// Propagate break/continue
			if (global.gmlp_loop_control != undefined) {
			    return last_value;
			}
		    continue;
		}
		
		// Check for for statement
		if (array_length(stmt_tokens) > 0 && stmt_tokens[0].type == "keyword" && stmt_tokens[0].value == "for") {
		    var result = gmlp_execute_for(stmt_tokens, statements, i);
		    last_value = result[0];
		    i = result[1];
			
			// Propagate break/continue
			if (global.gmlp_loop_control != undefined) {
			    return last_value;
			}
		    continue;
		}
		
		// Check for repeat statement
		if (array_length(stmt_tokens) > 0 && stmt_tokens[0].type == "keyword" && stmt_tokens[0].value == "repeat") {
		    var result = gmlp_execute_repeat(stmt_tokens, statements, i);
		    last_value = result[0];
		    i = result[1];
			
			// Propagate break/continue
			if (global.gmlp_loop_control != undefined) {
			    return last_value;
			}
		    continue;
		}
		
		// Check for switch statement
		if (array_length(stmt_tokens) > 0 && stmt_tokens[0].type == "keyword" && stmt_tokens[0].value == "switch") {
		    var result = gmlp_execute_switch(stmt_tokens, statements, i);
		    last_value = result[0];
		    i = result[1];
			
			// Propagate break/continue
			if (global.gmlp_loop_control != undefined) {
			    return last_value;
			}
		    continue;
		}
        
        // Execute normal statement
		show_debug_message("Executing normal statement with " + string(array_length(stmt_tokens)) + " tokens");
        last_value = gmlp_execute_statement(stmt_tokens);
		show_debug_message("Statement executed, result: " + string(last_value));
		
		// Propagate break/continue
		if (global.gmlp_loop_control != undefined) {
		    return last_value;
		}
		
        i++;
    }
    
    return last_value;
}

/// @function gmlp_execute_repeat(repeat_tokens, all_statements, current_index)
/// @description Executes a repeat loop
/// @param {array} repeat_tokens Tokens for the repeat statement
/// @param {array} all_statements All statements in the current block
/// @param {real} current_index Current statement index
/// @returns {array} [last_value, next_index]
function gmlp_execute_repeat(repeat_tokens, all_statements, current_index) {
    var index = 1; // Skip 'repeat'
    var last_value = undefined;
    
    // Expect opening parenthesis
    if (index >= array_length(repeat_tokens) || repeat_tokens[index].type != "paren" || repeat_tokens[index].value != "(") {
        show_debug_message("Syntax error: Expected '(' after 'repeat'");
        return [undefined, current_index + 1];
    }
    index++;
    
    // Extract count expression until matching ')'
    var paren_count = 1;
    var count_tokens = [];
    
    while (index < array_length(repeat_tokens) && paren_count > 0) {
        var token = repeat_tokens[index];
        if (token.type == "paren") {
            if (token.value == "(") paren_count++;
            else if (token.value == ")") {
                paren_count--;
                if (paren_count == 0) break;
            }
        }
        array_push(count_tokens, token);
        index++;
    }
    
    // Evaluate the count
    var count_result = gmlp_parse_expression(count_tokens, 0);
    var count = count_result[0];
    
    // Move past the closing parenthesis
    index++;
    
    // Check for opening brace or single statement
    var block_tokens = [];
    var next_stmt_index = current_index;
    var is_single_statement = false;
    
    if (index < array_length(repeat_tokens) && repeat_tokens[index].type == "brace" && repeat_tokens[index].value == "{") {
        var block_result = gmlp_parse_block(repeat_tokens, index);
        block_tokens = block_result[0];
        next_stmt_index = current_index + 1;
    } else {
        var remaining_tokens = [];
        for (var j = index; j < array_length(repeat_tokens); j++) {
            array_push(remaining_tokens, repeat_tokens[j]);
        }
        
        if (array_length(remaining_tokens) > 0) {
            block_tokens = remaining_tokens;
            is_single_statement = true;
            next_stmt_index = current_index + 1;
        } else if (current_index + 1 < array_length(all_statements)) {
            var next_stmt = all_statements[current_index + 1];
            if (array_length(next_stmt) == 1 && next_stmt[0].type == "block") {
                block_tokens = next_stmt[0].tokens;
                next_stmt_index = current_index + 2;
            } else {
                block_tokens = next_stmt;
                is_single_statement = true;
                next_stmt_index = current_index + 2;
            }
        }
    }
    
    // Execute the repeat loop
    for (var i = 0; i < count; i++) {
        if (is_single_statement) {
            last_value = gmlp_execute_statement(block_tokens);
        } else {
            last_value = gmlp_execute_block(block_tokens);
        }
		
		// Check for break/continue
		if (global.gmlp_break_requested) {
		    global.gmlp_break_requested = false;
		    break;
		}
		if (global.gmlp_continue_requested) {
		    global.gmlp_continue_requested = false;
		    continue;
		}
    }
    
    return [last_value, next_stmt_index];
}

/// @function gmlp_execute_switch(switch_tokens, all_statements, current_index)
/// @description Executes a switch statement
/// @param {array} switch_tokens Tokens for the switch statement
/// @param {array} all_statements All statements in the current block
/// @param {real} current_index Current statement index
/// @returns {array} [last_value, next_index]
function gmlp_execute_switch(switch_tokens, all_statements, current_index) {
    var index = 1; // Skip 'switch'
    var last_value = undefined;
    
    // Expect opening parenthesis
    if (index >= array_length(switch_tokens) || switch_tokens[index].type != "paren" || switch_tokens[index].value != "(") {
        show_debug_message("Syntax error: Expected '(' after 'switch'");
        return [undefined, current_index + 1];
    }
    index++;
    
    // Extract switch expression
    var paren_count = 1;
    var expr_tokens = [];
    
    while (index < array_length(switch_tokens) && paren_count > 0) {
        var token = switch_tokens[index];
        if (token.type == "paren") {
            if (token.value == "(") paren_count++;
            else if (token.value == ")") {
                paren_count--;
                if (paren_count == 0) break;
            }
        }
        array_push(expr_tokens, token);
        index++;
    }
    
    // Evaluate switch value
    var expr_result = gmlp_parse_expression(expr_tokens, 0);
    var switch_value = expr_result[0];
    
    // Move past closing parenthesis
    index++;
    
    // Get the switch body block
    var block_tokens = [];
    var next_stmt_index = current_index;
    
    if (current_index + 1 < array_length(all_statements)) {
        var next_stmt = all_statements[current_index + 1];
        if (array_length(next_stmt) == 1 && next_stmt[0].type == "block") {
            block_tokens = next_stmt[0].tokens;
            next_stmt_index = current_index + 2;
        }
    }
    
    if (array_length(block_tokens) == 0) {
        return [undefined, current_index + 1];
    }
    
    // Process the block tokens directly without splitting into statements
    var i = 0;
    var matched = false;
    var executing = false;
    
    while (i < array_length(block_tokens)) {
        var token = block_tokens[i];
        
        // Check for case or default labels
        if (token.type == "keyword") {
            if (token.value == "case") {
                // Parse the case value
                i++;
                var case_tokens = [];
                while (i < array_length(block_tokens) && !(block_tokens[i].type == "separator" && block_tokens[i].value == ":")) {
                    array_push(case_tokens, block_tokens[i]);
                    i++;
                }
                // Skip the colon
                i++;
                
                if (!matched) {
                    var case_result = gmlp_parse_expression(case_tokens, 0);
                    if (case_result[0] == switch_value) {
                        matched = true;
                        executing = true;
                    }
                }
                continue;
            }
            else if (token.value == "default") {
                // Skip the colon
                i += 2;
                if (!matched) {
                    matched = true;
                    executing = true;
                }
                continue;
            }
            else if (token.value == "break") {
                if (executing) {
                    executing = false;
                }
                // Skip the semicolon
                i += 2;
                continue;
            }
        }
        
        // If we're executing, collect the statement tokens
        if (executing) {
            var stmt_tokens = [];
            while (i < array_length(block_tokens) && !(block_tokens[i].type == "separator" && block_tokens[i].value == ";")) {
                array_push(stmt_tokens, block_tokens[i]);
                i++;
            }
            // Skip the semicolon
            i++;
            
            if (array_length(stmt_tokens) > 0) {
                last_value = gmlp_execute_statement(stmt_tokens);
            }
        } else {
            // Skip until semicolon
            while (i < array_length(block_tokens) && !(block_tokens[i].type == "separator" && block_tokens[i].value == ";")) {
                i++;
            }
            i++; // Skip semicolon
        }
    }
    
    return [last_value, next_stmt_index];
}

/// @function gmlp_execute_for(for_tokens, all_statements, current_index)
/// @description Executes a for loop
/// @param {array} for_tokens Tokens for the for statement
/// @param {array} all_statements All statements in the current block
/// @param {real} current_index Current statement index
/// @returns {array} [last_value, next_index]
function gmlp_execute_for(for_tokens, all_statements, current_index) {
    var index = 1; // Skip 'for'
    var last_value = undefined;
    
    // Expect opening parenthesis
    if (index >= array_length(for_tokens) || for_tokens[index].type != "paren" || for_tokens[index].value != "(") {
        show_debug_message("Syntax error: Expected '(' after 'for'");
        return [undefined, current_index + 1];
    }
    index++;
    
    // Parse initialization
	var init_tokens = [];
	while (index < array_length(for_tokens) && for_tokens[index].type != "separator") {
	    array_push(init_tokens, for_tokens[index]);
	    index++;
	}
	if (index < array_length(for_tokens) && for_tokens[index].type == "separator") {
	    index++; // Skip semicolon
	}

	// Parse condition
	var condition_tokens = [];
	while (index < array_length(for_tokens) && for_tokens[index].type != "separator") {
	    array_push(condition_tokens, for_tokens[index]);
	    index++;
	}
	if (index < array_length(for_tokens) && for_tokens[index].type == "separator") {
	    index++; // Skip semicolon
	}

	// Parse increment
	var increment_tokens = [];
	while (index < array_length(for_tokens) && for_tokens[index].type != "paren") {
	    array_push(increment_tokens, for_tokens[index]);
	    index++;
	}
	// Consume the closing parenthesis
	if (index < array_length(for_tokens) && for_tokens[index].type == "paren" && for_tokens[index].value == ")") {
	    index++;
	}
    
    // Check for opening brace or single statement
    var block_tokens = [];
    var next_stmt_index = current_index;
    var is_single_statement = false;
    
    if (index < array_length(for_tokens) && for_tokens[index].type == "brace" && for_tokens[index].value == "{") {
        var block_result = gmlp_parse_block(for_tokens, index);
        block_tokens = block_result[0];
        next_stmt_index = current_index + 1;
    } else {
        var remaining_tokens = [];
        for (var j = index; j < array_length(for_tokens); j++) {
            array_push(remaining_tokens, for_tokens[j]);
        }
        
        if (array_length(remaining_tokens) > 0) {
            block_tokens = remaining_tokens;
            is_single_statement = true;
            next_stmt_index = current_index + 1;
        } else if (current_index + 1 < array_length(all_statements)) {
            var next_stmt = all_statements[current_index + 1];
            if (array_length(next_stmt) == 1 && next_stmt[0].type == "block") {
                block_tokens = next_stmt[0].tokens;
                next_stmt_index = current_index + 2;
            } else {
                block_tokens = next_stmt;
                is_single_statement = true;
                next_stmt_index = current_index + 2;
            }
        }
    }
    
    // Execute initialization once
    if (array_length(init_tokens) > 0) {
        gmlp_execute_statement(init_tokens);
    }
    
    // Execute the for loop
    var max_iterations = 10000; // needs a global
    var iterations = 0;
    
	while (iterations < max_iterations) {
	    // Reset loop control
	    global.gmlp_loop_control = undefined;
    
	    // Evaluate condition
	    var condition = true;
	    if (array_length(condition_tokens) > 0) {
	        var condition_result = gmlp_parse_expression(condition_tokens, 0);
	        condition = condition_result[0];
	    }
    
	    if (!condition) break;
    
	    // Execute body
	    if (is_single_statement) {
	        last_value = gmlp_execute_statement(block_tokens);
	    } else {
	        last_value = gmlp_execute_block(block_tokens);
	    }
    
	    // Check loop control before increment
	    if (global.gmlp_loop_control == "break") {
	        global.gmlp_loop_control = undefined;
	        break;
	    }
    
	    // Execute increment
	    if (array_length(increment_tokens) > 0) {
	        gmlp_execute_statement(increment_tokens);
	    }
    
	    if (global.gmlp_loop_control == "continue") {
	        global.gmlp_loop_control = undefined;
	        continue;
	    }
    
	    iterations++;
	}
    
    if (iterations >= max_iterations) {
        show_debug_message("Warning: For loop exceeded maximum iterations");
    }
    
    return [last_value, next_stmt_index];
}

/// @function gmlp_execute_if(if_tokens, all_statements, current_index)
/// @description Executes an if statement with optional else
/// @param {array} if_tokens Tokens for the if statement
/// @param {array} all_statements All statements in the current block
/// @param {real} current_index Current statement index
/// @returns {array} [last_value, next_index]
function gmlp_execute_if(if_tokens, all_statements, current_index) {
    // if_tokens format: [keyword:if, paren:(, ...condition..., paren:), brace:{]
    // or with else: followed by keyword:else and brace:{
    
    var index = 1; // Skip 'if'
    var last_value = undefined;
    
    // Expect opening parenthesis
    if (index >= array_length(if_tokens) || if_tokens[index].type != "paren" || if_tokens[index].value != "(") {
        show_debug_message("Syntax error: Expected '(' after 'if'");
        return [undefined, current_index + 1];
    }
    
    // Extract condition tokens until matching ')'
    var paren_count = 1;
    index++;
    var condition_start = index;
    var condition_tokens = [];
    
    while (index < array_length(if_tokens) && paren_count > 0) {
        var token = if_tokens[index];
        if (token.type == "paren") {
            if (token.value == "(") paren_count++;
            else if (token.value == ")") {
                paren_count--;
                if (paren_count == 0) break;
            }
        }
        array_push(condition_tokens, token);
        index++;
    }
    
    // Evaluate condition
    var condition_result = gmlp_parse_expression(condition_tokens, 0);
    var condition = condition_result[0];
    
    // Move past the closing parenthesis
    index++;
    
    // Check for opening brace (might be in this statement or next)
    var block_tokens = [];
	var next_stmt_index = current_index;
	var is_single_statement = false;

	if (index < array_length(if_tokens) && if_tokens[index].type == "brace" && if_tokens[index].value == "{") {
	    // Brace is in the same statement
	    var block_result = gmlp_parse_block(if_tokens, index);
	    block_tokens = block_result[0];
	    next_stmt_index = current_index + 1;
	} else {
	    // Check if there are remaining tokens in this statement (single statement without braces)
	    var remaining_tokens = [];
	    for (var j = index; j < array_length(if_tokens); j++) {
	        array_push(remaining_tokens, if_tokens[j]);
	    }
    
	    if (array_length(remaining_tokens) > 0) {
	        // Single statement in the same line
	        block_tokens = remaining_tokens;
	        is_single_statement = true;
	        next_stmt_index = current_index + 1;
	    } else if (current_index + 1 < array_length(all_statements)) {
	        // Next statement is the body
	        var next_stmt = all_statements[current_index + 1];
	        if (array_length(next_stmt) == 1 && next_stmt[0].type == "block") {
	            block_tokens = next_stmt[0].tokens;
	            next_stmt_index = current_index + 2;
	        } else {
	            // Single statement as next statement
	            block_tokens = next_stmt;
	            is_single_statement = true;
	            next_stmt_index = current_index + 2;
	        }
	    }
	}
    
    // Execute the if block if condition is true
    if (condition) {
        last_value = gmlp_execute_block(block_tokens);
        
        // Check for else
        var else_index = next_stmt_index;
        if (else_index < array_length(all_statements)) {
            var else_stmt = all_statements[else_index];
            if (array_length(else_stmt) > 0 && else_stmt[0].type == "keyword" && else_stmt[0].value == "else") {
                // Skip the else block
                if (else_index + 1 < array_length(all_statements)) {
                    next_stmt_index = else_index + 2; // Skip else and its block
                } else {
                    next_stmt_index = else_index + 1;
                }
            }
        }
    } else {
        // Condition false, skip if block and check for else
        var else_index = next_stmt_index;
        
        if (else_index < array_length(all_statements)) {
            var else_stmt = all_statements[else_index];
            if (array_length(else_stmt) > 0 && else_stmt[0].type == "keyword" && else_stmt[0].value == "else") {
                // Execute else block
                var else_block_tokens = [];
                
                // Check if else is followed by brace in same statement or next
                if (array_length(else_stmt) > 1 && else_stmt[1].type == "brace" && else_stmt[1].value == "{") {
                    var block_result = gmlp_parse_block(else_stmt, 1);
                    else_block_tokens = block_result[0];
                    next_stmt_index = else_index + 1;
                } else if (else_index + 1 < array_length(all_statements)) {
                    var next_stmt = all_statements[else_index + 1];
                    if (array_length(next_stmt) == 1 && next_stmt[0].type == "block") {
                        else_block_tokens = next_stmt[0].tokens;
                        next_stmt_index = else_index + 2;
                    }
                }
                
                if (array_length(else_block_tokens) > 0) {
                    last_value = gmlp_execute_block(else_block_tokens);
                }
            } else {
                next_stmt_index = else_index;
            }
        }
    }
    
    return [last_value, next_stmt_index];
}

/// @function gmlp_split_statements(tokens)
/// @description Splits tokens into separate statements by semicolons or braces
/// @param {array} tokens Array of tokens
/// @returns {array} Array of statement token arrays
function gmlp_split_statements(tokens) {
    show_debug_message("=== split_statements ===");
    show_debug_message("Input tokens: " + string(array_length(tokens)));
	
    var statements = [];
    var current = [];
    var i = 0;
    var paren_depth = 0; // Track parentheses depth
    
    while (i < array_length(tokens)) {
        var token = tokens[i];
        
        // Track parentheses depth
        if (token.type == "paren") {
            if (token.value == "(") paren_depth++;
            else if (token.value == ")") paren_depth--;
        }
        
        // Handle blocks as single statements
        //if (token.type == "brace" && token.value == "{") {
        //    if (array_length(current) > 0) {
        //        array_push(statements, current);
        //        current = [];
        //    }
        //    
        //    var block_result = gmlp_parse_block(tokens, i);
        //    var block_tokens = block_result[0];
        //    var consumed = block_result[1];
        //    
        //    array_push(statements, [{ type: "block", tokens: block_tokens }]);
        //    i += consumed;
        //    continue;
        //}
		// Handle blocks as single statements (but not struct literals)
		if (token.type == "brace" && token.value == "{") {
		    // Check if this is a struct literal (after =, (, [, or at start of expression)
		    var is_struct_literal = false;
    
		    // Look backwards to see if we're in an expression context
		    if (array_length(current) > 0) {
		        var last_token = current[array_length(current) - 1];
		        if (last_token.type == "operator" && last_token.value == "=") {
		            is_struct_literal = true;
		        } else if (last_token.type == "paren" && last_token.value == "(") {
		            is_struct_literal = true;
		        } else if (last_token.type == "bracket" && last_token.value == "[") {
		            is_struct_literal = true;
		        } else if (last_token.type == "comma") {
		            is_struct_literal = true;
		        } else if (last_token.type == "separator" && last_token.value == ":") {
		            is_struct_literal = true;
		        }
		    } else {
		        // At start of statement, could be struct literal
		        is_struct_literal = true;
		    }
    
		    if (is_struct_literal) {
		        // Treat as struct literal, not a block - just add to current
		        array_push(current, token);
		        i++;
		        continue;
		    }
    
		    // It's a code block
		    if (array_length(current) > 0) {
		        array_push(statements, current);
		        current = [];
		    }
    
		    var block_result = gmlp_parse_block(tokens, i);
		    var block_tokens = block_result[0];
		    var consumed = block_result[1];
    
		    array_push(statements, [{ type: "block", tokens: block_tokens }]);
		    i += consumed;
		    continue;
		}
        
        // Statement separator - ONLY if we're not inside parentheses
        if (token.type == "separator" && token.value == ";" && paren_depth == 0) {
            if (array_length(current) > 0) {
                array_push(statements, current);
                current = [];
            }
            i++;
            continue;
        }
        
        array_push(current, token);
        i++;
    }
    
    if (array_length(current) > 0) {
        array_push(statements, current);
    }
    
    show_debug_message("Statements created: " + string(array_length(statements)));
    for (var s = 0; s < array_length(statements); s++) {
        show_debug_message("  Statement " + string(s) + ": " + string(array_length(statements[s])) + " tokens");
    }
    
    return statements;
}

/// @function gmlp_execute_statement(stmt_tokens)
/// @description Executes a single statement from tokens
/// @param {array} stmt_tokens Tokens for the statement
/// @returns {any} The result of the statement
function gmlp_execute_statement(stmt_tokens) {
    if (array_length(stmt_tokens) == 0) return undefined;
    
	// Handle break and continue statements
	if (array_length(stmt_tokens) == 1 && stmt_tokens[0].type == "keyword") {
	    if (stmt_tokens[0].value == "break") {
	        global.gmlp_loop_control = "break";
	        return undefined;
	    }
	    if (stmt_tokens[0].value == "continue") {
	        global.gmlp_loop_control = "continue";
	        return undefined;
	    }
	}
	
    // Handle block statements
    if (array_length(stmt_tokens) == 1 && stmt_tokens[0].type == "block") {
        return gmlp_execute_block(stmt_tokens[0].tokens);
    }
    
    // First, check if this is just a standalone postfix: identifier ++ or --
    if (array_length(stmt_tokens) == 2 && 
        stmt_tokens[0].type == "identifier" && 
        stmt_tokens[1].type == "operator" && 
        (stmt_tokens[1].value == "++" || stmt_tokens[1].value == "--")) {
        
        var var_name = stmt_tokens[0].name;
        var op = stmt_tokens[1].value;
        var current = gmlp_get_variable(var_name);
        var new_value = (op == "++") ? current + 1 : current - 1;
        gmlp_set_variable(var_name, new_value);
        return current;
    }
    
    // Check if this is just a standalone prefix: ++ or -- identifier
    if (array_length(stmt_tokens) == 2 && 
        stmt_tokens[0].type == "operator" && 
        (stmt_tokens[0].value == "++" || stmt_tokens[0].value == "--") &&
        stmt_tokens[1].type == "identifier") {
        
        var op = stmt_tokens[0].value;
        var var_name = stmt_tokens[1].name;
        var current = gmlp_get_variable(var_name);
        var new_value = (op == "++") ? current + 1 : current - 1;
        gmlp_set_variable(var_name, new_value);
        return new_value;
    }
    
    // Look for compound assignments (+=, -=, *=, /=)
    for (var i = 0; i < array_length(stmt_tokens) - 1; i++) {
        if (stmt_tokens[i].type == "operator" && 
            (stmt_tokens[i].value == "+" || stmt_tokens[i].value == "-" || 
             stmt_tokens[i].value == "*" || stmt_tokens[i].value == "/") &&
            stmt_tokens[i + 1].type == "operator" && 
            stmt_tokens[i + 1].value == "=") {
            
            var var_tokens = [];
            for (var j = 0; j < i; j++) {
                array_push(var_tokens, stmt_tokens[j]);
            }
            var var_name = gmlp_tokens_to_string_simple(var_tokens);
            
            var value_tokens = [];
            for (var j = i + 2; j < array_length(stmt_tokens); j++) {
                array_push(value_tokens, stmt_tokens[j]);
            }
            
            var value = gmlp_parse_expression(value_tokens, 0)[0];
            var current = gmlp_get_variable(var_name);
            var op = stmt_tokens[i].value;
            var new_value;
            
            switch (op) {
                case "+": new_value = current + value; break;
                case "-": new_value = current - value; break;
                case "*": new_value = current * value; break;
                case "/": new_value = current / value; break;
            }
            gmlp_set_variable(var_name, new_value);
            return new_value;
        }
    }
    
	// Check for struct property assignment: identifier . property = value
	var dot_pos = -1;
	for (var i = 0; i < array_length(stmt_tokens); i++) {
	    if (stmt_tokens[i].type == "dot") {
	        dot_pos = i;
	        break;
	    }
	}

	if (dot_pos > 0 && dot_pos + 1 < array_length(stmt_tokens)) {
	    if (stmt_tokens[dot_pos + 1].type == "identifier") {
	        // Look for = after the property name
	        var assign_pos = -1;
	        for (var i = dot_pos + 2; i < array_length(stmt_tokens); i++) {
	            if (stmt_tokens[i].type == "operator" && stmt_tokens[i].value == "=") {
	                assign_pos = i;
	                break;
	            }
	        }
        
	        if (assign_pos > 0) {
	            var struct_tokens = [];
	            for (var i = 0; i < dot_pos; i++) {
	                array_push(struct_tokens, stmt_tokens[i]);
	            }
	            var struct_name = gmlp_tokens_to_string_simple(struct_tokens);
	            var struct_value = gmlp_get_variable(struct_name);
	            var prop_name = stmt_tokens[dot_pos + 1].name;
            
	            var value_tokens = [];
	            for (var i = assign_pos + 1; i < array_length(stmt_tokens); i++) {
	                array_push(value_tokens, stmt_tokens[i]);
	            }
            
	            var value = gmlp_parse_expression(value_tokens, 0)[0];
            
	            if (is_struct(struct_value)) {
	                struct_value[$ prop_name] = value;
	            } else {
	                // Create a struct if it doesn't exist
	                struct_value = {};
	                struct_value[$ prop_name] = value;
	                gmlp_set_variable(struct_name, struct_value);
	            }
            
	            return value;
	        }
	    }
	}
	
	// Check for struct dollar accessor assignment: identifier [ $ expr ] = value
	var dollar_assign_pos = -1;
	for (var i = 0; i < array_length(stmt_tokens); i++) {
	    if (stmt_tokens[i].type == "bracket" && stmt_tokens[i].value == "[") {
	        // Check if next token is dollar
	        if (i + 1 < array_length(stmt_tokens) && stmt_tokens[i + 1].type == "dollar") {
	            dollar_assign_pos = i;
	            break;
	        }
	    }
	}

	if (dollar_assign_pos > 0) {
	    // Find the matching closing bracket
	    var bracket_count = 1;
	    var close_pos = -1;
	    for (var i = dollar_assign_pos + 2; i < array_length(stmt_tokens); i++) {
	        if (stmt_tokens[i].type == "bracket") {
	            if (stmt_tokens[i].value == "[") bracket_count++;
	            else if (stmt_tokens[i].value == "]") {
	                bracket_count--;
	                if (bracket_count == 0) {
	                    close_pos = i;
	                    break;
	                }
	            }
	        }
	    }
    
	    if (close_pos > 0 && close_pos + 1 < array_length(stmt_tokens)) {
	        // Check for assignment operator
	        if (stmt_tokens[close_pos + 1].type == "operator" && stmt_tokens[close_pos + 1].value == "=") {
	            // Get struct name
	            var struct_tokens = [];
	            for (var i = 0; i < dollar_assign_pos; i++) {
	                array_push(struct_tokens, stmt_tokens[i]);
	            }
	            var struct_name = gmlp_tokens_to_string_simple(struct_tokens);
	            var struct_value = gmlp_get_variable(struct_name);
            
	            // Get key from between $ and ]
	            var key = undefined;
	            for (var i = dollar_assign_pos + 2; i < close_pos; i++) {
	                var t = stmt_tokens[i];
	                if (t.type == "string") {
	                    key = t.value;
	                    break;
	                } else if (t.type == "identifier") {
	                    key = gmlp_get_variable(t.name);
	                    break;
	                }
	            }
            
	            // Parse value tokens
	            var value_tokens = [];
	            for (var i = close_pos + 2; i < array_length(stmt_tokens); i++) {
	                array_push(value_tokens, stmt_tokens[i]);
	            }
	            var value = gmlp_parse_expression(value_tokens, 0)[0];
            
	            // Set struct property
	            if (!is_struct(struct_value)) {
	                struct_value = {};
	                gmlp_set_variable(struct_name, struct_value);
	            }
	            struct_value[$ key] = value;
            
	            return value;
	        }
	    }
	}
	
	// Check for array assignment: identifier [ index ] = value
	var bracket_pos = -1;
	for (var i = 0; i < array_length(stmt_tokens); i++) {
	    if (stmt_tokens[i].type == "bracket" && stmt_tokens[i].value == "[") {
	        // Skip if this is a dollar accessor
	        if (i + 1 < array_length(stmt_tokens) && stmt_tokens[i + 1].type == "dollar") {
	            continue;
	        }
	        bracket_pos = i;
	        break;
	    }
	}

	if (bracket_pos > 0) {
	    // Find the matching closing bracket
	    var bracket_count = 1;
	    var close_pos = -1;
	    for (var i = bracket_pos + 1; i < array_length(stmt_tokens); i++) {
	        if (stmt_tokens[i].type == "bracket") {
	            if (stmt_tokens[i].value == "[") bracket_count++;
	            else if (stmt_tokens[i].value == "]") {
	                bracket_count--;
	                if (bracket_count == 0) {
	                    close_pos = i;
	                    break;
	                }
	            }
	        }
	    }
    
	    if (close_pos > 0 && close_pos + 1 < array_length(stmt_tokens)) {
	        // Check for assignment operator
	        if (stmt_tokens[close_pos + 1].type == "operator" && stmt_tokens[close_pos + 1].value == "=") {
	            // Array assignment
	            var array_tokens = [];
	            for (var i = 0; i < bracket_pos; i++) {
	                array_push(array_tokens, stmt_tokens[i]);
	            }
	            var array_name = gmlp_tokens_to_string_simple(array_tokens);
	            var array_value = gmlp_get_variable(array_name);
            
	            // Parse index
	            var index_tokens = [];
	            var use_reference = false;
	            var j = bracket_pos + 1;
	            if (j < close_pos && stmt_tokens[j].type == "operator" && stmt_tokens[j].value == "@") {
	                use_reference = true;
	                j++;
	            }
	            for (var i = j; i < close_pos; i++) {
	                array_push(index_tokens, stmt_tokens[i]);
	            }
            
	            // Parse value
	            var value_tokens = [];
	            for (var i = close_pos + 2; i < array_length(stmt_tokens); i++) {
	                array_push(value_tokens, stmt_tokens[i]);
	            }
            
	            var index_result = gmlp_parse_expression(index_tokens, 0);
	            var index_value = index_result[0];
	            var value_result = gmlp_parse_expression(value_tokens, 0);
	            var assign_value = value_result[0];
            
	            // Set array element
	            if (is_array(array_value)) {
	                if (use_reference) {
	                    array_value[@ index_value] = assign_value;
	                } else {
	                    array_value[index_value] = assign_value;
	                }
	            }
            
	            return assign_value;
	        }
	    }
	}
	
    // Look for simple assignment =
    for (var i = 0; i < array_length(stmt_tokens); i++) {
        if (stmt_tokens[i].type == "operator" && stmt_tokens[i].value == "=") {
			show_debug_message("Found simple assignment at index " + string(i));
            // Make sure it's not part of compound assignment
            if (i > 0 && stmt_tokens[i - 1].type == "operator") {
                var prev_op = stmt_tokens[i - 1].value;
                if (prev_op == "+" || prev_op == "-" || prev_op == "*" || prev_op == "/") {
                    continue;
                }
            }
            var var_tokens = [];
            for (var j = 0; j < i; j++) {
                array_push(var_tokens, stmt_tokens[j]);
            }
            var var_name = gmlp_tokens_to_string_simple(var_tokens);
			
            var value_tokens = [];
            for (var j = i + 1; j < array_length(stmt_tokens); j++) {
                array_push(value_tokens, stmt_tokens[j]);
            }
			
            // Parse the right side as an expression
            var value = gmlp_parse_expression(value_tokens, 0)[0];
			show_debug_message("Parsed value type: " + (is_struct(value) ? "struct" : typeof(value)));
            gmlp_set_variable(var_name, value);
            return value;
        }
    }
    
    // If no assignment, evaluate as expression
    return gmlp_parse_expression(stmt_tokens, 0)[0];
}

/// @function gmlp_tokens_to_string_simple(tokens)
/// @description Converts tokens to a simple string (for variable names)
/// @param {array} tokens Array of tokens
/// @returns {string} The variable name
function gmlp_tokens_to_string_simple(tokens) {
    if (array_length(tokens) == 0) return "";
    if (array_length(tokens) == 1 && tokens[0].type == "identifier") {
        return tokens[0].name;
    }
    // For now, just join all token values
    var str = "";
    for (var i = 0; i < array_length(tokens); i++) {
        var token = tokens[i];
        if (token.type == "identifier") str += token.name;
        else if (token.type == "number") str += string(token.value);
        else if (token.type == "string") str += token.value;
        else if (token.type == "operator") str += token.value;
        else if (token.type == "paren") str += token.value;
    }
    return str;
}

/// @function gmlp_tokens_to_expression_string(tokens)
/// @description Converts tokens back to a string expression
/// @param {array} tokens Array of tokens
/// @returns {string} The expression as a string
function gmlp_tokens_to_expression_string(tokens) {
    var str = "";
    
    for (var i = 0; i < array_length(tokens); i++) {
        var token = tokens[i];
        
        switch (token.type) {
            case "number":
                str += string(token.value);
                break;
            case "string":
                str += "\"" + token.value + "\"";
                break;
            case "identifier":
                str += token.name;
                break;
            case "operator":
                str += " " + token.value + " ";
                break;
            case "paren":
                str += token.value;
                break;
            case "comma":
                str += ", ";
                break;
            case "function_call":
                str += token.name + "(";
                for (var j = 0; j < array_length(token.arguments); j++) {
                    if (j > 0) str += ", ";
                    str += token.arguments[j];
                }
                str += ")";
                break;
        }
    }
    
    return str;
}

/// @function gmlp_execute_while(while_tokens, all_statements, current_index)
/// @description Executes a while loop
/// @param {array} while_tokens Tokens for the while statement
/// @param {array} all_statements All statements in the current block
/// @param {real} current_index Current statement index
/// @returns {array} [last_value, next_index]
function gmlp_execute_while(while_tokens, all_statements, current_index) {
    var index = 1; // Skip 'while'
    var last_value = undefined;
    
    // Expect opening parenthesis
    if (index >= array_length(while_tokens) || while_tokens[index].type != "paren" || while_tokens[index].value != "(") {
        show_debug_message("Syntax error: Expected '(' after 'while'");
        return [undefined, current_index + 1];
    }
    
    // Extract condition tokens until matching ')'
    var paren_count = 1;
    index++;
    var condition_tokens = [];
    
    while (index < array_length(while_tokens) && paren_count > 0) {
        var token = while_tokens[index];
        if (token.type == "paren") {
            if (token.value == "(") paren_count++;
            else if (token.value == ")") {
                paren_count--;
                if (paren_count == 0) break;
            }
        }
        array_push(condition_tokens, token);
        index++;
    }
    
    // Move past the closing parenthesis
    index++;
    
    // Check for opening brace or single statement
    var block_tokens = [];
    var next_stmt_index = current_index;
    var is_single_statement = false;
    
    if (index < array_length(while_tokens) && while_tokens[index].type == "brace" && while_tokens[index].value == "{") {
        var block_result = gmlp_parse_block(while_tokens, index);
        block_tokens = block_result[0];
        next_stmt_index = current_index + 1;
    } else {
        var remaining_tokens = [];
        for (var j = index; j < array_length(while_tokens); j++) {
            array_push(remaining_tokens, while_tokens[j]);
        }
        
        if (array_length(remaining_tokens) > 0) {
            block_tokens = remaining_tokens;
            is_single_statement = true;
            next_stmt_index = current_index + 1;
        } else if (current_index + 1 < array_length(all_statements)) {
            var next_stmt = all_statements[current_index + 1];
            if (array_length(next_stmt) == 1 && next_stmt[0].type == "block") {
                block_tokens = next_stmt[0].tokens;
                next_stmt_index = current_index + 2;
            } else {
                block_tokens = next_stmt;
                is_single_statement = true;
                next_stmt_index = current_index + 2;
            }
        }
    }
    
    // Execute the while loop
    var max_iterations = 10000; // Prevent infinite loops
    var iterations = 0;
    
	while (iterations < max_iterations) {
	    // Reset loop control
	    global.gmlp_loop_control = undefined;
    
	    // Evaluate condition
	    var condition_result = gmlp_parse_expression(condition_tokens, 0);
	    var condition = condition_result[0];
    
	    if (!condition) break;
    
	    // Execute body
	    if (is_single_statement) {
	        last_value = gmlp_execute_statement(block_tokens);
	    } else {
	        last_value = gmlp_execute_block(block_tokens);
	    }
    
	    // Check loop control
	    if (global.gmlp_loop_control == "break") {
	        global.gmlp_loop_control = undefined;
	        break;
	    }
	    if (global.gmlp_loop_control == "continue") {
	        global.gmlp_loop_control = undefined;
	        continue;
	    }
    
	    iterations++;
	}
    
    if (iterations >= max_iterations) {
        show_debug_message("Warning: While loop exceeded maximum iterations");
    }
    
    return [last_value, next_stmt_index];
}

/// @function gmlp_execute_script(script_string)
/// @description Executes a script with block support
/// @param {string} script_string The GML code to execute
/// @returns {any} The result of the script
function gmlp_execute_script(script_string) {
    var tokens = gmlp_tokenize(script_string);
    
    show_debug_message("=== Tokens ===");
    for (var i = 0; i < array_length(tokens); i++) {
        var t = tokens[i];
        var out = string(i) + ": " + t.type;
        if (t.type == "identifier") out += " = " + t.name;
        else if (t.type == "brace") out += " = " + t.value;
        else if (t.type == "operator") out += " = " + t.value;
        else if (t.type == "number") out += " = " + string(t.value);
        else if (t.type == "separator") out += " = " + t.value;
        show_debug_message(out);
    }
    show_debug_message("=== End Tokens ===");
	
	// DEBUG: Show all tokens
	//show_debug_message("=== All Tokens ===");
	//for (var i = 0; i < array_length(tokens); i++) {
	//    var t = tokens[i];
	//    var out = string(i) + ": " + t.type;
	//    if (t.type == "identifier") out += " = " + t.name;
	//    else if (t.type == "bracket") out += " = " + t.value;
	//    else if (t.type == "dollar") out += " = $";
	//    else if (t.type == "string") out += " = " + t.value;
	//    else if (t.type == "operator") out += " = " + t.value;
	//    show_debug_message(out);
	//}
	//show_debug_message("=== End Tokens ===");
	
	// DEBUG: Show all tokens
	//show_debug_message("=== All Tokens for: " + script_string + " ===");
	//for (var i = 0; i < array_length(tokens); i++) {
	//    var t = tokens[i];
	//    var out = string(i) + ": " + t.type;
	//    if (t.type == "identifier") out += " = " + t.name;
	//    else if (t.type == "bracket") out += " = " + t.value;
	//    else if (t.type == "dollar") out += " = $";
	//    else if (t.type == "string") out += " = " + t.value;
	//    else if (t.type == "operator") out += " = " + t.value;
	//    show_debug_message(out);
	//}
	//show_debug_message("=== End Tokens ===");
	
	// DEBUG: Show all tokens
	//show_debug_message("=== All Tokens ===");
	//for (var i = 0; i < array_length(tokens); i++) {
	//    var t = tokens[i];
	//    var out = string(i) + ": " + t.type;
	//    if (t.type == "identifier") out += " = " + t.name;
	//    else if (t.type == "bracket") out += " = " + t.value;
	//    else if (t.type == "number") out += " = " + string(t.value);
	//    else if (t.type == "operator") out += " = " + t.value;
	//    show_debug_message(out);
	//}
	//show_debug_message("=== End Tokens ===");
	
	// DEBUG for for loop
	//if (string_pos("for", script_string) == 1) {
	//    show_debug_message("=== Tokens for for loop ===");
	//    for (var i = 0; i < array_length(tokens); i++) {
	//        var t = tokens[i];
	//        show_debug_message(string(i) + ": " + t.type + " = " + string(t.value));
	//    }
	//}
	
	// DEBUG: Show tokens for the if statement
	//if (string_pos("if (true)", script_string) > 0) {
	//    show_debug_message("=== Tokens for if (true) ===");
	//    for (var i = 0; i < array_length(tokens); i++) {
	//        var t = tokens[i];
	//        if (t.type == "keyword") {
	//            show_debug_message(string(i) + ": keyword = " + t.value);
	//        } else if (t.type == "identifier") {
	//            show_debug_message(string(i) + ": identifier = " + t.name);
	//        } else if (t.type == "operator") {
	//            show_debug_message(string(i) + ": operator = " + t.value);
	//        } else if (t.type == "paren") {
	//            show_debug_message(string(i) + ": paren = " + t.value);
	//        } else {
	//            show_debug_message(string(i) + ": " + t.type + " = " + string(t.value));
	//        }
	//    }
	//}
	
	//show_debug_message("=== Tokens for: " + script_string + " ===");
	//for (var i = 0; i < array_length(tokens); i++) {
	//    var t = tokens[i];
	//    if (t.type == "identifier") {
	//        show_debug_message(string(i) + ": identifier = " + t.name);
	//    } else {
	//        show_debug_message(string(i) + ": " + t.type + " = " + string(t.value));
	//    }
	//}
    
    // Add semicolons at line breaks to help statement separation
    var enhanced_tokens = [];
    for (var i = 0; i < array_length(tokens); i++) {
        array_push(enhanced_tokens, tokens[i]);
    }
    
    return gmlp_execute_block(enhanced_tokens);
}

/// @function gmlp_tokenize(expr)
/// @description Converts expression string into tokens
/// @param {string} expr The expression to tokenize
/// @returns {array} Array of tokens
function gmlp_tokenize(expr) {
    var tokens = [];
    var i = 1;
    
    while (i <= string_length(expr)) {
        var ch = string_char_at(expr, i);
        
        // Skip whitespace
        if (ch == " " || ch == "\t" || ch == "\r" || ch == "\n") {
            i++;
            continue;
        }
		
	    if (ch == "/" && i < string_length(expr) && string_char_at(expr, i + 1) == "/") {
	        // Skip everything until newline
	        i += 2;
	        while (i <= string_length(expr) && string_char_at(expr, i) != "\n") {
	            i++;
	        }
	        continue;
	    }
    
	    if (ch == "/" && i < string_length(expr) && string_char_at(expr, i + 1) == "*") {
	        // Skip everything until */
	        i += 2;
	        while (i < string_length(expr)) {
	            if (string_char_at(expr, i) == "*" && string_char_at(expr, i + 1) == "/") {
	                i += 2;
	                break;
	            }
	            i++;
	        }
	        continue;
	    }

		// Dollar sign for struct accessor
		if (ch == "$") {
		    array_push(tokens, { type: "dollar", value: "$" });
		    i++;
		    continue;
		}
		
		// Colon separator for case statements
		if (ch == ":") {
		    array_push(tokens, { type: "separator", value: ":" });
		    i++;
		    continue;
		}
		
		// Semicolon separator
		if (ch == ";") {
		    array_push(tokens, { type: "separator", value: ";" });
		    i++;
		    continue;
		}
        
        // Parentheses
        if (ch == "(" || ch == ")") {
            array_push(tokens, { type: "paren", value: ch });
            i++;
            continue;
        }
		
		// Brackets for arrays
		if (ch == "[" || ch == "]") {
		    array_push(tokens, { type: "bracket", value: ch });
		    i++;
		    continue;
		}
		
		// Braces for blocks
		if (ch == "{" || ch == "}") {
		    array_push(tokens, { type: "brace", value: ch });
		    i++;
		    continue;
		}
		
		// Single-character operators without multi-char versions
		if (ch == "~" || ch == "^" || ch == "@") {
		    array_push(tokens, { type: "operator", value: ch });
		    i++;
		    continue;
		}
		
		// Dot for struct access
		if (ch == ".") {
		    array_push(tokens, { type: "dot", value: "." });
		    i++;
		    continue;
		}
        
        //// Operators
        //if (ch == "+" || ch == "-" || ch == "*" || ch == "/" || ch == "=") {
        //    array_push(tokens, { type: "operator", value: ch });
        //    i++;
        //    continue;
        //}
		// Operators (including multi-character operators)
		if (ch == "+" || ch == "-" || ch == "*" || ch == "/" || ch == "=" || 
		    ch == "<" || ch == ">" || ch == "!" || ch == "&" || ch == "|") {
    
		    var next_ch = i < string_length(expr) ? string_char_at(expr, i + 1) : "";
    
		    // Check for two-character operators
		    if (ch == "=" && next_ch == "=") {
		        array_push(tokens, { type: "operator", value: "==" });
		        i += 2;
		        continue;
		    }
		    if (ch == "!" && next_ch == "=") {
		        array_push(tokens, { type: "operator", value: "!=" });
		        i += 2;
		        continue;
		    }
		    if (ch == "<" && next_ch == "=") {
		        array_push(tokens, { type: "operator", value: "<=" });
		        i += 2;
		        continue;
		    }
		    if (ch == ">" && next_ch == "=") {
		        array_push(tokens, { type: "operator", value: ">=" });
		        i += 2;
		        continue;
		    }
		    if (ch == "&" && next_ch == "&") {
		        array_push(tokens, { type: "operator", value: "&&" });
		        i += 2;
		        continue;
		    }
		    if (ch == "|" && next_ch == "|") {
		        array_push(tokens, { type: "operator", value: "||" });
		        i += 2;
		        continue;
		    }
			
			// Check for two-character operators
			if (ch == "+" && next_ch == "+") {
			    array_push(tokens, { type: "operator", value: "++" });
			    i += 2;
			    continue;
			}
			if (ch == "-" && next_ch == "-") {
			    array_push(tokens, { type: "operator", value: "--" });
			    i += 2;
			    continue;
			}
    
		    // Compound assignment operators
		    if ((ch == "+" || ch == "-" || ch == "*" || ch == "/") && next_ch == "=") {
		        array_push(tokens, { type: "operator", value: ch });
		        array_push(tokens, { type: "operator", value: "=" });
		        i += 2;
		        continue;
		    }
			
			// Check for two-character bitwise operators
			if (ch == "<" && next_ch == "<") {
			    array_push(tokens, { type: "operator", value: "<<" });
			    i += 2;
			    continue;
			}
			if (ch == ">" && next_ch == ">") {
			    array_push(tokens, { type: "operator", value: ">>" });
			    i += 2;
			    continue;
			}
    
		    // Single-character operators
		    array_push(tokens, { type: "operator", value: ch });
		    i++;
		    continue;
		}
        
        // Comma (for function arguments)
        if (ch == ",") {
            array_push(tokens, { type: "comma", value: ch });
            i++;
            continue;
        }
        
        // String literals
        if (ch == "\"" || ch == "'") {
            var quote_char = ch;
            var str_content = "";
            i++;
            
            while (i <= string_length(expr)) {
                var next_ch = string_char_at(expr, i);
                var next_next = i < string_length(expr) ? string_char_at(expr, i + 1) : "";
                
                if (next_ch == "\\" && next_next == quote_char) {
                    str_content += quote_char;
                    i += 2;
                    continue;
                }
                if (next_ch == quote_char) {
                    i++;
                    break;
                }
                str_content += next_ch;
                i++;
            }
            array_push(tokens, { type: "string", value: str_content });
            continue;
        }
        
        // Numbers
        if ((ch >= "0" && ch <= "9") || ch == ".") {
            var num_str = "";
            var has_decimal = false;
            
            while (i <= string_length(expr)) {
                var num_ch = string_char_at(expr, i);
                if (num_ch >= "0" && num_ch <= "9") {
                    num_str += num_ch;
                } else if (num_ch == "." && !has_decimal) {
                    num_str += num_ch;
                    has_decimal = true;
                } else {
                    break;
                }
                i++;
            }
            array_push(tokens, { type: "number", value: real(num_str) });
            continue;
        }
        
        // Identifiers (variables and functions)
        if ((ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") || ch == "_") {
            var ident = "";
            
            while (i <= string_length(expr)) {
                var ident_ch = string_char_at(expr, i);
                if ((ident_ch >= "a" && ident_ch <= "z") || 
                    (ident_ch >= "A" && ident_ch <= "Z") || 
                    (ident_ch >= "0" && ident_ch <= "9") || 
                    ident_ch == "_") {
                    ident += ident_ch;
                    i++;
                } else {
                    break;
                }
            }
			
		    // Check for control flow keywords
			if (ident == "if" || ident == "else" || ident == "while" || ident == "for" || 
			    ident == "repeat" || ident == "break" || ident == "continue" || ident == "return" ||
			    ident == "true" || ident == "false" || ident == "switch" || ident == "case" || 
			    ident == "default") {
			    array_push(tokens, { type: "keyword", value: ident });
			    continue;
			}
			
		    // Check for logical keywords
		    if (ident == "and" || ident == "or" || ident == "not" || ident == "xor") {
		        array_push(tokens, { type: "operator", value: ident });
		        continue;
		    }
            
            // Check if it's a function call
            if (i <= string_length(expr) && string_char_at(expr, i) == "(") {
                i++; // Skip '('
                var args = [];
                var current_arg = [];
                var paren_count = 1;
                
                while (i <= string_length(expr) && paren_count > 0) {
                    var arg_ch = string_char_at(expr, i);
                    
                    if (arg_ch == "(") paren_count++;
                    else if (arg_ch == ")") paren_count--;
                    
                    if (paren_count == 0) {
                        if (array_length(current_arg) > 0) {
                            array_push(args, gmlp_tokens_to_string(current_arg));
                        }
                        i++;
                        break;
                    }
                    
                    if (arg_ch == "," && paren_count == 1) {
                        array_push(args, gmlp_tokens_to_string(current_arg));
                        current_arg = [];
                    } else {
                        array_push(current_arg, arg_ch);
                    }
                    i++;
                }
                
                array_push(tokens, { 
                    type: "function_call", 
                    name: ident, 
                    arguments: args 
                });
            } else {
                array_push(tokens, { type: "identifier", name: ident });
            }
            continue;
        }
        
        i++;
    }
    
    return tokens;
}

/// @function gmlp_tokens_to_string(token_chars)
/// @description Converts character array back to string
/// @param {array} chars Array of characters
/// @returns {string} Combined string
function gmlp_tokens_to_string(chars) {
    var str = "";
    for (var i = 0; i < array_length(chars); i++) {
        str += chars[i];
    }
    return string_trim(str);
}

function gmlp_apply_operator(value_stack, op_stack) {
    var op = array_pop(op_stack);
    var right = array_pop(value_stack);
    var left = array_pop(value_stack);
    
    var result;
    switch (op) {
        // Arithmetic
        case "+": 
            if (is_string(left) || is_string(right)) {
                result = string(left) + string(right);
            } else {
                result = left + right;
            }
            break;
        case "-": result = left - right; break;
        case "*": result = left * right; break;
        case "/": result = left / right; break;
        
        // Comparison
        case "==": result = left == right; break;
        case "!=": result = left != right; break;
        case "<": result = left < right; break;
        case ">": result = left > right; break;
        case "<=": result = left <= right; break;
        case ">=": result = left >= right; break;
        
        // Logical
        case "&&": case "and": result = left && right; break;
        case "||": case "or": result = left || right; break;
    }
    
    array_push(value_stack, result);
}

/// @function gmlp_parse_expression(tokens, min_precedence)
/// @description Parses tokens with operator precedence using shunting yard
/// @param {array} tokens Array of tokens
/// @param {real} min_precedence Minimum precedence to parse
/// @returns {array} [value, tokens_consumed]
function gmlp_parse_expression(tokens, min_precedence) {
    var values = [];
    var ops = [];
    var index = 0;
    
	while (index < array_length(tokens)) {
	    var token = tokens[index];
    
	    // Stop if we hit a separator or brace
	    if (token.type == "separator" || token.type == "brace") {
	        break;
	    }
    
	    // Handle unary operators FIRST (they produce values, not binary ops)
	    if (token.type == "operator" && 
	        (token.value == "!" || token.value == "not" || token.value == "-" || 
	         token.value == "~" || token.value == "++" || token.value == "--")) {
        
	        // Check if it's actually unary (at start, after operator, or after open paren)
	        var is_unary = false;
	        if (array_length(values) == 0) {
	            is_unary = true;
	        } else if (index > 0 && tokens[index - 1].type == "operator") {
	            is_unary = true;
	        } else if (index > 0 && tokens[index - 1].type == "paren" && tokens[index - 1].value == "(") {
	            is_unary = true;
	        }
        
	        if (is_unary) {
	            var value_result = gmlp_parse_unary(tokens, index);
	            array_push(values, value_result[0]);
	            index += value_result[1];
	            continue;
	        }
	    }
    
	    // Handle values (numbers, strings, identifiers, function calls, parentheses)
		if (token.type == "number" || token.type == "string" || 
		    token.type == "identifier" || token.type == "function_call" ||
		    token.type == "paren" || token.type == "keyword" || 
			token.type == "bracket" || token.type == "brace") {
    
		    // Save the token info before parsing (needed for postfix)
		    var token_type = token.type;
		    var token_name = (token.type == "identifier") ? token.name : "";
    
		    // Parse the value
		    var value_result;
		    if (token.type == "brace" && token.value == "{") {
			    value_result = gmlp_parse_primary(tokens, index);
			} else if (token.type == "paren" && token.value == "(") {
				show_debug_message("Calling parse_primary for token type: " + token.type);
		        value_result = gmlp_parse_primary(tokens, index);
		    } else if (token.type == "keyword") {
		        if (token.value == "true") {
		            value_result = [1, 1];
		        } else if (token.value == "false") {
		            value_result = [0, 1];
		        } else {
					show_debug_message("Calling parse_primary for token type: " + token.type);
		            value_result = gmlp_parse_primary(tokens, index);
		        }
		    } else {
				show_debug_message("Calling parse_primary for token type: " + token.type);
		        value_result = gmlp_parse_primary(tokens, index);
		    }
    
		    var current_value = value_result[0];
		    var consumed = value_result[1];
		    index += consumed;
    
		    // CHECK FOR ARRAY ACCESS OR POSTFIX OPERATORS AFTER THE VALUE
		    while (index < array_length(tokens)) {
		        var next_token = tokens[index];
        
		        if (next_token.type == "bracket" && next_token.value == "[") {
				    // Check if this is actually a struct accessor: [$ ... ]
				    if (index + 1 < array_length(tokens) && tokens[index + 1].type == "dollar") {
				        // This is a struct accessor: [$ expr ]
				        index += 2; // Skip [ and $
        
				        // Now we're at the start of the index expression
				        // Parse until closing bracket
				        var bracket_count = 1;
				        var index_tokens = [];
				        var consumed = 2;
        
				        while (index < array_length(tokens) && bracket_count > 0) {
				            var t = tokens[index];
				            if (t.type == "bracket") {
				                if (t.value == "[") bracket_count++;
				                else if (t.value == "]") {
				                    bracket_count--;
				                    if (bracket_count == 0) {
				                        consumed++;
				                        break;
				                    }
				                }
				            }
				            array_push(index_tokens, t);
				            consumed++;
				            index++;
				        }
        
				        // Evaluate the key expression
				        var key_result = gmlp_parse_expression(index_tokens, 0);
				        var key = key_result[0];
        
				        // Access the struct
				        if (is_struct(current_value)) {
				            current_value = current_value[$ key];
				        } else {
				            current_value = undefined;
				        }
        
				        index++; // Skip closing bracket
				        continue;
				    } else {
				        // Regular array access
				        var array_result = gmlp_parse_array_access_from_index(current_value, tokens, index);
				        current_value = array_result[0];
				        index += array_result[1];
				        continue;
				    }
				}
    
			    if (next_token.type == "dot") {
			        // Struct property access: .property
			        index++; // Skip dot
			        if (index < array_length(tokens) && tokens[index].type == "identifier") {
			            var prop_name = tokens[index].name;
			            index++;
			            if (is_struct(current_value)) {
			                current_value = current_value[$ prop_name];
			            } else {
			                current_value = undefined;
			            }
			        }
			        continue;
			    }
    
			    if (next_token.type == "dollar") {
				    // Struct accessor: $[ expr ] or $.property
				    index++; // Skip $
    
				    if (index < array_length(tokens)) {
				        if (tokens[index].type == "bracket" && tokens[index].value == "[") {
				            // $[ expr ] syntax
				            var access_result = gmlp_parse_array_access_from_index(current_value, tokens, index);
				            current_value = access_result[0];
				            index += access_result[1];
				        }
				        else if (tokens[index].type == "dot") {
				            // $.property syntax
				            index++; // Skip .
				            if (index < array_length(tokens) && tokens[index].type == "identifier") {
				                var prop_name = tokens[index].name;
				                index++;
				                if (is_struct(current_value)) {
				                    current_value = current_value[$ prop_name];
				                }
				            }
				        }
				        else if (tokens[index].type == "identifier") {
				            // $ identifier (without dot)
				            var prop_name = tokens[index].name;
				            index++;
				            if (is_struct(current_value)) {
				                current_value = current_value[$ prop_name];
				            }
				        }
				    }
				    continue;
				}
        
		        if (next_token.type == "operator" && (next_token.value == "++" || next_token.value == "--")) {
		            // Postfix operator on a variable
		            if (token_type == "identifier" && token_name != "") {
		                var current = gmlp_get_variable(token_name);
		                var new_value = (next_token.value == "++") ? current + 1 : current - 1;
		                gmlp_set_variable(token_name, new_value);
		                current_value = current;
		                index++;
		            }
		            continue;
		        }
        
		        break;
		    }
    
		    array_push(values, current_value);
		    continue;
		}
    
	    // Handle binary operators
	    if (token.type == "operator") {
	        var op = token.value;
	        var precedence = gmlp_get_precedence(op);
        
	        // Apply higher precedence operators from stack
	        while (array_length(ops) > 0) {
	            var top_op = ops[array_length(ops) - 1];
	            var top_prec = gmlp_get_precedence(top_op);
            
	            if (top_prec >= precedence) {
	                var right = array_pop(values);
	                var left = array_pop(values);
	                var op_to_apply = array_pop(ops);
                
	                var result = 0;
	                switch (op_to_apply) {
	                    case "+": 
						    if (is_string(left) || is_string(right)) {
						        result = string(left) + string(right);
						    } else if (is_array(left) || is_array(right)) {
						        // Convert arrays to strings for display, or throw error
						        show_debug_message("Warning: Cannot add arrays with + operator");
						        result = 0;
						    } else {
						        result = left + right;
						    }
						    break;
	                    case "-": result = left - right; break;
	                    case "*": result = left * right; break;
	                    case "/": result = left / right; break;
	                    case "==": result = left == right; break;
	                    case "!=": result = left != right; break;
	                    case "<": result = left < right; break;
	                    case ">": result = left > right; break;
	                    case "<=": result = left <= right; break;
	                    case ">=": result = left >= right; break;
	                    case "&&": case "and": result = left && right; break;
	                    case "||": case "or": result = left || right; break;
	                    case "&": result = left & right; break;
	                    case "|": result = left | right; break;
	                    case "^": result = left ^ right; break;
	                    case "<<": result = left << right; break;
	                    case ">>": result = left >> right; break;
	                }
	                array_push(values, result);
	            } else {
	                break;
	            }
	        }
        
	        array_push(ops, op);
	        index++;
	        continue;
	    }
    
	    index++;
	}
    
    // Apply remaining operators
    while (array_length(ops) > 0) {
        var right = array_pop(values);
        var left = array_pop(values);
        var op_to_apply = array_pop(ops);
        
        var result = 0;
        switch (op_to_apply) {
            case "+": 
			    if (is_string(left) || is_string(right)) {
			        result = string(left) + string(right);
			    } else if (is_array(left) || is_array(right)) {
			        // Convert arrays to strings for display, or throw error
			        show_debug_message("Warning: Cannot add arrays with + operator");
			        result = 0;
			    } else {
			        result = left + right;
			    }
			    break;
            case "-": result = left - right; break;
            case "*": result = left * right; break;
            case "/": result = left / right; break;
            case "==": result = left == right; break;
            case "!=": result = left != right; break;
            case "<": result = left < right; break;
            case ">": result = left > right; break;
            case "<=": result = left <= right; break;
            case ">=": result = left >= right; break;
            case "&&": case "and": result = left && right; break;
            case "||": case "or": result = left || right; break;
            case "&": result = left & right; break;
            case "|": result = left | right; break;
            case "^": result = left ^ right; break;
            case "<<": result = left << right; break;
            case ">>": result = left >> right; break;
        }
        array_push(values, result);
    }
    
    var final_value = array_length(values) > 0 ? values[0] : 0;
    return [final_value, index];
}

/// @function gmlp_parse_array_access_from_index(array_value, tokens, bracket_index)
/// @description Parses array access starting from the opening bracket
/// @param {any} array_value The array variable value
/// @param {array} tokens All tokens
/// @param {real} bracket_index Index of the opening bracket
/// @returns {array} [value, tokens_consumed]
function gmlp_parse_array_access_from_index(array_value, tokens, bracket_index) {
    var index = bracket_index + 1; // Skip '['
    var consumed = 1;
    
    // Parse the index expression until closing bracket
    var bracket_count = 1;
    var index_tokens = [];
    
    while (index < array_length(tokens) && bracket_count > 0) {
        var token = tokens[index];
        if (token.type == "bracket") {
            if (token.value == "[") bracket_count++;
            else if (token.value == "]") {
                bracket_count--;
                if (bracket_count == 0) {
                    consumed++;
                    break;
                }
            }
        }
        array_push(index_tokens, token);
        consumed++;
        index++;
    }
    
    // Check for @ operator
    var use_reference = false;
    if (array_length(index_tokens) > 0 && index_tokens[0].type == "operator" && index_tokens[0].value == "@") {
        use_reference = true;
        var new_index_tokens = [];
        for (var i = 1; i < array_length(index_tokens); i++) {
            array_push(new_index_tokens, index_tokens[i]);
        }
        index_tokens = new_index_tokens;
    }
    
    // Evaluate the index
    var index_result = gmlp_parse_expression(index_tokens, 0);
    var index_value = index_result[0];
    
    // Access the array
    var result_value;
    if (is_array(array_value)) {
        if (use_reference) {
            result_value = array_value[@ index_value];
        } else {
            result_value = array_value[index_value];
        }
    } else {
        result_value = undefined;
    }
	
    return [result_value, consumed];
}

/// @function gmlp_get_precedence(op)
/// @description Returns operator precedence (higher = binds tighter)
/// @param {string} op The operator
/// @returns {real} Precedence value
function gmlp_get_precedence(op) {
    switch (op) {
        // Logical OR
        case "||": case "or": return 1;
        
        // Logical AND
        case "&&": case "and": return 2;
        
        // Bitwise OR
        case "|": return 3;
        
        // Bitwise XOR
        case "^": return 4;
        
        // Bitwise AND
        case "&": return 5;
        
        // Equality
        case "==": case "!=": return 6;
        
        // Comparison
        case "<": case ">": case "<=": case ">=": return 7;
        
        // Bitwise shift
        case "<<": case ">>": return 8;
        
        // Addition/Subtraction
        case "+": case "-": return 9;
        
        // Multiplication/Division
        case "*": case "/": return 10;
        
        // Unary operators
        case "!": case "not": case "~": return 11;
    }
    return 0;
}

/// @function gmlp_parse_unary(tokens, start_index)
/// @description Parses unary operators (!, not, -, ~) and prefix (++, --)
/// @param {array} tokens Array of tokens
/// @param {real} start_index Starting index
/// @returns {array} [value, tokens_consumed]
function gmlp_parse_unary(tokens, start_index) {
    if (start_index >= array_length(tokens)) {
        return [0, 0];
    }
    
    var token = tokens[start_index];
    
    // Handle prefix increment/decrement FIRST
    if (token.type == "operator" && (token.value == "++" || token.value == "--")) {
        if (start_index + 1 < array_length(tokens) && tokens[start_index + 1].type == "identifier") {
            var op = token.value;
            var var_name = tokens[start_index + 1].name;
            var current = gmlp_get_variable(var_name);
            var new_value = (op == "++") ? current + 1 : current - 1;
            gmlp_set_variable(var_name, new_value);
            return [new_value, 2];
        }
    }
    
    // Check for unary operators
    if (token.type == "operator" && (token.value == "!" || token.value == "not" || token.value == "-" || token.value == "~")) {
        var op = token.value;
        
        // Parse the operand
        var operand_result = gmlp_parse_unary(tokens, start_index + 1);
        var value = operand_result[0];
        var consumed = operand_result[1] + 1;
        
        // Apply the operator
        var result;
        switch (op) {
            case "!": case "not": result = !value; break;
            case "-": result = -value; break;
            case "~": result = ~value; break;
        }
        
        return [result, consumed];
    }
    
    // Not a unary operator, parse postfix
    return gmlp_parse_postfix(tokens, start_index);
}

/// @function gmlp_parse_postfix(tokens, start_index)
/// @description Parses postfix operators (var++, var--)
/// @param {array} tokens Array of tokens
/// @param {real} start_index Starting index
/// @returns {array} [value, tokens_consumed]
function gmlp_parse_postfix(tokens, start_index) {
    // Parse the primary expression first
    var result = gmlp_parse_primary(tokens, start_index);
    var value = result[0];
    var consumed = result[1];
    var index = start_index + consumed;
    
    // Check for postfix operators (++/--) or array access
    while (index < array_length(tokens)) {
        var token = tokens[index];
        
        if (token.type == "operator" && (token.value == "++" || token.value == "--")) {
            // Postfix increment/decrement
            var var_name = "";
            if (start_index < array_length(tokens) && tokens[start_index].type == "identifier") {
                var_name = tokens[start_index].name;
            }
            
            if (var_name != "") {
                var current = gmlp_get_variable(var_name);
                var new_value = (token.value == "++") ? current + 1 : current - 1;
                gmlp_set_variable(var_name, new_value);
                value = current;
                consumed++;
                index++;
            } else {
                break;
            }
        }
        else if (token.type == "bracket" && token.value == "[") {
            // Array access
            var array_result = gmlp_parse_array_access(tokens, start_index, value);
            value = array_result[0];
            consumed = array_result[1];
            index = start_index + consumed;
        }
        else {
            break;
        }
    }
    
    return [value, consumed];
}

/// @function gmlp_parse_primary(tokens, start_index)
/// @description Parses a primary expression (number, string, variable, parenthesized expression)
/// @param {array} tokens Array of tokens
/// @param {real} start_index Starting index in tokens array
/// @returns {array} [value, tokens_consumed]
function gmlp_parse_primary(tokens, start_index) {
    if (start_index >= array_length(tokens)) {
        return [0, 0];
    }
    show_debug_message("=== parse_primary called ===");
    if (start_index < array_length(tokens)) {
        show_debug_message("Token: " + tokens[start_index].type);
    }
    
    // Check for prefix increment/decrement in expression: ++var or --var
    if (start_index + 1 < array_length(tokens) &&
        tokens[start_index].type == "operator" && 
        (tokens[start_index].value == "++" || tokens[start_index].value == "--") &&
        tokens[start_index + 1].type == "identifier") {
        
        var op = tokens[start_index].value;
        var var_name = tokens[start_index + 1].name;
        var current = gmlp_get_variable(var_name);
        var new_value = (op == "++") ? current + 1 : current - 1;
        gmlp_set_variable(var_name, new_value);
        return [new_value, 2];
    }
    
    var token = tokens[start_index];
    
    // Handle struct literal: { key: value, ... }
	if (token.type == "brace" && token.value == "{") {
	    var struct_obj = {};
	    var i = start_index + 1;
	    var consumed = 1;
    
	    // Empty struct
	    if (i < array_length(tokens) && tokens[i].type == "brace" && tokens[i].value == "}") {
	        return [struct_obj, 2];
	    }
    
	    while (i < array_length(tokens)) {
	        // Stop at closing brace
	        if (tokens[i].type == "brace" && tokens[i].value == "}") {
	            consumed++;
	            break;
	        }
        
	        // Get key
	        var key = null;
	        if (tokens[i].type == "identifier") {
	            key = tokens[i].name;
	        } else if (tokens[i].type == "string") {
	            key = tokens[i].value;
	        }
	        i++;
	        consumed++;
        
	        // Skip colon
	        if (i < array_length(tokens) && tokens[i].type == "separator" && tokens[i].value == ":") {
	            i++;
	            consumed++;
	        }
        
	        // Parse value until comma or closing brace
	        var value_tokens = [];
	        var brace_depth = 0;
	        while (i < array_length(tokens)) {
	            var t = tokens[i];
	            if (t.type == "brace") {
	                if (t.value == "{") brace_depth++;
	                else if (t.value == "}") {
	                    if (brace_depth == 0) break;
	                    brace_depth--;
	                }
	            }
	            if (brace_depth == 0 && t.type == "comma") {
	                i++;
	                consumed++;
	                break;
	            }
	            array_push(value_tokens, t);
	            i++;
	            consumed++;
	        }
        
	        // Set property
	        if (key != null && array_length(value_tokens) > 0) {
	            var val_result = gmlp_parse_expression(value_tokens, 0);
	            struct_obj[$ key] = val_result[0];
	        }
        
	        // Skip comma
	        if (i < array_length(tokens) && tokens[i].type == "comma") {
	            i++;
	            consumed++;
	        }
	    }
    
	    return [struct_obj, consumed];
	}
    
    // Handle array literal: [ expr, expr, ... ]
	if (token.type == "bracket" && token.value == "[") {
	    var elements = [];
	    var i = start_index + 1;
	    var consumed = 1;
    
	    // Empty array check
	    if (i < array_length(tokens) && tokens[i].type == "bracket" && tokens[i].value == "]") {
	        return [[], 2];
	    }
    
	    while (i < array_length(tokens)) {
	        var t = tokens[i];
        
	        // Stop at closing bracket
	        if (t.type == "bracket" && t.value == "]") {
	            consumed++;
	            i++;
	            break;
	        }
        
	        // Parse one element until comma or closing bracket
	        var elem_tokens = [];
	        var bracket_depth = 0;
        
	        while (i < array_length(tokens)) {
	            var et = tokens[i];
            
	            if (et.type == "bracket") {
	                if (et.value == "[") bracket_depth++;
	                else if (et.value == "]") {
	                    if (bracket_depth == 0) {
	                        // This is the closing bracket of the array
	                        break;
	                    }
	                    bracket_depth--;
	                }
	            }
            
	            if (bracket_depth == 0 && et.type == "comma") {
	                i++; // Skip comma
	                consumed++;
	                break;
	            }
            
	            array_push(elem_tokens, et);
	            i++;
	            consumed++;
	        }
        
	        // Evaluate the element
	        if (array_length(elem_tokens) > 0) {
	            var elem_result = gmlp_parse_expression(elem_tokens, 0);
	            array_push(elements, elem_result[0]);
	        }
        
	        // If we stopped at closing bracket, break outer loop
	        if (i < array_length(tokens) && tokens[i-1].type == "bracket" && tokens[i-1].value == "]") {
	            break;
	        }
	    }
    
	    // Consume the closing bracket if we haven't already
	    if (i < array_length(tokens) && tokens[i].type == "bracket" && tokens[i].value == "]") {
	        consumed++;
	    }
		
	    return [elements, consumed];
	}
    
    // Handle true/false keywords
    if (token.type == "keyword") {
        if (token.value == "true") return [1, 1];
        if (token.value == "false") return [0, 1];
    }
    
    // Number
    if (token.type == "number") {
        return [token.value, 1];
    }
    
    // String
    if (token.type == "string") {
        return [token.value, 1];
    }
    
    // Identifier (variable)
    if (token.type == "identifier") {
        return [gmlp_get_variable(token.name), 1];
    }
    
    // Function call
    if (token.type == "function_call") {
        var args = [];
        for (var i = 0; i < array_length(token.arguments); i++) {
            var arg_tokens = gmlp_tokenize(token.arguments[i]);
            var arg_result = gmlp_parse_expression(arg_tokens, 0);
            args[i] = arg_result[0];
        }
        return [gmlp_execute_function(token.name, args), 1];
    }
    
    // Parenthesized expression
    if (token.type == "paren" && token.value == "(") {
        var sub_tokens = [];
        var paren_count = 1;
        var consumed = 1; // Start with 1 for the opening paren
        var i = start_index + 1;
        
        while (i < array_length(tokens)) {
            var t = tokens[i];
            
            if (t.type == "paren") {
                if (t.value == "(") paren_count++;
                else if (t.value == ")") {
                    paren_count--;
                    if (paren_count == 0) {
                        consumed++; // Add the closing paren
                        break;
                    }
                }
            }
            
            array_push(sub_tokens, t);
            consumed++;
            i++;
        }
        
        // Evaluate the sub-expression
        var result = gmlp_parse_expression(sub_tokens, 0);
        return [result[0], consumed];
    }
    
    return [0, 1];
}

/// @function gmlp_parse_array_access(tokens, start_index, array_value)
/// @description Parses array access like array[index] or array[@ index]
/// @param {array} tokens Array of tokens
/// @param {real} start_index Starting index of the array identifier
/// @param {any} array_value The array variable value
/// @returns {array} [value, tokens_consumed]
function gmlp_parse_array_access(tokens, start_index, array_value) {
    // We need to find the end of the primary expression first
    var primary_result = gmlp_parse_primary(tokens, start_index);
    var consumed = primary_result[1];
    var index = start_index + consumed;
    
    // Check for opening bracket
    if (index >= array_length(tokens) || tokens[index].type != "bracket" || tokens[index].value != "[") {
        return [array_value, consumed];
    }
    
    index++; // Skip '['
    var total_consumed = consumed + 1;
    
    // Parse the index expression until closing bracket
    var bracket_count = 1;
    var index_tokens = [];
    
    while (index < array_length(tokens) && bracket_count > 0) {
        var token = tokens[index];
        if (token.type == "bracket") {
            if (token.value == "[") bracket_count++;
            else if (token.value == "]") {
                bracket_count--;
                if (bracket_count == 0) {
                    total_consumed++;
                    break;
                }
            }
        }
        array_push(index_tokens, token);
        total_consumed++;
        index++;
    }
    
    // Check for @ operator (array reference accessor)
    var use_reference = false;
    if (array_length(index_tokens) > 0 && index_tokens[0].type == "operator" && index_tokens[0].value == "@") {
        use_reference = true;
        // Remove @ from index tokens
        var new_index_tokens = [];
        for (var i = 1; i < array_length(index_tokens); i++) {
            array_push(new_index_tokens, index_tokens[i]);
        }
        index_tokens = new_index_tokens;
    }
    
    // Evaluate the index expression
    var index_result = gmlp_parse_expression(index_tokens, 0);
    var index_value = index_result[0];
    
    // Access the array
    var result_value;
	if (is_array(array_value)) {
	    if (use_reference) {
	        result_value = array_value[@ index_value];
	    } else {
	        // Make sure index is a number
	        var idx = real(index_value);
	        result_value = array_value[idx];
	    }
	} else {
	    show_debug_message("Warning: Trying to index a non-array value");
	    result_value = undefined;
	}
	
    // Check for chained array access (multi-dimensional)
    if (start_index + total_consumed < array_length(tokens) && 
        tokens[start_index + total_consumed].type == "bracket" && 
        tokens[start_index + total_consumed].value == "[") {
        
        var chain_result = gmlp_parse_array_access(tokens, start_index + total_consumed, result_value);
        return [chain_result[0], total_consumed + chain_result[1]];
    }
    
    return [result_value, total_consumed];
}

/// @function gmlp_execute_function(name, args)
/// @description Executes a function with arguments
/// @param {string} name Function name
/// @param {array} args Arguments array
/// @returns {any} Function return value
function gmlp_execute_function(name, args) {
    var func_id = asset_get_index(name);
    var arg_count = array_length(args);
    
    switch (arg_count) {
        case 0: return script_execute(func_id);
        case 1: return script_execute(func_id, args[0]);
        case 2: return script_execute(func_id, args[0], args[1]);
        case 3: return script_execute(func_id, args[0], args[1], args[2]);
        case 4: return script_execute(func_id, args[0], args[1], args[2], args[3]);
        default:
            show_debug_message("Warning: Function calls with >4 arguments not supported: " + name);
            return undefined;
    }
}

/// @function gmlp_get_variable(name)
/// @description Gets a variable value from the current scope
/// @param {string} name Variable name
/// @returns {any} The variable's value
function gmlp_get_variable(name) {
    if (variable_instance_exists(id, name)) {
        return variable_instance_get(id, name);
    }
    if (variable_global_exists(name)) {
        return variable_global_get(name);
    }
    show_debug_message("Warning: Variable '" + name + "' not found");
    return undefined;
}

/// @function gmlp_set_variable(name, value)
/// @description Sets a variable value in the current scope
/// @param {string} name Variable name
/// @param {any} value Value to set
function gmlp_set_variable(name, value) {
    if (variable_instance_exists(id, name)) {
        variable_instance_set(id, name, value);
        return;
    }
    if (variable_global_exists(name)) {
        variable_global_set(name, value);
        return;
    }
    // Create as instance variable by default
    variable_instance_set(id, name, value);
}

/// @function gmlp_find_operator_outside_strings(expr, op)
/// @description Finds an operator position, ignoring those inside string literals
/// @param {string} expr The expression to search
/// @param {string} op The operator to find
/// @returns {real} Position of operator or -1 if not found
function gmlp_find_operator_outside_strings(expr, op) {
    var in_string = false;
    var string_char = "";
    var paren_count = 0;
    
    for (var i = 1; i <= string_length(expr); i++) {
        var ch = string_char_at(expr, i);
        var prev_ch = i > 1 ? string_char_at(expr, i - 1) : "";
        
        if ((ch == "\"" || ch == "'") && prev_ch != "\\") {
            if (!in_string) {
                in_string = true;
                string_char = ch;
            } else if (ch == string_char) {
                in_string = false;
            }
        }
        
        if (!in_string) {
            if (ch == "(") paren_count++;
            else if (ch == ")") paren_count--;
            else if (paren_count == 0) {
                // Check if this position matches the operator
                var matches = true;
                for (var j = 0; j < string_length(op); j++) {
                    if (i + j > string_length(expr) || string_char_at(expr, i + j) != string_char_at(op, j + 1)) {
                        matches = false;
                        break;
                    }
                }
                if (matches) return i;
            }
        }
    }
    return -1;
}

/// @function gmlp_find_first_operator(expr)
/// @description Finds the first operator (+ - * /) outside strings and parentheses
/// @param {string} expr The expression to search
/// @returns {array} [position, operator_char] or [-1, ""]
function gmlp_find_first_operator(expr) {
    var in_string = false;
    var string_char = "";
    var paren_count = 0;
    
    for (var i = 1; i <= string_length(expr); i++) {
        var ch = string_char_at(expr, i);
        var prev_ch = i > 1 ? string_char_at(expr, i - 1) : "";
        var next_ch = i < string_length(expr) ? string_char_at(expr, i + 1) : "";
        
        if ((ch == "\"" || ch == "'") && prev_ch != "\\") {
            if (!in_string) {
                in_string = true;
                string_char = ch;
            } else if (ch == string_char) {
                in_string = false;
            }
        }
        
        if (!in_string) {
            if (ch == "(") paren_count++;
            else if (ch == ")") paren_count--;
            else if (paren_count == 0 && (ch == "+" || ch == "-" || ch == "*" || ch == "/")) {
                // Skip compound assignment operators
                if ((ch == "+" || ch == "-" || ch == "*" || ch == "/") && next_ch == "=") {
                    continue;
                }
                return [i, ch];
            }
        }
    }
    return [-1, ""];
}

/// @function gmlp_parse_string_literal(expr)
/// @description Extracts the content of a string literal
/// @param {string} expr The string literal expression
/// @returns {string} The string content
function gmlp_parse_string_literal(expr) {
    var quote_char = string_char_at(expr, 1);
    var i = 2;
    var content = "";
    
    while (i <= string_length(expr)) {
        var ch = string_char_at(expr, i);
        var next_ch = i < string_length(expr) ? string_char_at(expr, i + 1) : "";
        
        if (ch == "\\" && next_ch == quote_char) {
            content += quote_char;
            i += 2;
            continue;
        }
        if (ch == quote_char) break;
        
        content += ch;
        i += 1;
    }
    return content;
}

/// @function gmlp_split_arguments(str)
/// @description Splits function arguments, respecting nested calls and strings
/// @param {string} str The argument string
/// @returns {array} Array of argument strings
function gmlp_split_arguments(str) {
    var args = [];
    var current = "";
    var paren_count = 0;
    var in_string = false;
    var string_char = "";
    
    for (var i = 1; i <= string_length(str); i++) {
        var ch = string_char_at(str, i);
        var prev_ch = i > 1 ? string_char_at(str, i - 1) : "";
        
        if ((ch == "\"" || ch == "'") && prev_ch != "\\") {
            if (!in_string) {
                in_string = true;
                string_char = ch;
            } else if (ch == string_char) {
                in_string = false;
            }
        }
        
        if (!in_string) {
            if (ch == "(") paren_count++;
            else if (ch == ")") paren_count--;
            else if (ch == "," && paren_count == 0) {
                array_push(args, current);
                current = "";
                continue;
            }
        }
        current += ch;
    }
    
    if (string_trim(current) != "") {
        array_push(args, current);
    }
    return args;
}

/// @function gmlp_is_numeric(str)
/// @description Checks if a string represents a valid number
/// @param {string} str The string to check
/// @returns {bool} True if numeric
function gmlp_is_numeric(str) {
    if (str == "") return false;
    
    var i = 1;
    if (string_char_at(str, 1) == "-") {
        if (string_length(str) == 1) return false;
        i = 2;
    }
    
    var has_decimal = false;
    for (var j = i; j <= string_length(str); j++) {
        var ch = string_char_at(str, j);
        if (ch == ".") {
            if (has_decimal) return false;
            has_decimal = true;
        } else if (ch < "0" || ch > "9") {
            return false;
        }
    }
    return true;
}

/// @function gmlp_split_string(str, delimiter)
/// @description Splits a string by delimiter
/// @param {string} str The string to split
/// @param {string} delimiter The delimiter character
/// @returns {array} Array of split strings
function gmlp_split_string(str, delimiter) {
    var result = [];
    var current = "";
    
    for (var i = 1; i <= string_length(str); i++) {
        var ch = string_char_at(str, i);
        if (ch == delimiter) {
            array_push(result, current);
            current = "";
        } else {
            current += ch;
        }
    }
    if (current != "") array_push(result, current);
    return result;
}