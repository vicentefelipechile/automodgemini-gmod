--[[----------------------------------------------------------------------------
                         Gemini Automod - Response Object
----------------------------------------------------------------------------]]-- BG

-- When i was coding this Object, i added cache to the objects to avoid unnecessary calculations
-- that was my worse mistake, the cache isn't stored on the new object, it's stored on the metatable.
-- Thank god i was able to fix it.

--[[------------------------
    Safety Rating Object
------------------------]]--

local SAFETYRATING = {
    category = GEMINI_ENUM.HARM_CATEGORY_UNSPECIFIED,
    probability = GEMINI_ENUM.HARM_PROBABILITY_UNSPECIFIED,
    blocked = false,
}

function SAFETYRATING:IsBlocked()
    return self.blocked
end

function SAFETYRATING:GetCategory()
    return self.category
end

function SAFETYRATING:GetProbability()
    return self.probability
end

SAFETYRATING.__index = SAFETYRATING



--[[------------------------
   Prompt Feedback Object
------------------------]]--

local PROMPTFEEDBACK = {
    blockReason = GEMINI_ENUM.BLOCK_REASON_UNSPECIFIED,
    safetyRatings = {}
}

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

PROMPTFEEDBACK.__index = PROMPTFEEDBACK



--[[------------------------
      Metadata Object
------------------------]]--

local USAGEMETADATA = {
    promptTokenCount = 0,
    candidatesTokenCount = 0,
    totalTokenCount = 0
}

function USAGEMETADATA:GetPromptTokenCount()
    return self.promptTokenCount
end

function USAGEMETADATA:GetCandidatesTokenCount()
    return self.candidatesTokenCount
end

function USAGEMETADATA:GetTotalTokenCount()
    return self.totalTokenCount
end

USAGEMETADATA.__index = USAGEMETADATA



--[[------------------------
       Content Object
------------------------]]--

local PART_BLOB = {
    mimeType = "",
    data = ""
}

PART_BLOB.__index = PART_BLOB


local PART = {
    text = "",
    inlineData = {},
}

function PART:GetText()
    return self.text
end

function PART:GetInlineData()
    if not istable(self.inlineData) then
        return nil
    end

    if table.IsEmpty(self.inlineData) then
        return nil
    end

    return setmetatable(self.inlineData, PART_BLOB)
end

PART.__index = PART


local CONTENT = {
    parts = {},
    role = "model"
}

function CONTENT:GetParts()
    local parts = {}

    for index, part in ipairs(self.parts) do
        table.insert(parts, setmetatable(part, PART))
    end

    return parts
end

function CONTENT:GetFirstPart()
    if table.IsEmpty(self.parts) then
        return nil
    end

    return setmetatable(self.parts[1], PART)
end

function CONTENT:GetLastPart()
    if table.IsEmpty(self.parts) then
        return nil
    end

    return setmetatable(self.parts[#self.parts], PART)
end

function CONTENT:GetRole()
    return self.role
end

function CONTENT:GetText()
    local FirstPart = self:GetFirstPart()

    if not FirstPart then
        return nil
    end

    return FirstPart:GetText()
end

CONTENT.__index = CONTENT



--[[------------------------
  Citation Metadata Object
------------------------]]--

local CITATIONSOURCES = {
    startIndex = 0,
    endIndex = 0,
    uri = "",
    license = "",
}

CITATIONSOURCES.__index = CITATIONSOURCES

local CITATIONMETADATA = {
    citationSources = {}
}

function CITATIONMETADATA:GetSources()
    local sources = {}

    for index, source in ipairs(self.citationSources) do
        table.insert(sources, setmetatable(source, CITATIONSOURCES))
    end

    return sources
end

CITATIONMETADATA.__index = CITATIONMETADATA



--[[------------------------
      Candidate Object
------------------------]]-- BG

local CANDIDATE = {
    content = {},
    finishReason = GEMINI_ENUM.FINISH_REASON_UNSPECIFIED,
    safetyRatings = {},
    citationMetadata = {},
    tokenCount = 0,
    index = 0
}

function CANDIDATE:GetContent()
    if table.IsEmpty(self.content) then
        return nil
    end

    return setmetatable(self.content, CONTENT)
end

function CANDIDATE:GetFinishReason()
    return self.finishReason
end

function CANDIDATE:IsStop()
    return self.finishReason == STOP
end

function CANDIDATE:GetSafetyRatings()
    local safetyRatings = {}

    for index, safetyRating in ipairs(self.safetyRatings) do
        table.insert(safetyRatings, setmetatable(safetyRating, SAFETYRATING))
    end

    return safetyRatings
end

function CANDIDATE:GetCitationMetadata()
    if not istable(self.citationMetadata) then
        return nil
    end

    return setmetatable(self.citationMetadata, CITATIONMETADATA)
end
CANDIDATE.GetCitationMetadata = CANDIDATE.GetCitationMetaData

function CANDIDATE:GetTokenCount()
    return self.tokenCount
end

function CANDIDATE:GetIndex()
    return self.index
end

--[ Util functions ]--

function CANDIDATE:GetTextContent()
    return self:GetContent() and self:GetContent():GetText() or nil
end

CANDIDATE.__index = CANDIDATE



--[[------------------------
      Response Object
------------------------]]--

local GENERATECONTENTRESPONSE = {
    code = 0,
    body = {},
    headers = {}
}

function GENERATECONTENTRESPONSE:GetCode()
    return self.code
end

function GENERATECONTENTRESPONSE:GetBody()
    return self.body
end

function GENERATECONTENTRESPONSE:GetHeaders()
    return self.headers
end

function GENERATECONTENTRESPONSE:GetMetadata()
    if not table.IsEmpty(self.body) then
        return nil
    end

    if not istable(self.body["usageMetadata"]) then
        return nil
    end

    return setmetatable({self.body["usageMetadata"]}, USAGEMETADATA)
end

function GENERATECONTENTRESPONSE:GetPromptFeedback()
    if not table.IsEmpty(self.body) then
        return nil
    end

    if not istable(self.body["promptFeedback"]) then
        return nil
    end

    return setmetatable({self.body["promptFeedback"]}, PROMPTFEEDBACK)
end

function GENERATECONTENTRESPONSE:GetCandidates()
    if not table.IsEmpty(self.body) then
        return nil
    end

    if not istable(self.body["candidates"]) then
        return nil
    end

    local candidates = {}

    for index, candidate in ipairs(self.body["candidates"]) do
        table.insert(candidates, setmetatable(candidate, CANDIDATE))
    end

    return candidates
end
GENERATECONTENTRESPONSE.GetCandidate = GENERATECONTENTRESPONSE.GetCandidates

--[ Util functions ]--
function GENERATECONTENTRESPONSE:GetFirstCandidate()
    if istable(self.body["candidates"]) and table.IsEmpty(self.body["candidates"]) then
        return nil
    end

    return setmetatable(self.body["candidates"][1], CANDIDATE)
end

function GENERATECONTENTRESPONSE:GetBlockReason()
    if not istable(self.body["promptFeedback"]) then
        return BLOCK_REASON_UNSPECIFIED
    end

    return self.body["promptFeedback"]["blockReason"]
end

GENERATECONTENTRESPONSE.__index = GENERATECONTENTRESPONSE



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