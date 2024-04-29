--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

local function OnlyThreeSafety(value)
    return isnumber(value) and ( value == math.floor(value) ) and ( value >= 1 ) and ( value <= 3 )
end

--[[------------------------
       Gemini Config
------------------------]]--

Gemini:CreateConfig("ModelName",     "Gemini", Gemini.VERIFICATION_TYPE.string, "gemini-1.0-pro")
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
       Gemini Begin
------------------------]]--

local CurrentGamemodeContext = ""

local SAFETY_ENUM = {
    [1] = "BLOCK_LOW_AND_ABOVE",
    [2] = "BLOCK_MEDIUM_AND_ABOVE",
    [3] = "BLOCK_ONLY_HIGH"
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

    if OnlyThreeSafety(Value) then
        SetGlobal2Float("Gemini:" .. Name, Value)
    elseif isnumber(Value) then
        SetGlobal2Int("Gemini:" .. Name, Value)
    else
        SetGlobal2String("Gemini:" .. Name, Value)
    end
end)

hook.Add("PostGamemodeLoaded", "Gemini:GeminiSetGlobal", function()
    SetGlobal2String("Gemini:ModelName", Gemini:GetConfig("ModelName", "Gemini"))
    SetGlobal2Float("Gemini:Temperature", Gemini:GetConfig("Temperature", "Gemini"))
    SetGlobal2Float("Gemini:TopP", Gemini:GetConfig("TopP", "Gemini"))
    SetGlobal2Float("Gemini:TopK", Gemini:GetConfig("TopK", "Gemini"))
    SetGlobal2Int("Gemini:MaxTokens", Gemini:GetConfig("MaxTokens", "Gemini"))
end)