--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Information
----------------------------------------------------------------------------]]-- BG

if SERVER then
    util.AddNetworkString("Gemini:SetServerRules")
    util.AddNetworkString("Gemini:SetServerInformation")
end

local function GetDate()
    return os.date("%H:%M:%S")
end

local function CompressDataText(Text)
    local CompressedText = util.Compress(Text)
    if #CompressedText > Gemini.Util.MaxBandwidth then
        Gemini:Error("The string is too big to be sended", #CompressedText, "X<=" .. Gemini.Util.MaxBandwidth)
    end

    net.WriteUInt(#CompressedText, Gemini.Util.DefaultNetworkUInt)
    net.WriteData(CompressedText, #CompressedText)
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

function Gemini:SetServerInformation(Information, NoLoop)
    self:Checker({Information, "string", 1})

    ServerData["Information"] = Information

    if
        ( CLIENT and ( NoLoop ~= true ) and self:CanUse("gemini_rules_set") ) or
        SERVER
    then
        net.Start("Gemini:SetServerInformation")
            CompressDataText(Information)

        if SERVER then
            net.Broadcast()
            self:SaveServerData()
            hook.Run("Gemini:ServerInformationUpdated", Information)
        else
            net.SendToServer()
        end
    end

    self:Debug("Server info has been set", GetDate())
end

function Gemini:SetServerRules(Rules, NoLoop)
    self:Checker({Rules, "string", 1})

    ServerData["Rules"] = Rules

    if
        ( CLIENT and ( NoLoop ~= true ) and self:CanUse("gemini_rules_set") ) or
        SERVER
    then
        net.Start("Gemini:SetServerRules")
            CompressDataText(Rules)

        if SERVER then
            net.Broadcast()
            self:SaveServerData()
            hook.Run("Gemini:ServerRulesUpdated", Rules)
        else
            net.SendToServer()
        end
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

hook.Add("Gemini:PostInit", "Gemini:LoadServerData", function()
    Gemini:LoadServerData()
end)

hook.Add("Gemini:PlayerFullyConnected", "Gemini:SendServerData", function(ply)
    if CLIENT then return end

    net.Start("Gemini:SetServerRules")
        CompressDataText(ServerData["Rules"])
    net.Send(ply)

    net.Start("Gemini:SetServerInformation")
        CompressDataText(ServerData["Information"])
    net.Send(ply)
end)

--[[------------------------
      Network Functions
------------------------]]--

if CLIENT then
    net.Receive("Gemini:SetServerRules", function()
        local Rules = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
        Gemini:SetServerRules(Rules, true)

        hook.Run("Gemini:ServerRulesUpdated", Rules)
    end)

    net.Receive("Gemini:SetServerInformation", function()
        local Information = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
        Gemini:SetServerInformation(Information, true)

        hook.Run("Gemini:ServerInformationUpdated", Information)
    end)
else
    net.Receive("Gemini:SetServerRules", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local Rules = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
        Gemini:SetServerRules(Rules)
    end)

    net.Receive("Gemini:SetServerInformation", function(_, ply)
        if not Gemini:CanUse(ply, "gemini_rules_set") then return end

        local Information = net.ReadData( net.ReadUInt(Gemini.Util.DefaultNetworkUInt) )
        Gemini:SetServerInformation(Information)
    end)
end