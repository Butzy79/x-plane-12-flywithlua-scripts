-- ****************************************************************************
-- X-PLANE AIRCRAFT SEATBELT SIGN COMPATIBILITY FOR SELF-LOADING CARGO!
-- ****************************************************************************
-- 
-- Written by Ricky S. (Manta32). 
-- Questions? Email: info@panthila.ch
-- Take inspiration from script made by Steve Woods (FPVSteve) for SeatBelts
-- Visit www.selfloadingcargo.com to find out more.
-- 
-- SUPPLIED WITHOUT WARRANTY OR GUARANTEE OF OPERATION.
-- ****************************************************************************
-- IMPORTANT - THERE IS A PREREQUISITE BIT OF PREP FOR THIS TO WORK!
-- ****************************************************************************
-- 1:
-- Please copy the entirety of this script into:
-- ~\YourXplaneFolder\Resources\Plugins\FlyWithLUA\Scripts
-- 2:
-- Please copy and paste the following four lines of code to the BOTTOM of your 
-- XPUIPCOffsets.cfg file in your xplane/resources/plugins/xpuipc folder, then 
-- remove the "-- " characters from the start of each line).
--
-- vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
-- 
-- # SELF-LOADING CARGO DOORS
-- # Declarations of all doors datarefs
-- Dataref A20NDoorStatus sim/cockpit2/switches/canopy_open int
-- Offset    0x3367    UINT8    1    rw    $A20NDoorStatus
--
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--
-- That's it!!
-- Enjoy your working doors for Toolis with SLC in your X-Plane aircraft :)
-- ****************************************************************************
-- DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING!
-- HERE BE DRAGONS! MIND YOUR HEAD! HIDDEN VERGE! ABANDON HOPE! IT'S A TRAP!
-- ****************************************************************************

dataref("baseDoorOpenDataRefs", "sim/cockpit2/switches/canopy_open", "writeable")
define_shared_DataRef("FlyWithLua/TolissA20NDoors", "Int")
dataref("DoorMonitor", "FlyWithLua/TolissA20NDoors", "writable")


function checkDoorStatus()

    local aircraft = {
        ["A319"] = function()   -- for Toliss A319
            local ToolisDoorValues = dataref_table("AirbusFBW/PaxDoorModeArray")
            DoorMonitor = 0

            for i = 0, 3 do
                if ToolisDoorValues[i] == 2 then
                    DoorMonitor = DoorMonitor + (2 ^ i)
                end
            end
        end,
        ["A20N"] = function()   -- for Toliss A320 NEO (A20N)
            local ToolisDoorValues = dataref_table("AirbusFBW/PaxDoorModeArray")
            DoorMonitor = 0

            for i = 0, 3 do
                if ToolisDoorValues[i] == 2 then
                    DoorMonitor = DoorMonitor + (2 ^ i)
                end
            end
        end,
        ["A321"] = function()   -- for Toliss A321
            local ToolisDoorValues = dataref_table("AirbusFBW/PaxDoorModeArray")
            DoorMonitor = 0

            for i = 0, 3 do
                if ToolisDoorValues[i] == 2 then
                    DoorMonitor = DoorMonitor + (2 ^ i)
                end
            end
        end,
        ["A333"] = function()   -- for Toliss A333
            local ToolisDoorValues = dataref_table("AirbusFBW/PaxDoorModeArray")
            DoorMonitor = 0

            for i = 0, 3 do
                if ToolisDoorValues[i] == 2 then
                    DoorMonitor = DoorMonitor + (2 ^ i)
                end
            end
        end,
        ["A339"] = function()   -- for Toliss A339
            local ToolisDoorValues = dataref_table("AirbusFBW/PaxDoorModeArray")
            DoorMonitor = 0

            for i = 0, 3 do
                if ToolisDoorValues[i] == 2 then
                    DoorMonitor = DoorMonitor + (2 ^ i)
                end
            end
        end,
        ["A346"] = function()   -- for Toliss A340-600
            local ToolisDoorValues = dataref_table("AirbusFBW/PaxDoorModeArray")
            DoorMonitor = 0

            for i = 0, 3 do
                if ToolisDoorValues[i] == 2 then
                    DoorMonitor = DoorMonitor + (2 ^ i)
                end
            end
        end,
    }
    
    local actionableAircraftResult = aircraft[PLANE_ICAO]
    if (actionableAircraftResult) then
        --  We found a aircraft that we recognise, run the associated method.
        actionableAircraftResult()
    end

    if baseDoorOpenDataRefs ~= DoorMonitor then
        baseDoorOpenDataRefs = DoorMonitor
    end
    -- *******************************************************  
end



do_often("checkDoorStatus()")
