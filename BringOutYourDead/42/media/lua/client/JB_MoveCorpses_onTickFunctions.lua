-- JB_MoveCorpses_onTickFunctions.lua
-- main logic and speed keeper

JB_MoveCorpses = JB_MoveCorpses or {}

-- reset game speed if you wanted it to
local function resetGameSpeed()
    if JB_MoveCorpses.oldOptionTimedActionGameSpeedReset then
        setGameSpeed(1)
        getGameTime():setMultiplier(1)
    end
    getCore():setOptionTimedActionGameSpeedReset(JB_MoveCorpses.oldOptionTimedActionGameSpeedReset)
end

JB_MoveCorpses.doMarker = function()
    JB_MoveCorpses.dirMarker = getWorldMarkers():addPlayerHomingPoint(JB_MoveCorpses.playerObj,
        JB_MoveCorpses.nextCorpse:getSquare():getX(), JB_MoveCorpses.nextCorpse:getSquare():getY(), "arrow_triangle", 1,
        1, 1, 0.6, true, 20)
    JB_MoveCorpses.dirMarker:setRenderHeight(32)
    JB_MoveCorpses.dirMarker:setRenderWidth(32);
    JB_MoveCorpses.dirMarker:setActive(false)
end

-- show/hide arrow based on distance to ded
JB_MoveCorpses.showMarker = function()
    if JB_MoveCorpses.playerObj:getSquare():DistTo(JB_MoveCorpses.nextCorpse:getSquare()) > 2 then
        JB_MoveCorpses.dirMarker:setActive(true)
        return
    end
    -- needs a fade out over maybe 20 ticks
    JB_MoveCorpses.dirMarker:setActive(false)
end

-- init and clean up
JB_MoveCorpses.Reset = function()
    JB_MoveCorpses.newAnimState = nil
    JB_MoveCorpses.oldAnimState = nil
    JB_MoveCorpses.donePickedUpBody = nil
    JB_MoveCorpses.pickingUp = nil
    JB_MoveCorpses.doneDroppingBody = nil
    JB_MoveCorpses.droppingOff = nil
    JB_MoveCorpses.corpsesToMove = nil
    JB_MoveCorpses.firstActionDone = nil
    JB_MoveCorpses.nextCorpse = nil
    JB_MoveCorpses.movingCorpses = false
    JB_MoveCorpses.justThrowThemOutTheWindow = false
    if JB_MoveCorpses.dirMarker then
        getWorldMarkers():removeAllHomingPoints(JB_MoveCorpses.playerObj)
    end
    if JB_MoveCorpses.playerObj:isGrappling() then
        JB_MoveCorpses.playerObj:setDoGrappleLetGo()
    end

    resetGameSpeed()
end

