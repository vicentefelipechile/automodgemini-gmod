--[[------------------------
       Spanish phrases
------------------------]]--

local function GetEntityName(ent)
    if ent:IsWorld() then
        return "el mundo"
    elseif ent:IsPlayer() then
        return ent:Name()
    elseif ent:IsNPC() then
        return GAMEMODE:GetDeathNoticeEntityName(ent)
    else
        return ent:GetClass()
    end
end

local LANG = Gemini:CreateLanguage("Spanish")

Gemini:AddPhrase(LANG, "DoPlayerDeath", [[El jugador "%s" fue asesinado por "%s" en las coordendas %s usando %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawn", [[El jugador "%s" ha respawneado, han pasado %s segundos desde su muerte.]])
Gemini:AddPhrase(LANG, "PlayerInitialSpawn", [[El jugador "%s" ha conectado al servidor.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedEffect", [[El jugador "%s" ha creado el efecto "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedNPC", [[El jugador "%s" ha creado el npc "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedProp", [[El jugador "%s" ha creado el prop "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedRagdoll", [[El jugador "%s" ha creado un ragdoll "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedSENT", [[El jugador "%s" ha creado una entidad "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerGiveSWEP", [[El jugador "%s" se ha sacado el arma "%s" del menu.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedVehicle", [[El jugador "%s" ha colocado un auto "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "OnDamagedByExplosion", [[El jugador "%s" ha recibido %s de daño por una explosion.]])
Gemini:AddPhrase(LANG, "PlayerHurt", [[El jugador "%s" ha recibido %s de daño por "%s" y ahora tiene %s de vida.]])
Gemini:AddPhrase(LANG, "PlayerChangedTeam", [[El jugador "%s" ha cambiado de equipo/trabajo a "%s" (antes era "%s").]])
Gemini:AddPhrase(LANG, "OnCrazyPhysics", [[Se ha detectado fisicas locas en la entidad "%s", esta entidad %s dueño%s.]])

local DamageType = {
    [-1]            = "algo que no se puede determinar",
    [6144]          = "el suicidio",
    [DMG_GENERIC]   = "un daño generico o los puños",
    [DMG_CRUSH]     = "un daño por aplastamiento",
    [DMG_BULLET]    = "un daño por un arma o centinela",
    [DMG_SLASH]     = "un daño por un NPC o ataque cuerpo a cuerpo",
    [DMG_BURN]      = "el fuego",
    [DMG_VEHICLE]   = "un auto",
    [DMG_FALL]      = "la gravedad (basicamente se cayo)",
    [DMG_BLAST]     = "una explosión",
    [DMG_CLUB]      = "un arma cuerpo a cuerpo",
    [DMG_SHOCK]     = "la electricidad",
    [DMG_SONIC]     = "un daño por sonido",
    [DMG_ENERGYBEAM]    = "un rayo de energia",
    [DMG_PREVENT_PHYSICS_FORCE] = "una fuerza fisica (le pegaron una piña fuerte)",
    [DMG_NEVERGIB]  = "un daño que no lo hace explotar",
    [DMG_ALWAYSGIB] = "un daño que lo hace explotar",
    [DMG_DROWN]     = "el agua para quitarle el oxigeno",
    [DMG_PARALYZE]  = "un quimico paralizante",
    [DMG_NERVEGAS]  = "un gas de neurotoxina",
    [DMG_POISON]    = "un veneno",
    [DMG_ACID]      = "un acido",
    [DMG_SLOWBURN]  = "un fuego lento",
    [DMG_REMOVENORAGDOLL]       = "una muerte silenciosa",
    [DMG_PHYSGUN]   = "la pistola antigravedad",
    [DMG_PLASMA]    = "un daño por plasma",
    [DMG_AIRBOAT]   = "el airboat",
    [DMG_DISSOLVE]  = "una bola de energia (lo desintegraron)",
    [DMG_BLAST_SURFACE]     = "una explosion en la superficie",
    [DMG_DIRECT]    = "un daño directo",
    [DMG_BUCKSHOT]  = "una escopeta",
    [DMG_SNIPER]    = "un rifle de francotirador",
    [DMG_MISSILEDEFENSE]    = "un misil",
}

Gemini:OverrideHookLanguage(LANG, {
    ["DoPlayerDeath"] = function(victim, attacker, dmg)
        local DmgType = DamageType[dmg:GetDamageType()] or DamageType[-1]
        local AttackerName = ( attacker == victim ) and "el mismo" or GetEntityName(attacker)
        local VictimPos = victim:GetPos()

        local Coordinates = string.format("(%s, %s, %s)", math.Round(VictimPos.x, 2), math.Round(VictimPos.y, 2), math.Round(VictimPos.z, 2))

        return {victim:Name(), AttackerName, Coordinates, DmgType}
    end,
    ["PlayerSpawn"] = function(ply, time)
        return {ply:Name(), math.Round(ply.__LAST_DEATH and CurTime() - ply.__LAST_DEATH or 0, 2)}
    end,
    ["PlayerInitialSpawn"] = function(ply)
        return {ply:Name()}
    end,
    ["PlayerSpawnedEffect"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), model, string.format("(%s, %s, %s)", math.Round(EntPos.x, 2), math.Round(EntPos.y, 2), math.Round(EntPos.z, 2))}
    end,
    ["PlayerSpawnedNPC"] = function(ply, npc)
        local EntPos = npc:GetPos()
        return {ply:Name(), npc, string.format("(%s, %s, %s)", math.Round(EntPos.x, 2), math.Round(EntPos.y, 2), math.Round(EntPos.z, 2))}
    end,
    ["PlayerSpawnedProp"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), model, string.format("(%s, %s, %s)", math.Round(EntPos.x, 2), math.Round(EntPos.y, 2), math.Round(EntPos.z, 2))}
    end,
    ["PlayerSpawnedRagdoll"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), model, string.format("(%s, %s, %s)", math.Round(EntPos.x, 2), math.Round(EntPos.y, 2), math.Round(EntPos.z, 2))}
    end,
    ["PlayerSpawnedSENT"] = function(ply, sent)
        local EntPos = sent:GetPos()
        return {ply:Name(), sent, string.format("(%s, %s, %s)", math.Round(EntPos.x, 2), math.Round(EntPos.y, 2), math.Round(EntPos.z, 2))}
    end,
    ["PlayerGiveSWEP"] = function(ply, wpn, swep)
        return {ply:Name(), swep.PrintName or wpn}
    end,
    ["PlayerSpawnedVehicle"] = function(ply, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), ent:GetClass(), string.format("(%s, %s, %s)", math.Round(EntPos.x, 2), math.Round(EntPos.y, 2), math.Round(EntPos.z, 2))}
    end,
    ["OnDamagedByExplosion"] = function(ply, dmg)
        return {ply:Name(), dmg:GetDamage()}
    end,
    ["PlayerHurt"] = function(ply, attacker, remaininghealth, damagetaken)
        local AttackerName = ( attacker == ply ) and "el mismo" or GetEntityName(attacker)
        return {ply:Name(), damagetaken, AttackerName, remaininghealth}
    end,
    ["PlayerChangedTeam"] = function(ply, newteam, oldteam)
        return {ply:Name(), team.GetName(newteam), team.GetName(oldteam)}
    end,
    ["OnCrazyPhysics"] = function(ent, physobj)
        local Owner = NULL
        if CPPI then
            Owner = ent:CPPIGetOwner()
        elseif ent.Getowning_ent then
            Owner = ent:Getowning_ent()
        end

        return {ent:GetClass(), IsValid(Owner) and Owner:IsPlayer() and Owner:Name() or "no tiene", IsValid(Owner) and Owner:IsPlayer() and (", su dueño es " .. Owner:Name()) or ""}
    end,
})