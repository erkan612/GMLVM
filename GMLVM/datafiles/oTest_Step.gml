if (keyboard_check(ord("W"))) {
    y -= spd;
}
if (keyboard_check(ord("A"))) {
    x -= spd;
}
if (keyboard_check(ord("S"))) {
    y += spd;
}
if (keyboard_check(ord("D"))) {
    x += spd;
}
//if (!place_meeting(x, y, Object2)) { show_debug_message(delta_time); }
if (keyboard_check_pressed(vk_space)) show_debug_message("Oopsie..."); // this should work without { }