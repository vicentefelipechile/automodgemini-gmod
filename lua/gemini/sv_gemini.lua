--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

include("gemini/gemini_object.lua")

util.AddNetworkString("Gemini:SendGeminiModules")
util.AddNetworkString("Gemini:SetGeminiModel")
util.AddNetworkString("Gemini:SetGeminiSetting")
util.AddNetworkString("Gemini:SetGeminiGeneration")
util.AddNetworkString("Gemini:SetAPIKey")

local function OnlyThreeSafety(value)
    return isnumber(value) and ( value == math.floor(value) ) and ( value >= 1 ) and ( value <= 4 )
end

--[[------------------------
       Gemini Config
------------------------]]--

Gemini:CreateConfig("ModelName",    "Gemini", Gemini.VERIFICATION_TYPE.string, "gemini-1.5-pro-latest")
Gemini:CreateConfig("Temperature",  "Gemini", Gemini.VERIFICATION_TYPE.range,  0.9)
Gemini:CreateConfig("TopP",         "Gemini", Gemini.VERIFICATION_TYPE.range,  1)
Gemini:CreateConfig("TopK",         "Gemini", Gemini.VERIFICATION_TYPE.number, 1)
Gemini:CreateConfig("MaxTokens",    "Gemini", Gemini.VERIFICATION_TYPE.number, 2048)
Gemini:CreateConfig("APIKey",       "Gemini", Gemini.VERIFICATION_TYPE.string, "YOUR_API_KEY", Gemini.VISIBILITY_TYPE.PRIVATE)

Gemini:CreateConfig("SafetyHarassment", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetyHateSpeech", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetySexuallyExplicit", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetyDangerousContent", "Gemini", OnlyThreeSafety, 2)



--[[------------------------
       Gemini Begin
------------------------]]--

local CurrentLanguage = CurrentLanguage or {}

local SAFETY_ENUM = {
    [1] = GEMINI_ENUM.BLOCK_NONE,
    [2] = GEMINI_ENUM.BLOCK_ONLY_HIGH,
    [3] = GEMINI_ENUM.BLOCK_MEDIUM_AND_ABOVE,
    [4] = GEMINI_ENUM.BLOCK_LOW_AND_ABOVE
}

local SAFETY_TYPE = {
    [GEMINI_ENUM.HARM_CATEGORY_HARASSMENT] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetyHarassment", "Gemini") ] end,
    [GEMINI_ENUM.HARM_CATEGORY_HATE_SPEECH] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetyHateSpeech", "Gemini") ] end,
    [GEMINI_ENUM.HARM_CATEGORY_SEXUALLY_EXPLICIT] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetySexuallyExplicit", "Gemini") ] end,
    [GEMINI_ENUM.HARM_CATEGORY_DANGEROUS_CONTENT] = function() return SAFETY_ENUM[ Gemini:GetConfig("SafetyDangerousContent", "Gemini") ] end
}

function Gemini:GeminiPoblate()
    CurrentLanguage = self:CurrentLanguage()
end



--[[------------------------
       Gemini Functions
------------------------]]--

function Gemini:GeminiGetGeneration(ResponseWithJson)
    return {
        ["temperature"] = self:GetConfig("Temperature", "Gemini"),
        ["topK"] = self:GetConfig("TopK", "Gemini"),
        ["topP"] = self:GetConfig("TopP", "Gemini"),
        ["maxOutputTokens"] = self:GetConfig("MaxTokens", "Gemini"),
        ["stopSequences"] = {},
        -- ["responseMimeType"] = ResponseWithJson and "application/json" or "text/plain"
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
    if isnumber(Logs) then
        local TableLogs = self:LoggerGetLogsLimit(Logs)
        local LogsFormat = {}
        for _, LogInfo in ipairs(TableLogs) do
            table.insert(LogsFormat, LogInfo["geminilog_time"] .. " - " .. LogInfo["geminilog_log"])
        end
        Logs = self:LogsToText(LogsFormat)
    end

    local Candidate = self:GeminiCreateCandidate()
    local MainPrompt = CurrentLanguage.GeneratePrompt(
        self:GetServerInformation(),
        self:GetServerRules(),
        UserMessage, Logs, Gamemode
    )

    --[[ Inserting the contents ]]--
    table.insert(Candidate["contents"], {
        ["parts"] = { ["text"] = MainPrompt },
        ["role"] = "user"
    })

    return Candidate
end


function Gemini:GenerateSimplePrompt(Prompt, Success, LogsAmount) -- BG
    self:Checker({Prompt, "string", 1})

    if not isfunction(Success) then
        self:Error("The second argument of Gemini:GenerateSimplePrompt() must be a function.", Success, "function")
    end

    local Context = ""
    if isnumber(LogsAmount) then
        local Logs = self:LoggerGetLogsLimit(LogsAmount)
        local LogsFormat = {}

        for _, LogInfo in ipairs(Logs) do
            table.insert(LogsFormat, LogInfo["geminilog_time"] .. " - " .. LogInfo["geminilog_log"])
        end

        Context = self:LogsToText(LogsFormat) .. "\n"
    end

    local NewRequest = Gemini:NewRequest()
    NewRequest:AddContent( Context .. Prompt, "user" )
    NewRequest:SetMethod("models/" .. Gemini:GetConfig("ModelName", "Gemini") .. ":generateContent")
    NewRequest:SetVersion("v1")

    local NewPromise = NewRequest:SendRequest()
    NewPromise:Then(function(Response)
        local Candidates = Response:GetFirstCandidate()
        if not Candidates then
            local BlockReason = "Enum.BlockReason." .. Response:GetBlockReason()
            self:Print( self:GetPhrase(BlockReason) )
            return
        end

        local ContentText = Candidates:GetTextContent()
        if not ContentText then return end

        Success(ContentText)
    end):Catch(function(Error)
        self:Print("Error: " .. Error)
    end)
end

concommand.Add("gemini_testprompt", function(ply, _, arg, argStr)
    if IsValid(ply) and not Gemini:CanUse(ply, "gemini_automod") then return end

    local Prompt = "What is the meaning of life?"
    local LogsAmount = nil

    if arg[1] then
        LogsAmount = tonumber(arg[1])
    end

    if arg[2] then
        local argSplit = string.Explode(" ", argStr)
        table.remove(argSplit, 1)
        Prompt = table.concat(argSplit, " ")
    end

    Gemini:GenerateSimplePrompt(Prompt, function(Content)
        print(Content)
    end, LogsAmount)
end)



--[[------------------------
       Hook Functions
------------------------]]--

local GeminiConfigAllowedInAVeryGoodTable = {
    ["ModelName"] =     function() SetGlobal2String("Gemini:ModelName", Gemini:GetConfig("ModelName", "Gemini")) end,
    ["Temperature"] =   function() SetGlobal2Float("Gemini:Temperature", Gemini:GetConfig("Temperature", "Gemini")) end,
    ["TopP"] =          function() SetGlobal2Float("Gemini:TopP", Gemini:GetConfig("TopP", "Gemini")) end,
    ["TopK"] =          function() SetGlobal2Float("Gemini:TopK", Gemini:GetConfig("TopK", "Gemini")) end,
    ["MaxTokens"] =     function() SetGlobal2Int("Gemini:MaxTokens", Gemini:GetConfig("MaxTokens", "Gemini")) end,
    ["SafetyHarassment"] = function() SetGlobal2Int("Gemini:SafetyHarassment", Gemini:GetConfig("SafetyHarassment", "Gemini")) end,
    ["SafetyHateSpeech"] = function() SetGlobal2Int("Gemini:SafetyHateSpeech", Gemini:GetConfig("SafetyHateSpeech", "Gemini")) end,
    ["SafetySexuallyExplicit"] = function() SetGlobal2Int("Gemini:SafetySexuallyExplicit", Gemini:GetConfig("SafetySexuallyExplicit", "Gemini")) end,
    ["SafetyDangerousContent"] = function() SetGlobal2Int("Gemini:SafetyDangerousContent", Gemini:GetConfig("SafetyDangerousContent", "Gemini")) end
}

hook.Add("Gemini:ConfigChanged", "Gemini:ReplicateGemini", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string.lower(Name) == "apikey" ) then return end

    if ( GeminiConfigAllowedInAVeryGoodTable[Name] ) then
        GeminiConfigAllowedInAVeryGoodTable[Name]()
    else
        Gemini:Print("The config " .. Name .. " is not allowed to be replicated.")
    end
end)

hook.Add("Gemini:ConfigChanged", "Gemini:APIKeyIsSetted", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string.lower(Name) ~= "apikey" ) then return end

    SetGlobal2Bool("Gemini:APIKeyEnabled", Value ~= "YOUR_API_KEY")
end)

