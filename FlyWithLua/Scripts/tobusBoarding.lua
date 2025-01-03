if PLANE_ICAO == "A319" or PLANE_ICAO == "A20N" or PLANE_ICAO == "A321" or
   PLANE_ICAO == "A21N" or PLANE_ICAO == "A346" or PLANE_ICAO == "A339"
then

-- fork Manta32 --
LEAVE_DOOR1_OPEN_DEBOARD = true
WINDOW_X = 200
WINDOW_Y = 100
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 250
STARTUP_VIEW = true
AUTO_FETCH_SIMBRIEF = true
-- end --

local VERSION = "1.0.1-manta32"
logMsg("TOBUS " .. VERSION .. " startup")

 --http library import
local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")
local socket = require "socket"
local http = require "socket.http"
local LIP = require("LIP")

local wait_until_speak = 0
local speak_string

local intendedPassengerNumber
local intended_no_pax_set = false

local tls_no_pax        -- dataref_table
local MAX_PAX_NUMBER = 224

local SETTINGS_FILENAME = "tobus_settings.ini"
local SETTINGS_DIRECTORY = "tobus"
local SIMBRIEF_FLIGHTPLAN_FILENAME = "simbrief.xml"
local SIMBRIEF_ACCOUNT_NAME = ""
local RANDOMIZE_SIMBRIEF_PASSENGER_NUMBER = false
local USE_SECOND_DOOR = false
local CLOSE_DOORS = true
local LEAVE_DOOR1_OPEN = false
local SIMBRIEF_FLIGHTPLAN = {}

local jw1_connected = false     -- set if an opensam jw at the second door is detected
local opensam_door_status = nil
if nil ~= XPLMFindDataRef("opensam/jetway/door/status") then
	opensam_door_status = dataref_table("opensam/jetway/door/status")
end

local function createDirectoryIfNotExists()
    local file = io.open(SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY .. "/"..SETTINGS_FILENAME, "r")
    if file then
        file:close()
    else
        local success = os.execute('mkdir "' .. SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY .. '"')
        if success then
            logMsg("Directory created: " .. SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY)
        else
            logMsg("Failed to create directory: " .. SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY)
        end
    end
end

local function createFileIfNotExists()
    local file = io.open(SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY..'/'..SETTINGS_FILENAME, "r")
    if not file then
        file = io.open(SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY..'/'..SETTINGS_FILENAME, "w")
        if file then
            local content = [[
[simbrief]
username=
randomizePassengerNumber=true
auto_fetch=true

[doors]
closeDoors=true
leaveDoor1Open=false
leaveDoor1OpenDeboard=true
useSecondDoor=false

[general]
x=100
y=230
width=800
height=250
startup=true
]]
            file:write(content)
        end
        file:close()
        logMsg("File created: " .. SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY..'/'..SETTINGS_FILENAME)
    else
        file:close()
    end
end

local function openDoorsForBoarding()
    passengerDoorArray[0] = 2
    if USE_SECOND_DOOR or jw1_connected then
        if PLANE_ICAO == "A319" or PLANE_ICAO == "A20N" or PLANE_ICAO == "A339" then
            passengerDoorArray[2] = 2
        end
        if PLANE_ICAO == "A321" or PLANE_ICAO == "A21N" or PLANE_ICAO == "A346" then
            passengerDoorArray[6] = 2
        end
    end
    cargoDoorArray[0] = 2
    cargoDoorArray[1] = 2
end

local function closeDoorsAfterBoarding(board)
    if not CLOSE_DOORS then return end
    if board then
        if not LEAVE_DOOR1_OPEN then
            passengerDoorArray[0] = 0
        end    
    else
        if not LEAVE_DOOR1_OPEN_DEBOARD then
            passengerDoorArray[0] = 0
        end
    end


    if USE_SECOND_DOOR or jw1_connected then
        if PLANE_ICAO == "A319" or PLANE_ICAO == "A20N" or PLANE_ICAO == "A339" then
            passengerDoorArray[2] = 0
        end

        if PLANE_ICAO == "A321" or PLANE_ICAO == "A21N" or PLANE_ICAO == "A346" or PLANE_ICAO == "A339" then
            passengerDoorArray[6] = 0
        end
    end
    cargoDoorArray[0] = 0
    cargoDoorArray[1] = 0
end

