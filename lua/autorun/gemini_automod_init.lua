--[[----------------------------------------------------------------------------
                         Google Gemini Automod (v{{ script_version_name }})
----------------------------------------------------------------------------]]--

--[[------------------------
         Gemini Init
------------------------]]--

if Gemini and ( Gemini.Version == nil ) then print("Error: Something else is using the Gemini name.") return end

include("enum_color.lua")

local GeminiCFG = GeminiCFG or {["general"] = {}}
Gemini = Gemini or {
    Version = "v1.0",
    Author = "vicentefelipechile",
    Name = "Gemini",
    URL = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
    EndPoint = "https://generativelanguage.googleapis.com/v1beta/models"
}



--[[------------------------
       Server Preload
------------------------]]--

if SERVER then
    resource.AddFile("resource/fonts/Frutiger Roman.ttf")
    resource.AddFile("materials/gemini/gcloud.png")
    resource.AddFile("materials/gemini/gcloud_big.png")
    resource.AddFile("materials/gemini/gemini_icon.png")

    util.AddNetworkString("Gemini:ReplicateConfig")
    util.AddNetworkString("Gemini:SetConfig")
    util.AddNetworkString("Gemini:AddConfig")

    Promise = include("gemini/includes/promise.lua")
    AddCSLuaFile("gemini/sh_enum.lua")
end
include("gemini/sh_enum.lua")



--[[------------------------
       Local Variables
------------------------]]--

local print = print
local EmptyFunc = function() end

local isfunction = isfunction
local isentity = isentity
local isnumber = isnumber
local istable = istable
local isbool = isbool

local SetGlobal2Int = SetGlobal2Int
local SetGlobal2String = SetGlobal2String
local SetGlobal2Float = SetGlobal2Float
local SetGlobal2Bool = SetGlobal2Bool

local VERIFICATION_TYPE = {
    ["string"] = isstring,
    ["number"] = isnumber,
    ["table"] = istable,
    ["bool"] = isbool,
    ["boolean"] = isbool,
    ["range"] = function(v)
        return isnumber(v) and ( v >= 0 ) and ( v <= 1 )
    end
}

local TypeToGlobal = {
    ["string"] = SetGlobal2String,
    ["float"] = SetGlobal2Float,
    ["boolean"] = SetGlobal2Bool,
    ["number"] = SetGlobal2Int
}

local VISIBILITY_TYPE = {
    ["PRIVATE"] = function(Name, Category, Value)
        return {FCVAR_ARCHIVE, FCVAR_PROTECTED, FCVAR_DONTRECORD}
    end,
    ["PUBLIC"] = function(Name, Category, Value)
        return
            SERVER and {FCVAR_ARCHIVE, FCVAR_REPLICATED} or
            {FCVAR_ARCHIVE, FCVAR_USERINFO}
    end,
    ["REPLICATED"] = function(Name, Category, Value)
        if SERVER then
            if isnumber(Value) then
                local IsFloat = math.Round(Value, 0) == Value
                if IsFloat then
                    TypeToGlobal["float"]("Gemini:" .. Category .. "." .. Name, Value)
                else
                    TypeToGlobal["number"]("Gemini:" .. Category .. "." .. Name, Value)
                end
            else
                TypeToGlobal[ type(Value) ]("Gemini:" .. Category .. "." .. Name, Value)
            end
        end

        return {FCVAR_ARCHIVE, FCVAR_REPLICATED}
    end
}



--[[------------------------
      Error Validation
------------------------]]--

local FuncMatchRegEx = {
    "Gemini:(.*)%(",
    "(.*)%.(.*)%(",
    "(.*)%(",
    "self:(.*)%("
}

local LuaRun = {
    ["@lua_run"] = true, -- Server
    ["@LuaCmd"] = true -- Client
}

