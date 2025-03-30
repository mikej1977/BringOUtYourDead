-- outdoor dorpses functions
-- JB_MoveCorpses_outdoorCorpses.lua

JB_MoveCorpses = JB_MoveCorpses or {}

JB_MoveCorpses.getOutdoorCorpses = function(stagingSquare, selectedSquares)
    -- set up some oft used variables that won't change
    JB_MoveCorpses.playerObj = getPlayer()
    JB_MoveCorpses.playerNum = getPlayer():getPlayerNum()
    JB_MoveCorpses.stagingSquare = stagingSquare
    Events.OnSelectArea.Remove(JB_MoveCorpses.getOutdoorCorpses)
    if not selectedSquares then return end

    if stagingSquare:getCampfire() then
        local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(stagingSquare)
        if campfire.isLit then
            return
        end
    end

    -- check for deds on square
    JB_MoveCorpses.corpsesToMove = {}
    for _, square in ipairs(selectedSquares) do
        local deadzeds = square:getDeadBodys()
        for i = 0, deadzeds:size() - 1 do
            local deadzed = deadzeds:get(i)
            if square:getDeadBody() and not square:getDeadBody():isAnimal() then
                table.insert(JB_MoveCorpses.corpsesToMove, deadzed)
            end
        end
    end

    -- no corpseses, nope out
    if #JB_MoveCorpses.corpsesToMove == 0 then
        JB_MoveCorpses.Reset()
        return
    end

    -- let's get this party started
    JB_MoveCorpses.startDraggingThemDedZeds()

end