--[[

 ▄▄▄██▀▀▀ ██▓ ███▄ ▄███▓ ▄▄▄▄   ▓█████  ▄▄▄       ███▄ ▄███▓▓█████▄  ██▓ ▄▄▄       ▄▄▄▄    ██▓     ▒█████
   ▒██   ▓██▒▓██▒▀█▀ ██▒▓█████▄ ▓█   ▀ ▒████▄    ▓██▒▀█▀ ██▒▒██▀ ██▌▓██▒▒████▄    ▓█████▄ ▓██▒    ▒██▒  ██▒
   ░██   ▒██▒▓██    ▓██░▒██▒ ▄██▒███   ▒██  ▀█▄  ▓██    ▓██░░██   █▌▒██▒▒██  ▀█▄  ▒██▒ ▄██▒██░    ▒██░  ██▒
▓██▄██▓  ░██░▒██    ▒██ ▒██░█▀  ▒▓█  ▄ ░██▄▄▄▄██ ▒██    ▒██ ░▓█▄   ▌░██░░██▄▄▄▄██ ▒██░█▀  ▒██░    ▒██   ██░
 ▓███▒   ░██░▒██▒   ░██▒░▓█  ▀█▓░▒████▒ ▓█   ▓██▒▒██▒   ░██▒░▒████▓ ░██░ ▓█   ▓██▒░▓█  ▀█▓░██████▒░ ████▓▒░
 ▒▓▒▒░   ░▓  ░ ▒░   ░  ░░▒▓███▀▒░░ ▒░ ░ ▒▒   ▓▒█░░ ▒░   ░  ░ ▒▒▓  ▒ ░▓   ▒▒   ▓▒█░░▒▓███▀▒░ ▒░▓  ░░ ▒░▒░▒░
 ▒ ░▒░    ▒ ░░  ░      ░▒░▒   ░  ░ ░  ░  ▒   ▒▒ ░░  ░      ░ ░ ▒  ▒  ▒ ░  ▒   ▒▒ ░▒░▒   ░ ░ ░ ▒  ░  ░ ▒ ▒░
 ░ ░ ░    ▒ ░░      ░    ░    ░    ░     ░   ▒   ░      ░    ░ ░  ░  ▒ ░  ░   ▒    ░    ░   ░ ░   ░ ░ ░ ▒
 ░   ░    ░         ░    ░         ░  ░      ░  ░       ░      ░     ░        ░  ░ ░          ░  ░    ░ ░
                              ░                              ░                          ░

    JBSelectUtils[B42] by jimbeamdiablo
    This a WIP. Any errors should fail gracefully.

]]


JBSelectUtils = {
    stagingSquare = nil,
    endX = nil,
    endY = nil,
    startX = nil,
    startY = nil,
    doMouseMarker = false,
    currentMouseSquare = nil,
    selectedArea = {},
}

Events.OnCreatePlayer.Add(function()
    if getPlayer():getModData().highlightColorData then
        JBSelectUtils.highlightColorData = getPlayer():getModData().highlightColorData
    else
        JBSelectUtils.highlightColorData = { red = 0.2, green = 0.5, blue = 0.7 }
        getPlayer():getModData().highlightColorData = JBSelectUtils.highlightColorData
    end
end)

LuaEventManager.AddEvent("OnSelectArea")
LuaEventManager.AddEvent("OnSelectSquare")
LuaEventManager.AddEvent("OnPickedWindow")

-- change highlight color
-- todo: show a square under player that changes colors on mousehover
JBSelectUtils.doPickColor = function(_, playerObj)
    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local buttonSize = FONT_HGT_SMALL + 6
    local borderSize = 11
    local x = (getCore():getScreenWidth() / 4) - (14 * buttonSize + borderSize * 2) / 2
    local y = (getCore():getScreenHeight() / 3) - (6 * buttonSize + borderSize * 2) / 2

    local ui = ISColorPicker:new(x, y)
    ui:initialise()
    ui:addToUIManager()
    ui:setPickedFunc(function()
        local color = ui.colors[ui.index]
        getPlayer():getModData().highlightColorData = { red = color.r, green = color.g, blue = color.b }
        JBSelectUtils.highlightColorData = { red = color.r, green = color.g, blue = color.b }
    end)
end


---@param getStagingFlag boolean
JBSelectUtils.selectArea = function(getStagingFlag)
    Events.OnTick.Add(JBSelectUtils.update)
    JBSelectUtils.doMouseMarker = true
    JBSelectUtils.selectedArea = {}
    JBSelectUtils.stagingSquare = nil
    if getStagingFlag then
        Events.OnMouseUp.Add(JBSelectUtils.setStagingSquare)
    else
        Events.OnMouseDown.Add(JBSelectUtils.getFirstClick)
    end
