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
    if not ( IsValid(ply) and ply:IsPlayer() ) then
        self:Error("The first argument of Gemini:PlaygroundSendMessage() must be a player.", ply, "player")
    end

    if not isstring(Message) then
        self:Error("The second argument of Gemini:PlaygroundSendMessage() must be a string.", Message, "string")
    elseif ( Message == "" ) then
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
    local Logs = self:LoggerGetLogsUsingPlayerSettings(ply, "playground")

    local LogsTable = {}
    for _, LogInfo in ipairs(Logs) do
        table.insert(LogsTable, LogInfo["geminilog_time"] .. " - " .. LogInfo["geminilog_log"])
    end

    return LogsTable
end

--[[------------------------
       Playground API
------------------------]]--

function Gemini:PlaygroundMakeRequest(Prompt, ply) -- BG
    if not isstring(Prompt) then
        self:Error("The first argument of Gemini:PlaygroundMakeRequest() must be a string.", Prompt, "string")
    elseif ( Prompt == "" ) then
        self:Error("The first argument of Gemini:PlaygroundMakeRequest() must not be empty.", Prompt, "string")
    end

    local NewRequest = self:NewRequest()

    if PlayerUsingPlayground[ply] then
        local content = NewRequest:AddContent(Prompt, "user")
        table.insert(PlayerUsingPlayground[ply]["contents"], content)

        NewRequest.__requestbody = PlayerUsingPlayground[ply]
    else
        local PlayerWantToAttachContext = self:GetPlayerInfo(ply, AttachContext)
        if PlayerWantToAttachContext then
            local Logs = self:LogsToText( self:PlaygroundGetLogsFromPlayer(ply) )

            NewRequest.__requestbody = self:GeminiCreateBodyRequest(Prompt, Logs)
        else
            NewRequest.__requestbody = self:GeminiCreateBodyRequest(Prompt)
        end

        PlayerUsingPlayground[ply] = NewRequest:GetBody()
    end

    file.Write("gemini/debug/playground_request.json", util.TableToJSON(NewRequest:GetBody(), true))

    NewRequest:SetMethod("models/" .. self:GetConfig("ModelName", "Gemini") .. ":generateContent")
    NewRequest:SetVersion("v1")

    local NewPromise = NewRequest:SendRequest()
    NewPromise:Then(function(Response)
        file.Write("gemini/debug/playground_response.json", util.TableToJSON(Response:GetBody(), true))

        local Candidates = Response:GetFirstCandidate()
        if not Candidates then
            local BlockReason = "Enum.BlockReason." .. Response:GetBlockReason()

            self:Print( self:GetPhrase(BlockReason) )
            self:PlaygroundSendMessage(ply, BlockReason)

            self:PlaygroundClearHistory(ply)
            return
        end

        if not IsValid(ply) then
            self:Print("The player that requested the prompt no longer exists.")
            return
        elseif not istable( PlayerUsingPlayground[ply] ) then
            self:Print("The player that requested the prompt is no longer using the playground.")
            return
        end

        local ContentText = Candidates:GetTextContent()
        if not ContentText then return end

        local Compress = util.Compress( ContentText )
        local CompressSize = #Compress

        if ( CompressSize > Gemini.Util.MaxBandwidth ) then
            self:Print("The response from Gemini API is too large to send to the client. Size: ", CompressSize, " bytes")

            self:PlaygroundSendMessage(ply, "Gemini.Error.TooBig")
            self:PlaygroundClearHistory(ply)
            return
        end

        table.insert(PlayerUsingPlayground[ply]["contents"], {
            ["parts"] = { ["text"] = ContentText },
            ["role"] = "model"
        })

        net.Start("Gemini:PlaygroundMakeRequest")
            net.WriteUInt(CompressSize, Gemini.Util.DefaultNetworkUInt)
            net.WriteData(Compress, CompressSize)
        net.Send(ply)
    end)

    self:PlaygroundSendMessage(ply, "Gemini.Requested")
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

function Gemini.PlaygroundPlayerAskLogs(len, ply)
    if not Gemini:CanUse(ply, "gemini_playground") then return end

    local Logs = Gemini:LoggerGetLogsUsingPlayerSettings(ply, "playground")

    local LogsCompressed = util.Compress( util.TableToJSON(Logs) )
    local LogsSize = #LogsCompressed

    net.Start("Gemini:AskLogs:Playground")
        net.WriteBool(true)
        net.WriteString("Logger.LogsSended")

        net.WriteUInt(LogsSize, Gemini.Util.DefaultNetworkUIntBig)
        net.WriteData(LogsCompressed, LogsSize)
    net.Send(ply)
end

net.Receive("Gemini:PlaygroundMakeRequest", Gemini.PlaygroundReceivePetition)
net.Receive("Gemini:PlaygroundResetRequest", Gemini.PlaygroundResetRequest)
net.Receive("Gemini:AskLogs:Playground", Gemini.PlaygroundPlayerAskLogs)