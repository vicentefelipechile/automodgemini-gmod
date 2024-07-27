--[[----------------------------------------------------------------------------
                        Gemini Automod - Spanish Sandbox
----------------------------------------------------------------------------]]--

local SandboxModule = {
    ["DoPlayerDeath"] =        [[El jugador "%s" fue asesinado por "%s" en las coordendas %s usando %s.]],
    ["PlayerSpawn"] =          [[El jugador "%s" ha respawneado, han pasado %s segundos desde su muerte.]],
    ["PlayerInitialSpawn"] =   [[El jugador "%s" ha conectado al servidor.]],
    ["PlayerSpawnedEffect"] =  [[El jugador "%s" ha creado el efecto "%s" en las coordenadas %s.]],
    ["PlayerSpawnedNPC"] =     [[El jugador "%s" ha creado el npc "%s" en las coordenadas %s.]],
    ["PlayerSpawnedProp"] =    [[El jugador "%s" ha creado el prop "%s" en las coordenadas %s.]],
    ["PlayerSpawnedRagdoll"] = [[El jugador "%s" ha creado un ragdoll "%s" en las coordenadas %s.]],
    ["PlayerSpawnedSENT"] =    [[El jugador "%s" ha creado la entidad "%s" en las coordenadas %s.]],
    ["PlayerGiveSWEP"] =       [[El jugador "%s" se ha sacado el arma "%s" del menu de armas.]],
    ["PlayerSpawnedVehicle"] = [[El jugador "%s" ha colocado un auto "%s" en las coordenadas %s usando el menu de vehiculos.]],
    ["OnDamagedByExplosion"] = [[El jugador "%s" ha recibido %s de daño por una explosion provocada por "%s".]],
    ["PlayerHurt"] =           [[El jugador "%s" ha sido atacado por "%s", ha recibido %s de daño y ahora %s]],
    ["PlayerChangedTeam"] =    [[El jugador "%s" ha cambiado de equipo/trabajo a "%s" (antes era "%s").]],
    ["OnCrazyPhysics"] =       [[Se ha detectado fisicas locas en la entidad "%s", esta entidad %s dueño%s.]],
    ["PlayerEnteredVehicle"] = [[El jugador "%s" ha entrado al auto "%s" en las coordenadas %s.]],
    ["PlayerLeaveVehicle"] =   [[El jugador "%s" estuvo en el auto "%s" por %s segundos y ahora se fue del auto en las coordenadas %s.]],
    ["PlayerOnVehicle"] =      [[El jugador "%s" aun se encuentra en el auto "%s" pero ahora en las coordenadas %s.]],
    ["VariableEdited"] =       [[El jugador "%s" edito la entidad "%s" y cambio la variable "%s" a "%s".]],
    ["GravGunOnPickedUp"] =    [[El jugador "%s" agarro la entidad "%s" con la pistola antigravedad en las coordenadas %s.]],
    ["GravGunOnDropped"] =     [[El jugador "%s" solto la entidad "%s" con la pistola antigravedad en las coordenadas %s.]],
    ["OnPhysgunPickup"] =      [[El jugador "%s" agarro %s "%s" con la pistola fisica en las coordenadas %s.]],
    ["PhysgunDrop"] =          [[El jugador "%s" solto %s "%s" con la pistola fisica en las coordenadas %s.]],
    ["PlayerSay"] =            [[El jugador "%s" dijo "%s" cerca de %s en las coordenadas %s.]],
    ["PlayerDisconnected"] =   [[El jugador "%s" se fue del servidor.]],
    ["PlayerSilentDeath"] =    [[El jugador "%s" se murio silenciosamente.]],
    -- ["PostCleanupMap"] =       [[El servidor ha limpiado el mapa, todas las entidades/props han sido eliminados.]],
    ["OnNPCKilled"] =          [[El NPC "%s" ha sido asesinado por "%s" en las coordenadas %s.]],
}

return SandboxModule