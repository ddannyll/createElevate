SCREEN_PROTOCOL_FILTER = 'ELEVATOR_SCREEN'
PROTOCOL_FILTER = 'ELEVATOR'
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
                requesting = true,
                elevatorIsAtFloor = false
            }
            rednet.broadcast(textutils.serialiseJSON(messageToSend), PROTOCOL_FILTER)
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

local function redstoneListen()
    while true do
        local selected = nil
        local minFloor = math.huge
        local maxFloor = -math.huge
        for k, v in pairs(floorsList) do
            if k < minFloor then
                minFloor = k
            end
            if k > maxFloor then
                maxFloor = k
            end
        end
        if redstone.getInput('left') then
            selected = minFloor
        end
        if redstone.getInput('right') then
            selected = maxFloor
        end
        if selected then
            local messageToSend = {
                floor = selected,
                requesting = true,
                elevatorIsAtFloor = false
            }
            rednet.broadcast(textutils.serialiseJSON(messageToSend), PROTOCOL_FILTER)
        end
    end

end

parallel.waitForAll(loop, listen, redstoneListen)