-- the madness
JB_MoveCorpses.ProcessOnTick = function(tick)
    
    -- find a reason to stop the madness
    if instanceof(JB_MoveCorpses.playerObj, "IsoPlayer") then

        -- got some zambalambs, do we care?
        if JB_MoveCorpses.safetyToggle then
            if JB_MoveCorpses.playerObj:getStats():getNumVisibleZombies() > 0 or
                JB_MoveCorpses.playerObj:getStats():getNumChasingZombies() > 0 or
                JB_MoveCorpses.playerObj:getStats():getNumVeryCloseZombies() > 0 then
                -- aww shit
                local say = getText("UI_JB_MoveCorpses_Annoyed_By_The_Dead")
                JB_MoveCorpses.playerObj:Say(tostring(say))

                -- clear the actions queues and reset so player can deal with it
                ISTimedActionQueue.clear(JB_MoveCorpses.playerObj)
                JB_MoveCorpses.Reset()
                Events.OnTick.Remove(JB_MoveCorpses.ProcessOnTick)
                return
            end
        end

        -- you pushed a key? why?
        if JB_MoveCorpses.playerObj:pressedMovement(false) or JB_MoveCorpses.playerObj:pressedCancelAction() then
            JB_MoveCorpses.Reset()
            Events.OnTick.Remove(JB_MoveCorpses.ProcessOnTick)
            return
        end

        if JB_MoveCorpses.playerObj:isGrappling() and (isAltKeyDown() or isShiftKeyDown()) then
            ISTimedActionQueue.clear(JB_MoveCorpses.playerObj)
            JB_MoveCorpses.Reset()
            Events.OnTick.Remove(JB_MoveCorpses.ProcessOnTick)
        end
    end

    -- we check the player animation state and compare it to the previous animation state
    -- to keep track of what the player is doing on any given tick
    JB_MoveCorpses.newAnimState = getPlayer():getAnimationStateName()

    -- init the oldAnimState on the first tick
    if JB_MoveCorpses.oldAnimState == nil then
        JB_MoveCorpses.oldAnimState = JB_MoveCorpses.newAnimState
    end

    -- pops the anim state to the command window if it changes
    --[[ if JB_MoveCorpses.oldAnimState ~= JB_MoveCorpses.newAnimState then
        print(JB_MoveCorpses.newAnimState)
    end ]]

    if JB_MoveCorpses.newAnimState == "pickUpBody" then
        --print("Skip along, cowboy")
        return
    end

    -- if we've been draggingBody for only 1 tick, we are ready to move to the stagingSquare
    -- else 2+ ticks means we're dragging this body already
    if luautils.stringStarts(JB_MoveCorpses.newAnimState, "draggingBody") then
        if luautils.stringStarts(JB_MoveCorpses.oldAnimState, "draggingBody") then
            JB_MoveCorpses.donePickedUpBody = false
        else
            JB_MoveCorpses.donePickedUpBody = true
            JB_MoveCorpses.pickingUp = false
        end
    end

    -- if we were layDownBody and now we're not layDownBody, then we're done dropping the corpse
    -- else we're still in the process of layDownBody
    if JB_MoveCorpses.oldAnimState == "layDownBody" and JB_MoveCorpses.newAnimState ~= "layDownBody" then
        JB_MoveCorpses.doneDroppingBody = true
        JB_MoveCorpses.droppingOff = false
    else
        JB_MoveCorpses.doneDroppingBody = false
    end

    -- save the animState so we can compare the next tick
    JB_MoveCorpses.oldAnimState = JB_MoveCorpses.newAnimState

    -- if we have a stagingsquare then highlight it
    if JB_MoveCorpses.stagingSquare then
        local x, y, z = JB_MoveCorpses.stagingSquare:getX(), JB_MoveCorpses.stagingSquare:getY(),
            JB_MoveCorpses.stagingSquare:getZ()
        addAreaHighlight(x, y, x + 1, y + 1, z, JBSelectUtils.highlightColorData.red,
            JBSelectUtils.highlightColorData.green, JBSelectUtils.highlightColorData.blue, 0)
    end

    -- if corpsesToMove hasn't been initted, wait
    if not JB_MoveCorpses.corpsesToMove then
        return
    end

    -- if this is the first run, queue the first pickup
    -- this should only fire once
    if not JB_MoveCorpses.firstActionDone then
        getCore():setOptionTimedActionGameSpeedReset(false)
        JB_MoveCorpses.firstActionDone = true
        JB_MoveCorpses.pickingUp = true
        JB_MoveCorpses.nextCorpse = table.remove(JB_MoveCorpses.corpsesToMove)
        JB_MoveCorpses.doMarker()
        ISWorldObjectContextMenu.onGrabCorpseItem(nil, JB_MoveCorpses.nextCorpse, JB_MoveCorpses.playerNum)
    end

    --if you have a corpse then
    if JB_MoveCorpses.nextCorpse then
        JB_MoveCorpses.showMarker()
        local hx, hy, hz = JB_MoveCorpses.stagingSquare:getX(), JB_MoveCorpses.stagingSquare:getY(),
            JB_MoveCorpses.stagingSquare:getZ()
        addAreaHighlight(hx, hy, hx + 1, hy + 1, hz, JBSelectUtils.highlightColorData.red,
            JBSelectUtils.highlightColorData.green, JBSelectUtils.highlightColorData.blue, 0)
    end

    -- check if you lost the corpse somewhere
    if JB_MoveCorpses.playerObj:isGrappling() and JB_MoveCorpses.droppingOff then
        local player = JB_MoveCorpses.playerObj
        local target = JB_MoveCorpses.playerObj:getGrapplingTarget()

        --addAreaHighlight(target:getX(), target:getY(),target:getX() + 1, target:getY() + 1, target:getZ(), 1, 1, 1, 0)
        --addAreaHighlight(player:getX(), player:getY(), player:getX() + 1, player:getY() + 1, player:getZ(), .5, .2, 1, 0)


        if player:getSquare() ~= target:getSquare() then
            local px, py = math.abs(player:getX()), math.abs(target:getY())
            local tx, ty = math.abs(player:getX()), math.abs(target:getY())
            local pz, tz = math.abs(player:getZ()), math.abs(target:getZ())
            
            if px - tx > 1 or py - ty > 2 or pz - tz > 0 then
                JB_MoveCorpses.Reset()
                --print("Corpse and player ARE NOTTTTTTT NEAR EACH OTHER whyyyy")
                --print("X: " .. px - tx .. "  Y: " .. py - ty .. "  Z: " .. pz - tz)
            end
        end
    end

    -- player has finished laying the body down, we can grab a new body and commence a pickup
    if JB_MoveCorpses.doneDroppingBody then
        --print("getting another body...")
        JB_MoveCorpses.pickingUp = true

        if #JB_MoveCorpses.corpsesToMove == 0 then
            --print("No more bodies!")
            JB_MoveCorpses.Reset()
            JB_MoveCorpses.movingCorpses = false
            Events.OnTick.Remove(JB_MoveCorpses.ProcessOnTick)
            return
        elseif #JB_MoveCorpses.corpsesToMove > 0 then
            --print("finding the next corpse")
            JB_MoveCorpses.nextCorpse = table.remove(JB_MoveCorpses.corpsesToMove)
            getWorldMarkers():removeAllHomingPoints(JB_MoveCorpses.playerObj)
            JB_MoveCorpses.doMarker()
        end

        ISWorldObjectContextMenu.onGrabCorpseItem(nil, JB_MoveCorpses.nextCorpse, JB_MoveCorpses.playerNum)

        return
    end

    -- player has finshed picking up a body, we can commence a drop off
    if JB_MoveCorpses.donePickedUpBody then
        JB_MoveCorpses.droppingOff = true

        getWorldMarkers():removeAllHomingPoints(JB_MoveCorpses.playerObj)

        -- do a normal drop corpse
        --print("Dropping off a body...")
        local locations = {}
        table.insert(locations, JB_MoveCorpses.stagingSquare:getX())
        table.insert(locations, JB_MoveCorpses.stagingSquare:getY())
        table.insert(locations, JB_MoveCorpses.stagingSquare:getZ())
        local drop = ISWalkToTimedAction:new(JB_MoveCorpses.playerObj, JB_MoveCorpses.stagingSquare)
        --local drop = ISPathFindAction:pathToNearest(JB_MoveCorpses.playerObj, locations)
        drop:setOnComplete(function()
            --print("Dropping Complete")
            JB_MoveCorpses.playerObj:setDoGrappleLetGo()
        end)
        ISTimedActionQueue.add(drop)

        return
    end
end