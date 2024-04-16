--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

--[[------------------------
       Gemini Config
------------------------]]--

Gemini:CreateConfig("ModelTarget",   "Gemini", Gemini.VERIFICATION_TYPE.string,    "auto")
Gemini:CreateConfig("ModelName",     "Gemini", Gemini.VERIFICATION_TYPE.string,    "gemini-1.0-pro")
Gemini:CreateConfig("Temperature",   "Gemini", Gemini.VERIFICATION_TYPE.range,     0.9)
Gemini:CreateConfig("TopP",          "Gemini", Gemini.VERIFICATION_TYPE.range,     1)
Gemini:CreateConfig("TopK",          "Gemini", Gemini.VERIFICATION_TYPE.range,     1)
Gemini:CreateConfig("MaxTokens",     "Gemini", Gemini.VERIFICATION_TYPE.number,    2048)
Gemini:CreateConfig("APIKey",        "Gemini", Gemini.VERIFICATION_TYPE.string,    "YOUR_API_KEY", true)
Gemini:CreateConfig("DebugEnabled",  "Gemini", Gemini.VERIFICATION_TYPE.bool,      false)
Gemini:CreateConfig("DebugMessage",  "Gemini", Gemini.VERIFICATION_TYPE.string,    "Make a summary of the logs of the player.")

Gemini:CreateConfig("SafetyHarassment", "Gemini", Gemini.VERIFICATION_TYPE.number, 2)
Gemini:CreateConfig("SafetyHateSpeech", "Gemini", Gemini.VERIFICATION_TYPE.number, 2)
Gemini:CreateConfig("SafetySexuallyExplicit", "Gemini", Gemini.VERIFICATION_TYPE.number, 2)
Gemini:CreateConfig("SafetyDangerousContent", "Gemini", Gemini.VERIFICATION_TYPE.number, 2)

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

function Gemini:GenerationResetConfig()
    self:ResetConfig("ModelName", "Gemini")
    self:ResetConfig("Temperature", "Gemini")
    self:ResetConfig("TopP", "Gemini")
    self:ResetConfig("TopK", "Gemini")
    self:ResetConfig("MaxTokens", "Gemini")

    self:Print("Generation reseted to default settings.")
end

function Gemini:GetGenerationConfig()
    return {
        ["temperature"] = self:GetConfig("Temperature", "Gemini"),
        ["topK"] = self:GetConfig("TopK", "Gemini"),
        ["topP"] = self:GetConfig("TopP", "Gemini"),
        ["maxOutputTokens"] = self:GetConfig("MaxTokens", "Gemini"),
        ["stopSequences"] = {}
    }
end

local CacheSafety = {}
function Gemini:GetSafetyConfig(UseCache)
    if ( UseCache == true and CacheSafety ) then return CacheSafety end

    local SafetySettings = {}

    for Category, FuncValue in pairs(SAFETY_TYPE) do
        table.insert(SafetySettings, {
            ["category"] = Category,
            ["threshold"] = FuncValue()
        })
    end

    CacheSafety = SafetySettings

    return SafetySettings
end



--[[------------------------
       Pre-Parameters
------------------------]]--

function Gemini:GetGamemodeContext()
    return self:GetPhrase("context") .. "\n\n" .. CurrentGamemodeContext
end

function Gemini:GetLogsOfPlayer(Player, Amount)
    local Logs = self:LoggerGetLogsPlayer(Player, Amount, true)
    local FormatedLogs = ""

    for _, SQLTable in ipairs(Logs) do
        FormatedLogs = FormatedLogs .. "\n" .. SQLTable["geminilog_log"]
    end
    return FormatedLogs
end



--[[------------------------
        AI Structure
------------------------]]--

--[[

1- Game Context
2- Pre-Context (Server owner config)
3- Trained Data
4- Player-related logs
5- Post-Context (Server owner config)
6- Output

--]]

