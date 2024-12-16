-- FlyWithLua script for ToLISS Lights Honeycomb Bravo
-- Value set -1 (negative) = no button assigned
local lights_buttons = {
        landing_lights_left_on = 1111,
        landing_lights_left_off = 1111,
        landing_lights_right_on = 1111,
        landing_lights_right_off = 1111,
        strobe_lights_on = 1111,
        strobe_lights_off = 1111,
        wings_lights_on = 1111,
        wings_lights_off = 1111,
        runeway_turnoff_lights_on = 1111,
        runeway_turnoff_lights_off = 1111,
        nose_taxi_lights = 1111,
        nose_takeoff_lights = 1111,
        nose_off_lights = 1111,
        beacon_lights_on = -1,
        beacon_lights_auto = -1,
        beacon_lights_off = -1,
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
        end if
    end
end

function handle_lights()
    if lights_buttons.landing_lights_left_on >=0 and button(lights_buttons.landing_lights_left_on) then
      lights_status_value[4] = 2
    end if
    if lights_buttons.landing_lights_left_off >=0 and button(lights_buttons.landing_lights_left_off) then
      lights_status_value[4] = 0
    end if

    if lights_buttons.landing_lights_right_on >=0 and button(lights_buttons.landing_lights_right_on) then
      lights_status_value[5] = 2
    end if
    if lights_buttons.landing_lights_right_off >=0 and button(lights_buttons.landing_lights_right_off) then
      lights_status_value[5] = 0
    end if

    if lights_buttons.strobe_lights_on >=0 and button(lights_buttons.strobe_lights_on) then
      lights_status_value[7] = 1
    end if
    if lights_buttons.strobe_lights_off >=0 and button(lights_buttons.strobe_lights_off) then
      lights_status_value[7] = 0
    end if

    if lights_buttons.wings_lights_on >=0 and button(lights_buttons.wings_lights_on) then
      lights_status_value[1] = 1
    end if
    if lights_buttons.wings_lights_off >=0 and button(lights_buttons.wings_lights_off) then
      lights_status_value[1] = 0
    end if

    if lights_buttons.runeway_turnoff_lights_on >=0 and button(lights_buttons.runeway_turnoff_lights_on) then
      lights_status_value[6] = 1
    end if
    if lights_buttons.runeway_turnoff_lights_on >=0 and button(lights_buttons.runeway_turnoff_lights_on) then
      lights_status_value[6] = 0
    end if
                      
    if lights_buttons.beacon_lights_off >=0 and button(lights_buttons.beacon_lights_off) then
      lights_status_value[0] = 0
    end if
    if lights_buttons.beacon_lights_auto >=0 and button(lights_buttons.beacon_lights_auto) then
      lights_status_value[0] = 1
    end if
    if lights_buttons.beacon_lights_on >=0 and button(lights_buttons.beacon_lights_on) then
      lights_status_value[0] = 2
    end if

    if lights_buttons.nose_off_lights >=0 and button(lights_buttons.nose_off_lights) then
      lights_status_value[3] = 0
    end if 
    if lights_buttons.nose_taxi_lights >=0 and button(lights_buttons.nose_taxi_lights) then
      lights_status_value[3] = 1
    end if
    if lights_buttons.nose_takeoff_lights >=0 and button(lights_buttons.nose_takeoff_lights) then
      lights_status_value[3] = 2
    end if

    if lights_buttons.navandlogo_lights_off >=0 and button(lights_buttons.navandlogo_lights_off) then
      lights_status_value[2] = 0
    end if 
    if lights_buttons.navandlogo_lights_1 >=0 and button(lights_buttons.navandlogo_lights_1) then
      lights_status_value[2] = 1
    end if
    if lights_buttons.navandlogo_lights_2 >=0 and button(lights_buttons.navandlogo_lights_2) then
      lights_status_value[2] = 2
    end if
    inject_lights_status()
end

do_often("handle_lights()")