local function setDefaultBoardingState()
    set("AirbusFBW/NoPax", 0)
    set("AirbusFBW/PaxDistrib", math.random(35, 60) / 100)
    passengersBoarded = 0
    boardingPaused = false
    boardingStopped = false
    boardingActive = true
end

local function playChimeSound(boarding)
    command_once( "AirbusFBW/CheckCabin" )
    if boarding then
        speak_string = "Boarding Completed"
    else
        speak_string = "Deboarding Completed"
    end

    wait_until_speak = os.time() + 0.5
    intended_no_pax_set = false
end

local function boardInstantly()
    set("AirbusFBW/NoPax", intendedPassengerNumber)
    passengersBoarded = intendedPassengerNumber
    boardingActive = false
    boardingCompleted = true
    playChimeSound(true)
    command_once("AirbusFBW/SetWeightAndCG")
    closeDoorsAfterBoarding(true)
end

local function deboardInstantly()
    set("AirbusFBW/NoPax", 0)
    deboardingActive = false
    deboardingCompleted = true
    playChimeSound(false)
    command_once("AirbusFBW/SetWeightAndCG")
    closeDoorsAfterBoarding(false)
end

local function setRandomNumberOfPassengers()
    local passengerDistributionGroup = math.random(0, 100)

    if passengerDistributionGroup < 2 then
        intendedPassengerNumber = math.random(math.floor(MAX_PAX_NUMBER * 0.22), math.floor(MAX_PAX_NUMBER * 0.54))
        return
    end

    if passengerDistributionGroup < 16 then
        intendedPassengerNumber = math.random(math.floor(MAX_PAX_NUMBER * 0.54), math.floor(MAX_PAX_NUMBER * 0.72))
        return
    end

    if passengerDistributionGroup < 58 then
        intendedPassengerNumber = math.random(math.floor(MAX_PAX_NUMBER * 0.72), math.floor(MAX_PAX_NUMBER * 0.87))
        return
    end

    intendedPassengerNumber = math.random(math.floor(MAX_PAX_NUMBER * 0.87), MAX_PAX_NUMBER)
end

local function startBoardingOrDeboarding()
    boardingPaused = false
    boardingActive = false
    boardingCompleted = false
    deboardingCompleted = false
    deboardingPaused = false
end

local function resetAllParameters()
    passengersBoarded = 0
    intendedPassengerNumber = 0
    boardingActive = false
    deboardingActive = false
    nextTimeBoardingCheck = os.time()
    boardingSpeedMode = 3
    if USE_SECOND_DOOR then
        secondsPerPassenger = 4
    else
        secondsPerPassenger = 6
    end
    jw1_connected = false
    boardingPaused = false
    deboardingPaused = false
    deboardingCompleted = false
    boardingCompleted = false
    isTobusWindowDisplayed = false
    isSettingsWindowDisplayed = false
end

-- frame loop, efficient coding please
function tobusBoarding()
    local now = os.time()

    if speak_string and now > wait_until_speak then
      XPLMSpeakString(speak_string)
      speak_string = nil
    end

    if boardingActive then
        if passengersBoarded < intendedPassengerNumber and now > nextTimeBoardingCheck then
            passengersBoarded = passengersBoarded + 1
            tls_no_pax[0] = passengersBoarded
            command_once("AirbusFBW/SetWeightAndCG")
            nextTimeBoardingCheck = os.time() + secondsPerPassenger + math.random(-2, 2)
        end

        if passengersBoarded == intendedPassengerNumber and not boardingCompleted then
            boardingCompleted = true
            boardingActive = false
            closeDoorsAfterBoarding(true)
            if not isTobusWindowDisplayed then
                buildTobusWindow()
            end
            playChimeSound(true)
        end

    elseif deboardingActive then
        if passengersBoarded > 0 and now >= nextTimeBoardingCheck then
            passengersBoarded = passengersBoarded - 1
            tls_no_pax[0] = passengersBoarded
            command_once("AirbusFBW/SetWeightAndCG")
            nextTimeBoardingCheck = os.time() + secondsPerPassenger + math.random(-2, 2)
        end

        if passengersBoarded == 0 and not deboardingCompleted then
            deboardingCompleted = true
            deboardingActive = false
            closeDoorsAfterBoarding(false)
            if not isTobusWindowDisplayed then
                buildTobusWindow()
            end
            playChimeSound(false)
        end
    end
end

function settings_toboolean(str)
    if str == nil then
        str = 'false'
    end
    local bool = false
    if str == "true" or str == true then
        bool = true
    end
    return bool
