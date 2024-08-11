--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Information
----------------------------------------------------------------------------]]-- BG

if SERVER then
    util.AddNetworkString("Gemini:SetServerRules")
    util.AddNetworkString("Gemini:SetServerInformation")
    util.AddNetworkString("Gemini:RequestServerData")
end

local function GetDate()
    return os.date("%H:%M:%S")
end

--[[------------------------
         Server Data
------------------------]]--

local ServerData = ServerData or {
    ["Information"] = string.format([[# Server Information:
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

function Gemini:SaveServerData()
    if CLIENT then return end

    file.Write("gemini/serverdata.txt", util.TableToJSON(ServerData, true))
end

function Gemini:SetServerInformation(Information, OnlySet)
    self:Checker({Information, "string", 1})

    ServerData["Information"] = Information

    if ( OnlySet == true ) then return end

    if #Information > Gemini.Util.MaxBandwidth then
        self:Error("Information is too big to be sended", #Information, "x<=" .. Gemini.Util.MaxBandwidth)
    end

    if CLIENT and self:CanUse("gemini_rules_set") then
        net.Start("Gemini:SetServerInformation")
            net.WriteString(Information)
        net.SendToServer()

    elseif SERVER then
        net.Start("Gemini:SetServerInformation")
            net.WriteString(Information)
        net.Broadcast()

        self:SaveServerData()
        hook.Run("Gemini:ServerInformationUpdated", Information)
    end

    self:Debug("Server info has been set", GetDate())
end

function Gemini:SetServerRules(Rules, OnlySet)
    self:Checker({Rules, "string", 1})

    ServerData["Rules"] = Rules

    if ( OnlySet == true ) then return end

    if #Rules > Gemini.Util.MaxBandwidth then
        self:Error("Rules are too big to be sended", #Rules, "x<=" .. Gemini.Util.MaxBandwidth)
    end

    if ( CLIENT and self:CanUse("gemini_rules_set") ) then
        net.Start("Gemini:SetServerRules")
            net.WriteString(Rules)
        net.SendToServer()

    elseif SERVER then
        net.Start("Gemini:SetServerRules")
            net.WriteString(Rules)
        net.Broadcast()

        self:SaveServerData()
        hook.Run("Gemini:ServerRulesUpdated", Rules)
    end

    self:Debug("Server rules have been set", GetDate())
end

function Gemini:GetServerInformation()
    return ServerData["Information"]
end

function Gemini:GetServerRules()
    return ServerData["Rules"]
end

function Gemini:GetServerData()
    return table.Copy(ServerData)
end

function Gemini:LoadServerData()
    if CLIENT then return end

    if not file.Exists("gemini/serverdata.txt", "DATA") then
        self:SaveServerData()
    end

    ServerData = util.JSONToTable(file.Read("gemini/serverdata.txt", "DATA"))
end

if SERVER then
    hook.Add("Gemini:PostInit", "Gemini:LoadServerData", function()
        Gemini:LoadServerData()

        net.Start("Gemini:SetServerRules")
            net.WriteString(ServerData["Rules"])
        net.Broadcast()

        net.Start("Gemini:SetServerInformation")
            net.WriteString(ServerData["Information"])
        net.Broadcast()
    end)

    hook.Add("Gemini:PlayerFullyConnected", "Gemini:SendServerData", function(ply)
        net.Start("Gemini:SetServerRules")
            net.WriteString(ServerData["Rules"])
        net.Send(ply)

        net.Start("Gemini:SetServerInformation")
            net.WriteString(ServerData["Information"])
        net.Send(ply)
    end)
end

--[[------------------------
      Network Functions
------------------------]]--

if CLIENT then
    net.Receive("Gemini:SetServerRules", function()
        local Rules = net.ReadString()
        Gemini:SetServerRules(Rules, true)

        hook.Run("Gemini:ServerRulesUpdated", Rules)
    end)

    net.Receive("Gemini:SetServerInformation", function()
        local Information = net.ReadString()
        Gemini:SetServerInformation(Information, true)

        hook.Run("Gemini:ServerInformationUpdated", Information)
    end)

    net.Receive("Gemini:RequestServerData", function()
        local Rules = net.ReadString()
        local Information = net.ReadString()

        Gemini:SetServerRules(Rules, true)
        Gemini:SetServerInformation(Information, true)
        hook.Run("Gemini:ServerRulesUpdated", Rules)
        hook.Run("Gemini:ServerInformationUpdated", Information)
    end)
else
    net.Receive("Gemini:SetServerRules", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local Rules = net.ReadString()
        Gemini:SetServerRules(Rules)
    end)

    net.Receive("Gemini:SetServerInformation", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local Information = net.ReadString()
        Gemini:SetServerInformation(Information)
    end)

    net.Receive("Gemini:RequestServerData", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules") then return end

        net.Start("Gemini:RequestServerData")
            net.WriteString(ServerData["Rules"])
            net.WriteString(ServerData["Information"])
        net.Send(ply)
    end)
end