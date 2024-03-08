--[[----------------------------------------------------------------------------
                         Google Gemini Automod - Spanish
----------------------------------------------------------------------------]]--

--[[------------------------
       Util Functions
------------------------]]--

local function GetEntityName(ent)
    if ent:IsWorld() then
        return "el mundo"
    elseif not IsValid(ent) then
        return "algo que ya no existe"
    elseif ent:IsPlayer() then
        return ent:Name()
    elseif ent:IsNPC() then
        return GAMEMODE:GetDeathNoticeEntityName(ent)
    else
        return ent.PrintName or ent:GetClass()
    end
end

--[[------------------------
          Language
------------------------]]--

local LANG = Gemini:CreateLanguage("Spanish")

Gemini:AddPhrase(LANG, "DoPlayerDeath", [[El jugador "%s" fue asesinado por "%s" en las coordendas %s usando %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawn", [[El jugador "%s" ha respawneado, han pasado %s segundos desde su muerte.]])
Gemini:AddPhrase(LANG, "PlayerInitialSpawn", [[El jugador "%s" ha conectado al servidor.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedEffect", [[El jugador "%s" ha creado el efecto "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedNPC", [[El jugador "%s" ha creado el npc "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedProp", [[El jugador "%s" ha creado el prop "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedRagdoll", [[El jugador "%s" ha creado un ragdoll "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedSENT", [[El jugador "%s" ha creado la entidad "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerGiveSWEP", [[El jugador "%s" se ha sacado el arma "%s" del menu.]])
Gemini:AddPhrase(LANG, "PlayerSpawnedVehicle", [[El jugador "%s" ha colocado un auto "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "OnDamagedByExplosion", [[El jugador "%s" ha recibido %s de daño por una explosion provocada por "%s".]])
Gemini:AddPhrase(LANG, "PlayerHurt", [[El jugador "%s" ha recibido %s de daño por "%s" y ahora tiene %s de vida.]])
Gemini:AddPhrase(LANG, "PlayerChangedTeam", [[El jugador "%s" ha cambiado de equipo/trabajo a "%s" (antes era "%s").]])
Gemini:AddPhrase(LANG, "OnCrazyPhysics", [[Se ha detectado fisicas locas en la entidad "%s", esta entidad %s dueño%s.]])
Gemini:AddPhrase(LANG, "PlayerEnteredVehicle", [[El jugador "%s" ha entrado al auto "%s" en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerLeaveVehicle", [[El jugador "%s" estuvo en el auto "%s" por %s segundos y ahora se fue del auto en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerOnVehicle", [[El jugador "%s" aun se encuentra en el auto "%s" pero ahora en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "VariableEdited", [[El jugador "%s" edito la entidad "%s" y cambio la variable "%s" a "%s".]])
Gemini:AddPhrase(LANG, "GravGunOnPickedUp", [[El jugador "%s" agarro la entidad "%s" con la pistola antigravedad en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "GravGunOnDropped", [[El jugador "%s" solto la entidad "%s" con la pistola antigravedad en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "OnPhysgunPickup", [[El jugador "%s" agarro la entidad "%s" con la pistola fisica en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PhysgunDrop", [[El jugador "%s" solto la entidad "%s" con la pistola fisica en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerSay", [[El jugador "%s" dijo "%s" cerca de %s en las coordenadas %s.]])
Gemini:AddPhrase(LANG, "PlayerDisconnected", [[El jugador "%s" se fue del servidor.]])
Gemini:AddPhrase(LANG, "PlayerSilentDeath", [[El jugador "%s" se murio silenciosamente.]])
Gemini:AddPhrase(LANG, "PostCleanupMap", [[El servidor ha limpiado el mapa, todas las entidades/props han sido eliminados y el jugador ha presenciado el evento.]])


--[[------------------------
            Hooks
------------------------]]--

local DamageType = {
    [-1]            = "algo que no se puede determinar",
    [4096 + 2]      = "la crossbow",
    [4096 + 2048]   = "el suicidio",
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
    [DMG_REMOVENORAGDOLL]   = "una muerte silenciosa",
    [DMG_PHYSGUN]   = "la pistola antigravedad",
    [DMG_PLASMA]    = "un daño por plasma",
    [DMG_AIRBOAT]   = "el airboat",
    [DMG_DISSOLVE]  = "una bola de energia (lo desintegraron)",
    [DMG_BLAST_SURFACE] = "una explosion en la superficie",
    [DMG_DIRECT]    = "un daño directo",
    [DMG_BUCKSHOT]  = "una escopeta",
    [DMG_SNIPER]    = "un rifle de francotirador",
    [DMG_MISSILEDEFENSE]    = "un misil",
}

Gemini:OverrideHookLanguage(LANG, {
    ["DoPlayerDeath"] = function(victim, attacker, dmg)
        local DmgType = DamageType[dmg:GetDamageType()] or dmg:GetAmmoType() and "una bala de " .. game.GetAmmoName(dmg:GetAmmoType()) or "algo que no se puede determinar"
        local AttackerName = ( attacker == victim ) and "el mismo" or GetEntityName(attacker)

        return {victim:Name(), AttackerName, Gemini:VectorToString(victim:GetPos()), DmgType}
    end,
    ["PlayerSpawn"] = function(ply, time)
        return {ply:Name(), math.Round(ply.__LAST_DEATH and CurTime() - ply.__LAST_DEATH or 0, 2)}
    end,
    ["PlayerInitialSpawn"] = function(ply)
        return {ply:Name()}
    end,
    ["PlayerSpawnedEffect"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), model, Gemini:VectorToString(EntPos)}
    end,
    ["PlayerSpawnedNPC"] = function(ply, npc)
        local EntPos = npc:GetPos()
        return {ply:Name(), GAMEMODE:GetDeathNoticeEntityName(npc), Gemini:VectorToString(EntPos)}
    end,
    ["PlayerSpawnedProp"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), model, Gemini:VectorToString(EntPos)}
    end,
    ["PlayerSpawnedRagdoll"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), model, Gemini:VectorToString(EntPos)}
    end,
    ["PlayerSpawnedSENT"] = function(ply, sent)
        local EntPos = sent:GetPos()
        return {ply:Name(), GetEntityName(sent), Gemini:VectorToString(EntPos)}
    end,
    ["PlayerGiveSWEP"] = function(ply, wpn, swep)
        return {ply:Name(), swep.PrintName or wpn}
    end,
    ["PlayerSpawnedVehicle"] = function(ply, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), ent:GetClass(), Gemini:VectorToString(EntPos)}
    end,
    ["OnDamagedByExplosion"] = function(ply, dmg)
        return {ply:Name(), math.Round(dmg:GetDamage(), 2), dmg:GetAttacker() == ply and "el mismo" or GetEntityName(dmg:GetAttacker())}
    end,
    ["PlayerHurt"] = function(ply, attacker, remaininghealth, damagetaken)
        local AttackerName = ( attacker == ply ) and "el mismo" or GetEntityName(attacker)
        return {ply:Name(), math.Round(damagetaken, 2), AttackerName, remaininghealth}
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

        local OwnerName = IsValid(Owner) and Owner:IsPlayer() and Owner:Name() or "no tiene"

        return {ent:GetClass(), OwnerName, IsValid(Owner) and Owner:IsPlayer() and (", su dueño es " .. Owner:Name()) or ""}
    end,
    ["PlayerEnteredVehicle"] = function(ply, vehicle)
        local EntPos = vehicle:GetPos()
        return {ply:Name(), vehicle:GetClass(), Gemini:VectorToString(EntPos)}
    end,
    ["PlayerLeaveVehicle"] = function(ply, vehicle)
        local EntPos = vehicle:GetPos()
        return {ply:Name(), vehicle:GetClass(), math.Round(CurTime() - ply.__LAST_VEHICLE, 2), Gemini:VectorToString(EntPos)}
    end,
    ["PlayerOnVehicle"] = function(ply)
        local EntPos = ply:GetPos()
        return {ply:Name(), ply.__LAST_VEHICLE_NAME, Gemini:VectorToString(EntPos)}
    end,
    ["VariableEdited"] = function(ent, ply, key, val)
        return {ply:Name(), GetEntityName(ent), key, val}
    end,
    ["GravGunOnPickedUp"] = function(ply, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), GetEntityName(ent), Gemini:VectorToString(EntPos)}
    end,
    ["GravGunOnDropped"] = function(ply, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), GetEntityName(ent), Gemini:VectorToString(EntPos)}
    end,
    ["OnPhysgunPickup"] = function(ply, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), GetEntityName(ent), Gemini:VectorToString(EntPos)}
    end,
    ["PhysgunDrop"] = function(ply, ent)
        local EntPos = ent:GetPos()
        return {ply:Name(), GetEntityName(ent), Gemini:VectorToString(EntPos)}
    end,
    ["PlayerSay"] = function(ply, text, IsTeamChat)
        -- Obtener todos los jugadores cercanos a "ply" en un radio de 300 unidades
        local NearbyPlayersPhrase = "nadie"
        local NearToPlayer = Gemini:GetConfig("CloseToPlayer", "Language", true)

        for k, plys in ipairs(player.GetAll()) do
            if plys == ply then continue end
            if ply:GetPos():Distance(plys:GetPos()) <= NearToPlayer then
                if NearbyPlayersPhrase == "nadie" then
                    NearbyPlayersPhrase = ""
                end

                NearbyPlayersPhrase = NearbyPlayersPhrase .. plys:Name() .. ", "
            end
        end

        NearbyPlayersPhrase = NearbyPlayersPhrase == "nadie" and "nadie" or NearbyPlayersPhrase:sub(1, -3)

        return {ply:Name(), text, NearbyPlayersPhrase, Gemini:VectorToString(ply:GetPos())}
    end,
    ["PlayerDisconnected"] = function(ply)
        return {ply:Name()}
    end,
    ["PlayerSilentDeath"] = function(ply)
        return {ply:Name()}
    end
})

--[[------------------------
   Gamemodes Descriptions
------------------------]]--

Gemini:AddPhrase(LANG, "context", [[La información que se muestra a continuacion se trata de los modos de juego que existen en Garry's Mod]])

Gemini:AddPhrase(LANG, "default", [[Modo de Juego:
Ningún Modo de Juego Conocido

Descripcion:
El siguiente modo de juego no tiene ningun objetivo conocido, por lo que es recomendable aplicar las reglas y descripciones del modo de juego Sandbox, ya que es el modo de juego por defecto y usado como base para la mayoria de los modos de juego.
En el Sandbox los jugadores pueden construir o tambien pelear entre ellos, por lo que se deja a la imaginación de los jugadores, por lo cual el comportamiento de estos no estan establecidos o no hay ninguno que se pueda tomar de referencia.

Objetivo:
No hay ningun objetivo conocido, por lo que se recomienda aplicar las reglas y descripciones del modo de juego Sandbox.

Mecanicas Conocidas:
- Construcción de estructuras
- Peleas entre jugadores
- Uso de armas y herramientas
- Uso de entidades y vehiculos

Mapas/Entornos:
El entorno o los mapas seleccionados por este modo de juego no tienen un objetivo conocido, por lo que se asumira los mapas como entornos de construcción (Con lugares abiertos o cerrados) o peleas entre jugadores.

Comportamiento de los jugadores:
El comportamiento de los jugadores no esta establecido, por lo que se asumira que los jugadores pueden hacer lo que quieran, siempre y cuando no rompan las reglas establecidas por el propio servidor.

Reglas:
Las unicas reglas conocidas son las reglas establecidas por el servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.]])

Gemini:AddPhrase(LANG, "sandbox", [[Modo de Juego:
Sandbox

Descripcion:
El modo de juego Sandbox es un modo de juego donde los jugadores pueden hacer lo que quieran, como construir, pelear, usar armas, usar herramientas, usar entidades y vehiculos, entre otras cosas. Este modo de juego se resume en una caja de arena donde los jugadores pueden hacer lo que quieran, siempre y cuando no rompan las reglas establecidas por el servidor o por el administrador del servidor.

Objetivo:
El Sandbox no tiene ningun objetivo, los jugadores solo haran lo que quieran como construir o matarse entre si.

Mecanicas Conocidas:
- Construcción de estructuras
- Peleas entre jugadores
- Uso de armas y herramientas
- Uso de entidades y vehiculos
- Noclip (Volar por el mapa)

Mapas/Entornos:
El entorno o los mapas seleccionados son por lo general de mundo abierto o tambien son estructuras diseñadas para explorar y construir. La mayoría de estos mapas tienen una estetica como una ciudad, un campo de pasto verde o incluso lugares abstractos.

Comportamiento de los jugadores:
El comportamiento de los jugadores cambia dependiendo de la situacion, por ejemplo si los jugadores desean construir, estos se comportaran de manera pacifica, pero si los jugadores desean pelear, estos se comportaran de manera agresiva.

Reglas:
Las reglas del Sandbox son establecidas por el servidor o por el administrador del servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.]])

Gemini:AddPhrase(LANG, "darkrp", [[Modo de Juego:
DarkRP

Descripcion:
DarkRP es un modo de juego basado en el modo de juego Sandbox, pero con la diferencia de que este modo de juego tiene un sistema de economia, trabajos, salarios, entre otras cosas. Este modo de juego es muy popular en Garry's Mod, ya que es un modo de juego que simula la vida real, por lo que los jugadores pueden simular tener una vida y dentro del contexto de que estan en un roleplay.

Objetivo:
El objetivo de DarkRP es simular una vida real, por lo que los jugadores pueden hacer lo que quieran, pero siempre y cuando esten dentro del contexto de que estan en un roleplay.

Mecanicas Conocidas:
- Casas y propiedades
- Trabajos y salarios
- Sistema de economia
- Policias y criminales
- Vehiculos y entidades
- Robo de casas y propiedades

Mapas/Entornos:
Los mapas preferiblemente son de ciudades o lugares urbanos, ya que estos mapas son los mas adecuados para simular una vida real. Los mapas pueden tener casas, tiendas, calles, entre otras cosas.

Comportamiento de los jugadores:
El comportamiento de los jugadores depende del trabajo que tengan, por ejemplo si un jugador es policia, este se enfocara de buscar criminales o mantener el orden, pero si un jugador es un criminal, este se enfocara en robar casas o propiedades, tambien existen los trabajos civiles, que estos se enfocaran en trabajar para ganar dinero.

Reglas:
Existen reglas predefinidad por el modo de juego, como por ejemplo:
- RDM (Random Deathmatch): Matar a alguien sin razon alguna.
- NLR (New Life Rule): Esta regla es algo compleja, pero se resume en que si un jugador muere, este tiene que olvidar todo lo que paso antes de morir, por ejemplo si le han robado la casa, no puede volver inmediatamente o durante el robo.
- FailRP: Hacer algo que no tiene sentido o que no esta dentro del contexto de que estan en un roleplay, como un policia robando a un civil.
Y tambien existen reglas establecidas por el servidor o por el administrador del servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.]])

Gemini:AddPhrase(LANG, "terrortown", [[Modo de Juego:
Trouble in T Town

Descripcion:
Trouble in T Town es un modo de juego basado en el modo de juego Sandbox, pero con la diferencia de que este modo de juego tiene un sistema de roles, donde los jugadores son asignados a un rol especifico, como por ejemplo un inocente, un detective o un traidor. Este modo de juego es muy popular en Garry's Mod, ya que es un modo de juego que simula una situacion estilo among us, donde los jugadores tienen que descubrir quien es el traidor.

Objetivo:
El objetivo de Trouble in T Town es descubrir quien es el traidor, por lo que los jugadores tienen que trabajar en equipo para descubrir quien es el traidor y matarlo.

Mecanicas Conocidas:
- Detectives e inocentes
- Traidores
- Herramientas para los detectives y traidores
- Armas para todos

Mapas/Entornos:
No existe un entorno especifico, ya que los mapas son muy variados pero todos son hechos para adaptarse al modo de juego, por lo que los mapas no estan limitados a un entorno especifico.

Comportamiento de los jugadores:
El comportamiento de los jugadores depende del rol que tengan, por ejemplo si un jugador es un detective, este se enfocara en buscar al traidor, pero si un jugador es un traidor, este se enfocara en matar a los inocentes o al detective, mientras que los inocentes ayudaran al detective a buscar al traidor.

Reglas:
Las reglas de Trouble in T Town son establecidas por el servidor o por el administrador del servidor, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.]])

Gemini:AddPhrase(LANG, "trashcompactor", [[Modo de Juego:
Trash Compactor

Descripcion:
Trash Compactor consiste en un modo de juego donde hay un jugador que tirara basura (props/entidades) a los jugadores de abajo y los jugadores de abajo tienen que esquivar los props.

Objetivo:
El objetivo del jugador que esta arriba es de asesinar a todos los jugadores que se encuentren abajo con los props que tiene, mientras que el objetivo de los jugadores que estan abajo es de esquivar los props que el jugador de arriba les tira, si el tiempo se acaba y los jugadores de abajo sobreviven, estos ganan, pero si el jugador de arriba mata a todos los jugadores de abajo, este gana.

Mecanicas Conocidas:
- Props y entidades
- El jugador de arriba disponde de props para tirar
- Los jugadores de abajo tienen un arma para disparar al jugador de arriba si llega a bajar
- Los jugadores de abajo tambien pueden matar al jugador de arriba si se asoma
- El jugador de arriba tiene un tiempo limite para matar a los jugadores de abajo
- El jugador de arriba disponde de la physgun, gravity gun y granadas
- Los jugadores pueden manualmente participar como el jugador de arriba

Mapas/Entornos:
Los mapas que estan dedicados a este modo de juego tienen entidades/props que se pueden tirar a los jugadores de abajo, en cambio los jugadores de abajo estan expuestos a los props que el jugador de arriba les tira ya que la zona de abajo es un lugar abierto. Los mapas tambien tienen un trigger que empuja los props con mas fuerza para mata a los jugadores de abajo.

Comportamiento de los jugadores:
Habra un jugador que intentara o matara a los jugadores con props, por lo que es normal que los jugadores de abajo se muevan constantemente para esquivar los props que el jugador de arriba les tira, tambien es normal que el jugador de arriba tome props con la physgun o gravity gun para tirarlos a los jugadores de abajo.

Reglas:
Debido a que el modo de juego es muy simple y los mapas estan hechos exclusivamente para este modo de juego, no hay reglas establecidas por el modo de juego, por lo que se recomienda seguir las reglas establecidas por el servidor o por el administrador del servidor.]])