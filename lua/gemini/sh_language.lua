--[[----------------------------------------------------------------------------
                        Google Gemini Automod - Language
----------------------------------------------------------------------------]]--

Gemini.__LANG = {}

function Gemini:CreateLanguage(LanguageTarget)
    if istable(self.__LANG[LanguageTarget]) then
        self:Error([[The first argument of Gemini:CreateLanguage() already exists]], LanguageTarget, [[string]])
    end

    Gemini.__LANG[LanguageTarget] = {}

    return LanguageTarget
end

function Gemini:AddPhrase(LanguageTarget, PhraseName, Phrase)
    if not isstring(LanguageTarget) then
        self:Error("Invalid language target", LanguageTarget, "A valid language")
    elseif (LanguageTarget == "") then
        self:Error("Invalid language target", LanguageTarget, "A valid language")
    end
end