function Gemini:Error(Message, Value, Expected, OneMore)
    local Data = debug.getinfo( 3 + ( OneMore and 1 or 0 ) )

    local FilePath = LuaRun[ Data["source"] ] and "Console" or "lua/" .. string.match(Data["source"], "lua/(.*)")
    local File = ( FilePath == "Console" ) and "Console" or file.Read(FilePath, "GAME")
    local Line = string.Trim( string.Explode("\n", File)[Data["currentline"]] )

    local ErrorLine = "\t\t" .. Data["currentline"]
    local ErrorPath = "\t" .. FilePath
    local ErrorFunc = nil

    local AddQuota = ( type(Expected) == "string" ) and "\"" or ""
    local ErrorArg = "\t" .. AddQuota .. tostring(Value) .. AddQuota .. " (" .. type(Value) .. ")"

    for _, regex in ipairs(FuncMatchRegEx) do
        ErrorFunc = string.match(Line, regex)
        if ErrorFunc then break end
    end

    ErrorFunc = "\t" .. (ErrorFunc or "Unknown") .. "(...)"
    Expected = "\t" .. Expected

    error("\n" .. string.format([[
========  Gemini ThrowError  ========
- Error found in: %s
- In the line: %s
- In the function: %s

- Argument: %s
- Expected: %s

- Error Message: %s
  
========  Gemini ThrowError  ========]], ErrorPath, ErrorLine, ErrorFunc, ErrorArg, Expected, Message))
end

function Gemini:Checker(InfoTable)
    if not istable(InfoTable) then
        self:Error([[The first argument of Gemini:Checker() must be a table.]], InfoTable, "table")
    elseif table.IsEmpty(InfoTable) then
        self:Error([[The first argument of Gemini:Checker() must not be empty.]], InfoTable, "table")
    end

    local ValueToCheck = InfoTable[1]
    local ExpectedType = InfoTable[2]
    local ArgumentPos = InfoTable[3]

    if not VERIFICATION_TYPE[ ExpectedType ] then
        self:Error([[The second argument of Gemini:Checker() must be a valid type.]], ExpectedType, "a valid type")
    elseif not isnumber(ArgumentPos) then
        self:Error([[The third argument of Gemini:Checker() must be a number.]], ArgumentPos, "number")
    end

    -- Verification
    local LuaDataInfo = debug.getinfo(2)

    if not VERIFICATION_TYPE[ ExpectedType ](ValueToCheck) then
        local Phrase = "The " .. string.CardinalToOrdinal(ArgumentPos) .. " argument of the function " .. LuaDataInfo["name"] .. "() must be a " .. ExpectedType .. "."
        self:Error(Phrase, ValueToCheck, ExpectedType, true)
    end

    if ExpectedType == "string" and ( ValueToCheck == "" ) then
        local Phrase = "The " .. string.CardinalToOrdinal(ArgumentPos) .. " argument of the function " .. LuaDataInfo["name"] .. "() must not be empty."
        self:Error(Phrase, ValueToCheck, ExpectedType, true)
    end
end



--[[------------------------
       Print Function
------------------------]]--

function Gemini:GeneratePrint(cfg)
    cfg.prefix = cfg.prefix or "[Gemini] "
    cfg.prefix_clr = cfg.prefix_clr or color_white
    cfg.color = cfg.color or color_white
    cfg.func = cfg.func or EmptyFunc

    return function(...)
        local args = {...}
        local str = ""

        for _, arg in ipairs(args) do
            str = str .. tostring(arg) .. " "
        end

        str = string.TrimRight(str)

        local response = cfg.func(args)
        if ( response == false ) then return end

        MsgC(cfg.prefix_clr, cfg.prefix, cfg.color, str .. "\n")
    end
end


local LocalPrint = Gemini:GeneratePrint({color = COLOR_STATE})
local DebugPrint = Gemini:GeneratePrint({
    color = COLOR_STATE,
    func = function() return Gemini:IsDebug() end,
    prefix = "[Gemini-Debug] "
})

Gemini.Print = function(self, ...) LocalPrint(...) end
Gemini.Debug = function(self, ...) DebugPrint(...) end



--[[------------------------
      Convar Functions
------------------------]]--

local RegexFindType = {
    ["number"] = "(%d+%.?%d*)[nf]",
    ["boolean"] = "(%d)b",
}

local FromConvarConverter = {
    ["CLIENT"] = {
        ["string"] = function(Value)
            return Value
        end,
        ["number"] = function(Value)
            return tonumber( string.match(Value, RegexFindType["number"]) )
        end,
        ["boolean"] = function(Value)
            return Value == "1b"
        end
    },
    ["SERVER"] = {
        ["string"] = function(Value)
            return Value
        end,
        ["number"] = function(Value)
            return tonumber(Value)
        end,
        ["boolean"] = function(Value)
            return Value == "1"
        end
    }
}

