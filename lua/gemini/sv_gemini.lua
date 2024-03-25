--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

--[[------------------------
       Gamemode Models
------------------------]]--

Gemini.__MODELS = Gemini.__MODELS or {
    ["default"] = nil,
    ["sandbox"] = nil,
    ["darkrp"] = nil,
    ["terrortown"] = nil,
    ["trashcompactor"] = nil
}

function Gemini:GeminiPoblate()
    self.__MODELS["default"] = self:GetPhrase("default")
    self.__MODELS["sandbox"] = self:GetPhrase("sandbox")
    self.__MODELS["darkrp"] = self:GetPhrase("darkrp")
    self.__MODELS["terrortown"] = self:GetPhrase("terrortown")
    self.__MODELS["trashcompactor"] = self:GetPhrase("trashcompactor")

    self:AddConfig("ModelTarget",   "Gemini", self.VERIFICATION_TYPE.string,    "auto")
    self:AddConfig("ModelName",     "Gemini", self.VERIFICATION_TYPE.string,    "gemini-1.0-pro")
    self:AddConfig("Temperature",   "Gemini", self.VERIFICATION_TYPE.number,    0.9)
    self:AddConfig("TopP",          "Gemini", self.VERIFICATION_TYPE.number,    1)
    self:AddConfig("TopK",          "Gemini", self.VERIFICATION_TYPE.number,    1)
    self:AddConfig("MaxTokens",     "Gemini", self.VERIFICATION_TYPE.number,    2048)
    self:AddConfig("APIKey",        "Gemini", self.VERIFICATION_TYPE.string,    "YOUR_API_KEY", true)
    self:AddConfig("DebugEnabled",  "Gemini", self.VERIFICATION_TYPE.bool,      false)
    self:AddConfig("DebugMessage",  "Gemini", self.VERIFICATION_TYPE.string,    "Make a summary of the logs of the player.")

    -- Safety settings
    self:AddConfig("SafetyHarassment", "Gemini", self.VERIFICATION_TYPE.number, 2)
    self:AddConfig("SafetyHateSpeech", "Gemini", self.VERIFICATION_TYPE.number, 2)
    self:AddConfig("SafetySexuallyExplicit", "Gemini", self.VERIFICATION_TYPE.number, 2)
    self:AddConfig("SafetyDangerousContent", "Gemini", self.VERIFICATION_TYPE.number, 2)

    self.__SAFETY_ENUM = {
        [1] = "BLOCK_LOW_AND_ABOVE",
        [2] = "BLOCK_MEDIUM_AND_ABOVE",
        [3] = "BLOCK_ONLY_HIGH"
    }

    self.__SAFETY_TYPE = {
        ["HARM_CATEGORY_HARASSMENT"] = function() return self.__SAFETY_ENUM[ self:GetConfig("SafetyHarassment", "Gemini") ] end,
        ["HARM_CATEGORY_HATE_SPEECH"] = function() return self.__SAFETY_ENUM[ self:GetConfig("SafetyHateSpeech", "Gemini") ] end,
        ["HARM_CATEGORY_SEXUALLY_EXPLICIT"] = function() return self.__SAFETY_ENUM[ self:GetConfig("SafetySexuallyExplicit", "Gemini") ] end,
        ["HARM_CATEGORY_DANGEROUS_CONTENT"] = function() return self.__SAFETY_ENUM[ self:GetConfig("SafetyDangerousContent", "Gemini") ] end
    }
end



--[[------------------------
       Safety Settings
------------------------]]--

function Gemini:GenerationResetConfig()
    self:SetConfig("ModelTarget", "auto", "Gemini")
    self:SetConfig("ModelName", "gemini-1.0-pro", "Gemini")
    self:SetConfig("Temperature", 0.9, "Gemini")
    self:SetConfig("TopP", 1, "Gemini")
    self:SetConfig("TopK", 1, "Gemini")
    self:SetConfig("MaxTokens", 2048, "Gemini")

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

    for Category, FuncValue in pairs(self.__SAFETY_TYPE) do
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
    local ModelTarget = self:GetConfig("ModelTarget", "Gemini")

    if ( ModelTarget == "auto" ) then
        local GamemodeModel = self.__MODELS[engine.ActiveGamemode()] or self.__MODELS["default"]

        return self:GetPhrase("context") .. "\n\n" .. GamemodeModel
    else
        return self:GetPhrase("context") .. "\n\n" .. self.__MODELS[ModelTarget]
    end
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