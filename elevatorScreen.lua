SCREEN_PROTOCOL_FILTER = 'ELEVATOR_SCREEN'
MODEM_FACE = 'FRONT'

rednet.open(MODEM_FACE)
local floors = {}

local function getFloorsAsString(floors)
    local str = ""
    for key, _ in pairs(floors) do
        str = str .. ', '.. key
    end
    return str
end

local function loop()
    while true do
        print(string.format('Please enter a floor: %s', getFloorsAsString(floors)))
        local selected = tonumber(read())
        if floors[selected] then
            local messageToSend = {
                floor = selected,
                requesting = true
            }
            rednet.broadcast(textutils.serialiseJSON(messageToSend), SCREEN_PROTOCOL_FILTER)
        end
        sleep(0.05)
    end
end

local function listen()
    while true do
        local sender, message = rednet.receive(SCREEN_PROTOCOL_FILTER)
        message = textutils.unserialiseJSON(message)
        floors = {}
        for _, floor in pairs(message) do
            floors[floor] = true
        end
    end
end

parallel.waitForAll(loop, listen)