end


JBSelectUtils.getSingleSquare = function()
    JBSelectUtils.doMouseMarker = true
    Events.OnMouseUp.Add(JBSelectUtils.setSingleSquare)
    Events.OnTick.Add(JBSelectUtils.update)
end


JBSelectUtils.setSingleSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    local sq = getSquare(x, y, getPlayer():getZ())
    if JBSelectUtils.isValidSquare(sq) then
        Events.OnMouseUp.Remove(JBSelectUtils.setSingleSquare)
        Events.OnTick.Remove(JBSelectUtils.update)
        triggerEvent("OnSelectSquare", sq)
        JBSelectUtils.doMouseMarker = false
        JBSelectUtils.reset()
    end
end


JBSelectUtils.highlightSquare = function(square)
    local x, y, z
    if not square then
        x, y = luautils.round(JBSelectUtils.getMouseSquare():getX(), 0), luautils.round(JBSelectUtils.getMouseSquare():getY(), getPlayer():getZ())
        z = getPlayer():getZ()
    else
        x, y = square:getX(), square:getY()
        z = square:getZ()
    end
    addAreaHighlight(x, y, x + 1, y + 1, z, JBSelectUtils.highlightColorData.red, JBSelectUtils.highlightColorData.green, JBSelectUtils.highlightColorData.blue, 0)
end

JBSelectUtils.isValidSquare = function(sq)
    local gsq = getCell():getGridSquare(sq:getX(), sq:getY(), sq:getZ())
    if sq:TreatAsSolidFloor() and sq:isFree(false) then
        local dirs = { gsq, gsq:getN(), gsq:getS(), gsq:getE(), gsq:getW() }
        for _, square in ipairs(dirs) do
            if square:HasStairs() then
                return false
            end
        end
        return true
    end
    return false
end


JBSelectUtils.setStagingSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    local sq = getSquare(x, y, getPlayer():getZ())
    if JBSelectUtils.isValidSquare(sq) then
        JBSelectUtils.stagingSquare = sq
        Events.OnMouseUp.Remove(JBSelectUtils.setStagingSquare)
        Events.OnMouseDown.Add(JBSelectUtils.getFirstClick)
    end
end

JBSelectUtils.pickWindow = function()
    local OnTickfunc
    local OnMouseClickFunc
    local window

    OnMouseClickFunc = function() -- OnMouseDown function
        if IsoObjectPicker.Instance:PickWindow(getMouseX(), getMouseY()) then
            window = IsoObjectPicker.Instance:PickWindow(getMouseX(), getMouseY())
            window:setOutlineHighlight(false)
            triggerEvent("OnPickedWindow", window)
            --print("got a window")
            Events.OnMouseDown.Remove(OnMouseClickFunc)
            Events.OnTick.Remove(OnTickfunc)
            return
        end
    end

    OnTickfunc = function() -- OnTick function

        if not IsoObjectPicker.Instance:PickWindow(getMouseX(), getMouseY()) then
            Events.OnMouseDown.Remove(OnMouseClickFunc)
            if window then
                window:setOutlineHighlight(false)
            end            
            return
        end

        window = IsoObjectPicker.Instance:PickWindow(getMouseX(), getMouseY())

        if not window:isOutlineHighlight() then
            window:setOutlineHighlight(true)
            Events.OnMouseDown.Add(OnMouseClickFunc)
        end
    end

    Events.OnTick.Add(OnTickfunc)

end


JBSelectUtils.getFirstClick = function()
    JBSelectUtils.doMouseMarker = false
    JBSelectUtils.startX, JBSelectUtils.startY = JBSelectUtils.getMouseWorldCoords()
    Events.OnMouseDown.Remove(JBSelectUtils.getFirstClick)
    Events.OnMouseMove.Add(JBSelectUtils.highlightArea)
    Events.OnMouseUp.Add(JBSelectUtils.getSecondClick)
end


JBSelectUtils.highlightArea = function()
    Events.OnMouseMove.Remove(JBSelectUtils.highlightSquare)
    JBSelectUtils.endX, JBSelectUtils.endY = JBSelectUtils.getMouseWorldCoords()
    local minX, maxX = math.min(JBSelectUtils.startX, JBSelectUtils.endX),
        math.max(JBSelectUtils.startX, JBSelectUtils.endX)
    local minY, maxY = math.min(JBSelectUtils.startY, JBSelectUtils.endY),
        math.max(JBSelectUtils.startY, JBSelectUtils.endY)
    for x = minX, maxX do
        for y = minY, maxY do
            local r, g, b = JBSelectUtils.highlightColorData.red, JBSelectUtils.highlightColorData.green, JBSelectUtils.highlightColorData.blue
            local z = getPlayer():getZ()
            addAreaHighlight(minX, minY, maxX + 1, maxY + 1, z, r, g, b, 0)
        end
    end
