--[[----------------------------------------------------------------------------
                    Google Gemini Automod - Playground Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:PlaygroundMakeRequest")
util.AddNetworkString("Gemini:PlaygroundResetRequest")
util.AddNetworkString("Gemini:PlaygroundAskLogs")

local PlayerUsingPlayground = {}

--[[------------------------
       Util Functions
------------------------]]--

function Gemini:PlaygroundClearHistory(ply)
    PlayerUsingPlayground[ply] = nil
end

function Gemini:PlaygroundGetLogsFromPlayer(ply)
    local Logs = self:GetLogsFromPlayerSettings(ply, "Playground")

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
    self:Checker({Prompt, "string", 1})

    local NewRequest = self:NewRequest()

    if ( PlayerUsingPlayground[ply] ~= nil ) then
        local content = NewRequest:AddContent(Prompt, "user")
        table.insert(PlayerUsingPlayground[ply]["contents"], content)

        NewRequest:SetBody( PlayerUsingPlayground[ply] )
    else
        local PlayerWantToAttachContext = self:GetPlayerConfig(ply, "AttachContext", "Playground")
        if PlayerWantToAttachContext then
            local Logs = self:LogsToText( self:PlaygroundGetLogsFromPlayer(ply) )

            NewRequest:SetBody( self:GeminiCreateBodyRequest(Prompt, Logs) )
        else
            NewRequest:SetBody( self:GeminiCreateBodyRequest(Prompt) )
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
            self:SendMessage(ply, BlockReason, "Playground")

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

            self:SendMessage(ply, "Gemini.Error.TooBig", "Playground")
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

    self:SendMessage(ply, "Gemini.Requested", "Playground")
end

--[[------------------------
      Network Functions
------------------------]]--

net.Receive("Gemini:PlaygroundMakeRequest", function(len, ply)
    local Prompt = net.ReadString()

    if not Gemini:CanUse(ply, "gemini_playground") then
        Gemini:SendMessage(ply, "Gemini.Error.NoPermission", "Playground")
    else
        Gemini:PlaygroundMakeRequest(Prompt, ply)
    end
end)

net.Receive("Gemini:PlaygroundResetRequest", function(len, ply)
    Gemini:PlaygroundClearHistory(ply)
    Gemini:SendMessage(ply, "Playground.Prompt.Reseted", "Playground")

    net.Start("Gemini:PlaygroundResetRequest")
    net.Send(ply)
end)

net.Receive("Gemini:PlaygroundAskLogs", function(len, ply)
    if not Gemini:CanUse(ply, "gemini_playground") then return end

    local Logs = Gemini:GetLogsFromPlayerSettings(ply, "Playground")

    local LogsCompressed = util.Compress( util.TableToJSON(Logs) )
    local LogsSize = #LogsCompressed

    net.Start("Gemini:PlaygroundAskLogs")
        net.WriteBool(true)
        net.WriteString("Logger.LogsSended")

        net.WriteUInt(LogsSize, Gemini.Util.DefaultNetworkUIntBig)
        net.WriteData(LogsCompressed, LogsSize)
    net.Send(ply)
end)


concommand.Add("gemini_displaychats", function()
    PrintTable(PlayerUsingPlayground)
end)