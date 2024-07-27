--[[----------------------------------------------------------------------------
                            Gemini Automod - Spanish
----------------------------------------------------------------------------]]--

local LANG = Gemini:LanguageCreate("Spanish")
LANG:Require("gemini.lua")
LANG:Require("menu.lua")
LANG:Require("damage.lua", true)
LANG:Require("sandbox.lua", true)
LANG:Require("darkrp.lua", true)
LANG:Require("prompts.lua", true)

--[[------------------------
        Extra Phrases
------------------------]]--

for Name, Phrase in pairs( LANG:Get("gemini") ) do
    LANG:AddPhrase(Name, Phrase)
end

for Name, Phrase in pairs( LANG:Get("menu") ) do
    LANG:AddPhrase(Name, Phrase)
end

if CLIENT then return end

for Name, PromptFunction in pairs( LANG:Get("prompts") ) do
    LANG[Name] = PromptFunction
end

--[[------------------------
        Name Function
------------------------]]--

local function GetEntityName(ent)
    if ent:IsWorld() then
        return "el mundo"
    elseif not IsValid(ent) then
        return "algo que ya no existe"
    elseif ent:IsPlayer() then
        return ent:Name()
    elseif ent:IsNPC() then
        local EntityName = hook.Run("GetDeathNoticeEntityName", ent)
        return EntityName .. " (NPC)"
    else
        return ent.PrintName or ent:GetClass()
    end
end

--[[------------------------
        Damage Phrases
------------------------]]--

local DamageType = LANG:Get("damage")

--[[------------------------
        Sandbox Hooks
------------------------]]--

