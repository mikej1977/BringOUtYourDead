-- indoor corpses
-- JB_MoveCorpses_indoorCorpses.lua

JB_MoveCorpses = JB_MoveCorpses or {}

JB_MoveCorpses.moveIndoorCorpses = function(stagingSquare)
    JB_MoveCorpses.playerObj = getPlayer()
    JB_MoveCorpses.playerNum = getPlayer():getPlayerNum()
    JB_MoveCorpses.stagingSquare = stagingSquare
    Events.OnSelectSquare.Remove(JB_MoveCorpses.moveIndoorCorpses)
    local buildingSquares = {}
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
    if JB_MoveCorpses.playerObj:getSquare():getChunk():getMinLevel() < 0 then
        for _, sq in ipairs(buildingSquares) do
            local undergroundSquare = getSquare(sq:getX(), sq:getY(), sq:getZ() - 1)
            if undergroundSquare and undergroundSquare:getRoom() then
                table.insert(buildingSquares, undergroundSquare)
            end
        end
    end
    JB_MoveCorpses.corpsesToMove = {}
    local function theyAlreadyThere(corpseSquare)
        local ssq = JB_MoveCorpses.stagingSquare
        local target = corpseSquare

        local px, py = math.abs(ssq:getX()), math.abs(ssq:getY())
        local tx, ty = math.abs(target:getX()), math.abs(target:getY())
        local pz, tz = math.abs(ssq:getZ()), math.abs(target:getZ())
        local onAdjSquare = math.abs(px - tx) < 2 and math.abs(py - ty) < 2 and pz - tz == 0

        if ssq:DistTo(corpseSquare) < 1 and pz == tz then
            return true
        else
            return false
        end
    end
    for _, square in ipairs(buildingSquares) do
        local deadzeds = square:getDeadBodys()
        for i = 0, deadzeds:size() - 1 do
            local deadzed = deadzeds:get(i)
            if square:getDeadBody() and not square:getDeadBody():isAnimal() then
                if not theyAlreadyThere(square) then
                    table.insert(JB_MoveCorpses.corpsesToMove, deadzed)
                end
            end
        end
    end
    if #JB_MoveCorpses.corpsesToMove == 0 then
        JB_MoveCorpses.Reset()
        return
    end
    JB_MoveCorpses.startDraggingThemDedZeds()
end