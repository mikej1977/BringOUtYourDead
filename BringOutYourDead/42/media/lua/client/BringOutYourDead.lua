JB_MoveCorpses = JB_MoveCorpses or {}

-- NOTES:
-- trasnslation file DONE kind of
-- getting stuck dragging a body? Yes, but why?

-- unequip yo shit
local function unequipHandItems(playerObj)
    if playerObj:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50))
    end
    if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50))
    end
end

-- do you have a digging device?
local function predicateDigGrave(item)
    return not item:isBroken() and item:hasTag("DigGrave")
end

-- set up the menu
local function doWorldContextMenu(playerIndex, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    if test then return ISWorldObjectContextMenu.setTest() end
    local playerObj = getSpecificPlayer(playerIndex)
    if playerObj:getVehicle() or playerObj:isGrappling() then return end

    if JB_MoveCorpses.movingCorpses or JBSelectUtils.doMouseMarker then
        Events.OnTick.Remove(JB_MoveCorpses.ProcessOnTick)
        Events.OnTick.Remove(JB_MoveCorpses.OnTickKeepSpeed)
        JB_MoveCorpses.Reset()
        JBSelectUtils.reset()
    end

    local function checkForBody()
        local corpse = nil
        local mouseCorpe = IsoObjectPicker.Instance:PickCorpse(getMouseX(), getMouseY())
        if worldObjects then
            for _, v in ipairs(worldObjects) do
                if v:getSquare() and v:getSquare():getDeadBody() and not v:getSquare():getDeadBody():isAnimal() then
                    corpse = true
                    break -- got a corpse, get out of here
                end
            end
        end
        return mouseCorpe or corpse
    end

    if checkForBody() then

        local shovel = playerObj:getInventory():getFirstEvalRecurse(predicateDigGrave)

        local mainMenu

        if context:getOptionFromName(getText("ContextMenu_Grab")) then
            mainMenu = context:insertOptionAfter(getText("ContextMenu_Grab"), getText("UI_JB_MoveCorpses_Main_Menu"),
                worldObjects, nil)
        else
            mainMenu = context:addOptionOnTop(getText("UI_JB_MoveCorpses_Main_Menu"), worldObjects, nil)
        end

        local subMenu = ISContextMenu:getNew(context)
        local sub

        -- Move Corpses To Square (outside)
        if not playerObj:getBuilding() then
            sub = subMenu:addOption(getText("UI_JB_MoveCorpses_Move"), worldObjects, JB_MoveCorpses.doMoveCorpses)
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip.description = getText("UI_JB_MoveCorpses_Tooltip_Outside")
            sub.toolTip = tooltip
        end

        -- Move Corpses To Square (inside)
        if playerObj:getBuilding() then -- and playerObj:getZ() == 0 then
            sub = subMenu:addOption(getText("UI_JB_MoveCorpses_Move"), worldObjects, JB_MoveCorpses.doMoveIndoorCorpses)
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip.description = getText("UI_JB_MoveCorpses_Tooltip_Indoors")
            sub.toolTip = tooltip
        end

        if JB_MoveCorpses.safetyToggle then
            sub = subMenu:addOption(getText("UI_JB_MoveCorpses_Toggle_Safety_Off"), worldObjects, JB_MoveCorpses.toggleSafety, false)
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip.description = getText("UI_JB_MoveCorpses_Tooltip_Toggle_Safety_Off")
            sub.toolTip = tooltip
            
        else
            sub = subMenu:addOption(getText("UI_JB_MoveCorpses_Toggle_Safety_On"), worldObjects, JB_MoveCorpses.toggleSafety, true)
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip.description = getText("UI_JB_MoveCorpses_Tooltip_Toggle_Safety_On")
            sub.toolTip = tooltip
        end

        sub = subMenu:addOption(getText("UI_JB_MoveCorpses_Change_Highlight_Color"), worldObjects, JBSelectUtils.doPickColor, playerObj)
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("UI_JB_MoveCorpses_Tooltip_Change_Highlight_Color")
        sub.toolTip = tooltip

        --sub = subMenu:addOption(getText("UI_JB_MoveCorpses_New_Version"), worldObjects, JB_MoveCorpses.newVersion)

        context:addSubMenu(mainMenu, subMenu)

    end
end

-- wait to get a table, reset variables and then move em
JB_MoveCorpses.doMoveCorpses = function()
    JBSelectUtils.selectArea(true)
    Events.OnSelectArea.Add(JB_MoveCorpses.getOutdoorCorpses)
    JB_MoveCorpses.oldOptionTimedActionGameSpeedReset = getCore():getOptionTimedActionGameSpeedReset()
end


JB_MoveCorpses.doMoveIndoorCorpses = function()
    JBSelectUtils.getSingleSquare()
    Events.OnSelectSquare.Add(JB_MoveCorpses.moveIndoorCorpses)
    JB_MoveCorpses.oldOptionTimedActionGameSpeedReset = getCore():getOptionTimedActionGameSpeedReset()
end


JB_MoveCorpses.startDraggingThemDedZeds = function()
    --unequipHandItems(JB_MoveCorpses.playerObj)
    -- fire up our main logic
    if getPlayer():isGrappling() then
        JBSelectUtils.reset()
        return
    end
    JB_MoveCorpses.movingCorpses = true
    Events.OnTick.Add(JB_MoveCorpses.ProcessOnTick)
end

JB_MoveCorpses.toggleSafety = function(_, toggle)
    JB_MoveCorpses.safetyToggle = toggle
    getPlayer():getModData().safetyToggle = toggle
    --print("Safety is set to " .. tostring(toggle))
end

JB_MoveCorpses.newVersion = function()
    luautils.okModal(getText("UI_JB_MoveCorpses_New_Version_Modal"), true)
end

Events.OnFillWorldObjectContextMenu.Add(doWorldContextMenu)

Events.OnCreatePlayer.Add(function()
    if getPlayer():getModData().safetyToggle ~= nil then
        JB_MoveCorpses.safetyToggle = getPlayer():getModData().safetyToggle
        --print("Using modData safety toggle " .. tostring(JB_MoveCorpses.safetyToggle))
    else
        JB_MoveCorpses.safetyToggle = true
        getPlayer():getModData().safetyToggle = JB_MoveCorpses.safetyToggle
        --print("Using default true safety toggle " .. tostring(JB_MoveCorpses.safetyToggle))
    end
end)


return JB_MoveCorpses -- always return the whole. damn. thing.