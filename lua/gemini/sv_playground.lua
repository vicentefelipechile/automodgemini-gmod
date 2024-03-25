--[[----------------------------------------------------------------------------
                    Google Gemini Automod - Playground Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:PlaygroundSendMessage")
util.AddNetworkString("Gemini:PlaygroundMakeRequest")
local WhoAreUsingPlayground = {}

--[[------------------------
       Util Functions
------------------------]]--

function Gemini:PlaygroundSendMessage(ply, Message)
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
    net.Send(ply)
end

--[[------------------------
       Playground API
------------------------]]--

function Gemini:PlaygroundGetLogsFromPly(ply)
    local IsBetween = ply:GetInfoNum("gemini_playground_betweenlogs", 0) == 1
    local Limit = math.min(
        self:GetConfig("MaxLogsRequest", "Logger"), 
        ply:GetInfoNum("gemini_playground_maxlogs", 30)
    )
    local Logs = {}

    if IsBetween then
        local Min = ply:GetInfoNum("gemini_playground_betweenlogs_min", 1)
        local Max = ply:GetInfoNum("gemini_playground_betweenlogs_max", 1)
        Logs = sql_Query( string.format(Gemini.__LOGGER.GETALLLOGSRANGE, Min, Max, Limit) )
    
        Logs = ( Logs == nil ) and {} or Logs
    else
        local PlayerID = ply:GetInfoNum("gemini_playground_playertarget", 0)

        if ( PlayerID == 0 ) then
            Logs = self:LoggerGetLogsLimit(Limit)
        else
            Logs = self:LoggerGetLogsPlayer(PlayerID, Limit)
        end
    end

    local LogsTable = {}
    for _, LogInfo in ipairs(Logs) do
        table.insert(LogsTable, LogInfo["geminilog_time"] .. " - " .. LogInfo["geminilog_log"])
    end

    return LogsTable
end

function Gemini:PlaygroundMakeRequest(Prompt, ply)
    if not isstring(Prompt) then
        self:Error("The first argument of Gemini:PlaygroundMakeRequest() must be a string.", Prompt, "string")
    elseif ( Prompt == "" ) then
        self:Error("The first argument of Gemini:PlaygroundMakeRequest() must not be empty.", Prompt, "string")
    end

    --[[ All Body ]]--
    local GeminiModel = self:GetConfig("ModelName", "Gemini")
    local GamemodeModel = self:GetGamemodeContext()
    local Prompt = AllConfig["Prompt"] or ""

    --[[ Contents ]]--
    local Contents = {
        { ["parts"] = {["text"] = GamemodeModel}, ["role"] = "user"}
    }

    --[[ Context ]]--
    local PlayerWantContext = ply:GetInfoNum("gemini_playground_attachcontext", 0) == 1
    if PlayerWantContext then
        local Context = self:PlaygroundGetLogsFromPly(ply)
        table.insert(Contents, { ["parts"] = {["text"] = Context}, ["role"] = "context"})
    end

    --[[ Prompt ]]--
    table.insert(Contents, { ["parts"] = {["text"] = Prompt}, ["role"] = "prompt"})

    --[[ Body ]]--
    local Body = {
        ["generationConfig"] = self:GetGenerationConfig(),
        ["safetySettings"] = self:GetSafetyConfig(),
        ["contents"] = Contents
    }

    local BodyJSON = util.TableToJSON(Body, true)
    file.Write("gemini_request.txt", BodyJSON)

    --[[ Request ]]--
    local APIKey = self:GetConfig("APIKey", "Gemini")

    local RequestMade = HTTP({
        ["url"] = string.format(self.URL, GeminiModel, APIKey),
        ["method"] = "POST",
        ["type"] = "application/json",
        ["body"] = BodyJSON,
        ["success"] = function(Code, BodyResponse, Headers)    
            self:GetHTTPDescription(Code)

            file.Write("gemini_response.txt", BodyResponse)
        end,
        ["failed"] = function(Error)
            self:Print("Failed to make request to Gemini API. Error: ", Error)
        end
    })

    if RequestMade then
        self:PlaygroundSendMessage(ply, "Request has been made to Gemini API.")
    else
        self:PlaygroundSendMessage(ply, "Failed to make request to Gemini API.")
    end
end

function Gemini.PlaygroundReceivePetition(len, ply)
    local Prompt = net.ReadString()

    Gemini:PlaygroundMakeRequest(Prompt, ply)
end

net.Receive("Gemini:PlaygroundMakeRequest", Gemini.PlaygroundReceivePetition)