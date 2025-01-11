local omni = {
    title = "omniloadhub",
    version = "0.0.1",
    params = {
        zfw = 0,
        zfwcg = 0,
        gwcg = 0,
        f_blk = 0,
        flt_no = nil,
    },
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
    omniloadhub_window = float_wnd_create(omni.settings.window.window_width, omni.settings.window.window_height, 1, true)
    float_wnd_set_position(omniloadhub_window, omni.settings.window.window_x, omni.settings.window.window_y)
    float_wnd_set_title(omniloadhub_window, string.format("%s - v%s", omni.title, omni.version))
    float_wnd_set_imgui_builder(omniloadhub_window, "viewomniloadhubWindow")
end

function viewomniloadhubWindow()
    for key in pairs(omni.params) do
        imguiText(key, omni.params[key])
    end

    imguiText("Ground", omniloadhub_onground_any)
end

-- == Main Loop Often (1 Sec) ==
function omniloadhubMainLoop()

    local arm_fuel = 24 -- meeters
    local mac = 4.29 --  meeters
    local le_mac = 20 --  meeters



    local pax_ant = 50 -- percent
    local cargo_ant = 70 -- percent

    local zfw = (omniloadhub_m_total - omniloadhub_m_total)
    local momentun_total = zfw * omniloadhub_cgz_ref
    local momentun_fuel = omniloadhub_m_total * arm_fuel
    local momentun_zwf = momentun_total - momentun_fuel
    local zfwcg_meeters = momentun_zwf / zfw
    local zfwcg_percenage_decimal  = (zfwcg_meeters - le_mac) / mac



    omni.params.f_blk = string.format("%.1f", omniloadhub_m_total / 1000)
    omni.params.zfw = string.format("%.1f", zfw / 1000)
    omni.params.gwcg = string.format("%.1f", omniloadhub_cgz_ref)
    omni.params.zfwcg = string.format("%.1f", zfwcg_percenage_decimal * 100)

end

-- == Main code ==
dataref("omniloadhub_onground_any", "sim/flightmodel/failures/onground_any", "readonly")
dataref("omniloadhub_m_total", "sim/flightmodel/weight/m_total", "readonly")
dataref("omniloadhub_m_fuel_total", "sim/flightmodel/weight/m_fuel_total", "readonly")
dataref("omniloadhub_cgz_ref", "sim/flightmodel/misc/cgz_ref", "readonly")


do_often("omniloadhubMainLoop()")

openomniloadhubWindow()
