local button_cockpits_views = 490
local button_views = 491

local last_pressed_cockpit_view = false
local last_pressed_view = false

local view_cockpit_default = "sim/view/3d_cockpit_cmnd_look"
local view_cockpit_mod = "sim/view/quick_look_7"

local view_external = "sim/view/chase"
local view_window = "sim/view/quick_look_8"
local view_mode = 0  -- 0 = External Chase, 1 = Internal Window

local axis_horizontal = 78
local axis_vertical = 77

local Axis_Values = dataref_table("sim/joystick/joystick_axis_values")

function switch_view(view_passed)
    if view_mode == 0 then
        command_once(view_passed[1])
        view_mode = 1
    else
        command_once(view_passed[2])
        view_mode = 0
    end
end

function check_hat_switch()
    if Axis_Values[axis_horizontal] == 1 then
        command_once("sim/view/pan_right") 
    elseif Axis_Values[axis_horizontal] == 0 then
        command_once("sim/view/pan_left") 
    end

    if Axis_Values[axis_vertical] == 1 then
        command_once("sim/view/pan_down") 
    elseif Axis_Values[axis_vertical] == 0 then
        command_once("sim/view/pan_up") 
    end
end

function check_button_inputs()
      if button(button_cockpits_views) then
        if not last_pressed_cockpit_view then
            switch_view({view_cockpit_default, view_cockpit_mod})
        end
        last_pressed_cockpit_view = true
    else
        last_pressed_cockpit_view = false
    end

    if button(button_views) then
        if not last_pressed_view then
            switch_view({view_external, view_window})
        end
        last_pressed_view = true
    else
        last_pressed_view = false
    end
end

function on_frame()
    check_button_inputs()
    check_hat_switch()
end

do_every_frame("on_frame()")
