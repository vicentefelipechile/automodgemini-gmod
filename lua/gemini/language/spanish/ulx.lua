--[[----------------------------------------------------------------------------
                          Gemini Automod - Spanish ULX
----------------------------------------------------------------------------]]--

-- Sorry william, i fail you :(
local ULX_Blacklist = {
    ["ulx luarun"] = true,
    ["ulx rcon"] = true,

    ["ulx votebanMinvotes"] = true,
    ["ulx votebanSuccessratio"] = true,
    ["ulx votekickMinvotes"] = true,
    ["ulx votekickSuccessratio"] = true,
    ["ulx votemap2Minvotes"] = true,
    ["ulx votemap2Successratio"] = true,
    ["ulx voteEcho"] = true,
    ["ulx votemapMapmode"] = true,
    ["ulx votemapVetotime"] = true,
    ["ulx votemapMinvotes"] = true,
    ["ulx votemapWaittime"] = true,
    ["ulx votemapMintime"] = true,
    ["ulx votemapEnabled"] = true,
    ["ulx rslotsVisible"] = true,
    ["ulx rslots"] = true,
    ["ulx rslotsMode"] = true,
    ["ulx logEchoColorMisc"] = true,
    ["ulx logEchoColorPlayer"] = true,
    ["ulx logEchoColorPlayerAsGroup"] = true,
    ["ulx logEchoColorEveryone"] = true,
    ["ulx logEchoColorSelf"] = true,
    ["ulx logEchoColorConsole"] = true,
    ["ulx logEchoColorDefault"] = true,
    ["ulx logEchoColors"] = true,
    ["ulx logEcho"] = true,
    ["ulx logDir"] = true,
    ["ulx logJoinLeaveEcho"] = true,
    ["ulx logSpawnsEcho"] = true,
    ["ulx votemapSuccessratio"] = true,
    ["ulx logSpawns"] = true,
    ["ulx logChat"] = true,
    ["ulx logEvents"] = true,
    ["ulx logFile"] = true,
    ["ulx welcomemessage"] = true,
    ["ulx meChatEnabled"] = true,
    ["ulx chattime"] = true,
    ["ulx motdurl"] = true,
    ["ulx motdfile"] = true,
    ["ulx showMotd"] = true,
}

local ULX_MODULE = {
    ["ULibCommandCalled"] = {
        ["Phrase"] = "%s ejecuto el comando \"%s\".",
        ["Function"] = function(ply, cmd, ArgsTable)
            print("ULX_MODULE", ply, cmd)
            PrintTable(ArgsTable)
            if not ArgsTable then return false end
            if ULX_Blacklist[cmd] then return false end

            local ArgPhrase = " sin argumentos"
            if (#ArgsTable > 0) then
                cmd = cmd .. " " .. ArgsTable[1]
                if ULX_Blacklist[cmd] then return false end

                ArgPhrase = " con argumentos \"" .. table.concat(ArgsTable, "\" \"", 2)
                ArgPhrase = ArgPhrase:sub(1, -2) .. "\""
            end

            ply = IsValid(ply) and ("El jugador \"" .. ply:Name() .. "\"") or "El servidor"

            return {ply, cmd}
        end
    }
}

return ULX_MODULE