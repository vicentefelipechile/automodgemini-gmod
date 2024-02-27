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