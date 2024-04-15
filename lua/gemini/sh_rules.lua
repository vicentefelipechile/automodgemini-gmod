--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Owner Config
----------------------------------------------------------------------------]]--

local MaxBandwidth = (2 ^ 16) - 1024 -- 63KB
local DefaultNetworkUInt = 16

if SERVER then
    util.AddNetworkString("Gemini:BroadcastRules")
end

local ServerRule = ServerRule or {
    ["ServerInfo"] = string.format([[# Server Owner
Put your name here

# Server Name
%s

# Extra Info
- Put extra info about your server, like:
- This is a english server
- This server has a discord server
- Also has a forum on forum.example.com


// Warning: This text is purely informative
// it only serves so that the artificial intelligence has more context of your server
// Remove this text after you have finished editing this file]], GetHostName()),
    ["Rules"] = [[No rules]]
}

--[[------------------------
       Main Functions
------------------------]]--

function Gemini:LoadServerInfo()
    if CLIENT then return end

    if not file.Exists("gemini/server_rules.txt", "DATA") then
        self:SaveServerInfo()
    end

    self:SetRules( file.Read("gemini/server_rules.txt", "DATA") )
    self:SetServerInfo( file.Read("gemini/server_info.txt", "DATA") )
end

function Gemini:SaveServerInfo()
    if CLIENT then return end

    file.Write("gemini/server_rules.txt", ServerRule["Rules"])
    file.Write("gemini/server_info.txt", ServerRule["ServerInfo"])
end

function Gemini:SetServerInfo(Info)
    if not isstring(Info) then
        self:Error("The server name must be a string", Name, "string")
    end

    if ( Info == "" ) then
        self:Error("The server name cannot be empty", Name, "string")
    end

    ServerRule["ServerInfo"] = Info

    self:Print("Server info has been set", os.date("%H:%M:%S"))
    self:SaveServerInfo()
end

function Gemini:SetRules(Rules)
    if not isstring(Rules) then
        self:Error("The rules must be a string", Rules, "string")
    end

    if ( Rules == "" ) then
        self:Error("The rules cannot be empty", Rules, "string")
    end

    ServerRule["Rules"] = Rules

    self:Print("Server rules have been set", os.date("%H:%M:%S"))
    self:SaveServerInfo()
end

function Gemini:GetServerInfo()
    return ServerRule["ServerInfo"]
end

function Gemini:GetRules()
    return ServerRule["Rules"]
end

function Gemini:GetAllRules()
    return table.Copy(ServerRule)
end

Gemini:LoadServerInfo()

--[[------------------------
      Network Functions
------------------------]]--

function Gemini:BroadcastServerInfo()
    -- Cut the rules to the maximum bandwidth
    local RulesCompressed = util.Compress(self:GetRules())
    local RulesUInt = RulesCompressed and #RulesCompressed or 0

    local ServerInfoCompressed = util.Compress(self:GetServerInfo())
    local ServerInfoUInt = ServerInfoCompressed and #ServerInfoCompressed or 0

    if ( RulesUInt > MaxBandwidth ) then
        self:Print("The rules are too big to be broadcasted", os.date("%H:%M:%S"))
        return
    elseif ( ServerInfoUInt > MaxBandwidth ) then
        self:Print("The server info is too big to be broadcasted", os.date("%H:%M:%S"))
        return
    end

    net.Start("Gemini:BroadcastRules")
        net.WriteUInt(RulesUInt, DefaultNetworkUInt)
        net.WriteData(RulesCompressed, RulesUInt)
        net.WriteUInt(ServerInfoUInt, DefaultNetworkUInt)
        net.WriteData(ServerInfoCompressed, ServerInfoUInt)
    net.Broadcast()

    self:Print("Broadcasted server rules", os.date("%H:%M:%S"))
end

function Gemini.ReceiveServerInfo()
    local RulesCompressed = net.ReadData( net.ReadUInt(DefaultNetworkUInt) )
    local ServerInfoCompressed = net.ReadData( net.ReadUInt(DefaultNetworkUInt) )

    local Rules = util.Decompress(RulesCompressed)
    local ServerInfo = util.Decompress(ServerInfoCompressed)

    Gemini:SetRules(Rules)
    Gemini:SetServerInfo(ServerInfo)

    hook.Run("Gemini:ReceivedServerRules", Rules, ServerInfo)
end

if CLIENT then
    net.Receive("Gemini:BroadcastRules", Gemini.ReceiveServerInfo)
end