--[[------------------------
       Spanish phrases
------------------------]]--

local LANG = Gemini:CreateLanguage("Spanish")

Gemini:AddPhrase(LANG, "DoPlayerDeath", [[El jugador "%" fue asesinado en las coordendas %s por "%" usando %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawn", [[El jugador "%" ha respawneado, han pasado %s segundos desde su muerte.]])

Gemini:OverrideHookLanguage(LANG, {
    ["DoPlayerDeath"] = function(victim, attacker, weapon)
        return {victim:Name(), victim:GetPos(), attacker:Name(), weapon:GetClass()}
    end,
    ["PlayerSpawn"] = function(ply, time)
        return {ply:Name(), ply.__LAST_DEATH and ( CurTime() - ply.__LAST_DEATH )}
    end
})

--[[------------------------
            Hooks
------------------------]]--

hook.Add("PlayerDeath", "Gemini_PlayerDeath", function(ply)
    if IsValid(ply) then
        ply.__LAST_DEATH = CurTime()
    end
end)