end


local function readSettings()
    local f = io.open(SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY..'/'..SETTINGS_FILENAME)
    if f == nil then return end

    f:close()
    local settings = LIP.load(SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY..'/'..SETTINGS_FILENAME)

    settings.simbrief = settings.simbrief or {}    -- for backwards compatibility
    settings.doors = settings.doors or {}
    settings.general = settings.general or {}

    if settings.simbrief.username ~= nil then
        SIMBRIEF_ACCOUNT_NAME = settings.simbrief.username
    end

    RANDOMIZE_SIMBRIEF_PASSENGER_NUMBER = settings_toboolean(settings.simbrief.randomizePassengerNumber)
    AUTO_FETCH_SIMBRIEF = settings_toboolean(settings.simbrief.auto_fetch)
    USE_SECOND_DOOR = settings_toboolean(settings.doors.useSecondDoor)
    CLOSE_DOORS = settings_toboolean(settings.doors.closeDoors)
    LEAVE_DOOR1_OPEN = settings_toboolean(settings.doors.leaveDoor1Open)
    LEAVE_DOOR1_OPEN_DEBOARD = settings_toboolean(settings.doors.leaveDoor1OpenDeboard)

    WINDOW_X  = tonumber(settings.general.x) or WINDOW_X
    WINDOW_Y  = tonumber(settings.general.y) or WINDOW_Y
    WINDOW_WIDTH  = tonumber(settings.general.width) or WINDOW_WIDTH
    WINDOW_HEIGHT  = tonumber(settings.general.height) or WINDOW_HEIGHT
    STARTUP_VIEW = settings_toboolean(settings.general.startup)
end

local function saveSettings()
    logMsg("tobus: saveSettings...")
    local newSettings = {}
    newSettings.general = {}
    newSettings.general.x = WINDOW_X
    newSettings.general.y = WINDOW_Y
    newSettings.general.width = WINDOW_WIDTH
    newSettings.general.height = WINDOW_HEIGHT
    newSettings.general.startup = STARTUP_VIEW

    newSettings.simbrief = {}
    newSettings.simbrief.username = SIMBRIEF_ACCOUNT_NAME
    newSettings.simbrief.randomizePassengerNumber = RANDOMIZE_SIMBRIEF_PASSENGER_NUMBER
    newSettings.simbrief.auto_fetch = AUTO_FETCH_SIMBRIEF

    newSettings.doors = {}
    newSettings.doors.useSecondDoor = USE_SECOND_DOOR
    newSettings.doors.closeDoors = CLOSE_DOORS
    newSettings.doors.leaveDoor1Open = LEAVE_DOOR1_OPEN
    newSettings.doors.leaveDoor1OpenDeboard = LEAVE_DOOR1_OPEN_DEBOARD

    LIP.save(SCRIPT_DIRECTORY..'/'..SETTINGS_DIRECTORY..'/'..SETTINGS_FILENAME, newSettings)
    logMsg("tobus file: done")
end

local function fetchData()
    if SIMBRIEF_ACCOUNT_NAME == nil then
      logMsg("No simbrief username has been configured")
      return false
    end

    local response, statusCode = http.request("http://www.simbrief.com/api/xml.fetcher.php?username=" .. SIMBRIEF_ACCOUNT_NAME)

    if statusCode ~= 200 then
      logMsg("Simbrief API is not responding")
      return false
    end

    local f = io.open(SCRIPT_DIRECTORY..SIMBRIEF_FLIGHTPLAN_FILENAME, "w")
    f:write(response)
    f:close()

    logMsg("Simbrief XML data downloaded")
    return true
end

local function readXML()
    local xfile = xml2lua.loadFile(SCRIPT_DIRECTORY..SIMBRIEF_FLIGHTPLAN_FILENAME)
    local parser = xml2lua.parser(handler)
    parser:parse(xfile)

    SIMBRIEF_FLIGHTPLAN["Status"] = handler.root.OFP.fetch.status

    if SIMBRIEF_FLIGHTPLAN["Status"] ~= "Success" then
      logMsg("XML status is not success")
      return false
    end

    intendedPassengerNumber = tonumber(handler.root.OFP.weights.pax_count)
    logMsg(string.format("intendedPassengerNumber: %d", intendedPassengerNumber))
    if RANDOMIZE_SIMBRIEF_PASSENGER_NUMBER then
        local f = 0.01 * math.random(92, 103) -- lua 5.1: random take integer args!
	    intendedPassengerNumber = math.floor(intendedPassengerNumber * f)
        if intendedPassengerNumber > MAX_PAX_NUMBER then intendedPassengerNumber = MAX_PAX_NUMBER end
        logMsg(string.format("randomized intendedPassengerNumber: %d", intendedPassengerNumber))
    end
