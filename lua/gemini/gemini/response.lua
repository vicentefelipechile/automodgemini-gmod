--[[----------------------------------------------------------------------------
                         Gemini Automod - Response Object
----------------------------------------------------------------------------]]-- BG

--[[------------------------
    Safety Rating Object
------------------------]]--

local SAFETYRATING = {
    ["category"] = HARM_CATEGORY_UNSPECIFIED,
    ["probability"] = HARM_PROBABILITY_UNSPECIFIED,
    ["blocked"] = false,
}
SAFETYRATING.__index = SAFETYRATING

function SAFETYRATING:IsBlocked()
    return self.blocked
end

function SAFETYRATING:GetCategory()
    return self.category
end

function SAFETYRATING:GetProbability()
    return self.probability
end



--[[------------------------
   Prompt Feedback Object
------------------------]]--

local PROMPTFEEDBACK = {
    ["blockReason"] = BLOCK_REASON_UNSPECIFIED,
    ["safetyRatings"] = {}
}
PROMPTFEEDBACK.__index = PROMPTFEEDBACK

function PROMPTFEEDBACK:GetBlockReason()
    return self.blockReason
end

function PROMPTFEEDBACK:GetSafetyRatings()
    local safetyRatings = {}

    for index, safetyRating in ipairs(self.safetyRatings) do
        table.insert(safetyRatings, setmetatable(safetyRating, SAFETYRATING))
    end

    return safetyRatings
end

function PROMPTFEEDBACK:GetFirstSafetyRating()
    if istable(self.safetyRatings) and table.IsEmpty(self.safetyRatings) then
        return nil
    end

    return setmetatable(self.safetyRatings[1], SAFETYRATING)
end



--[[------------------------
      Metadata Methods
------------------------]]--

local USAGEMETADATA = {
    ["promptTokenCount"] = 0,
    ["candidatesTokenCount"] = 0,
    ["totalTokenCount"] = 0
}
USAGEMETADATA.__index = USAGEMETADATA

function USAGEMETADATA:GetPromptTokenCount()
    return self.promptTokenCount
end

function USAGEMETADATA:GetCandidatesTokenCount()
    return self.candidatesTokenCount
end

function USAGEMETADATA:GetTotalTokenCount()
    return self.totalTokenCount
end



--[[------------------------
      Response Object
------------------------]]--

local GENERATECONTENTRESPONSE = {
    __cache = {},
    code = 0,
    body = {},
    headers = {}
}

function GENERATECONTENTRESPONSE:GetCode()
    return self.code
end

function GENERATECONTENTRESPONSE:GetMetadata()
    if self.__cache["metadata"] then
        return self.__cache["metadata"]
    end

    if not table.IsEmpty(self.body) then
        return nil
    end

    if not istable(self.body["usageMetadata"]) then
        return nil
    end

    self.__cache["metadata"] = setmetatable({self.body["usageMetadata"]}, USAGEMETADATA)

    return self.__cache["metadata"]
end

function GENERATECONTENTRESPONSE:GetPromptFeedback()
    if self.__cache["promptFeedback"] then
        return self.__cache["promptFeedback"]
    end

    if not table.IsEmpty(self.body) then
        return nil
    end

    if not istable(self.body["promptFeedback"]) then
        return nil
    end

    self.__cache["promptFeedback"] = setmetatable({self.body["promptFeedback"]}, PROMPTFEEDBACK)

    return self.__cache["promptFeedback"]
end



--[[------------------------
        Create Object
------------------------]]--

function Gemini:CreateResponseObject(response)
    if not istable(response) then
        self:Error("The first argument of Gemini:CreateResponseObject must be a table.", response, "table")
    elseif table.IsEmpty(response) then
        self:Error("The first argument of Gemini:CreateResponseObject must not be an empty table.", response, "table")
    end

    return setmetatable(response, GENERATECONTENTRESPONSE)
end