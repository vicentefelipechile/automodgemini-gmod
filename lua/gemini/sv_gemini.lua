--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

include("gemini/gemini_object.lua")

util.AddNetworkString("Gemini:SendGeminiModules")
util.AddNetworkString("Gemini:SetGeminiModel")

local function OnlyThreeSafety(value)
    return isnumber(value) and ( value == math.floor(value) ) and ( value >= 1 ) and ( value <= 4 )
end

--[[------------------------
       Gemini Config
------------------------]]--

Gemini:CreateConfig("ModelName",    "Gemini", Gemini.VERIFICATION_TYPE.string, "gemini-1.5-pro-latest")
Gemini:CreateConfig("Temperature",  "Gemini", Gemini.VERIFICATION_TYPE.range,  0.9)
Gemini:CreateConfig("TopP",         "Gemini", Gemini.VERIFICATION_TYPE.range,  1)
Gemini:CreateConfig("TopK",         "Gemini", Gemini.VERIFICATION_TYPE.range,  1)
Gemini:CreateConfig("MaxTokens",    "Gemini", Gemini.VERIFICATION_TYPE.number, 2048)
Gemini:CreateConfig("APIKey",       "Gemini", Gemini.VERIFICATION_TYPE.string, "YOUR_API_KEY", true)

Gemini:CreateConfig("SafetyHarassment", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetyHateSpeech", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetySexuallyExplicit", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetyDangerousContent", "Gemini", OnlyThreeSafety, 2)



--[[------------------------
       Gemini Begin
------------------------]]--

local CurrentLanguage = CurrentLanguage or {}

local SAFETY_ENUM = {
    [1] = "BLOCK_NONE",
    [2] = "BLOCK_ONLY_HIGH",
    [3] = "BLOCK_MEDIUM_AND_ABOVE",
    [4] = "BLOCK_LOW_AND_ABOVE"
}

local SAFETY_TYPE = {
    ["HARM_CATEGORY_HARASSMENT"] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetyHarassment", "Gemini") ] end,
    ["HARM_CATEGORY_HATE_SPEECH"] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetyHateSpeech", "Gemini") ] end,
    ["HARM_CATEGORY_SEXUALLY_EXPLICIT"] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetySexuallyExplicit", "Gemini") ] end,
    ["HARM_CATEGORY_DANGEROUS_CONTENT"] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetyDangerousContent", "Gemini") ] end
}

function Gemini:GeminiPoblate()
    CurrentLanguage = self:CurrentLanguage()
end



--[[------------------------
       Retreive Models
------------------------]]--

local function BroadcastGeminiModels(ply)
    local Models = util.TableToJSON( Gemini:GetModels() )
    local ModelsCompressed = util.Compress(Models)
    local ModelsSize = #ModelsCompressed

    local NetSend = ( ply == nil ) and net.Broadcast or net.Send

    net.Start("Gemini:SendGeminiModules")
        net.WriteUInt(ModelsSize, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(ModelsCompressed, ModelsSize)
    NetSend(ply)
end

hook.Add("PlayerInitialSpawn", "Gemini:SendGeminiModules", function(Player)
    BroadcastGeminiModels(Player)
end)



--[[------------------------
       Gemini Functions
------------------------]]--

function Gemini:GeminiGetGeneration(ResponseWithJson)
    return {
        ["temperature"] = self:GetConfig("Temperature", "Gemini"),
        ["topK"] = self:GetConfig("TopK", "Gemini"),
        ["topP"] = self:GetConfig("TopP", "Gemini"),
        ["maxOutputTokens"] = self:GetConfig("MaxTokens", "Gemini"),
        ["stopSequences"] = {}
    }
end

function Gemini:GeminiGetSafety()
    local SafetySettings = {}

    for Category, FuncValue in pairs(SAFETY_TYPE) do
        table.insert(SafetySettings, {
            ["category"] = Category,
            ["threshold"] = FuncValue()
        })
    end

    return SafetySettings
end

function Gemini:GeminiGetPlayerLogs(Player, Amount)
    local Logs = self:LoggerFindPlayerLogs(Player, Amount, true)
    local FormatedLogs = ""

    for _, SQLTable in ipairs(Logs) do
        FormatedLogs = FormatedLogs .. "\n" .. SQLTable["geminilog_log"]
    end
    return FormatedLogs
end

function Gemini:GeminiCreateCandidate()
    return {
        ["generationConfig"] = self:GeminiGetGeneration(),
        ["safetySettings"] = self:GeminiGetSafety(),
        ["contents"] = {}
    }
end

function Gemini:GeminiCreateBodyRequest(UserMessage, Logs, Gamemode)
    local Candidate = self:GeminiCreateCandidate()
    local MainPrompt = CurrentLanguage.GeneratePrompt(
        self:GetServerInfo(),
        self:GetRules(),
        UserMessage, Logs, Gamemode
    )

    --[[ Inserting the contents ]]--
    Candidate["contents"] = {
        {
            ["parts"] = {["text"] = MainPrompt},
            ["role"] = "user"
        }
    }

    return Candidate
end



--[[------------------------
       Hook Functions
------------------------]]--

hook.Add("Gemini:ConfigChanged", "Gemini:ReplicateGemini", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string.lower(Name) == "apikey" ) then return end

    local IsSafety = string.StartsWith(Name, "Safety")
    if ( IsSafety == true ) then
        SetGlobal2Int("Gemini:" .. Name, Value)
    elseif isnumber(Value) then
        SetGlobal2Int("Gemini:" .. Name, Value)
    else
        SetGlobal2String("Gemini:" .. Name, Value)
    end
end)

hook.Add("Gemini:ConfigChanged", "Gemini:APIKeyIsSetted", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string.lower(Name) ~= "apikey" ) then return end

    SetGlobal2Bool("Gemini:APIKeyEnabled", Value ~= "YOUR_API_KEY")
end)

hook.Add("PostGamemodeLoaded", "Gemini:GeminiSetGlobal", function()
    SetGlobal2String("Gemini:ModelName", Gemini:GetConfig("ModelName", "Gemini"))
    SetGlobal2Float("Gemini:Temperature", Gemini:GetConfig("Temperature", "Gemini"))
    SetGlobal2Float("Gemini:TopP", Gemini:GetConfig("TopP", "Gemini"))
    SetGlobal2Float("Gemini:TopK", Gemini:GetConfig("TopK", "Gemini"))
    SetGlobal2Int("Gemini:MaxTokens", Gemini:GetConfig("MaxTokens", "Gemini"))
    SetGlobal2Int("Gemini:SafetyHarassment", Gemini:GetConfig("SafetyHarassment", "Gemini") )
    SetGlobal2Int("Gemini:SafetyHateSpeech", Gemini:GetConfig("SafetyHateSpeech", "Gemini") )
    SetGlobal2Int("Gemini:SafetySexuallyExplicit", Gemini:GetConfig("SafetySexuallyExplicit", "Gemini") )
    SetGlobal2Int("Gemini:SafetyDangerousContent", Gemini:GetConfig("SafetyDangerousContent", "Gemini") )

    SetGlobal2Bool("Gemini:APIKeyEnabled", Gemini:GetConfig("APIKey", "Gemini") ~= "YOUR_API_KEY")
end)



--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:SetGeminiModel", function(_, ply)
    if ( not Gemini:CanUse(ply, "gemini_config_set") ) then return end

    local ModelName = net.ReadString()
    Gemini:SetConfig("ModelName", "Gemini", ModelName)
end)