end


-- init random
math.randomseed(os.time())

if not SUPPORTS_FLOATING_WINDOWS then
    -- to make sure the script doesn't stop old FlyWithLua versions
    logMsg("imgui not supported by your FlyWithLua version")
    return
end


if PLANE_ICAO == "A319" then
    MAX_PAX_NUMBER = 145
elseif PLANE_ICAO == "A321" or PLANE_ICAO == "A21N" then
    local a321EngineType = get("AirbusFBW/EngineTypeIndex")
    if a321EngineType == 0 or a321EngineType == 1 then
        MAX_PAX_NUMBER = 220
    else
        MAX_PAX_NUMBER = 224
    end
elseif PLANE_ICAO == "A20N" then
    MAX_PAX_NUMBER = 188
elseif PLANE_ICAO == "A339" then
    MAX_PAX_NUMBER = 375
elseif PLANE_ICAO == "A346" then
    MAX_PAX_NUMBER = 440
end

logMsg(string.format("tobus: plane: %s, MAX_PAX_NUMBER: %d", PLANE_ICAO, MAX_PAX_NUMBER))

-- crete subfolder and first ini settings
createDirectoryIfNotExists()
createFileIfNotExists()
-- init gloabl variables
readSettings()

local function delayed_init()
    if tls_no_pax ~= nil then return end
    tls_no_pax = dataref_table("AirbusFBW/NoPax")
    passengerDoorArray = dataref_table("AirbusFBW/PaxDoorModeArray")
    cargoDoorArray = dataref_table("AirbusFBW/CargoDoorModeArray")
    resetAllParameters()
end

