REDSTONE_CONTACT_FACE = 'BACK'
PROTOCOL_FILTER = 'ELEVATOR'
MODEM_FACE = 'TOP'
SETUP_PROTOCOL_FILTER = 'ELEVATOR_SETUP'
IS_TOP = false
IS_BOTTOM = false
COMPUTER_ID = os.getComputerID()
HOST_NAME = 'BRAIN'

local floor = nil

-- setup
local function setup()
    rednet.open(MODEM_FACE)
    CONTROLLER_ID = rednet.lookup(SETUP_PROTOCOL_FILTER, HOST_NAME)
    if not CONTROLLER_ID then
        print('Controller not found. Aborting...')
        return false
    end
    
    local finishSetup = false
    while not finishSetup do
        local isContacting = redstone.getInput(REDSTONE_CONTACT_FACE)
        print('not contacting')
        if isContacting then
            print('contacting')
            local messageToSend = {
                computerId = COMPUTER_ID,
                isBottom = IS_BOTTOM,
                isTop = IS_TOP
            }
            rednet.send(CONTROLLER_ID, textutils.serialiseJSON(messageToSend), SETUP_PROTOCOL_FILTER)
            print('waiting for message')
            local senderId, message = rednet.receive(SETUP_PROTOCOL_FILTER)
            message = textutils.unserialiseJSON(message)
            print(textutils.serialise(message))
            if message.setFloor then
                finishSetup = true
                floor = message.setFloor
            end
        end
        sleep(0.05)
    end
    return true
end



-- loop
local function loop()
    print('loop')
    while true do
        local isContacting = redstone.getInput(REDSTONE_CONTACT_FACE)
        if isContacting then
            local messageToSend = {
                floor = floor,
                requesting = false,
                elevatorIsAtFloor = true
            }
            rednet.send(CONTROLLER_ID, textutils.serialiseJSON(messageToSend), PROTOCOL_FILTER)
        end
        sleep(0.05)
    end
end

if setup() then
    loop()
end