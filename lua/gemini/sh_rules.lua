--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Owner Config
----------------------------------------------------------------------------]]--

if SERVER then
    util.AddNetworkString("Gemini:BroadcastRules")
    util.AddNetworkString("Gemini:SetServerRules")
    util.AddNetworkString("Gemini:SetServerInfo")
end

local ServerRule = ServerRule or {
    ["ServerInfo"] = string.format([[# Server Information:
## Server Owner
Put your name here

## Server Name
%s

## Extra Info
Put extra info about your server, like:
- This is a english server
- This server has a discord server
- Also has a forum on forum.example.com


// Warning: This text is purely informative
// it only serves so that the artificial intelligence has more context of your server
// Remove this text after you have finished editing this file]], GetHostName()),
    ["Rules"] = [[# Server Rules:
No rules]]
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

if SERVER then
    Gemini:LoadServerInfo()
end

--[[------------------------
      Network Functions
------------------------]]--

function Gemini:BroadcastServerInfo()
    local RulesCompressed = util.Compress(self:GetRules())
    local RulesUInt = RulesCompressed and #RulesCompressed or 0

    local ServerInfoCompressed = util.Compress(self:GetServerInfo())
    local ServerInfoUInt = ServerInfoCompressed and #ServerInfoCompressed or 0

    if ( RulesUInt > Gemini.Util.MaxBandwidth ) then
        self:Print("The rules are too big to be broadcasted", os.date("%H:%M:%S"))
        return
    elseif ( ServerInfoUInt > Gemini.Util.MaxBandwidth ) then
        self:Print("The server info is too big to be broadcasted", os.date("%H:%M:%S"))
        return
    end

    net.Start("Gemini:BroadcastRules")
        net.WriteUInt(RulesUInt, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(RulesCompressed, RulesUInt)
        net.WriteUInt(ServerInfoUInt, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(ServerInfoCompressed, ServerInfoUInt)
    net.Broadcast()

    self:Print("Broadcasted server rules", os.date("%H:%M:%S"))
end

function Gemini.ReceiveServerInfo()
    local RulesCompressed = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
    local ServerInfoCompressed = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )

    local Rules = util.Decompress(RulesCompressed)
    local ServerInfo = util.Decompress(ServerInfoCompressed)

    Gemini:SetRules(Rules)
    Gemini:SetServerInfo(ServerInfo)

    hook.Run("Gemini:ReceivedServerRules", Rules, ServerInfo)
end

if CLIENT then
    net.Receive("Gemini:BroadcastRules", Gemini.ReceiveServerInfo)
end

if SERVER then
    gameevent.Listen("player_activate")
    hook.Add("player_activate", "Gemini:BroadcastRules", function()
        Gemini:BroadcastServerInfo()
    end)
end

--[[------------------------
       Replicate Rules
------------------------]]--

function Gemini:SetServerRulesClient(Rules)
    if SERVER or not self:CanUse("gemini_rules_set") then return end

    if not isstring(Rules) then
        self:Error("The rules must be a string", Rules, "string")
    end

    if ( Rules == "" ) then
        self:Error("The rules cannot be empty", Rules, "string")
    end

    local RulesCompresed = util.Compress(Rules)
    local RulesUInt = RulesCompresed and #RulesCompresed or 0

    if ( RulesUInt > Gemini.Util.MaxBandwidth ) then
        self:Error("The rules are too big to be broadcasted")
    end

    net.Start("Gemini:SetServerRules")
        net.WriteUInt(RulesUInt, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(RulesCompresed, RulesUInt)
    net.SendToServer()
end

function Gemini:SetServerInfoClient(Info)
    if SERVER or not self:CanUse("gemini_rules_set") then return end

    if not isstring(Info) then
        self:Error("The server name must be a string", Info, "string")
    end

    if ( Info == "" ) then
        self:Error("The server name cannot be empty", Info, "string")
    end

    local InfoCompressed = util.Compress(Info)
    local InfoUInt = InfoCompressed and #InfoCompressed or 0

    if ( InfoUInt > Gemini.Util.MaxBandwidth ) then
        self:Error("The server name is too big to be broadcasted")
    end

    net.Start("Gemini:SetServerInfo")
        net.WriteUInt(InfoUInt, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(InfoCompressed, InfoUInt)
    net.SendToServer()
end


if SERVER then
    function Gemini.ReceivedClientRules(len, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local RulesCompressed = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
        local Rules = util.Decompress(RulesCompressed)

        Gemini:SetRules(Rules)
        Gemini:BroadcastServerInfo()
    end

    function Gemini.ReceivedClientInfo(len, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local InfoCompressed = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
        local Info = util.Decompress(InfoCompressed)

        Gemini:SetServerInfo(Info)
        Gemini:BroadcastServerInfo()
    end

    net.Receive("Gemini:SetServerRules", Gemini.ReceivedClientRules)
end