end


JBSelectUtils.getSecondClick = function()
    JBSelectUtils.endX, JBSelectUtils.endY = JBSelectUtils.getMouseWorldCoords()
    Events.OnMouseMove.Remove(JBSelectUtils.highlightArea)
    Events.OnMouseUp.Remove(JBSelectUtils.getSecondClick)
    local minX, maxX = math.min(JBSelectUtils.startX, JBSelectUtils.endX),
        math.max(JBSelectUtils.startX, JBSelectUtils.endX)
    local minY, maxY = math.min(JBSelectUtils.startY, JBSelectUtils.endY),
        math.max(JBSelectUtils.startY, JBSelectUtils.endY)
    for x = minX, maxX do
        for y = minY, maxY do
            local square = getSquare(x, y, getPlayer():getZ())
            table.insert(JBSelectUtils.selectedArea, square)
        end
    end
    Events.OnTick.Remove(JBSelectUtils.update)

    triggerEvent("OnSelectArea", JBSelectUtils.stagingSquare, JBSelectUtils.sortTable(JBSelectUtils.selectedArea))
    JBSelectUtils.reset()
end


---@param selectedSquares table
---@return table
JBSelectUtils.sortTable = function(selectedSquares)
    local sortedSquares = {}
    local posX, posY = getPlayer():getX(), getPlayer():getY()
    while #selectedSquares > 0 do
        local tableIndex = 1
        local bigDistance = math.huge
        for i, square in ipairs(selectedSquares) do
            local curDistance = IsoUtils.DistanceTo(square:getX(), square:getY(), posX, posY)
            if curDistance < bigDistance then
                bigDistance = curDistance
                tableIndex = i
            end
        end
        posX, posY = selectedSquares[tableIndex]:getX(), selectedSquares[tableIndex]:getY()
        table.insert(sortedSquares, selectedSquares[tableIndex])
        table.remove(selectedSquares, tableIndex)
    end
    return sortedSquares
end


JBSelectUtils.reset = function()
    Events.OnTick.Remove(JBSelectUtils.update)
    Events.OnMouseMove.Remove(JBSelectUtils.highlightArea)
    Events.OnMouseUp.Remove(JBSelectUtils.getSecondClick)
    Events.OnMouseDown.Remove(JBSelectUtils.getFirstClick)
    Events.OnMouseUp.Remove(JBSelectUtils.setStagingSquare)
    JBSelectUtils.endX = nil
    JBSelectUtils.endY = nil
    JBSelectUtils.startX = nil
    JBSelectUtils.startY = nil
    JBSelectUtils.currentMouseSquare = nil
    JBSelectUtils.doMouseMarker = false
    JBSelectUtils.selectedArea = {}
    JBSelectUtils.stagingSquare = false
end

JBSelectUtils.update = function()
    local player = getPlayer()

    if not JBSelectUtils.testValid(player) then
        JBSelectUtils.reset()
        return
    end

    JBSelectUtils.currentMouseSquare = JBSelectUtils.getMouseSquare()

    if JBSelectUtils.stagingSquare then
        local x, y = JBSelectUtils.stagingSquare:getX(), JBSelectUtils.stagingSquare:getY()
        local z = getPlayer():getZ()
        JBSelectUtils.highlightSquare(JBSelectUtils.stagingSquare)
    end

    if JBSelectUtils.doMouseMarker then
        JBSelectUtils.highlightSquare(JBSelectUtils.currentMouseSquare)
    end
end


---@param player IsoPlayer
---@return boolean
JBSelectUtils.testValid = function(player)
    if instanceof(player, "IsoPlayer") then
        if JBSelectUtils.stagingSquare and player:getZ() > 0 then return false end
        if player:getVehicle() or player:isRunning() or player:isSprinting() or player:pressedCancelAction() then return false end
    end
    return true
end


JBSelectUtils.getMouseWorldCoords = function()
    local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
    x, y = math.floor(x), math.floor(y)
    return x, y
end


JBSelectUtils.getMouseScreenCoords = function()
    local x, y = ISCoordConversion.ToScreen(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
    x, y = math.floor(x), math.floor(y)
    return x, y
end


JBSelectUtils.getMouseSquare = function()
    local x, y = JBSelectUtils.getMouseWorldCoords()
    local square = getSquare(x, y, getPlayer():getZ())
    if not square then
        for z = getPlayer():getZ()+1, 0, -1 do
            square = getSquare(x, y, z)
            if square then 
                return square
            end
        end
    end
    return square
end

return JBSelectUtils