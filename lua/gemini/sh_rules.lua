--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Owner Rules
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

    self:BroadcastServerInfo()
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
end

function Gemini:SetRules(Rules)
    if not isstring(Rules) then
        self:Error("The rules must be a string", Rules, "string")
    end

    if ( Rules == "" ) then
        self:Error("The rules cannot be empty", Rules, "string")
    end

    if #Rules > 60000 then
        self:Error("The rules are too big", Rules, "string")
    end

    ServerRule["Rules"] = Rules

    self:Print("Server rules have been set", os.date("%H:%M:%S"))

    if CLIENT then
        if Gemini:CanUse("gemini_rules_set") then
            net.Start("Gemini:SetServerRules")
                net.WriteString(Rules)
            net.SendToServer()
        else
            self:Print("You can't set rules")
        end
    else
        net.Start("Gemini:BroadcastRules")
            net.WriteString(Rules)
        net.Broadcast()
    end
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

hook.Add("Initialize", "Gemini:LoadServerInfo", function()
    Gemini:LoadServerInfo()
end)

if SERVER then
    function Gemini:BroadcastServerInfo()
        net.Start("Gemini:BroadcastRules")
            net.WriteString(ServerRule["Rules"])
            net.WriteString(ServerRule["ServerInfo"])
        net.Broadcast()
    end

    hook.Add("ShutDown", "Gemini:SaveServerInfo", function()
        Gemini:SaveServerInfo()
    end)
end

--[[------------------------
      Network Functions
------------------------]]--

if CLIENT then
    net.Receive("Gemini:BroadcastRules", function()
        local Rules = net.ReadString()
        local Info = net.ReadString()
        Gemini:SetRules(Rules)
        Gemini:SetServerInfo(Info)
    end)

    net.Receive("Gemini:SetServerRules", function()
        local Rules = net.ReadString()
        Gemini:SetRules(Rules)
    end)

    net.Receive("Gemini:SetServerInfo", function()
        local Info = net.ReadString()
        Gemini:SetServerInfo(Info)
    end)
else
    net.Receive("Gemini:BroadcastRules", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules") then return end

        local Rules = net.ReadString()
        local Info = net.ReadString()
        Gemini:SetRules(Rules)
        Gemini:SetServerInfo(Info)
    end)

    net.Receive("Gemini:SetServerRules", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local Rules = net.ReadString()
        Gemini:SetRules(Rules)
    end)

    net.Receive("Gemini:SetServerInfo", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local Info = net.ReadString()
        Gemini:SetServerInfo(Info)
    end)
end