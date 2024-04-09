--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Sandbox Module
----------------------------------------------------------------------------]]--

Gemini:HookAdd("PlayerDeath", function(ply)
    if IsValid(ply) then
        ply.__LAST_DEATH = CurTime()
    end
end)

Gemini:HookAdd("PlayerEnteredVehicle", function(ply, veh)
    if IsValid(ply) then
        ply.__LAST_VEHICLE = CurTime()
        ply.__LAST_VEHICLE_NAME = veh.PrintName or veh:GetClass()
    end
end)

Gemini:HookAdd("PostGamemodeLoaded", function()
    timer.Create("Gemini:CheckPlayerInVehicle", 15, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:InVehicle() then
                hook.Run("PlayerOnVehicle", ply)
            end
        end
    end)
end)

Gemini:HookAdd("PostCleanupMap", function()
    for _, ply in ipairs(player.GetAll()) do
        ply.__LAST_VEHICLE = nil
        ply.__LAST_VEHICLE_NAME = nil

        local Log = Gemini:GetPhrase("PostCleanupMap")

        hook.Run("Gemini.Log", Log, ply)
    end
end)

local GamemodeName = engine.ActiveGamemode()
Gemini:HookAdd("PreGamemodeLoaded", function()
    hook.Run("Gemini.Log", string.format( Gemini:GetPhrase("PreGamemodeLoaded"), GamemodeName ), Gemini.LoggerServerID)
end)

Gemini:HookAdd("OnGamemodeLoaded", function()
    hook.Run("Gemini.Log", string.format( Gemini:GetPhrase("OnGamemodeLoaded"), GamemodeName ), Gemini.LoggerServerID)
end)

Gemini:HookAdd("PostGamemodeLoaded", function()
    hook.Run("Gemini.Log", string.format( Gemini:GetPhrase("PostGamemodeLoaded"), GamemodeName ), Gemini.LoggerServerID)
end)