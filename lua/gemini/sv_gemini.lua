--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Gemini Module
----------------------------------------------------------------------------]]--

Gemini.__MODELS = {
    ["default"] = nil,
    ["sandbox"] = nil,
    ["darkrp"] = nil,
    ["terrortown"] = nil,
}

function Gemini:LoadModels()
    local LanguageTarget = self:GetConfig("Language", "General", true)

    self.__MODELS["default"] = self:GetPhrase(LanguageTarget, "default")
    self.__MODELS["sandbox"] = self:GetPhrase(LanguageTarget, "sandbox")
    self.__MODELS["darkrp"] = self:GetPhrase(LanguageTarget, "darkrp")
    self.__MODELS["terrortown"] = self:GetPhrase(LanguageTarget, "terrortown")

    self:AddConfig("ModelTarget", "Gemini", self.VERIFICATION_TYPE.string, "auto")
    self:AddConfig("ModelName", "Gemini", self.VERIFICATION_TYPE.string, "gemini-1.0-pro")
    self:AddConfig("Temperature", "Gemini", self.VERIFICATION_TYPE.number, 0.9)
    self:AddConfig("TopP", "Gemini", self.VERIFICATION_TYPE.number, 1)
    self:AddConfig("TopK", "Gemini", self.VERIFICATION_TYPE.number, 1)
    self:AddConfig("MaxTokens", "Gemini", self.VERIFICATION_TYPE.number, 2048)

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
        ["HARM_CATEGORY_HARASSMENT"] = self.__SAFETY_ENUM[ self:GetConfig("SafetyHarassment", "Gemini") ]
        ["HARM_CATEGORY_HATE_SPEECH"] = self.__SAFETY_ENUM[ self:GetConfig("SafetyHateSpeech", "Gemini") ]
        ["HARM_CATEGORY_SEXUALLY_EXPLICIT"] = self.__SAFETY_ENUM[ self:GetConfig("SafetySexuallyExplicit", "Gemini") ]
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

function Gemini:GenerationSetSafety(Category, Level, SkipValidation)
    if ( SkipValidation == true ) then
        self:SetConfig("Safety" .. Category, Level, "Gemini")
    end
end