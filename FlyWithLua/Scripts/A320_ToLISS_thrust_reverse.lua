-- FlyWithLua script for ToLISS thrust reverse max
-- Activates thrust reverse max on specified engines when the configured buttons are pressed.

-- Define configurations for each engine
local engines = {
    {
        button1 = 329, -- Button for reverse lever
        button2 = 345, -- Button for left lever
        command = "sim/engines/thrust_reverse_hold_1",
        reverse_active = false -- State tracking for thrust reverse
    },
    {
        button1 = 367, -- Button for reverse lever (engine 2)
        button2 = 346, -- Button for left lever (engine 2)
        command = "sim/engines/thrust_reverse_hold_2",
        reverse_active = false -- State tracking for thrust reverse
    }
}

-- Function to check button status and handle thrust reverse for each engine
function handle_thrust_reverse()
    for _, engine in ipairs(engines) do
        if button(engine.button1) and button(engine.button2) then
            if not engine.reverse_active then
                command_begin(engine.command)
                engine.reverse_active = true
            end
        else
            if engine.reverse_active then
                command_end(engine.command)
                engine.reverse_active = false
            end
        end
    end
end

-- Register the function to run every frame
do_every_draw("handle_thrust_reverse()")
