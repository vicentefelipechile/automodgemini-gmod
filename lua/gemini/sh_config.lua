--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Server Owner Config
----------------------------------------------------------------------------]]--

local MaxBandwidth = (2 ^ 16) - 1024 -- 63KB
local CustomConfig = "gemini/config/"

if SERVER then
    util.AddNetworkString("Gemini:BroadcastRules")
end

Gemini.__RULES = Gemini.__RULES or {
    ["Server Name"] = GetHostName(),
    ["Server Owner"] = "NO SERVER OWNER SET",
    ["Rules"] = [[No rules]]
}

--[[------------------------
       Main Functions
------------------------]]--

function Gemini:SetServerOwner(Name)
    if not isstring(Name) then
        self:Error("The server owner must be a string", Name, "string")
    end

    if ( Name == "" ) then
        self:Error("The server owner cannot be empty", Name, "string")
    end

    self.__RULES["Server Owner"] = Name

    self:Print("Server owner has been set", os.date("%H:%M:%S"))
end

function Gemini:SetServerName(Name)
    if not isstring(Name) then
        self:Error("The server name must be a string", Name, "string")
    end

    if ( Name == "" ) then
        self:Error("The server name cannot be empty", Name, "string")
    end

    self.__RULES["Server Name"] = Name

    self:Print("Server name has been set", os.date("%H:%M:%S"))
end

function Gemini:SetRules(Rules)
    if not isstring(Rules) then
        self:Error("The rules must be a string", Rules, "string")
    end

    if ( Rules == "" ) then
        self:Error("The rules cannot be empty", Rules, "string")
    end

    self.__RULES["Rules"] = Rules

    self:Print("Server rules have been set", os.date("%H:%M:%S"))
end

function Gemini:GetServerOwner()
    return self.__RULES["Server Owner"]
end

function Gemini:GetServerName()
    return self.__RULES["Server Name"]
end

function Gemini:GetRules()
    return self.__RULES["Rules"]
end

function Gemini:GetAllRules()
    return self.__RULES
end

--[[------------------------
      Network Functions
------------------------]]--

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

function Gemini:BroadcastServerInfo()
    -- Cut the rules to the maximum bandwidth
    local Compressed = util.Compress(self.__RULES["Rules"])
    local UInt = Compressed and #Compressed or 0

    if UInt > MaxBandwidth then
        self:Print("The rules are too big to be broadcasted", os.date("%H:%M:%S"))
        return
    elseif UInt == 0 then
        self:Print("Warning: The rules are empty")
    end

    net.Start("Gemini:BroadcastRules")
        net.WriteString(self.__RULES["Server Name"])
        net.WriteString(self.__RULES["Server Owner"])

        net.WriteUInt(UInt, 16)
        net.WriteData(Compressed, UInt)
    net.Broadcast()

    self:Print("Broadcasted server rules", os.date("%H:%M:%S"))
end

if CLIENT then
    net.Receive("Gemini:BroadcastRules", Gemini.ReceiveServerInfo)
end

--[[------------------------
     Load Server Config
------------------------]]--

function Gemini:ReloadRules()
    local LuaFiles = file.Find(CustomConfig .. "*.lua", "LUA")
    local AtLeastOne = false

    for _, LuaFile in ipairs(LuaFiles) do
        local LuaPath = CustomConfig .. File
        if SERVER then
            AddCSLuaFile(LuaPath)
        end
        include(LuaPath)
        self:Print("Loaded Server Owner File: ", LuaPath)

        AtLeastOne = true
    end

    if not AtLeastOne then
        self:Print("No server owner config found")
    end
end

concommand.Add("gemini_reload_rules", function()
    if CLIENT then
        Gemini:Print("You cannot reload the rules from the client")
        return
    end

    Gemini:ReloadRules()
end, nil, "Reload the server owner config")