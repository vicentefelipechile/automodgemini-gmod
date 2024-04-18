--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Language Module
----------------------------------------------------------------------------]]--

local Language = Language or {}

--[[------------------------
        Configuration
------------------------]]--

Gemini:CreateConfig("CloseToPlayer", "Language", Gemini.VERIFICATION_TYPE.number, 300)

--[[------------------------
        NPC Names
------------------------]]--

local NPCNamesPath = "resource/language/npc-ents_english.txt"
local NPCNames = {}

if ( file.Exists(NPCNamesPath, "GAME") ) then
    local FileContent = util.KeyValuesToTable(file.Read(NPCNamesPath, "GAME"))
    local FileTokens = FileContent["tokens"] or FileContent["Tokens"] or {}

    for NameClass, NameEntity in pairs(FileTokens) do
        NPCNames[NameClass] = NameEntity
    end
end

hook.Add("GetDeathNoticeEntityName", "GeminiLanguageHook:General.GetDeathNoticeEntityName", function(ent)
    local EntityClass = ent:GetClass()
    if ( NPCNames[EntityClass] ) then
        return NPCNames[EntityClass]
    end
end)

--[[------------------------
       Language Module
------------------------]]--

function Gemini:LanguageCreate(LanguageTarget)
    Language[LanguageTarget] = {}

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

        Language[LanguageTarget][HookName]["Func"] = HookFunc
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

    if not istable(Language[LanguageTarget]) then
        self:Error([[The language target does not exist]], LanguageTarget, "string")
    end

    Language[LanguageTarget][PhraseName] = {["Phrase"] = Phrase, ["Func"] = Gemini.Util.ReturnNoneFunction}
end

local LanguageTargetCache = Gemini:GetConfig("Language", "General", true)
function Gemini:GetPhrase(PhraseName, LanguageTarget, SkipValidation)
    LanguageTarget = LanguageTarget or LanguageTargetCache

    if ( SkipValidation == true ) then
        return Language[LanguageTarget][PhraseName]["Phrase"]
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

    if not istable(Language[LanguageTarget]) then
        self:Error([[The language target does not exist]], LanguageTarget, "string")
    end

    if not istable(Language[LanguageTarget][PhraseName]) then
        self:Error([[The phrase does not exist in the language target]], PhraseName, "string")
    end

    return Language[LanguageTarget][PhraseName]["Phrase"]
end

Gemini.LanguageGetPhrase = Gemini.GetPhrase

function Gemini:LanguagePhraseExists(PhraseName, LanguageTarget)
    LanguageTarget = LanguageTarget or LanguageTargetCache

    if not isstring(PhraseName) then return nil
    elseif (PhraseName == "") then return nil
    end

    if not isstring(LanguageTarget) then return nil
    elseif (LanguageTarget == "") then return nil
    end

    if not istable(Language[LanguageTarget]) then return nil end

    return istable(Language[LanguageTarget][PhraseName])
end

function Gemini:LanguagePoblate()
    local LangFile, _ = file.Find("gemini/language/*.lua", "LUA")

    for _, File in ipairs(LangFile) do
        if SERVER then
            AddCSLuaFile("gemini/language/" .. File)
        end
        include("gemini/language/" .. File)
        self:Print("Loaded language file: " .. File)
    end

    -- The client does not need to poblate the hook functions
    if CLIENT then return end

    -- Poblate hook functions
    for LangName, LangTable in pairs(Language) do
        for HookName, HookTable in pairs(LangTable) do
            if ( HookTable["Func"] == Gemini.Util.ReturnNoneFunction ) then continue end

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

                if ( #PlayersInvolved >= 1 ) then
                    hook.Run("Gemini.Log", Log, unpack(PlayersInvolved))
                end
            end)
        end
    end
end

hook.Add("Gemini:ConfigChanged", "Gemini:UpdateMainLanguage", function(Name, Category, Value)
    if ( Name == "Language" and Category == "General" ) then
        LanguageTargetCache = Value
    end
end)