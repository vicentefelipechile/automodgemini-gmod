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

    if not isstring(FileName) then
        Gemini:Error([[The first argument of LANG:Require must be a string.]], FileName, "string")
    end

    if #FileName == 0 then
        Gemini:Error([[The first argument of LANG:Require must not be an empty string.]], FileName, "string")
    end

    local FileValue = include(FileName)

    if FileValue == nil then
        Gemini:Error([[The file "]] .. FileName .. [[" doesn't return a value.]], FileName, "any")
    end

    local ImportName = string.Replace(FileName, ".lua", "")
    self.__imports[ImportName] = FileValue
end

function MODULE:Get(ImportName)
    if not isstring(ImportName) then
        Gemini:Error([[The first argument of LANG:Get must be a string.]], ImportName, "string")
    end

    if #ImportName == 0 then
        Gemini:Error([[The first argument of LANG:Get must not be an empty string.]], ImportName, "string")
    end

    if not self.__imports[ImportName] then
        Gemini:Error([[The module "]] .. ImportName .. [[" does not exist in the language module.]], ImportName, "string")
    end

    return self.__imports[ImportName]
end

function MODULE:AddPhrase(PhraseName, PhraseValue)
    if not isstring(PhraseName) then
        Gemini:Error([[The first argument of LANG:AddPhrase must be a string.]], PhraseName, "string")
    end

    if #PhraseName == 0 then
        Gemini:Error([[The first argument of LANG:AddPhrase must not be an empty string.]], PhraseName, "string")
    end

    if not isstring(PhraseValue) then
        Gemini:Error([[The second argument of LANG:AddPhrase must be a string.]], PhraseValue, "string")
    end

    if #PhraseValue == 0 then
        Gemini:Error([[The second argument of LANG:AddPhrase must not be an empty string.]], PhraseValue, "string")
    end

    self.__phrases[PhraseName] = PhraseValue
end

function MODULE:GetPhrase(PhraseName)
    if not isstring(PhraseName) then
        Gemini:Error([[The first argument of LANG:GetPhrase must be a string.]], PhraseName, "string")
    end

    if #PhraseName == 0 then
        Gemini:Error([[The first argument of LANG:GetPhrase must not be an empty string.]], PhraseName, "string")
    end

    return self.__phrases[PhraseName] or PhraseName
end

function MODULE:PoblateHooks(HooksTable)
    if not istable(HooksTable) then
        Gemini:Error([[The first argument of LANG:PoblateHooks must be a table.]], HooksTable, "table")
    end

    for HookName, HookTable in pairs(HooksTable) do
        if not istable(HookTable) then
            Gemini:Error([[The value of the table passed to LANG:PoblateHooks must be a table.]], HookTable, "tablw")
        end

        self.__hooks[HookName] = {["Function"] = HookTable["Function"], ["Phrase"] = HookTable["Phrase"]}
    end
end

function MODULE:GetHooks()
    return self.__hooks
end

function MODULE:PhraseExists(PhraseName)
    return self.__phrases[PhraseName] ~= nil
end

return MODULE