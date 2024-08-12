--[[----------------------------------------------------------------------------
                         Gemini Automod - Spanish DarkRP
----------------------------------------------------------------------------]]--

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
        Known Commands
------------------------]]--

local ChatCommands = {
    ["a"] = [[decirle a todo el mundo "%s"]],
    ["/"] = [[decirle a todo el mundo "%s"]],
    ["ooc"] = [[decirle a todo el mundo "%s"]],
    ["advert"] = [[avisarle a alguien "%s"]],
}

--[[------------------------
      Hook and Phrases
------------------------]]--

local DarkRPModule = {
    ["Verification"] = function()
        return DarkRP ~= nil
    end,
    ["Hooks"] = {
        ["addLaw"] = {
            ["Phrase"] = [[El alcalde %s añadio una nueva ley que dice "%s".]],
            ["Function"] = function(index, law, ply)
                return {GetEntityName(ply), law}
            end
        },
        ["agendaUpdated"] = {
            ["Phrase"] = [[%s actualizo la agenda a "%s".]],
            ["Function"] = function(ply, agenda, text)
                local AgendaPhrase = ( IsValid(ply) and ply:IsPlayer() ) and ply:Nick() or "El servidor"
                return {AgendaPhrase, text}
            end
        },
        ["lockdownEnded"] = {
            ["Phrase"] = [[%s ha terminado el toque de queda.]],
            ["Function"] = function(ply)
                return {GetEntityName(ply)}
            end
        },
        ["lockdownStarted"] = {
            ["Phrase"] = [[%s ha iniciado el toque de queda.]],
            ["Function"] = function(ply)
                return {GetEntityName(ply)}
            end
        },
        ["lockpickStarted"] = {
            ["Phrase"] = [[El jugador "%s" esta intentando forzar la cerradura en las coordenadas "%s", la puerta %s.]],
            ["Function"] = function(ply, ent, tbl)
                local OwnerName = IsValid( ent:getDoorOwner() ) and "le pertenece a " .. owner:Name() or "no le pertenece nadie"
                return {GetEntityName(ply), Gemini:VectorToString(ent:GetPos()), OwnerName}
            end
        },
        ["lotteryEnded"] = {
            ["Phrase"] = [[La loteria con %s participantes ha terminado, el ganador fue "%s" y recibio $%s.]],
            ["Function"] = function(participants, winner, amount)
                return {#participants, GetEntityName(winner), string.Comma(amount)}
            end
        },
        ["lotteryStarted"] = {
            ["Phrase"] = [[%s ha comenzado una loteria y para entrar deben pagar $%s.]],
            ["Function"] = function(ply, amount)
                return {GetEntityName(ply), string.Comma(amount)}
            end
        },
        ["moneyPrinterPrinted"] = {
            ["Phrase"] = [[La impresora de dinero de "%s" ha generado ilegalmente $%s en las coordenadas "%s".]],
            ["Function"] = function(printer, moneybag)
                local OwnerName = GetEntityName(printer:CPPIGetOwner())
                return {OwnerName, string.Comma(moneybag:Getamount()), Gemini:VectorToString(printer:GetPos())}
            end
        },
        ["onChatCommand"] = {
            ["Phrase"] = [[El jugador "%s" uso el comando "%s" para %s.]],
            ["Function"] = function(ply, cmd, args)
                local CommandPhrase = ChatCommands[cmd]
                if not CommandPhrase then return false end

                local Result = string.format(CommandPhrase, args)
                return {ply:Nick(), cmd, Result}
            end
        },
        ["onChatSound"] = {
            ["Phrase"] = [[El jugador "%s" ha reproducido el sonido "%s".]],
            ["Function"] = function(ply, phrase)
                return {ply:Nick(), phrase}
            end
        },
        ["onDarkRPWeaponDropped"] = {
            ["Phrase"] = [[El jugador "%s" tiro al suelo el arma "%s" en las coordenadas "%s".]],
            ["Function"] = function(ply, sent, swep)
                return {ply:Nick(), swep:GetClass(), Gemini:VectorToString(sent:GetPos())}
            end
        },
        ["onDoorRamUsed"] = {
            ["Phrase"] = [[El jugador "%s" %s usar el ariete en la puerta en las coordenadas "%s".]],
            ["Function"] = function(success, ply)
                local Result = success and "logro con exito" or "no pudo"
                return {ply:Nick(), Result, Gemini:VectorToString(ply:GetPos())}
            end
        },
        ["onHitAccepted"] = {
            ["Phrase"] = [[El sicario "%s" ha aceptado asesinar a "%s" por parte de "%s".]],
            ["Function"] = function(hitman, target, customer)
                return {hitman:Nick(), target:Nick(), customer:Nick()}
            end
        },
        ["onHitCompleted"] = {
            ["Phrase"] = [[El sicario "%s" ha asesinado a "%s" por parte de "%s".]],
            ["Function"] = function(hitman, target, customer)
                return {hitman:Nick(), target:Nick(), customer:Nick()}
            end
        },
        ["onHitFailed"] = {
            ["Phrase"] = [[El sicario "%s" fallo en asesinar a "%s", la razon fue "%s".]],
            ["Function"] = function(hitman, target, reason)
                return {hitman:Nick(), target:Nick(), reason}
            end
        },
        ["onKeysLocked"] = {
            ["Phrase"] = [[El dueño cerro con llave la puerta %sen las coordenadas "%s".]],
            ["Function"] = function(ent)
                local IsAVehicle = ent:IsVehicle() and "del auto " or ""
                return {IsAVehicle, Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["onKeysUnlocked"] = {
            ["Phrase"] = [[El dueño abrio con llave la puerta %sen las coordenadas "%s".]],
            ["Function"] = function(ent)
                local IsAVehicle = ent:IsVehicle() and "del auto " or ""
                return {IsAVehicle, Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["onLockpickCompleted"] = {
            ["Phrase"] = [[El jugador "%s" logro %s forzar la puerta%s en las coordenadas "%s".]],
            ["Function"] = function(ply, success, ent)
                local Result = success and "con" or "sin"
                local IsAVehicle = ent:IsVehicle() and "del auto " or ""
                return {ply:Nick(), Result, IsAVehicle, Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["onPlayerChangedName"] = {
            ["Phrase"] = [[El jugador "%s" se cambio el nombre y ahora se llama "%s".]],
            ["Function"] = function(_, oldname, newname)
                return {oldname, newname}
            end
        },
        ["onPlayerDemoted"] = {
            ["Phrase"] = [[El jugador "%s" fue degradado de su trabajo gracias a "%s", la razon: "%s".]],
            ["Function"] = function(source, target, reason)
                return {source:Nick(), target:Nick(), reason}
            end
        },
        ["onPocketItemAdded"] = {
            ["Phrase"] = [[El jugador "%s" guardo "%s" en su bolsillo en las coordenadas "%s".]],
            ["Function"] = function(ply, ent)
                return {ply:Nick(), ent:GetClass(), Gemini:VectorToString(ply:GetPos())}
            end
        },
        ["onPocketItemDropped"] = {
            ["Phrase"] = [[El jugador "%s" saco "%s" de su bolsillo en las coordenadas "%s".]],
            ["Function"] = function(ply, ent)
                return {ply:Nick(), ent:GetClass(), Gemini:VectorToString(ply:GetPos())}
            end
        },
        ["playerArrested"] = {
            ["Phrase"] = [[El jugador "%s" fue arrestado por "%s" por %s segundos.]],
            ["Function"] = function(criminal, time, police)
                return {criminal:Nick(), police:Nick(), time}
            end
        },
        ["playerBoughtAmmo"] = {
            ["Phrase"] = [[El jugador "%s" compro munición de "%s" en las coordenadas "%s".]],
            ["Function"] = function(ply, ammotbl, sent, price)
                return {ply:Nick(), ammotbl.ammoType, Gemini:VectorToString(sent:GetPos())}
            end
        },
        ["playerBoughtCustomEntity"] = {
            ["Phrase"] = [[El jugador "%s" compro "%s" en las coordenadas "%s".]],
            ["Function"] = function(ply, _, ent, price)
                return {ply:Nick(), ent:GetClass(), Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["playerBoughtDoor"] = {
            ["Phrase"] = [[El jugador "%s" compro una puerta en las coordenadas "%s".]],
            ["Function"] = function(ply, ent)
                return {ply:Nick(), Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["playerBoughtShipment"] = {
            ["Phrase"] = [[El jugador "%s" compro un cargamento de armas de "%s" en las coordenadas "%s".]],
            ["Function"] = function(ply, _, ent, price)
                return {ply:Nick(), ent:GetClass(), Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["playerDroppedCheque"] = {
            ["Phrase"] = [[El jugador "%s" creo un cheque para "%s" por $%s en las coordenadas "%s".]],
            ["Function"] = function(ply, target, amount, cheque)
                return {ply:Nick(), target:Nick(), string.Comma(amount), Gemini:VectorToString(cheque:GetPos())}
            end
        },
        ["playerDroppedMoney"] = {
            ["Phrase"] = [[El jugador "%s" tiro al suelo $%s en las coordenadas "%s".]],
            ["Function"] = function(ply, amount, moneybag)
                return {ply:Nick(), string.Comma(amount), Gemini:VectorToString(moneybag:GetPos())}
            end
        },
        ["playerEnteredLottery"] = {
            ["Phrase"] = [[El jugador "%s" entro a la loteria.]],
            ["Function"] = function(ply)
                return {ply:Nick()}
            end
        },
        ["playerGaveMoney"] = {
            ["Phrase"] = [[El jugador "%s" le dio dinero directamente a "%s" por $%s.]],
            ["Function"] = function(ply, target, amount)
                return {ply:Nick(), target:Nick(), string.Comma(amount)}
            end
        },
        ["playerGetSalary"] = {
            ["Phrase"] = [[El jugador "%s" obtuvo su salario de $%s y ahora tiene %s.]],
            ["Function"] = function(ply, amount)
                return {ply:Nick(), string.Comma(amount), string.Comma(ply:getDarkRPVar("money"))}
            end
        },
        ["playerGotLicense"] = {
            ["Phrase"] = [[El jugador "%s" recibio una licencia de armas de "%s".]],
            ["Function"] = function(ply, police)
                return {ply:Nick(), police:Nick()}
            end
        },
        ["playerKeysSold"] = {
            ["Phrase"] = [[El jugador "%s" vendio las llave de su puerta con coordenada "%s".]],
            ["Function"] = function(ply, ent)
                return {ply:Nick(), Gemini:VectorToString(ent:GetPos())}
            end
        },
        ["playerPickedUpCheque"] = {
            ["Phrase"] = [[El jugador "%s" recogio el cheque de "%s" por un total de $%s en las coordenadas "%s".]],
            ["Function"] = function(ply, target, amount, success, cheque)
                if not success then return false end
                return {ply:Nick(), GetEntityName(target), string.Comma(amount), Gemini:VectorToString(cheque:GetPos())}
            end
        },
        ["playerPickedUpMoney"] = {
            ["Phrase"] = [[El jugador "%s" recogio $%s del suelo en las coordenadas "%s".]],
            ["Function"] = function(ply, amount, moneybag)
                return {ply:Nick(), string.Comma(amount), Gemini:VectorToString(moneybag:GetPos())}
            end
        },
        ["PlayerPickupDarkRPWeapon"] = {
            ["Phrase"] = [[El jugador "%s" recogio el arma "%s" en las coordenadas "%s".]],
            ["Function"] = function(ply, sent, swep)
                return {ply:Nick(), swep:GetClass(), Gemini:VectorToString(sent:GetPos())}
            end
        },
        ["playerToreUpCheque"] = {
            ["Phrase"] = [[El jugador "%s" rompio el cheque de "%s" en las coordenadas "%s".]],
            ["Function"] = function(ply, target, _, cheque)
                return {ply:Nick(), GetEntityName(target), Gemini:VectorToString(cheque:GetPos())}
            end
        },
        ["playerUnArrested"] = {
            ["Phrase"] = [[El jugador "%s" salio de prision%s.]],
            ["Function"] = function(criminal, police)
                local PoliceName = IsValid(police) and (" gracias a \"" .. police:Nick() .. "\"") or ""
                return {criminal:Nick(), PoliceName}
            end
        },
        ["playerUnWanted"] = {
            ["Phrase"] = [[El jugador "%s" ya no es buscado por la ley.]],
            ["Function"] = function(ply)
                return {ply:Nick()}
            end
        },
        ["playerUnWarranted"] = {
            ["Phrase"] = [[La orden de allanamiento para "%s" %s.]],
            ["Function"] = function(ply, police)
                local PoliceName = IsValid(police) and ("fue cancelada por \"" .. police:Nick() .. "\"") or "expiro"
                return {ply:Nick(), PoliceName}
            end
        },
        ["playerWanted"] = {
            ["Phrase"] = [[El jugador "%s" tiene una orden de arresto por parte de "%s".]],
            ["Function"] = function(ply, police)
                return {ply:Nick(), GetEntityName(police)}
            end
        },
        ["playerWarranted"] = {
            ["Phrase"] = [[El jugador "%s" tiene una orden de allanamiento por parte de "%s", razon: %s.]],
            ["Function"] = function(ply, police, reason)
                return {ply:Nick(), GetEntityName(police), reason}
            end
        },
        ["playerWeaponsConfiscated"] = {
            ["Phrase"] = [[El jugador "%s" confisco las armas de "%s".]],
            ["Function"] = function(ply, target)
                return {ply:Nick(), target:Nick()}
            end
        },
        ["playerWeaponsReturned"] = {
            ["Phrase"] = [[El jugador "%s" devolvio las armas a "%s".]],
            ["Function"] = function(ply, target)
                return {ply:Nick(), target:Nick()}
            end
        }
    }
}

return DarkRPModule