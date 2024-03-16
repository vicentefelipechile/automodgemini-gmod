--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Language Module
----------------------------------------------------------------------------]]--

Gemini.__LANG = Gemini.__LANG or {}

--[[------------------------
        Configuration
------------------------]]--

Gemini:AddConfig("CloseToPlayer", "Language", Gemini.VERIFICATION_TYPE.number, 300)

--[[------------------------
       Language Module
------------------------]]--

function Gemini:LanguageCreate(LanguageTarget)
    Gemini.__LANG[LanguageTarget] = {}

    return LanguageTarget
end

function Gemini:LanguageOverrideHook(LanguageTarget, TableFunctions)
    if not isstring(LanguageTarget) then
        self:Error([[The first argument of Gemini:LanguageOverrideHook() is not a string]], LanguageTarget, "string")
    elseif (LanguageTarget == "") then
        self:Error([[The first argument of Gemini:LanguageOverrideHook() is an empty string]], LanguageTarget, "string")
    end

    if not istable(TableFunctions) then
        self:Error([[The second argument of Gemini:LanguageOverrideHook() is not a table]], TableFunctions, "table[function]")
    end

    for HookName, HookFunc in pairs(TableFunctions) do
        if not isfunction(HookFunc) then
            self:Error("The function \"" .. HookName .. "\" is not a valid function", HookFunc, "function")
        end

        self.__LANG[LanguageTarget][HookName]["Func"] = HookFunc
    end
end

function Gemini:LanguageAddPhrase(LanguageTarget, PhraseName, Phrase)
    if not isstring(LanguageTarget) then
        self:Error([[The first argument of Gemini:LanguageAddPhrase() is not a string]], LanguageTarget, "string")
    elseif (LanguageTarget == "") then
        self:Error([[The first argument of Gemini:LanguageAddPhrase() is an empty string]], LanguageTarget, "string")
    end

    if not isstring(PhraseName) then
        self:Error([[The second argument of Gemini:LanguageAddPhrase() is not a string]], PhraseName, "string")
    elseif (PhraseName == "") then
        self:Error([[The second argument of Gemini:LanguageAddPhrase() is an empty string]], PhraseName, "string")
    end

    if not isstring(Phrase) then
        self:Error([[The third argument of Gemini:LanguageAddPhrase() is not a string]], Phrase, "string")
    elseif (Phrase == "") then
        self:Error([[The third argument of Gemini:LanguageAddPhrase() is an empty string]], Phrase, "string")
    end

    if not istable(self.__LANG[LanguageTarget]) then
        self:Error([[The language target does not exist]], LanguageTarget, "string")
    end

    self.__LANG[LanguageTarget][PhraseName] = {["Phrase"] = Phrase, ["Func"] = Gemini.ReturnNoneFunction}
end

function Gemini:GetPhrase(PhraseName, LanguageTarget, SkipValidation)
    if ( LanguageTarget == nil ) then
        LanguageTarget = self:GetConfig("Language", "General", true)
    end

    if ( SkipValidation == true ) then
        return self.__LANG[LanguageTarget][PhraseName]["Phrase"]
    end

    if not isstring(PhraseName) then
        self:Error([[The first argument of Gemini:GetPhrase() is not a string]], PhraseName, "string")
    elseif (PhraseName == "") then
        self:Error([[The first argument of Gemini:GetPhrase() is an empty string]], PhraseName, "string")
    end

    if not isstring(LanguageTarget) then
        self:Error([[The second argument of Gemini:GetPhrase() is not a string]], LanguageTarget, "string")
    elseif (LanguageTarget == "") then
        self:Error([[The second argument of Gemini:GetPhrase() is an empty string]], LanguageTarget, "string")
    end

    if not istable(self.__LANG[LanguageTarget]) then
        self:Error([[The language target does not exist]], LanguageTarget, "string")
    end

    if not istable(self.__LANG[LanguageTarget][PhraseName]) then
        self:Error([[The phrase does not exist in the language target]], PhraseName, "string")
    end

    return self.__LANG[LanguageTarget][PhraseName]["Phrase"]
end

Gemini.LanguageGetPhrase = Gemini.GetPhrase

function Gemini:LanguagePoblate()
    local LangFile, _ = file.Find("gemini/language/*.lua", "LUA")

    for _, File in ipairs(LangFile) do
        include("gemini/language/" .. File)
        self:Print("Loaded language file: " .. File)
    end

    -- The client does not need to poblate the hook functions
    if CLIENT then return end

    -- Poblate hook functions
    for LangName, LangTable in pairs(self.__LANG) do
        for HookName, HookTable in pairs(LangTable) do
            if ( HookTable["Func"] == Gemini.ReturnNoneFunction ) then continue end

            hook.Add(HookName, "GeminiLanguageHook:" .. LangName .. "." .. HookName, function(...)
                local CurrentLang = self:GetConfig("Language", "General", true)
                if ( CurrentLang ~= LangName ) then return end

                local Args = HookTable["Func"](...)
                local Phrase = HookTable["Phrase"]

                if ( Args == false ) then return end

                local PlayersInvolved = {}
                for _, any in ipairs({...}) do
                    if ( isentity(any) and IsValid(any) and any:IsPlayer() ) then
                        PlayersInvolved[any] = true
                    end
                end
                PlayersInvolved = table.GetKeys(PlayersInvolved)

                local Log = string.format(Phrase, unpack(Args))
                hook.Run("Gemini.Log", Log, unpack(PlayersInvolved))
            end)
        end
    end
end