function Gemini:CreateBodyStructure(Player, Limit)
    --[[ Gemini Structure ]]--
    local GeminiStructure = {
        ["generationConfig"] = self:GetGenerationConfig(),
        ["safetySettings"] = self:GetSafetyConfig(true),
        ["contents"] = {}
    }

    --[[ Game Context ]]--
    local GameContext = self:GetGamemodeContext()

    --[[ Pre-Context ]]--
    local PreContext = self:LoadServerConfig("precontext")

    --[[ Trained Data ]]--
    local TrainedData = self:LoggerGetTrainedData() -- this return a key-value table with the trained data

    --[[ Player-related logs ]]--
    local PlayerLogs = self:GetLogsOfPlayer(Player, Limit)

    --[[ Post-Context ]]--
    local PostContext = self:LoadServerConfig("postcontext")

    --[[ Output ]]--
    local Contents = {
        {["text"] = GameContext, ["role"] = "user"},
        {["text"] = PreContext, ["role"] = "user"}
    }

    for _, Train in ipairs(TrainedData) do
        table.insert(Contents, {["text"] = Train["User"], ["role"] = "user"}) -- Previuosly trained data
        table.insert(Contents, {["text"] = Train["Bot"], ["role"] = "model"}) -- Bot response
    end

    table.insert(Contents, {["text"] = PlayerLogs, ["role"] = "user"})
    table.insert(Contents, {["text"] = PostContext, ["role"] = "user"})

    return GeminiStructure
end



--[[------------------------
        HTTP Request
------------------------]]--

local function HandleGeminiResponse(Code, BodyResponse, Headers)
    local DebugEnabled = Gemini:GetConfig("DebugEnabled", "Gemini")
    Gemini:GetHTTPDescription(Code)

    if ( Code == 200 ) then
        if DebugEnabled then
            file.Write("gemini_response.txt", BodyResponse)
        end

        Gemini:Print("Response from Gemini API: " .. util.JSONToTable(BodyResponse)["candidates"][1]["content"]["parts"][1]["text"])
    end
end

function Gemini:MakeRequest(Data)
    local DebugEnabled = self:GetConfig("DebugEnabled", "Gemini")

    --[[ Body ]]--
    local GeminiModel = self:GetConfig("ModelName", "Gemini")
    local GamemodeModel = self:GetGamemodeContext()
    local GenerationConfig = self:GetGenerationConfig()
    local SafetyConfig = self:GetSafetyConfig()

    local Parts = {
        {["text"] = GamemodeModel, ["role"] = "user"}
    }

    local Body = {
        ["generationConfig"] = GenerationConfig,
        ["safetySettings"] = SafetyConfig
    }

    for _, SubData in ipairs(Data) do
        table.insert(Parts, {["text"] = SubData["Text"], ["role"] = SubData["Role"] or "user"})
    end

    --[[ Debug ]]--
    if DebugEnabled then
        table.insert(Parts, {["text"] = self:GetConfig("DebugMessage", "Gemini")})
    end

    Body["contents"] = {{["parts"] = Parts}}
    local APIKey = self:GetConfig("APIKey", "Gemini")

    --[[ Debug ]]--
    if DebugEnabled then
        file.Write("gemini_request.txt", util.TableToJSON(Body, true))
    end

    --[[ Request ]]--
    local RequestMade = HTTP({
        ["url"] = string.format(self.URL, GeminiModel, APIKey),
        ["method"] = "POST",
        ["type"] = "application/json",
        ["body"] = util.TableToJSON(Body),
        ["success"] = HandleGeminiResponse,
        ["failed"] = function(Error)
            self:Print("Failed to make request to Gemini API. Error: ", Error)
        end
    })

    if RequestMade then
        self:Print("Request made to Gemini API.")
    else
        self:Print("Failed to make request to Gemini API.")
        self:Print("Make sure you make a valid body request.")
    end
end