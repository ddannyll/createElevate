MODEM_FACE = 'TOP'
CLUTCH_FACE = 'LEFT'
GEAR_SHIFT_FACE = 'RIGHT'
GEAR_SHIFT_ON_IS_UP = true
PROTOCOL_FILTER = 'ELEVATOR'
SETUP_PROTOCOL_FILTER = 'ELEVATOR_SETUP'
RESET_PROTOCOL_FILTER = 'ELEVATOR_RESET'
SCREEN_PROTOCOL_FILTER = 'ELEVATOR_SCREEN'
HOST_NAME = 'BRAIN'

local state = 'setup'
local currFloor = nil
local targetFloor = nil
local floors = {}
-- state can be idle, up, down

-- MAIN FUNCTIONS --


local function setup()
    print('setting up')
    floors = {}

    redstone.setOutput(GEAR_SHIFT_FACE, GEAR_SHIFT_ON_IS_UP)
    redstone.setOutput(CLUTCH_FACE, false)

    
    local foundTop = false
    while not foundTop do
        local senderId, message = rednet.receive(SETUP_PROTOCOL_FILTER)
        print(message)
        message = textutils.unserializeJSON(message)
        local senderIsTop = message.isTop
        if senderIsTop then
            foundTop = true
            redstone.setOutput(CLUTCH_FACE, true)
        end
    end

    -- from top to bottom -> go through every floor and assign them a floor number
    local curr = 0
    local foundBottom = false
    local prevComputer = nil
    redstone.setOutput(GEAR_SHIFT_FACE, not GEAR_SHIFT_ON_IS_UP)
    redstone.setOutput(CLUTCH_FACE, false)
    while not foundBottom do
        local senderId, message = rednet.receive(SETUP_PROTOCOL_FILTER)
        message = textutils.unserializeJSON(message)
        local computerId = message.computerId
        
        if computerId ~= prevComputer then
            local messageToSend = {
                setFloor = curr
            }
            table.insert(floors, curr)
            rednet.send(computerId, textutils.serialiseJSON(messageToSend), SETUP_PROTOCOL_FILTER)
            curr = curr - 1
        end

        local senderIsBottom = message.isBottom
        if senderIsBottom then
            foundBottom = true
            redstone.setOutput(CLUTCH_FACE, true)
        end
    end

    print(string.format('Finsihed Setup.\n Floors: %s', textutils.serialise(floors)))
end

local function listen ()
    while true do
        local senderId, message = rednet.receive(PROTOCOL_FILTER)
        print(message)
        message = textutils.unserializeJSON(message)
        local senderFloor = message.floor
        local senderIsRequesting = message.requesting
        local elevatorIsAtFloor = message.elevatorIsAtFloor
        if senderIsRequesting then
            targetFloor = senderFloor
        end
        if elevatorIsAtFloor then
            currFloor = senderFloor
        end
    end
end

local function resetListen ()
    while true do
        local senderId, message = rednet.receive(RESET_PROTOCOL_FILTER)
        print(string.format('received reset from %d', senderId))
        state = 'setup'
    end
end

local function loop()
    while true do
        if state == 'setup' then
            setup()
            state = 'idle'
        else
            if targetFloor and currFloor then
                if targetFloor == currFloor then
                    print('found floor')
                    state = 'idle'
                elseif targetFloor > currFloor then
                    state = 'up'
                elseif targetFloor < currFloor then
                    state = 'down'
                end
            end

            if state == 'idle' then
                redstone.setOutput(CLUTCH_FACE, true)
            elseif state == 'up' then
                redstone.setOutput(GEAR_SHIFT_FACE, GEAR_SHIFT_ON_IS_UP)
                redstone.setOutput(CLUTCH_FACE, false)
            else
                redstone.setOutput(GEAR_SHIFT_FACE, not GEAR_SHIFT_ON_IS_UP)
                redstone.setOutput(CLUTCH_FACE, false)
            end
            rednet.broadcast(textutils.serialiseJSON(floors), SCREEN_PROTOCOL_FILTER)
            sleep(0.05)
        end
    end
end

local function debugInput()
    if state == 'setup' then
        return
    end
    print('Available Debug Commands: idle, up, down, curr, target, resetTarget, setTarget')
    while true do
        local input = read()
        if input == 'idle' then
            state = 'idle'
        elseif input == 'up' then
            state = 'up'
        elseif input == 'down' then
            state = 'down'
        elseif input == 'target' then
            print(targetFloor)
        elseif input == 'resetTarget' then
            targetFloor = nil
        elseif input == 'curr' then
            print(currFloor)
        else
            print('unknown debug command')
        end
    end
end

rednet.open(MODEM_FACE)
rednet.host(PROTOCOL_FILTER, HOST_NAME)
rednet.host(SETUP_PROTOCOL_FILTER, HOST_NAME)
rednet.broadcast('reset', RESET_PROTOCOL_FILTER)
parallel.waitForAll(listen, loop, debugInput, resetListen)
-- HELPERS