local SandboxHooks = {
    ["DoPlayerDeath"] = {
        ["Function"] = function(victim, attacker, dmg)
            if not DamageType[dmg:GetDamageType()] then
                Gemini:Print("Daño desconocido: ", dmg:GetDamageType())
            end

            local DmgType = DamageType[dmg:GetDamageType()] or game.GetAmmoName(dmg:GetAmmoType()) and "una bala de " .. game.GetAmmoName(dmg:GetAmmoType()) or "algo que no se puede determinar"
            local AttackerName = ( attacker == victim ) and "el mismo" or GetEntityName(attacker)

            return {victim:Name(), AttackerName, Gemini:VectorToString(victim:GetPos()), DmgType}
        end
    },
    ["OnNPCKilled"] = {
        ["Function"] = function(npc, attacker, inflictor)
            return {GetEntityName(npc), GetEntityName(attacker), Gemini:VectorToString(npc:GetPos())}
        end
    },
    ["PlayerSpawn"] = {
        ["Function"] = function(ply, time)
            return {ply:Name(), math.Round(ply.__LAST_DEATH and CurTime() - ply.__LAST_DEATH or 0, 2)}
        end
    },
    ["PlayerInitialSpawn"] = {
        ["Function"] = function(ply)
            return {ply:Name()}
        end
    },
    ["PlayerSpawnedEffect"] = {
        ["Function"] = function(ply, model, ent)
        local EntPos = ent:GetPos()
            return {ply:Name(), model, Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerSpawnedNPC"] = {
        ["Function"] = function(ply, npc)
        local EntPos = npc:GetPos()
            return {ply:Name(), GAMEMODE:GetDeathNoticeEntityName(npc), Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerSpawnedProp"] = {
        ["Function"] = function(ply, model, ent)
            local EntPos = ent:GetPos()
            return {ply:Name(), model, Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerSpawnedRagdoll"] = {
        ["Function"] = function(ply, model, ent)
            local EntPos = ent:GetPos()
            return {ply:Name(), model, Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerSpawnedSENT"] = {
        ["Function"] = function(ply, sent)
            local EntPos = sent:GetPos()
            return {ply:Name(), GetEntityName(sent), Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerGiveSWEP"] = {
        ["Function"] = function(ply, wpn, swep)
            return {ply:Name(), swep.PrintName or wpn}
        end
    },
    ["PlayerSpawnedVehicle"] = {
        ["Function"] = function(ply, ent)
        local EntPos = ent:GetPos()
            return {ply:Name(), ent:GetClass(), Gemini:VectorToString(EntPos)}
        end
    },
    ["OnDamagedByExplosion"] = {
        ["Function"] = function(ply, dmg)
            local Responsable = dmg:GetAttacker() == ply and "el mismo" or GetEntityName(dmg:GetAttacker())

            return {ply:Name(), math.Round(dmg:GetDamage(), 0), Responsable}
        end
    },
    ["PlayerHurt"] = {
        ["Function"] = function(ply, attacker, remaininghealth, damagetaken)
            local AttackerName = ( attacker == ply ) and "el mismo" or GetEntityName(attacker)
            local IsDead = remaininghealth <= 0
            local Result = IsDead and ( "esta muerto (" .. remaininghealth .. " de vida)" ) or ( "tiene " .. remaininghealth .. " de vida" )

            return {ply:Name(), AttackerName, math.Round(damagetaken, 0), Result}
        end
    },
    ["PlayerChangedTeam"] = {
        ["Function"] = function(ply, newteam, oldteam)
            return {ply:Name(), team.GetName(newteam), team.GetName(oldteam)}
        end
    },
    ["OnCrazyPhysics"] = {
        ["Function"] = function(ent, physobj)
            local Owner = NULL
            if CPPI then
                Owner = ent:CPPIGetOwner()
            elseif ent.Getowning_ent then
                Owner = ent:Getowning_ent()
            end

            local OwnerIsValid = IsValid(Owner) and Owner:IsPlayer()
            local OwnerName = OwnerIsValid and Owner:Name() or "no tiene"

            return {ent:GetClass(), OwnerName, OwnerIsValid and (", su dueño es " .. Owner:Name()) or ""}
        end
    },
    ["PlayerEnteredVehicle"] = {
        ["Function"] = function(ply, vehicle)
            local EntPos = vehicle:GetPos()
            return {ply:Name(), vehicle:GetClass(), Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerLeaveVehicle"] = {
        ["Function"] = function(ply, vehicle)
            local EntPos = vehicle:GetPos()
            return {ply:Name(), vehicle:GetClass(), math.Round(CurTime() - ply.__LAST_VEHICLE, 2), Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerOnVehicle"] = {
        ["Function"] = function(ply)
            local EntPos = ply:GetPos()
            return {ply:Name(), ply.__LAST_VEHICLE_NAME, Gemini:VectorToString(EntPos)}
        end
    },
    ["VariableEdited"] = {
        ["Function"] = function(ent, ply, key, val)
            return {ply:Name(), GetEntityName(ent), key, val}
        end
    },
    ["GravGunOnPickedUp"] = {
        ["Function"] = function(ply, ent)
            local EntPos = ent:GetPos()
            return {ply:Name(), GetEntityName(ent), Gemini:VectorToString(EntPos)}
        end
    },
    ["GravGunOnDropped"] = {
        ["Function"] = function(ply, ent)
            local EntPos = ent:GetPos()
            return {ply:Name(), GetEntityName(ent), Gemini:VectorToString(EntPos)}
        end
    },
    ["OnPhysgunPickup"] = {
        ["Function"] = function(ply, ent)
            local EntPos = ent:GetPos()
            local PhraseEnt = ent:IsPlayer() and "al jugador" or "la entidad"

            return {ply:Name(), PhraseEnt, GetEntityName(ent), Gemini:VectorToString(EntPos)}
        end
    },
    ["PhysgunDrop"] = {
        ["Function"] = function(ply, ent)
            local EntPos = ent:GetPos()
            local PhraseEnt = ent:IsPlayer() and "al jugador" or "la entidad"

            return {ply:Name(), PhraseEnt, GetEntityName(ent), Gemini:VectorToString(EntPos)}
        end
    },
    ["PlayerSay"] = {
        ["Function"] = function(ply, text)
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
        end
    },
    ["PlayerDisconnected"] = {
        ["Function"] = function(ply)
            return {ply:Name()}
        end
    },
    ["PlayerSilentDeath"] = {
        ["Function"] = function(ply)
            return {ply:Name()}
        end
    }
}

for HookName, HookPhrase in pairs( LANG:Get("sandbox") ) do
    SandboxHooks[HookName]["Phrase"] = HookPhrase
end

LANG:PoblateHooks(SandboxHooks)

--[[------------------------
           DarkRP
------------------------]]--

local DarkRPModule = LANG:Get("darkrp")
if DarkRPModule["Verification"]() then
    LANG:PoblateHooks(DarkRPModule["Hooks"])
end