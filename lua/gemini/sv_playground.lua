--[[----------------------------------------------------------------------------
                    Google Gemini Automod - Playground Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:PlaygroundSendMessage")
util.AddNetworkString("Gemini:PlaygroundMakeRequest")
util.AddNetworkString("Gemini:PlaygroundResetRequest")
util.AddNetworkString("Gemini:AskLogs:Playground")

local PlayerUsingPlayground = {}

local AttachContext = "gemini_playground_attachcontext"

--[[------------------------
       Util Functions
------------------------]]--

function Gemini:PlaygroundSendMessage(ply, Message, Argument)
    if not IsValid(ply) then
        self:Error("The first argument of Gemini:PlaygroundSendMessage() must be a player.", ply, "player")
    end

    if not ( isentity(ply) and ply:IsPlayer() ) then
        self:Error("The first argument of Gemini:PlaygroundSendMessage() must be a player.", ply, "player")
    end

    if not isstring(Message) then
        self:Error("The second argument of Gemini:PlaygroundSendMessage() must be a string.", Message, "string")
    end

    if ( Message == "" ) then
        self:Error("The second argument of Gemini:PlaygroundSendMessage() must not be empty.", Message, "string")
    end

    net.Start("Gemini:PlaygroundSendMessage")
        net.WriteString(Message)
        net.WriteString(Argument or "")
    net.Send(ply)
end

function Gemini:PlaygroundClearHistory(ply)
    PlayerUsingPlayground[ply] = nil
end

function Gemini:PlaygroundGetLogsFromPlayer(ply)
    local Logs = self:LoggerGetLogsUsingPlayerSettings(ply)

    table.sort(Logs, function(a, b) return a["geminilog_time"] < b["geminilog_time"] end)

    local LogsTable = {}
    for _, LogInfo in ipairs(Logs) do
        table.insert(LogsTable, LogInfo["geminilog_time"] .. " - " .. LogInfo["geminilog_log"])
    end

    return LogsTable
end

--[[------------------------
       Playground API
------------------------]]--

function Gemini:PlaygroundMakeRequest(Prompt, ply)
    if not isstring(Prompt) then
        self:Error("The first argument of Gemini:PlaygroundMakeRequest() must be a string.", Prompt, "string")
    elseif ( Prompt == "" ) then
        self:Error("The first argument of Gemini:PlaygroundMakeRequest() must not be empty.", Prompt, "string")
    end

    --[[ Candidate ]]--
    local Candidate = nil
    local GeminiModel = self:GetConfig("ModelName", "Gemini")

    if PlayerUsingPlayground[ply] then
        local Part = {
            ["parts"] = {["text"] = Prompt},
            ["role"] = "user"
        }

        table.insert(PlayerUsingPlayground[ply]["contents"], Part)
        Candidate = PlayerUsingPlayground[ply]

    else
        --[[ Candidate ]]--
        Candidate = Gemini:GeminiCreateBodyRequest(ply)

        FullPrompt = FullPrompt .. Candidate["contents"][1]["text"]

        --[[ Context ]]--
        local PlayerWantContext = self:GetPlayerInfo(ply, AttachContext)
        if PlayerWantContext then
            local Context = self:LogsToText( self:PlaygroundGetLogsFromPlayer(ply) )

            FullPrompt = FullPrompt .. self:GetPhrase("context.playground") .. "\n\n" .. Context .. "\n\n" .. self:GetPhrase("context.post") .. "\n\n"
        end

        --[[ Prompt ]]--
        FullPrompt = FullPrompt .. Prompt

        Candidate["contents"][1] = { ["parts"] = {["text"] = FullPrompt}, ["role"] = "user"}

        --[[ Body ]]--
        PlayerUsingPlayground[ply] = Candidate
    end

    local Body = util.TableToJSON(Candidate, true)
    file.Write("gemini_request.txt", Body)

    --[[ Request ]]--
    local APIKey = self:GetConfig("APIKey", "Gemini")

    local RequestMade = HTTP({
        ["url"] = string.format(self.URL, GeminiModel, APIKey),
        ["method"] = "POST",
        ["type"] = "application/json",
        ["body"] = Body,
        ["success"] = function(Code, BodyResponse, Headers)
            self:GetHTTPDescription(Code)

            if ( Code ~= 200 ) then self:PlaygroundSendMessage(ply, "Gemini.Error.ServerError") return end

            file.Write("gemini_response.txt", BodyResponse)

            --[[ Check Response ]]--
            TableBody = util.JSONToTable(BodyResponse)

            if TableBody["promptFeedback"] and TableBody["promptFeedback"]["blockReason"] then
                local FeedbackMessage = "Enum.BlockReason." .. TableBody["promptFeedback"]["blockReason"]

                self:Print( self:GetPhrase(FeedbackMessage) )
                self:PlaygroundSendMessage(ply, FeedbackMessage)

                Gemini:PlaygroundClearHistory(ply)
                return
            end

            local Candidates = TableBody["candidates"]

            if not Candidates[1]["content"] then
                self:Print("The response from Gemini API is invalid. The content is missing.")
                self:PlaygroundSendMessage(ply, "Gemini.Error.FailedRequest")

                Gemini:PlaygroundClearHistory(ply)
                return
            end

            --[[ Check if the player still exists ]]--
            if not IsValid(ply) then
                self:Print("The player that requested the prompt no longer exists.")
                return
            elseif not istable( PlayerUsingPlayground[ply] ) then
                self:Print("The player that requested the prompt is no longer using the playground.")
                return
            end

            --[[ Save Response ]]--
            table.insert(PlayerUsingPlayground[ply]["contents"], Candidates[1]["content"])

            --[[ Send Response ]]--
            local Text = Candidates[1]["content"]["parts"][1]["text"]

            local Compress = util.Compress( string.Replace(Text, "**", "") )
            local CompressSize = #Compress

            if ( CompressSize > Gemini.Util.MaxBandwidth ) then
                self:Print("The response from Gemini API is too large to send to the client. Size: ", CompressSize, " bytes")

                self:PlaygroundSendMessage(ply, "Gemini.Error.TooBig")
                return
            end

            net.Start("Gemini:PlaygroundMakeRequest")
                net.WriteUInt(CompressSize, Gemini.Util.DefaultNetworkUInt)
                net.WriteData(Compress, CompressSize)
            net.Send(ply)
        end,
        ["failed"] = function(Error)
            self:Print( string.format("Gemini.Error.Reason", Error) )
            self:PlaygroundSendMessage(ply, "Gemini.Error.Reason", Error)
        end
    })

    if RequestMade then
        self:PlaygroundSendMessage(ply, "Gemini.Requested")
    else
        self:PlaygroundSendMessage(ply, "Gemini.Error")
    end
end

--[[------------------------
      Network Functions
------------------------]]--

function Gemini.PlaygroundReceivePetition(len, ply)
    local Prompt = net.ReadString()

    if not Gemini:CanUse(ply, "gemini_playground") then
        Gemini:PlaygroundSendMessage(ply, "Gemini.Error.NoPermission")
    else
        Gemini:PlaygroundMakeRequest(Prompt, ply)
    end
end

function Gemini.PlaygroundResetRequest(len, ply)
    Gemini:PlaygroundClearHistory(ply)
    Gemini:PlaygroundSendMessage(ply, "Playground.Prompt.Reseted")
end

net.Receive("Gemini:PlaygroundMakeRequest", Gemini.PlaygroundReceivePetition)
net.Receive("Gemini:PlaygroundResetRequest", Gemini.PlaygroundResetRequest)