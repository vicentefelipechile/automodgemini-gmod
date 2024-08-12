local MODULE = {
    __imports = {},
    __phrases = {},
    __hooks = {},
    Name = "English",

    GetResponseCriteria = function() return end,
    SetResponseCriteria = function() end,
    GeneratePrompt = function(...) return end,
}

function MODULE:Require(FileName, OnlyServer)
    if OnlyServer and CLIENT then return end

    Gemini:Checker({FileName, "string", 1})

    local FileValue = include(FileName)
    if FileValue == nil then
        Gemini:Error([[The file "]] .. FileName .. [[" doesn't return a value.]], FileName, "any")
    end

    local ImportName = string.Replace(FileName, ".lua", "")
    self.__imports[ImportName] = FileValue
end

function MODULE:Get(ImportName)
    Gemini:Checker({ImportName, "string", 1})

    if not self.__imports[ImportName] then
        Gemini:Error([[The module "]] .. ImportName .. [[" does not exist in the language module.]], ImportName, "string")
    end

    return self.__imports[ImportName]
end

function MODULE:AddPhrase(PhraseName, PhraseValue)
    Gemini:Checker({PhraseName, "string", 1})
    Gemini:Checker({PhraseValue, "string", 2})

    self.__phrases[PhraseName] = PhraseValue
end

function MODULE:GetPhrase(PhraseName)
    Gemini:Checker({PhraseName, "string", 1})

    return self.__phrases[PhraseName] or PhraseName
end

function MODULE:PoblateHooks(HooksTable)
    if not istable(HooksTable) then
        Gemini:Error([[The first argument of LANG:PoblateHooks must be a table.]], HooksTable, "table")
    end

    for HookName, HookData in pairs(HooksTable) do
        if not istable(HookData) then
            Gemini:Error([[The value of the table passed to LANG:PoblateHooks must be a table.]], HookData, "table")
        end

        hook.Add(HookName, "GeminiLanguageHook:" .. self.Name .. "." .. HookName, function(...)
            local Args = HookData["Function"](...)
            if ( Args == false ) then return end

            local PlayersInvolved = {}
            local ThereArePlayers = false
            for _, any in ipairs({...}) do
                if ( isentity(any) and any:IsPlayer() ) then
                    PlayersInvolved[any] = true
                    ThereArePlayers = true
                end
            end

            if not ThereArePlayers then return end

            PlayersInvolved = table.GetKeys(PlayersInvolved)
            local Log = string.format(HookData["Phrase"], unpack(Args))
            hook.Run("Gemini:Log", Log, unpack(PlayersInvolved))
        end)
    end
end

function MODULE:GetHooks()
    return self.__hooks
end

function MODULE:PhraseExists(PhraseName)
    return self.__phrases[PhraseName] ~= nil
end

return MODULE