local ToConvarConverter = {
    ["CLIENT"] = {
        ["string"] = function(Value)
            return Value
        end,
        ["number"] = function(Value)
            return tostring(Value) .. "n"
        end,
        ["boolean"] = function(Value)
            return ( Value == true ) and "1b" or "0b"
        end
    },
    ["SERVER"] = {
        ["string"] = function(Value)
            return Value
        end,
        ["number"] = function(Value)
            return tostring(Value)
        end,
        ["boolean"] = function(Value)
            return ( Value == true ) and 1 or 0
        end
    }
}

function Gemini:ConvertValue(Value)
    self:Checker({Value, "string", 1})

    local ValueType, ValueSuffix = "string", string.match(Value, "%a$")
    local TargetSide = "SERVER"

    if ( ValueSuffix == "n" ) and string.match(Value, "%d+") then
        ValueType = "number"
        TargetSide = "CLIENT"
    elseif ( ValueSuffix == "b") and string.match(Value, "(%d)b") then
        ValueType = "boolean"
        TargetSide = "CLIENT"
    end

    return FromConvarConverter[ TargetSide ][ ValueType ](Value)
end

function Gemini:FromConvar(Name, Category)
    self:Checker({Name, "string", 1})
    self:Checker({Category, "string", 2})

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    elseif not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    local CvarValue = GeminiCFG[Category][Name]["Convar"]:GetString()

    if ( CvarValue == "" ) then
        self:Error([[The convar value is empty.]], CvarValue, "string")
    end

    local ValueType = GeminiCFG[Category][Name]["Type"]
    return FromConvarConverter[ SERVER and "SERVER" or "CLIENT" ][ ValueType ](CvarValue)
end

function Gemini:ToConvar(Name, Category, Value)
    self:Checker({Name, "string", 1})
    self:Checker({Category, "string", 2})

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        GeminiCFG[Category] = {}
    end

    local ValueType, TargetSide = type(Value), SERVER and "SERVER" or "CLIENT"
    if ( ToConvarConverter[ TargetSide ][ ValueType ] == nil ) then
        self:Error([[The value type is not supported.]], Value, "a valid Value type")
    end

    return ToConvarConverter[ TargetSide ][ ValueType ](Value)
end

function Gemini:GetPlayerConfig(Player, Name, Category)
    if CLIENT then return self:GetConfig(Name, Category) end

    if not isentity(Player) then
        self:Error([[The first argument of Gemini:GetPlayerConfig() must be a valid player.]], Player, "player")
    elseif not Player:IsPlayer() then
        self:Error([[The first argument of Gemini:GetPlayerConfig() must be a valid player.]], Player, "player")
    end

    self:Checker({Name, "string", 2})
    self:Checker({Category, "string", 3})

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    return self:ConvertValue( Player:GetInfo( "gemini_" .. Category .. "_" .. Name ) )
end
Gemini.GetPlayerInfo = Gemini.GetPlayerConfig

function Gemini:CreateConfig(Name, Category, Verification, Default, Visibility)
    self:Checker({Name, "string", 1})
    self:Checker({Category, "string", 2})

    if not isfunction(Verification) then
        self:Error([[The third argument of Gemini:CreateConfig() must be a function.]], Verification, "function")
    end

    if not Verification(Default) then
        self:Error([[The fourth argument of Gemini:CreateConfig() must be the same type as the return of the third argument.]], Default, "any")
    end

    if ( Visibility == nil ) then
        Visibility = self.VISIBILITY_TYPE.PUBLIC
    else
        if not isfunction(Visibility) then
            self:Error([[The fifth argument of Gemini:CreateConfig() must be a function.]], Visibility, "function")
        end
    end

    local Value = self:ToConvar(Name, Category, Default)
    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    local Flags = Visibility(Category, Name, Value)

    GeminiCFG[Category] = GeminiCFG[Category] or {}
    GeminiCFG[Category][Name] = {
        ["Convar"] = CreateConVar("gemini_" .. Category .. "_" .. Name, Value, Flags),
        ["Verification"] = Verification,
        ["Type"] = type(Default)
    }

    -- Warning
    local TargetSide = SERVER and "SERVER" or "CLIENT"
    cvars.AddChangeCallback("gemini_" .. Category .. "_" .. Name, function(_, _, NewValue)
        local ConvertedValue = nil

        if ToConvarConverter[ TargetSide ][ GeminiCFG[Category][Name]["Type"] ] then
            ConvertedValue = ToConvarConverter[ TargetSide ][ GeminiCFG[Category][Name]["Type"] ](NewValue)
        else
            self:Print("The value type is not supported.")
            return
        end

        if not Verification(ConvertedValue) then
            self:Debug("The value doesn't match the verification function. Skipping...")
            return
        end

        self:SaveAllConfig()
        hook.Run("Gemini:ConfigChanged", Name, Category, ConvertedValue, Value)
    end, "Gemini_" .. Category .. "_" .. Name)
