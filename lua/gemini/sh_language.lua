--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Language Module
----------------------------------------------------------------------------]]--

local CurrentLanguage = {}
local LanguageList = {}

--[[------------------------
        Configuration
------------------------]]--

Gemini:CreateConfig("CloseToPlayer", "Language", Gemini.VERIFICATION_TYPE.number, 300)

--[[------------------------
        NPC Names
------------------------]]--

if SERVER then
    local NPCNamesPath = "resource/language/npc-ents_english.txt"
    local NPCNames = {}

    if ( file.Exists(NPCNamesPath, "GAME") ) then
        local FileContent = util.KeyValuesToTable(file.Read(NPCNamesPath, "GAME"))
        local FileTokens = FileContent["tokens"] or {}

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
end

--[[------------------------
       Language Module
------------------------]]--

local LANG_MODULE = {}
do
    if SERVER then
        AddCSLuaFile("gemini/language/module.lua")
    end
    LANG_MODULE = include("gemini/language/module.lua")
end

function Gemini:CurrentLanguage()
    return CurrentLanguage
end

function Gemini:LanguageCreate(LanguageTarget)
    self:Checker({LanguageTarget, "string", 1})

    CurrentLanguage = table.Copy(LANG_MODULE)
    CurrentLanguage.Name = LanguageTarget

    return CurrentLanguage
end

function Gemini:GetPhrase(PhraseName)
    if ( CurrentLanguage == nil ) then
        return PhraseName
    end

    self:Checker({PhraseName, "string", 1})

    return CurrentLanguage:GetPhrase(PhraseName)
end

function Gemini:LanguagePhraseExists(PhraseName)
    self:Checker({PhraseName, "string", 1})

    return CurrentLanguage:PhraseExists(PhraseName)
end

function Gemini:LanguagePoblate()
    local LanguageTarget = string.lower( Gemini:GetConfig("Language", "General") )
    local LangFile, _ = file.Find("gemini/language/" .. LanguageTarget .. "/*.lua", "LUA")

    for _, FileName in ipairs(LangFile) do
        if SERVER then
            AddCSLuaFile("gemini/language/" .. LanguageTarget .. "/" .. FileName)
        end
    end

    include("gemini/language/" .. LanguageTarget .. "/main.lua")

    local _, ExistingLanguages = file.Find("gemini/language/*", "LUA")
    for _, Language in ipairs(ExistingLanguages) do
        table.insert(LanguageList, Language)
    end

    if CLIENT then return end

    for HookName, HookTable in pairs( CurrentLanguage:GetHooks() ) do
        hook.Add(HookName, "GeminiLanguageHook:" .. CurrentLanguage.Name .. "." .. HookName, function(...)
            local Args = HookTable["Function"](...)
            local Phrase = HookTable["Phrase"]

            if ( Args == false ) then return end

            local PlayersInvolved = {}
            for _, any in ipairs({...}) do
                if ( isentity(any) and any:IsPlayer() ) then
                    PlayersInvolved[any] = true
                end
            end

            PlayersInvolved = table.GetKeys(PlayersInvolved)
            if ( #PlayersInvolved >= 1 ) then
                local Log = string.format(Phrase, unpack(Args))
                hook.Run("Gemini:Log", Log, unpack(PlayersInvolved))
            end
        end)
    end
end

function Gemini:GetLanguages()
    return table.Copy(LanguageList)
end