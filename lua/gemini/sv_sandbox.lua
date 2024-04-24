--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Sandbox Module
----------------------------------------------------------------------------]]--

hook.Add("PlayerDeath", "Gemini:PlayerDeath", function(ply)
    if IsValid(ply) then
        ply.__LAST_DEATH = CurTime()
    end
end)

hook.Add("PlayerEnteredVehicle", "Gemini:PlayerEnteredVehicle", function(ply, veh)
    if IsValid(ply) then
        ply.__LAST_VEHICLE = CurTime()
        ply.__LAST_VEHICLE_NAME = veh.PrintName or veh:GetClass()
    end
end)

hook.Add("PostGamemodeLoaded", "Gemini:PostGamemodeLoaded", function()
    timer.Create("Gemini:CheckPlayerInVehicle", 15, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:InVehicle() then
                hook.Run("PlayerOnVehicle", ply)
            end
        end
    end)
end)

hook.Add("PostCleanupMap", "Gemini:PostCleanupMap", function()
    for _, ply in ipairs(player.GetAll()) do
        ply.__LAST_VEHICLE = nil
        ply.__LAST_VEHICLE_NAME = nil

        local Log = Gemini:GetPhrase("PostCleanupMap")

        hook.Run("Gemini.Log", Log, ply)
    end
end)