hook.Add("PostGamemodeLoaded", "Gemini:GeminiSetGlobal", function()
    for Name, Func in pairs(GeminiConfigAllowedInAVeryGoodTable) do
        Func()
    end

    SetGlobal2Bool("Gemini:APIKeyEnabled", Gemini:GetConfig("APIKey", "Gemini") ~= "YOUR_API_KEY")
end)

local function BroadcastGeminiModels(ply)
    local Models = util.TableToJSON( Gemini:GetModels() )
    local ModelsCompressed = util.Compress(Models)
    local ModelsSize = #ModelsCompressed

    local NetSend = ( isentity(ply) and ply:IsPlayer() ) and net.Send or net.Broadcast

    net.Start("Gemini:SendGeminiModules")
        net.WriteUInt(ModelsSize, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(ModelsCompressed, ModelsSize)
    NetSend(ply)
end

hook.Add("PlayerInitialSpawn", "Gemini:SendGeminiModules", BroadcastGeminiModels)
hook.Add("Gemini:ModelsReloaded", "Gemini:SendGeminiModules", BroadcastGeminiModels)



--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:SetGeminiModel", function(_, ply)
    if ( not Gemini:CanUse(ply, "gemini_config_set") ) then return end

    local ModelName = net.ReadString()
    Gemini:SetConfig("ModelName", "Gemini", ModelName)
end)

net.Receive("Gemini:SetGeminiSetting", function(_, ply)
    if ( not Gemini:CanUse(ply, "gemini_config_set") ) then return end

    local SettingName = net.ReadString()
    if ( GeminiConfigAllowedInAVeryGoodTable[SettingName] == nil ) then return end

    local SettingValue = net.ReadType(Gemini.Util.DefaultNetworkType[SettingName])
    Gemini:SetConfig(SettingName, "Gemini", SettingValue)
end)

net.Receive("Gemini:SetGeminiGeneration", function(_, ply)
    if ( not Gemini:CanUse(ply, "gemini_config_set") ) then return end

    local GenerationTable = net.ReadTable()
    if ( not istable(GenerationTable) ) then return end

    for SettingName, SettingValue in pairs(GenerationTable) do
        if ( GeminiConfigAllowedInAVeryGoodTable[SettingName] == nil ) then continue end
        Gemini:SetConfig(SettingName, "Gemini", SettingValue)
    end
end)

net.Receive("Gemini:SetAPIKey", function(_, ply)
    if ( not Gemini:CanUse(ply, "gemini_config_set") ) then return end

    local APIKey = net.ReadString()
    Gemini:SetConfig("APIKey", "Gemini", APIKey)

    net.Start("Gemini:SetAPIKey")
    net.Broadcast()
end)