function tobusOnBuild(tobus_window, x, y)
    if boardingActive and not boardingCompleted then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF95FFF8)
        imgui.TextUnformatted(string.format("Boarding in progress %s / %s boarded", passengersBoarded, intendedPassengerNumber))
        imgui.PopStyleColor()
    end

    if deboardingActive and not deboardingCompleted then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF95FFF8)
        imgui.TextUnformatted(string.format("Deboarding in progress %s / %s deboarded", passengersBoarded, intendedPassengerNumber))
        imgui.PopStyleColor()
    end

    if boardingCompleted then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF43B54B)
        imgui.TextUnformatted("Boarding completed.")
        imgui.PopStyleColor()
    end

    if deboardingCompleted then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF87CEFA)
        imgui.TextUnformatted("Deboarding completed.")
        imgui.PopStyleColor()
    end

    if not (boardingActive or boardingPaused or deboardingActive or deboardingPaused or boardingCompleted or deboardingCompleted) then
        local pn = tls_no_pax[0]
        if not intended_no_pax_set or passengersBoarded ~= pn  then
            intendedPassengerNumber = pn
            passengersBoarded = pn
        end

        local passengeraNumberChanged, newPassengerNumber
        = imgui.SliderInt("Passengers number", intendedPassengerNumber, 0, MAX_PAX_NUMBER, "Value: %d")

        if passengeraNumberChanged then
            intendedPassengerNumber = newPassengerNumber
            intended_no_pax_set = true
        end

        if not boardingCompleted then
            if imgui.Button("Get from simbrief") then
                set("AirbusFBW/NoPax", 0)
                command_once("AirbusFBW/SetWeightAndCG")
                if fetchData() then
                    readXML()
                    intended_no_pax_set = true
                end
            end
            imgui.SameLine(155)
            if imgui.Button("Set random passenger number") then
                setRandomNumberOfPassengers()
                intended_no_pax_set = true
            end
            imgui.Separator()
        else
            imgui.Spacing()
        end
    end
    
    if not deboardingActive and deboardingPaused then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF95FFF8)
        imgui.TextUnformatted(string.format("Remaining passengers to deboard: %s / %s", passengersBoarded, intendedPassengerNumber))
        imgui.PopStyleColor()
    end

    if not boardingActive and boardingPaused then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFFFFD700)
        imgui.TextUnformatted(string.format("Remaining passengers to board: %s / %s", intendedPassengerNumber-passengersBoarded, intendedPassengerNumber))
        imgui.PopStyleColor()
    end

    if boardingCompleted then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFFFFD700)
        imgui.TextUnformatted(string.format("Passenger Onboard N. %s", passengersBoarded))
        imgui.PopStyleColor()
    end

    if not boardingActive and not deboardingActive and not boardingPaused then

        if not deboardingPaused and not boardingCompleted and intendedPassengerNumber > 0 and not deboardingCompleted then
            if imgui.Button("Start Boarding") then
                set("AirbusFBW/NoPax", 0)
                set("AirbusFBW/PaxDistrib", math.random(35, 60) / 100)
                passengersBoarded = 0
                startBoardingOrDeboarding()
                boardingActive = true
                nextTimeBoardingCheck = os.time()
                openDoorsForBoarding()
                if boardingSpeedMode == 1 then
                    boardInstantly()
                else
                    logMsg(string.format("start boarding with %0.1f s/pax", secondsPerPassenger))
                end
            end
        end

        if not boardingPaused and boardingCompleted then
            if imgui.Button("Start Deboarding") then
                passengersBoarded = intendedPassengerNumber
                startBoardingOrDeboarding()
                deboardingActive = true
                nextTimeBoardingCheck = os.time()
                openDoorsForBoarding()
                if boardingSpeedMode == 1 then
                    deboardInstantly()
                end
            end
        end
    end

    if boardingActive then
        imgui.SameLine()
        if imgui.Button("Pause Boarding") then
            boardingActive = false
            boardingPaused = true
            boardingInformationMessage = "Boarding paused."
        end
    elseif boardingPaused then
        imgui.SameLine()
        if imgui.Button("Resume Boarding") then
            boardingActive = true
            boardingPaused = false
            if boardingSpeedMode == 1 then
                boardInstantly()
            end
        end
    end

    if deboardingActive then
        imgui.SameLine()
        if imgui.Button("Pause Deboarding") then
            deboardingActive = false
            deboardingPaused = true
        end
    elseif deboardingPaused then
        imgui.SameLine()
        if imgui.Button("Resume Deboarding") then
            deboardingActive = true
            deboardingPaused = false
            if boardingSpeedMode == 1 then
                deboardInstantly()
            end
        end
    end

    if boardingPaused or deboardingPaused or boardingCompleted or deboardingCompleted then
        local txt_btn = "Flight completed! Reset"
        if not deboardingCompleted then
            imgui.SameLine()
            txt_btn = "Reset"
        end
        
        if imgui.Button(txt_btn) then
            set("AirbusFBW/NoPax", 0)
            command_once("AirbusFBW/SetWeightAndCG")
            resetAllParameters()
            closeDoorsAfterBoarding(false)
        end
    end

    if not boardingActive and not deboardingActive and not deboardingCompleted then
        if imgui.RadioButton("Instant", boardingSpeedMode == 1) then
            boardingSpeedMode = 1
        end

        local fastModeMinutes, realModeMinutes, label, spp

        jw1_connected = (opensam_door_status ~= nil and opensam_door_status[1] == 1)
        if jw1_connected then
            if not USE_SECOND_DOOR then
                imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF43B54B)
                imgui.TextUnformatted("A second jetway is connected, using both doors")
                imgui.PopStyleColor()
            end
        end

        -- fast mode
        if USE_SECOND_DOOR or jw1_connected then
            spp = 2
        else
            spp = 3
        end

        fastModeMinutes = math.floor((intendedPassengerNumber * spp) / 60 + 0.5)
        if fastModeMinutes ~= 0 then
            label = string.format("Fast (%d minutes)", fastModeMinutes)
        else
            label = "Fast (less than a minute)"
        end

        if imgui.RadioButton(label,boardingSpeedMode == 2) then
            boardingSpeedMode = 2
        end

        if boardingSpeedMode == 2 then  -- regardless whether the button was changed or not
            secondsPerPassenger = spp
        end

        -- real mode
        if USE_SECOND_DOOR or jw1_connected then
            spp = 4
        else
            spp = 6
        end

        realModeMinutes = math.floor((intendedPassengerNumber * spp) / 60 + 0.5)
        if realModeMinutes ~= 0 then
            label = string.format("Real (%d minutes)", realModeMinutes)
        else
            label = "Real (less than a minute)"
        end

        if imgui.RadioButton(label, boardingSpeedMode == 3) then
            boardingSpeedMode = 3
        end

        if boardingSpeedMode == 3 then
            secondsPerPassenger = spp
        end
    end

    imgui.Separator()

    if imgui.TreeNode("Settings") then
        imgui.TextUnformatted("SimBrief:")
        local changed, newval
        changed, newval = imgui.InputText("Simbrief Username", SIMBRIEF_ACCOUNT_NAME, 255)
        if changed then
            SIMBRIEF_ACCOUNT_NAME = newval
        end

        changed, newval = imgui.Checkbox("Simulate some passengers not showing up after simbrief import",
                                         RANDOMIZE_SIMBRIEF_PASSENGER_NUMBER)
        if changed then
            RANDOMIZE_SIMBRIEF_PASSENGER_NUMBER = newval
        end

        changed, newval = imgui.Checkbox("Auto Fetch from simbrief at startup",
                                         AUTO_FETCH_SIMBRIEF)
        if changed then
            AUTO_FETCH_SIMBRIEF = newval
        end

        imgui.Dummy(0, 10)
        imgui.TextUnformatted("Doors:")
        changed, newval = imgui.Checkbox(
            "Use front and back door for boarding and deboarding (only front door by default)", USE_SECOND_DOOR)
        if changed then
            USE_SECOND_DOOR = newval
            logMsg("USE_SECOND_DOOR set to " .. tostring(USE_SECOND_DOOR))
        end

        changed, newval = imgui.Checkbox(
            "Close doors after boarding/deboading", CLOSE_DOORS)
        if changed then
            CLOSE_DOORS = newval
            logMsg("CLOSE_DOORS set to " .. tostring(CLOSE_DOORS))
        end

        changed, newval = imgui.Checkbox(
            "Leave door1 open after boarding", LEAVE_DOOR1_OPEN)
        if changed then
            LEAVE_DOOR1_OPEN = newval
            logMsg("LEAVE_DOOR1_OPEN set to " .. tostring(LEAVE_DOOR1_OPEN))
        end

        changed, newval = imgui.Checkbox(
            "Leave door1 open after deboading", LEAVE_DOOR1_OPEN_DEBOARD)
        if changed then
            LEAVE_DOOR1_OPEN_DEBOARD = newval
            logMsg("LEAVE_DOOR1_OPEN_DEBOARD set to " .. tostring(LEAVE_DOOR1_OPEN_DEBOARD))
        end

        imgui.Dummy(0, 10)
        imgui.TextUnformatted("General:")
        changed, newval = imgui.Checkbox(
            "Show TOBUS at startup", STARTUP_VIEW)
        if changed then
            STARTUP_VIEW = newval
            logMsg("STARTUP_VIEW set to " .. tostring(STARTUP_VIEW))
        end

        if imgui.Button("Save Settings") then
            saveSettings()
        end
        imgui.TreePop()
    end
