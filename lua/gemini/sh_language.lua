--[[----------------------------------------------------------------------------
                        Google Gemini Automod - Language
----------------------------------------------------------------------------]]--

local EmptyFunc = function() return "" end

Gemini.__LANG = Gemini.__LANG or {}

function Gemini:CreateLanguage(LanguageTarget)
    if istable(self.__LANG[LanguageTarget]) then
        self:Error([[The first argument of Gemini:CreateLanguage() already exists]], LanguageTarget, [[string]])
    end
    Gemini.__LANG[LanguageTarget] = {}

    return LanguageTarget
end

function Gemini:OverrideHookLanguage(LanguageTarget, TableFunctions)
    if not isstring(LanguageTarget) then
        self:Error([[The first argument of Gemini:OverrideHookLanguage() is not a string]], LanguageTarget, "string")
    elseif (LanguageTarget == "") then
        self:Error([[The first argument of Gemini:OverrideHookLanguage() is an empty string]], LanguageTarget, "string")
    end

    if not istable(TableFunctions) then
        self:Error([[The second argument of Gemini:OverrideHookLanguage() is not a table]], TableFunctions, "table[function]")
    end

    for HookName, HookFunc in pairs(TableFunctions) do
        if not isfunction(HookFunc) then
            self:Error("The function \"" .. HookName .. "\" is not a valid function", HookFunc, "function")
        end

        self.__LANG[LanguageTarget][HookName]["Func"] = HookFunc
    end
end

function Gemini:AddPhrase(LanguageTarget, PhraseName, Phrase)
    if not isstring(LanguageTarget) then
        self:Error([[The first argument of Gemini:AddPhrase() is not a string]], LanguageTarget, "string")
    elseif (LanguageTarget == "") then
        self:Error([[The first argument of Gemini:AddPhrase() is an empty string]], LanguageTarget, "string")
    end

    if not isstring(PhraseName) then
        self:Error([[The second argument of Gemini:AddPhrase() is not a string]], PhraseName, "string")
    elseif (PhraseName == "") then
        self:Error([[The second argument of Gemini:AddPhrase() is an empty string]], PhraseName, "string")
    end

    if not isstring(Phrase) then
        self:Error([[The third argument of Gemini:AddPhrase() is not a string]], Phrase, "string")
    elseif (Phrase == "") then
        self:Error([[The third argument of Gemini:AddPhrase() is an empty string]], Phrase, "string")
    end

    if not istable(self.__LANG[LanguageTarget]) then
        self:Error([[The language target does not exist]], LanguageTarget, "string")
    end

    self.__LANG[LanguageTarget][PhraseName] = {["Phrase"] = Phrase, ["Func"] = EmptyFunc}
end

function Gemini:PoblateLanguages()
    local LangFile, _ = file.Find("gemini/language/*.lua", "LUA")

    for _, File in ipairs(LangFile) do
        include("gemini/language/" .. File)
        self:Print("Loaded language file: " .. File)
    end

    -- Poblate hook functions
    for LangName, LangTable in pairs(self.__LANG) do
        for HookName, HookTable in pairs(LangTable) do
            hook.Add(HookName, "GeminiLanguageHook:" .. LangName .. "." .. HookName, function(...)
                local Args = HookTable["Func"](...)
                local Phrase = HookTable["Phrase"]

                local Log = string.format(Phrase, unpack(Args))
                self:Print(Log)
            end)
        end
    end
end