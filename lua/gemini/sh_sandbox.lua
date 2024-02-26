--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Sandbox Module
----------------------------------------------------------------------------]]--

Gemini:AddHook("PlayerDeath", function(ply)
    if IsValid(ply) then
        ply.__LAST_DEATH = CurTime()
    end
end)

Gemini:AddHook("PlayerEnteredVehicle", function(ply, veh)
    if IsValid(ply) then
        ply.__LAST_VEHICLE = CurTime()
        ply.__LAST_VEHICLE_NAME = veh.PrintName or veh:GetClass()
    end
end)

Gemini:AddHook("PostGamemodeLoaded", function()
    timer.Create("Gemini:CheckPlayerInVehicle", 15, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:InVehicle() then
                hook.Run("PlayerOnVehicle", ply)
            end
        end
    end)
end)

local ListPlayerUse = {}
Gemini:AddHook("PlayerUse", function(ply, ent)
    if not IsValid(ent) then return end
    if not ListPlayerUse[ply] then
        ListPlayerUse[ply] = ent
        hook.Run("OnPlayerStartUseEntity", ply, ent)
    end
end)

Gemini:AddHook("Think", function()
    for _, ply in ipairs(ListPlayerUse) do
        -- Check if their eyetrace is hitting the same entity
        if IsValid(ply) and IsValid(ListPlayerUse[ply]) then
            local tr = ply:GetEyeTrace()
            if not tr.Entity or tr.Entity ~= ListPlayerUse[ply] then
                ListPlayerUse[ply] = nil
                hook.Run("OnPlayerStopUseEntity", ply, ListPlayerUse[ply])
            end
        else
            ListPlayerUse[ply] = nil
        end
    end
end)