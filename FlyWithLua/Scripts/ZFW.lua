local omniloadhub = {
    title = "omniloadhub",
    version = "0.0.1",
    settings = {
        window = {
            window_width = 400,
            window_height = 250,
            window_x = 160,
            window_y = 200,
        }
    }
}

local function imguiText(label, value)
    imgui.TextUnformatted(tostring(label)..": " .. tostring(value))
    imgui.Spacing()
end

local omniloadhub_window = nil
-- == X-Plane Functions ==
function openomniloadhubWindow()
    omniloadhub_window = float_wnd_create(omniloadhub.settings.window.window_width, omniloadhub.settings.window.window_height, 1, true)
    float_wnd_set_position(omniloadhub_window, omniloadhub.settings.window.window_x, omniloadhub.settings.window.window_y)
    float_wnd_set_title(omniloadhub_window, string.format("%s - v%s", omniloadhub.title, omniloadhub.version))
    float_wnd_set_imgui_builder(omniloadhub_window, "viewomniloadhubWindow")
end

function viewomniloadhubWindow()
    imguiText("Ground", omniloadhub_onground_any)
end

-- == Main Loop Often (1 Sec) ==
function omniloadhubMainLoop()
  
end

-- == Main code ==
dataref("omniloadhub_onground_any", "sim/flightmodel/failures/onground_any", "readonly")

do_often("omniloadhubMainLoop()")

openomniloadhubWindow()
