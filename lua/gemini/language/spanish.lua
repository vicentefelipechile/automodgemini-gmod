--[[------------------------
       Spanish phrases
------------------------]]--

local LANG = Gemini:CreateLanguage("Spanish")

Gemini:AddPhrase(LANG, "DoPlayerDeath", [[El jugador "%s" fue asesinado por "%s" en las coordendas %s usando %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawn", [[El jugador "%s" ha respawneado, han pasado %s segundos desde su muerte.]])

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
        local AttackerName = ( attacker == victim ) and "el mismo" or attacker:IsWorld() and "el mundo" or attacker:IsPlayer() and attacker:Name() or attacker:IsNPC() and GAMEMODE:GetDeathNoticeEntityName(attacker) or attacker:GetClass()
        local Coordinates = string.format("(%s, %s, %s)", math.Round(victim:GetPos().x, 2), math.Round(victim:GetPos().y, 2), math.Round(victim:GetPos().z, 2))

        return {victim:Name(), AttackerName, Coordinates, DmgType}
    end,
    ["PlayerSpawn"] = function(ply, time)
        return {ply:Name(), math.Round(ply.__LAST_DEATH and CurTime() - ply.__LAST_DEATH or 0, 2)}
    end
})