end

local winCloseInProgess = false

function tobusOnClose()
    isTobusWindowDisplayed = false
    winCloseInProgess = false
end

function buildTobusWindow()
    delayed_init()

    if (isTobusWindowDisplayed) then
        return
    end
	tobus_window = float_wnd_create(WINDOW_WIDTH, WINDOW_HEIGHT, 1, true)

    -- local leftCorner, height, width = XPLMGetScreenBoundsGlobal()

    float_wnd_set_position(tobus_window, WINDOW_X, WINDOW_Y)
	float_wnd_set_title(tobus_window, "TOBUS - Your Toliss Boarding Companion " .. VERSION)
	float_wnd_set_imgui_builder(tobus_window, "tobusOnBuild")
    float_wnd_set_onclose(tobus_window, "tobusOnClose")

    isTobusWindowDisplayed = true
end

function showTobusWindow()
    if isTobusWindowDisplayed then
        if not winCloseInProgess then
            winCloseInProgess = true
            float_wnd_destroy(tobus_window) -- marks for destroy, destroy is async
        end
        return
    end

    buildTobusWindow()
end

add_macro("TOBUS - Your Toliss Boarding Companion", "buildTobusWindow()")
create_command("FlyWithLua/TOBUS/Toggle_tobus", "Show TOBUS window", "showTobusWindow()", "", "")
do_every_frame("tobusBoarding()")
readSettings()
if STARTUP_VIEW then
    showTobusWindow()
end
if AUTO_FETCH_SIMBRIEF then
    set("AirbusFBW/NoPax", 0)
    command_once("AirbusFBW/SetWeightAndCG")
    if fetchData() then
        readXML()
        intended_no_pax_set = true
    end
end
end