end


function Gemini:GetConfig(Name, Category, FromServer)
    self:Checker({Name, "string", 1})
    self:Checker({Category, "string", 2})

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    --[[ TO DO
    if ( FromServer == true ) then
        local GlobalTable = string.Explode("^", GetGlobal2String("Gemini:" .. Category .. "." .. Name, "") )
        if ( #GlobalTable > 2 ) then
            self:Error([[The global variable is not valid.]+], GlobalTable, "string")
        elseif ( #GlobalTable < 1 ) then
            self:Error([[The global variable is empty.]+], GlobalTable, "string")
        end

        local GlobalType, GlobalValue = GlobalTable[1], GlobalTable[2]

        if ( GlobalType == "" ) then
            self:Error([[The category doesn't exist.]+], Category, "string")
        end
    end
    --]]

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    end

    if not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    return self:FromConvar(Name, Category)
end


function Gemini:SetConfig(Name, Category, Value)
    self:Checker({Name, "string", 1})
    self:Checker({Category, "string", 2})

    local FormatCategory = string.lower( string.gsub(Category, "%W", "") )
    local FormatName = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[FormatCategory] then
        self:Error([[The category doesn't exist.]], FormatCategory, "string")
    end

    if not GeminiCFG[FormatCategory][FormatName] then
        self:Error([[The config doesn't exist.]], FormatName, "string")
    end

    if not GeminiCFG[FormatCategory][FormatName]["Verification"](Value) then
        self:Debug("The value doesn't match the verification function. Skipping...")
        return
    end

    if ( GeminiCFG[FormatCategory][FormatName]["Type"] ~= type(Value) ) then
        self:Error([[The value type doesn't match the config type.]], Value, "any")
    end

    if CLIENT and GeminiCFG[FormatCategory][FormatName]["Convar"]:IsFlagSet(FCVAR_REPLICATED) then
        self:Debug("You can't the value of a replicated convar.")
    end

    local ConvarValue = self:ToConvar(FormatName, FormatCategory, Value)
    GeminiCFG[FormatCategory][FormatName]["Convar"]:SetString( ConvarValue )

    self:SaveAllConfig()

    hook.Run("Gemini:ConfigChanged", Name, Category, Value, ConvarValue)
end


function Gemini:ResetConfig(Name, Category, SkipValidation)
    if ( SkipValidation == true ) then
        GeminiCFG[Category][Name]["Convar"]:Revert()
        return
    end

    self:Checker({Name, "string", 1})
    self:Checker({Category, "string", 2})

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    end

    if not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    GeminiCFG[Category][Name]["Convar"]:Revert()
end


function Gemini:GetAllConfigs()
    return table.Copy(GeminiCFG)
end


function Gemini:SaveAllConfig()
    local CopyConfigs = self:GetAllConfigs()
    local Configs = {}

    for Category, ConfigsTable in pairs(CopyConfigs) do
        Configs[Category] = {}
        for Name, Config in pairs(ConfigsTable) do
            Configs[Category][Name] = {
                ["Value"] = Config["Convar"]:GetString(),
                ["Type"] = Config["Type"]
            }
        end
    end

    file.Write("gemini/configs.json", util.TableToJSON(Configs, true))
end


function Gemini:LoadAllConfig()
    local Configs = file.Read("gemini/configs.json", "DATA")
    if not Configs then return end

    Configs = util.JSONToTable(Configs)
    if not Configs then return end

    for Category, ConfigsTable in pairs(Configs) do
        for Name, Config in pairs(ConfigsTable) do
            if not GeminiCFG[Category] then
                self:Debug([[The category doesn't exist.]], Category, "string")
                continue
            end

            if not GeminiCFG[Category][Name] then
                self:Debug([[The config doesn't exist.]], Name, "string")
                continue
            end

            if ( GeminiCFG[Category][Name]["Type"] ~= Config["Type"] ) then
                self:Debug([[The value type doesn't match the config type.]], Config["Value"], "any")
                continue
            end

            -- Is a replicated convar
            local Convar = GeminiCFG[Category][Name]["Convar"]
            if CLIENT and Convar:IsFlagSet(FCVAR_REPLICATED) then continue end

            GeminiCFG[Category][Name]["Convar"]:SetString( Config["Value"] )
        end
    end
end



--[[------------------------
       Initialization
------------------------]]--

function Gemini:PreInit()
    local Print = self:GeneratePrint({prefix = ""})

    Print("==[[==================================")
    Print("       Loading Gemini Automod...")
    Print("==================================]]==")

    self:Print("Generating Default Config " .. (SERVER and "[SV]" or "[CL]"))

    self.VERIFICATION_TYPE = VERIFICATION_TYPE
    self.VISIBILITY_TYPE = VISIBILITY_TYPE

    self:CreateConfig("Enabled", "General", self.VERIFICATION_TYPE.bool, true, self.VISIBILITY_TYPE.REPLICATED)
    self:CreateConfig("Debug", "General", self.VERIFICATION_TYPE.bool, false, self.VISIBILITY_TYPE.REPLICATED)
    self:CreateConfig("Language", "General", self.VERIFICATION_TYPE.string, "Spanish")

    self.IsDebug = function()
        return Gemini:GetConfig("Debug", "General")
    end

    if SERVER then
        AddCSLuaFile("gemini/sh_enum.lua")      self:Print("File \"gemini/sh_enum.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_util.lua")      self:Print("File \"gemini/sh_util.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_language.lua")  self:Print("File \"gemini/sh_language.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_rules.lua")     self:Print("File \"gemini/sh_rules.lua\" has been send to client.")
        AddCSLuaFile("gemini/cl_derma.lua")     self:Print("File \"gemini/cl_derma.lua\" has been send to client.")
        AddCSLuaFile("gemini/cl_gemini.lua")    self:Print("File \"gemini/cl_gemini.lua\" has been send to client.")
        AddCSLuaFile("gemini/cl_gemini_panel.lua")  self:Print("File \"gemini/cl_gemini_panel.lua\" has been send to client.")
        include("gemini/sh_enum.lua")           self:Print("File \"gemini/sh_enum.lua\" has been loaded.")
        include("gemini/sh_util.lua")           self:Print("File \"gemini/sh_util.lua\" has been loaded.")
        include("gemini/sh_language.lua")       self:Print("File \"gemini/sh_language.lua\" has been loaded.")
        include("gemini/sv_sandbox.lua")        self:Print("File \"gemini/sv_sandbox.lua\" has been loaded.")
        include("gemini/sv_logger.lua")         self:Print("File \"gemini/sv_logger.lua\" has been loaded.")
        include("gemini/sv_httpcode.lua")       self:Print("File \"gemini/sv_httpcode.lua\" has been loaded.")
        include("gemini/sv_gemini.lua")         self:Print("File \"gemini/sv_gemini.lua\" has been loaded.")
        include("gemini/sv_train.lua")          self:Print("File \"gemini/sv_train.lua\" has been loaded.")
        include("gemini/sv_playground.lua")     self:Print("File \"gemini/sv_playground.lua\" has been loaded.")
        include("gemini/sv_formatter.lua")      self:Print("File \"gemini/sv_formatter.lua\" has been loaded.")
    else
        include("gemini/sh_util.lua")           self:Print("File \"gemini/sh_util.lua\" has been loaded.")
        include("gemini/sh_language.lua")       self:Print("File \"gemini/sh_language.lua\" has been loaded.")
    end

    include("gemini/sh_enum.lua")               self:Print("File \"gemini/sh_enum.lua\" has been loaded.")
    include("gemini/sh_rules.lua")              self:Print("File \"gemini/sh_rules.lua\" has been loaded.")

    hook.Run("Gemini:PreInit")
    Gemini:Init()
end

function Gemini:Init()
    file.CreateDir("gemini")

    if isfunction(self.LanguagePoblate) then
        self:LanguagePoblate()
    else
        self:Error([[The function "LanguagePoblate" has been replaced by another third-party addon!!!]], self.LanguagePoblate, "function")
    end

    if SERVER then
        if isfunction(self.LoggerCheckTable) then
            self:LoggerCheckTable()
        else
            self:Error([[The function "LoggerCheckTable" has been replaced by another third-party addon!!!]], self.LoggerCheckTable, "function")
        end

        if isfunction(self.GeminiPoblate) then
            self:GeminiPoblate()
        else
            self:Error([[The function "GeminiPoblate" has been replaced by another third-party addon!!!]], self.GeminiPoblate, "function")
        end

        if isfunction(self.TrainPoblate) then
            self:TrainPoblate()
        else
            self:Error([[The function "TrainPoblate" has been replaced by another third-party addon!!!]], self.TrainPoblate, "function")
        end

        if isfunction(self.FormatterPoblate) then
            self:FormatterPoblate()
        else
            self:Error([[The function "FormatterPoblate" has been replaced by another third-party addon!!!]], self.FormatterPoblate, "function")
        end

        -- AddCSLua file to all files inside "gemini/module"
        local LuaCSFiles, LuaSubFolder = file.Find("gemini/module/*", "LUA")
        for _, File in ipairs(LuaCSFiles) do
            AddCSLuaFile("gemini/module/" .. File)
            self:Print("File \"module/" .. File .. "\" has been send to client.")
        end

        for _, Folder in ipairs(LuaSubFolder) do
            local LuaSubCSFiles, _ = file.Find("gemini/module/" .. Folder .. "/*.lua", "LUA")
            for _, File in ipairs(LuaSubCSFiles) do
                AddCSLuaFile("gemini/module/" .. Folder .. "/" .. File)
                self:Print("File \"module/" .. Folder .. "/" .. File .. "\" has been send to client.")
            end
        end

    else
        include("gemini/cl_derma.lua")          self:Print("File \"gemini/cl_derma.lua\" has been loaded.")
        include("gemini/cl_gemini.lua")         self:Print("File \"gemini/cl_gemini.lua\" has been loaded.")
        include("gemini/cl_gemini_panel.lua")   self:Print("File \"gemini/cl_gemini_panel.lua\" has been loaded.")
    end

    hook.Run("Gemini:Init")
    Gemini:PostInit()
end


local HTTPLoaded = false
function Gemini:PostInit()
    local Print = Gemini:GeneratePrint({prefix = ""})

    Print("==[[==================================")
    Print("         Gemini Automod Loaded")
    Print("==================================]]==")
    print("")

    if file.Exists("gemini/configs.json", "DATA") then
        Gemini:LoadAllConfig()
    else
        Gemini:SaveAllConfig()
    end

    hook.Run("Gemini:PostInit")

    if HTTPLoaded then
        hook.Run("Gemini:HTTPLoaded")
    else
        hook.Add("InitPostEntity", "Gemini:HTTPLoaded", function()
            timer.Simple(8, function()
                hook.Run("Gemini:HTTPLoaded")
                HTTPLoaded = true
            end)
        end)
    end
end

Gemini:PreInit()


--[[------------------------
       Reload Command
------------------------]]--

if SERVER then
    net.Receive("Gemini:ReplicateConfig", function(len, ply)
        if not Gemini:CanUse(ply, "gemini_config") then return end

        Gemini:Print("Reloading Gemini Automod...")
        Gemini:PreInit()

        net.Start("Gemini:ReplicateConfig")
        net.Broadcast()
    end)

    net.Receive("Gemini:SetConfig", function(len, ply)
        if not Gemini:CanUse(ply, "gemini_config_sv") then return end

        local Name = net.ReadString()
        local Category = net.ReadString()
        local Value = net.ReadType()

        Gemini:SetConfig(Name, Category, Value)
    end)
else
    net.Receive("Gemini:ReplicateConfig", function(len)
        Gemini:Print("Reloading Gemini Automod...")
        Gemini:PreInit()
    end)
end

concommand.Add("gemini_reload", function(ply)
    if SERVER then
        Gemini:Print("Reloading Gemini Automod...")
        Gemini:PreInit()

        net.Start("Gemini:ReplicateConfig")
        net.Broadcast()
    elseif Gemini:CanUse("gemini_config_set") then
        net.Start("Gemini:ReplicateConfig")
        net.SendToServer()
    else
        Gemini:Print("You are not a superadmin.")
    end
end)


--[[------------------------
       Credits Command
------------------------]]--

concommand.Add("gemini_credits", function(ply)
    Gemini:Print("==== Gemini Automod ====")
    Gemini:Print("Version:   ", Gemini.Version)
    Gemini:Print("Author:    ", Gemini.Author)
    if Gemini:IsDebug() and (SERVER or Gemini:CanUse("gemini_automod")) then
        Gemini:Print("DEVELOPER MODE ENABLED")
        Gemini:Print("URL:       ", Gemini.URL)
        Gemini:Print("EndPoint:  ", Gemini.EndPoint)
        Gemini:Print("DEVELOPER MODE ENABLED")
    end
    Gemini:Print("==== Gemini Automod ====")
end)