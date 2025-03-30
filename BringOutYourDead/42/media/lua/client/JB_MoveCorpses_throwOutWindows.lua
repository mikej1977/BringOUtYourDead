-- JB_MoveCorpses_throwOutWindows
-- thow them fuckers out the nearest window

JB_MoveCorpses = JB_MoveCorpses or {}

-- check for windows
local function checkForWindow(square)
    local south = square:getS()
    local east = square:getE()
    local window
    if square:getWindow() then
        window = square:getWindow()
    elseif square:isWindowTo(south) then
        window = south:getWindow()
    elseif square:isWindowTo(east) then
        window = east:getWindow()
    end
    if instanceof(window, "IsoWindow") then
        return window
    end
    return nil
end

----    get a window, get corpses, pile corpses in front of window, open window if needed, chuck them out one by one


JB_MoveCorpses.throwOutWindow = function(window)
    Events.OnPickedWindow.Remove(JB_MoveCorpses.throwOutWindow)
    JB_MoveCorpses.playerObj = getPlayer()
    JB_MoveCorpses.playerNum = getPlayer():getPlayerNum()
    JB_MoveCorpses.pickedWindow = window
    JB_MoveCorpses.justThrowThemOutTheWindow = true    -- we gon chuck em

    -- if window square is inside a building, YAY otherwise, check north and west squares for the YAY
    if JB_MoveCorpses.pickedWindow then
        if JB_MoveCorpses.pickedWindow:getSquare():getBuilding() then
            JB_MoveCorpses.stagingSquare = JB_MoveCorpses.pickedWindow:getSquare()
        else
            local n = JB_MoveCorpses.pickedWindow:getSquare():getN()
            local w = JB_MoveCorpses.pickedWindow:getSquare():getW()
            if n:getBuilding() then
                JB_MoveCorpses.stagingSquare = n
            elseif w:getBuilding() then
                JB_MoveCorpses.stagingSquare = w
            else
                --print("awww fuckin shit")
            end
        
        end
    end

    local buildingSquares = {}

    -- this isn't how any of this works (stay in the building duh)
    if not JB_MoveCorpses.playerObj:getBuilding() then
        JB_MoveCorpses.Reset()
        return
    end

    local rooms = JB_MoveCorpses.playerObj:getCurrentBuildingDef():getRooms()
    for i = 0, rooms:size() - 1 do
        local room = rooms:get(i)
        if room then
            local roomSquares = room:getIsoRoom():getSquares()
            for h = 0, roomSquares:size() - 1 do
                table.insert(buildingSquares, roomSquares:get(h))
            end
        end
    end

    -- get basement squares if they exist
    if JB_MoveCorpses.playerObj:getSquare():getChunk():getMinLevel() < 0 then
        for _, sq in ipairs(buildingSquares) do
            local undergroundSquare = getSquare(sq:getX(), sq:getY(), sq:getZ() - 1)
            if undergroundSquare and undergroundSquare:getRoom() then
                table.insert(buildingSquares, undergroundSquare)
            end
        end
    end

    JB_MoveCorpses.corpsesToMove = {}
    for _, square in ipairs(buildingSquares) do
        local deadzeds = square:getDeadBodys()
        for i = 0, deadzeds:size() - 1 do
            local deadzed = deadzeds:get(i)
            if square:getDeadBody() and not square:getDeadBody():isAnimal() then
                table.insert(JB_MoveCorpses.corpsesToMove, deadzed)
            end
        end
    end

    JB_MoveCorpses.startDraggingThemDedZeds()

end
