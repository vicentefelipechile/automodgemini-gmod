--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:SendGeminiModules")
util.AddNetworkString("Gemini:SetGeminiModel")

local function OnlyThreeSafety(value)
    return isnumber(value) and ( value == math.floor(value) ) and ( value >= 1 ) and ( value <= 4 )
end

--[[------------------------
       Gemini Config
------------------------]]--

Gemini:CreateConfig("ModelName",     "Gemini", Gemini.VERIFICATION_TYPE.string, "gemini-1.5-pro-latest")
Gemini:CreateConfig("Temperature",   "Gemini", Gemini.VERIFICATION_TYPE.range,  0.9)
Gemini:CreateConfig("TopP",          "Gemini", Gemini.VERIFICATION_TYPE.range,  1)
Gemini:CreateConfig("TopK",          "Gemini", Gemini.VERIFICATION_TYPE.range,  1)
Gemini:CreateConfig("MaxTokens",     "Gemini", Gemini.VERIFICATION_TYPE.number, 2048)
Gemini:CreateConfig("APIKey",        "Gemini", Gemini.VERIFICATION_TYPE.string, "YOUR_API_KEY", true)

Gemini:CreateConfig("SafetyHarassment", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetyHateSpeech", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetySexuallyExplicit", "Gemini", OnlyThreeSafety, 2)
Gemini:CreateConfig("SafetyDangerousContent", "Gemini", OnlyThreeSafety, 2)



--[[------------------------
       Retreive Models
------------------------]]--

local GeminiModels = GeminiModels or {}
local function BroadcastGeminiModels(ply)
    local Models = util.TableToJSON(GeminiModels)
    local ModelsCompressed = util.Compress(Models)
    local ModelsSize = #ModelsCompressed

    local NetSend = ( ply == nil ) and net.Broadcast or net.Send

    net.Start("Gemini:SendGeminiModules")
        net.WriteUInt(ModelsSize, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(ModelsCompressed, ModelsSize)
    NetSend(ply)
end

local function RetreiveNewModels()
    local EndPointUrl = Gemini.EndPoint .. "?key=" .. Gemini:GetConfig("APIKey", "Gemini")

    local SuccessRequest = HTTP({
        ["url"] = EndPointUrl,
        ["method"] = "GET",
        ["success"] = function(Code, Body, Headers)
            Gemini:GetHTTPDescription(Code)

            file.Write("gemini_models.txt", Body)

            if ( Code ~= 200 ) then return end

            local Response = util.JSONToTable(Body)
            if ( Response == nil ) then return end

            GeminiModels = Response["models"]

            BroadcastGeminiModels()
        end,
        ["failed"] = function(Error)
            Gemini:Print("Failed to retreive models. Error: " .. Error)
        end
    })

    if ( SuccessRequest == false ) then
        Gemini:Print("Failed to retreive models. HTTP Request failed.")
    else
        Gemini:Print("Retreiving models...")
    end
end

hook.Add("InitPostEntity", "Gemini:RetreiveModels", function()
    timer.Simple(8, function()
        RetreiveNewModels()
    end)

    hook.Add("Gemini:PostInit", "Gemini:RetreiveModels", function()
        RetreiveNewModels()
    end)
end)

hook.Add("Gemini:ConfigChanged", "Gemini:UpdateModels", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string.lower(Name) ~= "apikey" ) then return end

    RetreiveNewModels()
end)

hook.Add("PlayerInitialSpawn", "Gemini:SendGeminiModules", function(Player)
    BroadcastGeminiModels(Player)
end)

function Gemini:GeminiGetModels()
    return table.Copy(GeminiModels)
end

concommand.Add("gemini_reloadmodels", function(ply)
    if ( IsValid(ply) and not Gemini:CanUse(ply, "gemini_automod") ) then return end

    RetreiveNewModels()
end)



--[[------------------------
       Gemini Begin
------------------------]]--

local CurrentGamemodeContext = ""

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
    local CurrentGamemode = self:LanguagePhraseExists("Gamemode." .. engine.ActiveGamemode()) and "Gamemode." .. engine.ActiveGamemode() or "Gamemode.default"
    CurrentGamemodeContext = self:GetPhrase(CurrentGamemode)
end



--[[------------------------
       Safety Settings
------------------------]]--

function Gemini:GemeniGetGeneration()
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



--[[------------------------
       Pre-Parameters
------------------------]]--

function Gemini:GeminiGetContext()
    return self:GetPhrase("context") .. "\n\n" .. CurrentGamemodeContext
end

function Gemini:GeminiGetPlayerLogs(Player, Amount)
    local Logs = self:LoggerFindPlayerLogs(Player, Amount, true)
    local FormatedLogs = ""

    for _, SQLTable in ipairs(Logs) do
        FormatedLogs = FormatedLogs .. "\n" .. SQLTable["geminilog_log"]
    end
    return FormatedLogs
end



--[[------------------------
        AI Structure
------------------------]]--

function Gemini:GeminiCreateBodyRequest()
    --[[ Candidate Structure ]]--
    local Candidate = {
        ["generationConfig"] = self:GemeniGetGeneration(),
        ["safetySettings"] = self:GeminiGetSafety(true),
        ["contents"] = {}
    }

    local MainPrompt = ""

    --[[ Game Context ]]--
    MainPrompt = MainPrompt .. self:GeminiGetContext() .. "\n"

    --[[ Pre-Context ]]--
    MainPrompt = MainPrompt .. self:GetServerInfo() .. "\n\n" .. self:GetRules()

    --[[ Trained Data ]]--
    -- local TrainedData = self:TrainGetTrainings()

    --[[ Output ]]--
    local Contents = {
        {["text"] = MainPrompt}
    }

    --[[
    for _, Train in ipairs(TrainedData) do
        table.insert(Contents, {["text"] = Train["User"], ["role"] = "user"}) -- Previuosly trained data
        table.insert(Contents, {["text"] = Train["Bot"], ["role"] = "model"}) -- Bot response
    end
    --]]

    --[[ Inserting the contents ]]--
    Candidate["contents"] = Contents

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