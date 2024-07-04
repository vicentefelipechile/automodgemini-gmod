--[[----------------------------------------------------------------------------
                 Google Gemini Automod - Server Owner Rules (SV)
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:GeminiFormatter:ServerInfo")

local FormatterTypes = FormatterTypes or {}
local HTTPRegExp = "https?://[%w-_%.%?%.:/%+=&]+"

--[[------------------------
          Settings
------------------------]]--

function Gemini:FormatterPoblate()
    self:CreateConfig("Source", "Formatter", self.VERIFICATION_TYPE.string, "https://google.com")
end

local function RetrieveFormats()
    -- Gemini:FormatterAddFromJson(Gemini:GetConfig("Source", "Formatter"), "ServerInfo")
end

hook.Add("InitPostEntity", "Gemini:RetreiveFormats", function()
    timer.Simple(8, RetrieveFormats)
    hook.Add("Gemini:PostInit", "Gemini:RetreiveFormats", RetrieveFormats)
end)


--[[------------------------
          Settings
------------------------]]--

function Gemini:Formatter(InputText, Formatter)
    if not isstring(InputText) then
        self:Error("The first argument of Gemini:Formatter must be a string", InputText, "string")
    elseif ( #InputText == 0 ) then
        self:Error("The first argument of Gemini:Formatter must not be empty", InputText, "string")
    end

    if not isstring(Formatter) then
        self:Error("The second argument of Gemini:Formatter must be a string", Formatter, "string")
    elseif ( #Formatter == 0 ) then
        self:Error("The second argument of Gemini:Formatter must not be empty", Formatter, "string")
    end

    if not FormatterTypes[Formatter] then
        self:Error("The formatter does not exist", Formatter, "string")
    end

    local FormatterTarget = table.Copy(FormatterTypes[Formatter])
    table.insert(FormatterTarget, {["text"] = "input: " .. InputText})
    table.insert(FormatterTarget, {["text"] = "output: "})

    local Candidate = self:GeminiCreateCandidate()
    Candidate["contents"] = {
        {
            ["parts"] = FormatterTarget,
            ["role"] = "user"
        }
    }

    file.Write("gemini_formatter_request.json", util.TableToJSON(Candidate, true))

    local promise = Promise()
    HTTP({
        ["url"] = string.format(self.URL, self:GetConfig("ModelName", "Gemini"), self:GetConfig("APIKey", "Gemini")),
        ["method"] = "POST",
        ["type"] = "application/json",
        ["body"] = Body,
        ["success"] = function(Code, BodyResponse, Headers)
            self:GetHTTPDescription(Code)

            file.Write("gemini_formatter_response.json", BodyResponse)

            if ( Code ~= 200 ) then promise:Reject("There was an error with the request to the url") end

            local Response = util.JSONToTable(BodyResponse)
            if ( Response == nil ) then promise:Reject("The response must be a valid json") end

            promise:Resolve(Response)
        end,
        ["failed"] = function(Reason)
            promise:Reject("The request to the url failed")
        end
    })

    return promise
end


--[[------------------------
   Formatter from sources
------------------------]]--

function Gemini:FormatterAddFromURL(URL, Formatter) -- First function with a promise
    if not isstring(URL) then
        self:Error("The first argument of Gemini:FormatterAddFromURL must be a string", URL, "string")
    elseif ( #URL == 0 ) then
        self:Error("The first argument of Gemini:FormatterAddFromURL must not be empty", URL, "string")
    end

    if not isstring(Formatter) then
        self:Error("The second argument of Gemini:FormatterAddFromURL must be a string", Formatter, "string")
    elseif ( #Formatter == 0 ) then
        self:Error("The second argument of Gemini:FormatterAddFromURL must not be empty", Formatter, "string")
    end

    if not string.match(URL, HTTPRegExp) then
        self:Error("The URL is not valid", URL, "string")
    end

    local promise = Promise()
    HTTP({
        url = URL,
        method = "GET",
        success = function(code, body, headers)
            Gemini:GetHTTPDescription(Code)

            file.Write("gemini_formatter.json", body)

            if ( code ~= 200 ) then promise:Reject("There was an error with the request to the url") end

            local JsonData = util.JSONToTable(body)
            if not JsonData then
                promise:Reject( Gemini:Error("The request to the url must return a valid json", body, "string") )
            end

            if not table.IsSequential(JsonData) then
                promise:Reject( Gemini:Error("The json must be an array", body, "string") )
            end

            FormatterTypes[Formatter] = JsonData

            promise:Resolve(JsonData)
        end,
        failed = function(reason)
            promise:Reject( Gemini:Error("The request to the url failed", reason, "string") )
        end
    })

    return promise
end

function Gemini:FormatterAddFromFile(FilePath, Formatter)
    if not isstring(FilePath) then
        self:Error("The first argument of Gemini:FormatterAddFromFile must be a string", FilePath, "string")
    elseif ( #FilePath == 0 ) then
        self:Error("The first argument of Gemini:FormatterAddFromFile must not be empty", FilePath, "string")
    end

    if not isstring(Formatter) then
        self:Error("The second argument of Gemini:FormatterAddFromFile must be a string", Formatter, "string")
    elseif ( #Formatter == 0 ) then
        self:Error("The second argument of Gemini:FormatterAddFromFile must not be empty", Formatter, "string")
    end

    if not file.Exists(FilePath, "DATA") then
        self:Error("The file does not exist", FilePath, "string")
    end

    local FileData = file.Read(FilePath, "DATA")
    if not FileData then
        self:Error("The file must contain data", FilePath, "string")
    end

    local JsonData = util.JSONToTable(FileData)
    if not JsonData then
        self:Error("The file must contain a valid json", FilePath, "string")
    end

    if not table.IsSequential(JsonData) then
        self:Error("The json must be an array", FilePath, "string")
    end

    FormatterTypes[Formatter] = JsonData

    return JsonData
end

local urlexample = "https://gist.githubusercontent.com/vicentefelipechile/60dc8d6faa88a72e121f2460079ea68a/raw/e3c0c3153aaa3ef1e937b241a05b25444a4810c3/gemini_formatter.json"
Gemini:FormatterAddFromURL(urlexample, "ServerInfo"):Then(function(Response)
    local promise = Gemini:Formatter("Generame un texto", "ServerInfo")

    promise:Then(function(SubResponse)
        PrintTable(SubResponse)

    end):Catch(function(Reason)
        Gemini:Error(Reason)

    end)
end)