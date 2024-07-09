--[[----------------------------------------------------------------------------
                 Google Gemini Automod - Gemini Formatter Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:GeminiFormatter:ServerInfo")

local MethodGenerateContent = "models/%s:generateContent"
local HTTPRegExp = "https?://[%w-_%.%?%.:/%+=&]+"
local FormatterTypes = FormatterTypes or {}

--[[------------------------
          Settings
------------------------]]--

function Gemini:FormatterPoblate()
    self:CreateConfig("Source", "Formatter", self.VERIFICATION_TYPE.string, "https://google.com")
    file.CreateDir("gemini/formatter")
end

local function RetrieveFormats()
    local SourcePath = Gemini:GetConfig("Source", "Formatter")

    if string.match(SourcePath, HTTPRegExp) then
        Gemini:LoadFormatterFromURL(SourcePath, "ServerInfo", true)
    else
        Gemini:LoadFormatterFromFile(SourcePath, "ServerInfo")
    end
end

hook.Add("Gemini:HTTPLoaded", "Gemini:RetreiveFormats", RetrieveFormats)


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

    local NewRequest = Gemini:NewRequest()
    NewRequest:AddContent(FormatterTarget, "user")
    NewRequest:SetMethod( string.format(MethodGenerateContent, self:GetConfig("ModelName", "Gemini")) )

    file.Write("gemini/formatter_request.json", util.TableToJSON(NewRequest:GetBody(), true))

    return NewRequest:MakeRequest()
end


--[[------------------------
   Formatter from sources
------------------------]]--

function Gemini:LoadFormatterFromURL(URL, Formatter, Cache) -- First function with a promise
    if not isstring(URL) then
        self:Error("The first argument of Gemini:LoadFormatterFromURL must be a string", URL, "string")
    elseif ( #URL == 0 ) then
        self:Error("The first argument of Gemini:LoadFormatterFromURL must not be empty", URL, "string")
    end

    if not isstring(Formatter) then
        self:Error("The second argument of Gemini:LoadFormatterFromURL must be a string", Formatter, "string")
    elseif ( #Formatter == 0 ) then
        self:Error("The second argument of Gemini:LoadFormatterFromURL must not be empty", Formatter, "string")
    end

    if not string.match(URL, HTTPRegExp) then
        self:Error("The URL is not valid", URL, "string")
    end

    local FilePath = "gemini/formatter/"
    if Cache then
        local FileName = string.GetFileFromFilename(URL)
        if not isstring(FileName) then
            FilePath = FilePath .. string.lower(Formatter) .. ".json"
        else
            FilePath = FilePath .. FileName
        end

        if file.Exists(FilePath, "DATA") then
            local FileData = file.Read(FilePath, "DATA")
            if FileData then
                local JsonData = util.JSONToTable(FileData)
                if JsonData then
                    FormatterTypes[Formatter] = JsonData
                    return JsonData
                end
            end
        end
    end

    local promise = Promise()
    HTTP({
        url = URL,
        method = "GET",
        success = function(code, body, headers)
            Gemini:GetHTTPDescription(Code)

            file.Write("gemini/formatter_result.json", body)

            if ( code ~= 200 ) then promise:Reject("There was an error with the request to the url") return end

            local JsonData = util.JSONToTable(body)
            if ( JsonData == nil ) then
                promise:Reject("The request to the url must return a valid json")
                return
            end

            if not table.IsSequential(JsonData) then
                promise:Reject("The json must be an array")
                return
            end

            FormatterTypes[Formatter] = JsonData

            if Cache then
                FilePath = "gemini/formatter/"

                local FileName = string.GetFileFromFilename(URL)
                if not isstring(FileName) then
                    FilePath = FilePath .. string.lower(Formatter) .. ".json"
                else
                    FilePath = FilePath .. FileName
                end

                file.Write(FilePath, body)
            end

            promise:Resolve(JsonData)
        end,
        failed = function(reason)
            promise:Reject("The request to the url failed", reason, "string")
        end
    })

    return promise
end

function Gemini:LoadFormatterFromFile(FilePath, Formatter)
    if not isstring(FilePath) then
        self:Error("The first argument of Gemini:LoadFormatterFromFile must be a string", FilePath, "string")
    elseif ( #FilePath == 0 ) then
        self:Error("The first argument of Gemini:LoadFormatterFromFile must not be empty", FilePath, "string")
    end

    if not isstring(Formatter) then
        self:Error("The second argument of Gemini:LoadFormatterFromFile must be a string", Formatter, "string")
    elseif ( #Formatter == 0 ) then
        self:Error("The second argument of Gemini:LoadFormatterFromFile must not be empty", Formatter, "string")
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

concommand.Add("gemini_formattertest", function(ply)
    if IsValid(ply) then return end

    Gemini:Formatter("Hello World", "ServerInfo"):Then(function(Response)
        PrintTable(Response)

        file.Write("gemini/formatter_response.json", util.TableToJSON(Response, true))
    end)
end)