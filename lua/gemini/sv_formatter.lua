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

Gemini:CreateConfig("Source", "Formatter", Gemini.VERIFICATION_TYPE.string, "https://google.com")

function Gemini:FormatterPoblate()
    file.CreateDir("gemini/formatter")
end

hook.Add("Gemini:HTTPLoaded", "Gemini:RetreiveFormats", function()
    local SourcePath = Gemini:GetConfig("Source", "Formatter")

    if string.match(SourcePath, HTTPRegExp) then
        Gemini:LoadFormatterFromURL(SourcePath, "ServerInfo", true)
    else
        Gemini:LoadFormatterFromFile(SourcePath, "ServerInfo")
    end
end)


--[[------------------------
          Methods
------------------------]]--

function Gemini:Formatter(InputText, Formatter)
    self:Checker({InputText, "string", 1})
    self:Checker({Formatter, "string", 2})

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

function Gemini:FormatterExists(Formatter)
    self:Checker({Formatter, "string", 1})

    return FormatterTypes[Formatter] ~= nil
end

function Gemini:GetFormatter(Formatter)
    self:Checker({Formatter, "string", 1})

    if not FormatterTypes[Formatter] then
        self:Error("The formatter does not exist", Formatter, "string")
    end

    return FormatterTypes[Formatter]
end


--[[------------------------
   Formatter from sources
------------------------]]--

function Gemini:LoadFormatterFromURL(URL, Formatter, Cache) -- First function with a promise
    self:Checker({URL, "string", 1})
    self:Checker({Formatter, "string", 2})

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

                Gemini:Print("Formatter downloaded and saved.")
            else
                Gemini:Print("Formatter downloaded.")
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
    self:Checker({FilePath, "string", 1})
    self:Checker({Formatter, "string", 2})

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


--[[------------------------
      Network Functions
------------------------]]--

function Gemini:BroadcastFormatterToPlayer(ply, Formatter, Text)
    if not IsValid(ply) then
        self:Error("The first argument of Gemini:BroadcastFormatterToPlayer must be a player", ply, "player")
    end

    self:Checker({Formatter, "string", 2})

    if not FormatterTypes[Formatter] then
        self:Error("The formatter does not exist", Formatter, "string")
    end

    self:Checker({Text, "string", 3})

    local CompressedText = util.Compress(Text)
    local CompressedSize = #CompressedText

    if CompressedSize > Gemini.Util.MaxBandwidth then
        self:Error("The text is too large to be sent", CompressedSize, Gemini.Util.MaxBandwidth)
    end

    net.Start("Gemini:Formatter")
        net.WriteString(Formatter)
        net.WriteUInt(CompressedSize, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(CompressedText, CompressedSize)
    net.Send(ply)
end

net.Receive("Gemini:Formatter", function(len, ply)
    if not (
        Gemini:CanUse(ply, "gemini_rules_set") or
        Gemini:CanUse(ply, "gemini_config_set") or
        ( hook.Run("Gemini:PlayerRequestFormatter", ply) == true )
    )
    then
        Gemini:SendMessage(ply, "You do not have permission to request a formatter", "Gemini:Formatter")
        return
    end

    local Formatter = net.ReadString()

    if not FormatterTypes[Formatter] then
        Gemini:SendMessage(ply, "Error: The formatter does not exist", "Gemini:Formatter")
        Gemini:Error("The formatter does not exist", Formatter, "string")
    end

    local CompressedSize = net.ReadUInt( Gemini.Util.DefaultNetworkUInt )
    local CompressedText = util.Decompress( net.ReadData( CompressedSize ) )

    local NewPromise = Gemini:Formatter(CompressedText, Formatter)
    NewPromise:Then(function(DataInfo)
        local Body = DataInfo["Body"]
        file.Write("gemini/debug/formatter_response.json", util.TableToJSON(Body, true))

        if ( Code == 429 ) then Gemini:SendMessage(ply, "Gemini.Error.RateLimit", "Formatter") return end
        if ( Code ~= 200 ) then Gemini:SendMessage(ply, "Gemini.Error.ServerError", "Formatter") return end

        if Body["promptFeedback"] and Body["promptFeedback"]["blockReason"] then
            local FeedbackMessage = "Enum.BlockReason." .. Body["promptFeedback"]["blockReason"]

            Gemini:Print( Gemini:GetPhrase(FeedbackMessage) )
            Gemini:SendMessage(ply, FeedbackMessage, "Formatter")
            return
        end

        local Candidates = Body["candidates"]

        if not Candidates[1]["content"] then
            local MessageError = "Gemini.Error.FailedRequest"
            if Candidates[1]["finishReason"] then
                MessageError = "Enum.FinishReason." .. Candidates[1]["finishReason"]
            end

            Gemini:Print(Gemini:GetPhrase(MessageError))
            Gemini:PlaygroundSendMessage(ply, MessageError, "Formatter")
            return
        end

        --[[ Send Response ]]--
        local Text = Candidates[1]["content"]["parts"][1]["text"]

        Gemini:BroadcastFormatterToPlayer(ply, Formatter, Text)
    end):Catch(function(Error)
        Gemini:Print("There was an error with the formatter request")
        Gemini:SendMessage(ply, Error, "Formatter")
    end)
end)


--[[------------------------
        Command Test
------------------------]]--

concommand.Add("gemini_testformatter", function(ply)
    if IsValid(ply) then return end

    if not Gemini:FormatterExists("ServerInfo") then
        Gemini:Print("There is not currently a formatter available for this test")
    else
        Gemini:Formatter("Hello World", "ServerInfo"):Then(function(Response)
            PrintTable(Response)

            file.Write("gemini/debug/formatter_test_response.json", util.TableToJSON(Response, true))
        end)
    end
end)