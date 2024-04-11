--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Owner Config
----------------------------------------------------------------------------]]--

local MaxBandwidth = (2 ^ 16) - 1024 -- 63KB
local CustomConfig = "gemini/config/"

if SERVER then
    util.AddNetworkString("Gemini:BroadcastRules")
end

local ServerRule = ServerRule or {
    ["ServerInfo"] = string.format([[# Server Owner
Put your name here

# Server Name
Garry's Mod

# Extra Info
- Put extra info about your server, like:
- This is a english server
- This server has a discord server
- Also has a forum on forum.example.com


// Warning: This text is purely informative, it only serves so that the artificial intelligence has more context of your server]], GetHostName()),
    ["Rules"] = [[No rules]]
}

--[[------------------------
       Main Functions
------------------------]]--

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

    ServerRule["Rules"] = Rules

    self:Print("Server rules have been set", os.date("%H:%M:%S"))
end

function Gemini:GetServerInfo()
    return ServerRule["ServerInfo"]
end

function Gemini:GetRules()
    return ServerRule["Rules"]
end

function Gemini:GetAllRules()
    return ServerRule
end

--[[------------------------
      Network Functions
------------------------]]--

function Gemini:BroadcastServerInfo()
    -- Cut the rules to the maximum bandwidth
    local Compressed = util.Compress(ServerRule["Rules"])
    local UInt = Compressed and #Compressed or 0

    if UInt > MaxBandwidth then
        self:Print("The rules are too big to be broadcasted", os.date("%H:%M:%S"))
        return
    elseif UInt == 0 then
        self:Print("Warning: The rules are empty")
    end

    net.Start("Gemini:BroadcastRules")
        net.WriteString(ServerRule["Server Name"])
        net.WriteString(ServerRule["Server Owner"])

        net.WriteUInt(UInt, 16)
        net.WriteData(Compressed, UInt)
    net.Broadcast()

    self:Print("Broadcasted server rules", os.date("%H:%M:%S"))
end

function Gemini.ReceiveServerInfo()
    local ServerName = net.ReadString()
    local ServerOwner = net.ReadString()

    -- Rules are compressed to save bandwidth
    local UInt = net.ReadUInt(16)
    local Rules = util.Decompress(net.ReadData(UInt))

    Gemini.__RULES["Server Name"] = ServerName
    Gemini.__RULES["Server Owner"] = ServerOwner
    Gemini.__RULES["Rules"] = Rules

    Gemini:Print("Received server rules", os.date("%H:%M:%S"))
end

if CLIENT then
    net.Receive("Gemini:BroadcastRules", Gemini.ReceiveServerInfo)
end

--[[------------------------
     Load Server Config
------------------------]]--

function Gemini:ReloadRules()
    local LuaFiles = file.Find(CustomConfig .. "*.lua", "LUA")

    if #LuaFiles == 0 then
        self:Print("No server owner config found")
        return
    end

    for _, LuaFile in ipairs(LuaFiles) do
        local LuaPath = CustomConfig .. File
        if SERVER then
            AddCSLuaFile(LuaPath)
        end
        include(LuaPath)
        self:Print("Loaded Server Owner File: ", LuaPath)
    end
end

concommand.Add("gemini_reload_rules", function()
    if CLIENT then
        Gemini:Print("You cannot reload the rules from the client")
        return
    end

    Gemini:ReloadRules()
end, nil, "Reload the server owner config")