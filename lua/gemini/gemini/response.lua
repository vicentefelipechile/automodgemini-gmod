--[[----------------------------------------------------------------------------
                         Gemini Automod - Response Object
----------------------------------------------------------------------------]]-- BG

--[[------------------------
    Safety Rating Object
------------------------]]--

local SAFETYRATING = {
    category = HARM_CATEGORY_UNSPECIFIED,
    probability = HARM_PROBABILITY_UNSPECIFIED,
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
    blockReason = BLOCK_REASON_UNSPECIFIED,
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
    __cache = {},
    parts = {},
    role = "model"
}

function CONTENT:GetParts()
    if self.__cache["parts"] then
        return self.__cache["parts"]
    end

    local parts = {}

    for index, part in ipairs(self.parts) do
        table.insert(parts, setmetatable(part, PART))
    end

    self.__cache["parts"] = parts

    return self.__cache["parts"]
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
    __cache = {},
    citationSources = {}
}

function CITATIONMETADATA:GetSources()
    if self.__cache["sources"] then
        return self.__cache["sources"]
    end

    local sources = {}

    for index, source in ipairs(self.citationSources) do
        table.insert(sources, setmetatable(source, CITATIONSOURCES))
    end

    self.__cache["sources"] = sources

    return self.__cache["sources"]
end

CITATIONMETADATA.__index = CITATIONMETADATA



--[[------------------------
      Candidate Object
------------------------]]-- BG

local CANDIDATE = {
    __cache = {},
    content = {},
    finishReason = FINISH_REASON_UNSPECIFIED,
    safetyRatings = {},
    citationMetadata = {},
    tokenCount = 0,
    index = 0
}

function CANDIDATE:GetContent()
    if self.__cache["content"] then
        return self.__cache["content"]
    end

    if table.IsEmpty(self.content) then
        return nil
    end

    self.__cache["content"] = setmetatable(self.content, CONTENT)

    return self.__cache["content"]
end

function CANDIDATE:GetFinishReason()
    return self.finishReason
end

function CANDIDATE:GetSafetyRatings()
    if self.__cache["safetyRatings"] then
        return self.__cache["safetyRatings"]
    end

    local safetyRatings = {}

    for index, safetyRating in ipairs(self.safetyRatings) do
        table.insert(safetyRatings, setmetatable(safetyRating, SAFETYRATING))
    end

    self.__cache["safetyRatings"] = safetyRatings

    return self.__cache["safetyRatings"]
end

function CANDIDATE:GetCitationMetadata()
    if self.__cache["citationMetadata"] then
        return self.__cache["citationMetadata"]
    end

    if not istable(self.citationMetadata) then
        return nil
    end

    self.__cache["citationMetadata"] = setmetatable(self.citationMetadata, CITATIONMETADATA)

    return self.__cache["citationMetadata"]
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
    __cache = {},
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

function GENERATECONTENTRESPONSE:GetCandidates()
    if self.__cache["candidates"] then
        return self.__cache["candidates"]
    end

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

    self.__cache["candidates"] = candidates

    return self.__cache["candidates"]
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