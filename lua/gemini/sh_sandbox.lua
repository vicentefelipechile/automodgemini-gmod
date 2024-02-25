--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Sandbox Hooks
----------------------------------------------------------------------------]]--

Gemini:AddHook("PlayerDeath", function(ply)
    if IsValid(ply) then
        ply.__LAST_DEATH = CurTime()
    end
end)