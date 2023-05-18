-- expects version 1.6.6 of basalt
 
SCREEN_PROTOCOL_FILTER = 'ELEVATOR_SCREEN'
PROTOCOL_FILTER = 'ELEVATOR'
MODEM_FACE = 'FRONT'
MONITOR_FACE = 'BOTTOM'
 
local basalt = require('basalt')
 
rednet.open(MODEM_FACE)
local mon = peripheral.wrap(MONITOR_FACE)
mon.setTextScale(0.5)
 
local floors = {}
local buttons = {}
local monitorFrame = basalt.createFrame():setMonitor({[1]={MONITOR_FACE}})
 
local function callToFloor(floorNumber)
    local messageToSend = {
        floor = floorNumber,
        requesting = true
    }
    rednet.broadcast(textutils.serialiseJSON(messageToSend), PROTOCOL_FILTER)
end
 
local function updateButtons()
    -- clear existing buttons
    for i = 1, #buttons, 1 do
        buttons[i]:remove()
    end
 
    for i = 1, #floors, 1 do
        local currButton = monitorFrame
            :addButton()
            :setSize('parent.w - 2', 3  )
            :setPosition(2 , (i - 1) * 3 + 2 )
            :setText(floors[i])
            :setBorder(colors.black, "bottom")
            :onClick(function() callToFloor(floors[i]) end)
        table.insert(buttons, currButton)
    end
end
 
local function listen()
    while true do
        local _, message = rednet.receive(SCREEN_PROTOCOL_FILTER)
        message = textutils.unserialiseJSON(message)
        floors = message
        updateButtons()
        sleep(2)
    end
end
 
parallel.waitForAll(basalt.autoUpdate, listen)