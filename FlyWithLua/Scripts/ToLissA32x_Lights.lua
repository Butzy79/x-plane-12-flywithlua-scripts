-- FlyWithLua script for ToLISS Lights Honeycomb Bravo
-- Value set -1 (negative) = no button assigned
local lights_buttons = {
        landing_lights_left_on = 353,
        landing_lights_left_off = 354,
        landing_lights_right_on = 353,
        landing_lights_right_off = 354,
        strobe_lights_on = 365,
        strobe_lights_auto = 366,
        strobe_lights_off = -1,
        wings_lights_on = 363,
        wings_lights_off = 364,
        runeway_turnoff_lights_on = 355,
        runeway_turnoff_lights_off = 356,
        nose_taxi_lights = 357,
        nose_takeoff_lights = 355,
        nose_off_lights = 356,
        beacon_lights_on = 363,
        beacon_lights_off = 364,
        navandlogo_lights_1 = -1,
        navandlogo_lights_2 = -1,
        navandlogo_lights_off = -1,
}
local lights_status_value = { [0] = 0, 0, 0, 0, 0, 0, 0, 0 }
local lightSwitches = dataref_table( "AirbusFBW/OHPLightSwitches" )
--	lightSwitches[0] -- BEACON
--	lightSwitches[1] -- WINGS
--	lightSwitches[2] -- NAV and LOGO
--	lightSwitches[3] -- NOSE WHEEL
--	lightSwitches[4] -- LANDING LEFT
--	lightSwitches[5] -- LANDING RIGHT
--	lightSwitches[6] -- RWY TURNOFF
--	lightSwitches[7] -- STROBE
function initialize_lights_status()
    for i = 0, 7 do
        lights_status_value[i] = lightSwitches[i]
    end
end

initialize_lights_status()

function inject_lights_status()
    for i = 0, 7 do
        if lightSwitches[i] ~= lights_status_value[i] then
                lightSwitches[i] = lights_status_value[i]
        end
    end
end

function handle_lights()
    local function set_light_dual_status(button_on, button_off, switch_idx, value_on, value_off)
        if button_on >= 0 and button(button_on) then lights_status_value[switch_idx] = value_on end
        if button_off >= 0 and button(button_off) then lights_status_value[switch_idx] = value_off end
        if button_on < 0 and button_off < 0 then lights_status_value[switch_idx] = lightSwitches[switch_idx] end
    end
    local function set_light_tri_status(button_on, button_mid, button_off, switch_idx, value_on, value_mid, value_off)
        if button_off >= 0 and button(button_off) then lights_status_value[switch_idx] = value_off end
        if button_mid >= 0 and button(button_mid) then lights_status_value[switch_idx] = value_mid end
        if button_on >= 0 and button(button_on) then lights_status_value[switch_idx] = value_on end
        if button_on < 0 and button_mid < 0 and button_off < 0 then lights_status_value[switch_idx] = lightSwitches[switch_idx] end
    end
    set_light_dual_status(lights_buttons.landing_lights_left_on, lights_buttons.landing_lights_left_off, 4, 2, 0)
    set_light_dual_status(lights_buttons.landing_lights_right_on, lights_buttons.landing_lights_right_off, 5, 2, 0)
    set_light_dual_status(lights_buttons.wings_lights_on, lights_buttons.wings_lights_off, 1, 1, 0)
    set_light_dual_status(lights_buttons.runeway_turnoff_lights_on, lights_buttons.runeway_turnoff_lights_off, 6, 1, 0)
    set_light_dual_status(lights_buttons.beacon_lights_on, lights_buttons.beacon_lights_off, 0, 1, 0)

    set_light_tri_status(lights_buttons.strobe_lights_on, lights_buttons.strobe_lights_auto, lights_buttons.strobe_lights_off, 7, 2, 1, 0)
    set_light_tri_status(lights_buttons.nose_takeoff_lights, lights_buttons.nose_taxi_lights, lights_buttons.nose_off_lights, 3, 2, 1, 0)
    set_light_tri_status(lights_buttons.navandlogo_lights_2, lights_buttons.navandlogo_lights_1, lights_buttons.navandlogo_lights_off, 2, 2, 1, 0)

    inject_lights_status()
end

do_often("handle_lights()")
