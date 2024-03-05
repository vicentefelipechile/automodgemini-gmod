--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

Gemini.__MODELS = Gemini.__MODELS or {
    ["default"] = nil,
    ["sandbox"] = nil,
    ["darkrp"] = nil,
    ["terrortown"] = nil,
    ["trashcompactor"] = nil
}

function Gemini:LoadModels()
    self.LanguageTarget = self:GetConfig("Language", "General", true)

    self.__MODELS["default"] = self:GetPhrase(self.LanguageTarget, "default")
    self.__MODELS["sandbox"] = self:GetPhrase(self.LanguageTarget, "sandbox")
    self.__MODELS["darkrp"] = self:GetPhrase(self.LanguageTarget, "darkrp")
    self.__MODELS["terrortown"] = self:GetPhrase(self.LanguageTarget, "terrortown")
    self.__MODELS["trashcompactor"] = self:GetPhrase(self.LanguageTarget, "trashcompactor")

    self:AddConfig("ModelTarget", "Gemini", self.VERIFICATION_TYPE.string, "auto")
    self:AddConfig("ModelName", "Gemini", self.VERIFICATION_TYPE.string, "gemini-1.0-pro")
    self:AddConfig("Temperature", "Gemini", self.VERIFICATION_TYPE.number, 0.9)
    self:AddConfig("TopP", "Gemini", self.VERIFICATION_TYPE.number, 1)
    self:AddConfig("TopK", "Gemini", self.VERIFICATION_TYPE.number, 1)
    self:AddConfig("MaxTokens", "Gemini", self.VERIFICATION_TYPE.number, 2048)
    self:AddConfig("APIKey", "Gemini", self.VERIFICATION_TYPE.string, "YOUR_API_KEY", true)

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
        ["HARM_CATEGORY_HARASSMENT"] = self.__SAFETY_ENUM[ self:GetConfig("SafetyHarassment", "Gemini") ],
        ["HARM_CATEGORY_HATE_SPEECH"] = self.__SAFETY_ENUM[ self:GetConfig("SafetyHateSpeech", "Gemini") ],
        ["HARM_CATEGORY_SEXUALLY_EXPLICIT"] = self.__SAFETY_ENUM[ self:GetConfig("SafetySexuallyExplicit", "Gemini") ],
        ["HARM_CATEGORY_DANGEROUS_CONTENT"] = self.__SAFETY_ENUM[ self:GetConfig("SafetyDangerousContent", "Gemini") ]
    }
end

function Gemini:GenerationResetConfig()
    self:SetConfig("ModelTarget", "auto", "Gemini")
    self:SetConfig("ModelName", "gemini-1.0-pro", "Gemini")
    self:SetConfig("Temperature", 0.9, "Gemini")
    self:SetConfig("TopP", 1, "Gemini")
    self:SetConfig("TopK", 1, "Gemini")
    self:SetConfig("MaxTokens", 2048, "Gemini")

    self:Print("Generation reset to default settings.")
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

    for Category, Value in pairs(self.__SAFETY_TYPE) do
        table.insert(SafetySettings, {
            ["category"] = Category,
            ["threshold"] = Value
        })
    end

    CacheSafety = SafetySettings

    return SafetySettings
end

function Gemini:GetGamemodeModel()
    local ModelTarget = self:GetConfig("ModelTarget", "Gemini")

    if ( ModelTarget == "auto" ) then
        local GamemodeModel = self.__MODELS[engine.ActiveGamemode()] or self.__MODELS["default"]

        return self:GetPhrase(self.LanguageTarget, "context") .. "\n\n" .. GamemodeModel
    else
        return self:GetPhrase(self.LanguageTarget, "context") .. "\n\n" .. self.__MODELS[ModelTarget]
    end
end

function Gemini:GetLogsOfPlayer(Player, Amount)
    local Logs = self:LoggerGetLogsPlayer(Player, 15, true)
    local FormatedLogs = ""

    for _, SQLTable in ipairs(Logs) do
        FormatedLogs = FormatedLogs .. "\n" .. SQLTable["geminilog_log"]
    end
    return FormatedLogs
end

function Gemini:MakeRequest(Data)
    --[[ Body ]]--
    local GeminiModel = self:GetConfig("ModelName", "Gemini")
    local GamemodeModel = self:GetGamemodeModel()
    local GenerationConfig = self:GetGenerationConfig()
    local SafetyConfig = self:GetSafetyConfig()

    local Parts = {
        {["text"] = GamemodeModel}
    }

    local Body = {
        ["generationConfig"] = GenerationConfig,
        ["safetySettings"] = SafetyConfig
    }

    for _, Text in ipairs(Data) do
        table.insert(Parts, {["text"] = Text})
    end

    table.insert(Parts, {["text"] = "Segun viendo el registro de actividad, con tus propias palabras escribe, ¿Que conclusiones puedes sacar?"})

    Body["contents"] = {{["parts"] = Parts}}
    local APIKey = self:GetConfig("APIKey", "Gemini")

    --[[ Debug ]]--
    file.Write("gemini_request.txt", util.TableToJSON(Body, true))

    --[[ Request ]]--
    local RequestMade = HTTP({
        ["url"] = string.format(self.URL, GeminiModel, APIKey),
        ["method"] = "POST",
        ["type"] = "application/json",
        ["body"] = util.TableToJSON(Body),
        ["success"] = function(Code, BodyResponse, Headers)
            Gemini:GetHTTPDescription(Code)

            if ( Code == 200 ) then
                self:Print("Response from Gemini API: " .. util.JSONToTable(BodyResponse)["candidates"][1]["content"]["parts"][1]["text"])
                file.Write("gemini_response.txt", BodyResponse)
            end
        end,
        ["failed"] = function(Error)
            self:Print("Failed to make request to Gemini API. Error: " .. Error)
        end
    })

    if RequestMade then
        self:Print("Request made to Gemini API.")
    else
        self:Print("Failed to make request to Gemini API.")
    end
end