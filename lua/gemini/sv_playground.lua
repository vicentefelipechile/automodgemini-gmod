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

function Gemini:PlaygroundMakeRequest(AllConfig, ply)
    if not istable(AllConfig) then
        self:Error("The first argument of Gemini:MakeRequest() must be a table.", AllConfig, "table")
    end

    --[[ All Body ]]--
    local GeminiModel = self:GetConfig("ModelName", "Gemini")
    local GamemodeModel = self:GetGamemodeContext()
    local GenerationConfig = AllConfig["GenerationConfig"] or self:GetGenerationConfig()
    local SafetyConfig = AllConfig["SafetyConfig"] or self:GetSafetyConfig()
    local Prompt = AllConfig["Prompt"] or ""

    --[[ Contents ]]--
    local Contents = {
        { ["parts"] = {["text"] = GamemodeModel}, ["role"] = "user"}
    }

    if ( Prompt ~= "" ) then
        table.insert(Contents, { ["parts"] = {["text"] = Prompt}, ["role"] = "prompt"})
    end

    --[[ Body ]]--
    local Body = {
        ["generationConfig"] = GenerationConfig,
        ["safetySettings"] = SafetyConfig,
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
    local RequestGenerationConfig = net.ReadTable()
    local RequestSafetyConfig = net.ReadTable()
    local RequestPrompt = net.ReadString()

    RequestGenerationConfig = RequestGenerationConfig == {} and nil or RequestGenerationConfig
    RequestSafetyConfig = RequestSafetyConfig == {} and nil or RequestSafetyConfig

    local RequestConfig = {
        ["GenerationConfig"] = RequestGenerationConfig,
        ["SafetyConfig"] = RequestSafetyConfig,
        ["Prompt"] = RequestPrompt
    }

    Gemini:PlaygroundMakeRequest(RequestConfig, ply)
end

net.Receive("Gemini:PlaygroundMakeRequest", Gemini.PlaygroundReceivePetition)