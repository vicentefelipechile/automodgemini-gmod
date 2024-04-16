include("enum_color.lua")

--[[----------------------------------------------------------------------------
                              Google Gemini Automod
----------------------------------------------------------------------------]]--

if Gemini and ( Gemini.Version == nil ) then print("Error: Something else is using the Gemini name.") return end

resource.AddFile("resource/fonts/Frutiger Roman.ttf")

local GeminiCFG = GeminiCFG or {["general"] = {}}
Gemini = Gemini or {
    Version = "1.0",
    Author = "vicentefelipechile",
    Name = "Gemini",
    URL = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s"
}

--[[------------------------
       Main Functions
------------------------]]--

if SERVER then
    util.AddNetworkString("Gemini:ReplicateConfig")
    util.AddNetworkString("Gemini:SetConfig")
    util.AddNetworkString("Gemini:AddConfig")
end

local FCVAR_PRIVATE = {FCVAR_ARCHIVE, FCVAR_PROTECTED, FCVAR_DONTRECORD}
local FCVAR_PUBLIC = SERVER and {FCVAR_ARCHIVE, FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_USERINFO}


local print = print
local EmptyFunc = function() end

local isfunction = isfunction
local isentity = isentity
local isnumber = isnumber
local isangle = isangle
local istable = istable
local IsColor = IsColor
local isbool = isbool

local VERIFICATION_TYPE = {
    ["function"] = isfunction,
    ["entity"] = isentity,
    ["string"] = isstring,
    ["number"] = isnumber,
    ["Angle"] = isangle,
    ["table"] = istable,
    ["color"] = IsColor,
    ["bool"] = isbool,
    ["range"] = function(v)
        return isnumber(v) and ( v >= 0 ) and ( v <= 1 )
    end
}

function Gemini:GeneratePrint(cfg)
    if not istable(cfg) then return print end

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
Gemini.Print = function(self, ...)
    LocalPrint(...)
end

local FuncMatchRegEx = {
    "Gemini:(.*)%(",
    "(.*)%.(.*)%(",
    "(.*)%(",
    "self:(.*)%("
}

local LuaRun = {["@lua_run"] = true, ["@LuaCmd"] = true}
function Gemini:Error(Message, Value, Expected)
    local Data = debug.getinfo(3)

    local FilePath = LuaRun[ Data["source"] ] and "Console" or "lua/" .. string.match(Data["source"], "lua/(.*)")
    local File = ( FilePath == "Console" ) and "Console" or file.Read(FilePath, "GAME")
    local Line = string.Trim( string.Explode("\n", File)[Data["currentline"]] )

    local ErrorLine = "\t\t" .. Data["currentline"]
    local ErrorPath = "\t" .. FilePath
    local ErrorFunc = nil
    local ErrorArg = "\t" .. tostring(Value) .. " (" .. type(Value) .. ")"

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


local ToConvarConverter = {
    ["string"] = function(Value) return Value end,
    ["number"] = function(Value)
        if ( math.floor(Value) == Value ) then
            return tostring(Value) .. "n"
        else
            return tostring(Value) .. "f"
        end
    end,
    ["boolean"] = function(Value) return Value and "1b" or "0b" end,
    ["color"] = function(Value) return Value end,
    ["Angle"] = function(Value) return Value end,
}

local SufixToType = {
    ["n"] = "number",
    ["f"] = "number",
    ["b"] = "boolean",
}

local FindAngleConvar = "(.*)P (.*)Y (.*)R"
local FindColorConvar = "(.*)R (.*)G (.*)B"
local FindColorAlphaConvar = "(.*)R (.*)G (.*)B (.*)A"

function Gemini:ConvertValue(Value)
    if not isstring(Value) then
        self:Error([[The first argument of Gemini:ConvertValue() must be a string.]], Value, "string")
    elseif ( Value == "" ) then
        self:Error([[The first argument of Gemini:ConvertValue() must not be empty.]], Value, "string")
    end

    local ValueType = string.sub(Value, -1)
    if SufixToType[ValueType] then
        if ( ValueType == "n" or ValueType == "f" ) then
            Value = tonumber( string.sub(Value, 1, -2) )
        elseif ValueType == "b" then
            Value = ( string.sub(Value, 1, -2) == "1" )
        end
    else
        if string.match(Value, FindColorAlphaConvar) then
            local R, G, B, A = string.match(Value, FindColorAlphaConvar)
            Value = Color(tonumber(R), tonumber(G), tonumber(B), tonumber(A))
        elseif string.match(Value, FindColorConvar) then
            local R, G, B = string.match(Value, FindColorConvar)
            Value = Color(tonumber(R), tonumber(G), tonumber(B))
        elseif string.match(Value, FindAngleConvar) then
            local P, Y, R = string.match(Value, FindAngleConvar)
            Value = Angle(tonumber(P), tonumber(Y), tonumber(R))
        end
    end

    return Value
end

function Gemini:FromConvar(Name, Category)
    if not isstring(Name) then
        self:Error([[The first argument of Gemini:FromConvar() must be a string.]], Name, "string")
    elseif ( Name == "" ) then
        self:Error([[The first argument of Gemini:FromConvar() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:FromConvar() must be a string.]], Category, "string")
    elseif ( Category == "" ) then
        self:Error([[The second argument of Gemini:FromConvar() must not be empty.]], Category, "string")
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    elseif not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    local Value = GeminiCFG[Category][Name][1]:GetString()

    if ( Value == "" ) then
        self:Error([[The convar value is empty.]], Value, "string")
    end

    return self:ConvertValue(Value)
end

function Gemini:ToConvar(Name, Category, Value)
    if not isstring(Name) then
        self:Error([[The first argument of Gemini:ToConvar() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:ToConvar() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:ToConvar() must be a string.]], Category, "string")
    end

    if ( Category == "" ) then
        self:Error([[The second argument of Gemini:ToConvar() must not be empty.]], Category, "string")
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        GeminiCFG[Category] = {}
    end

    local ValueType = IsColor(Value) and "color" or type(Value)
    if not ToConvarConverter[ ValueType ] then
        self:Error([[The value type is not supported.]], Value, "a valid Value")
    end

    local ConvertedValue = ToConvarConverter[ ValueType ](Value)

    if IsColor(ConvertedValue) then
        ConvertedValue = ConvertedValue:ToTable()
        ConvertedValue = string.format([["%sR %sG %sB %sA"]], ConvertedValue[1], ConvertedValue[2], ConvertedValue[3], ConvertedValue[4])
    elseif isangle(ConvertedValue) then
        ConvertedValue = string.format([["%sP %sY %sR"]], ConvertedValue.p, ConvertedValue.y, ConvertedValue.r)
    end

    return ConvertedValue
end

function Gemini:GetPlayerInfo(Player, ConvarName)
    ConvarName = CLIENT and Player or ConvarName
    Player = CLIENT and LocalPlayer() or Player

    if not isentity(Player) then
        self:Error([[The first argument of Gemini:GetPlayerInfo() must be a valid player.]], Player, "Player")
    elseif not Player:IsPlayer() then
        self:Error([[The first argument of Gemini:GetPlayerInfo() must be a valid player.]], Player, "Player")
    end

    if not isstring(ConvarName) then
        self:Error([[The second argument of Gemini:GetPlayerInfo() must be a string.]], ConvarName, "string")
    elseif ( ConvarName == "" ) then
        self:Error([[The second argument of Gemini:GetPlayerInfo() must not be empty.]], ConvarName, "string")
    end

    local InfoValue = Player:GetInfo(ConvarName)
    return self:ConvertValue(InfoValue)
end

function Gemini:CreateConfig(Name, Category, Verification, Default, Private)
    if not isstring(Name) then
        self:Error([[The first argument of Gemini:CreateConfig() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:CreateConfig() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:CreateConfig() must be a string.]], Category, "string")
    end

    if ( Category == "" ) then
        self:Error([[The second argument of Gemini:CreateConfig() must not be empty.]], Category, "string")
    end

    if not isfunction(Verification) then
        self:Error([[The third argument of Gemini:CreateConfig() must be a function.]], Verification, "function")
    end

    if not Verification(Default) then
        self:Error([[The fourth argument of Gemini:CreateConfig() must be the same type as the return of the third argument.]], Default, "any")
    end

    local Flags = ( Private == true ) and FCVAR_PRIVATE or FCVAR_PUBLIC
    local Value = self:ToConvar(Name, Category, Default)
    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    GeminiCFG[Category] = GeminiCFG[Category] or {}
    GeminiCFG[Category][Name] = {CreateConVar("gemini_" .. Category .. "_" .. Name, Value, Flags), Verification}
end


function Gemini:GetConfig(Name, Category, SkipValidation)
    if ( SkipValidation == true ) then
        return self:FromConvar(Name, Category)
    end

    if not isstring(Name) then
        self:Error([[The first argument of Gemini:GetConfig() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:GetConfig() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:GetConfig() must be a string.]], Category, "string")
    end

    if ( Category == "" ) then
        self:Error([[The second argument of Gemini:GetConfig() must not be empty.]], Category, "string")
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    end

    if not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    return self:FromConvar(Name, Category)
end


function Gemini:SetConfig(Name, Category, Value)
    if not isstring(Name) then
        self:Error([[The first argument of Gemini:SetConfig() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:SetConfig() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:SetConfig() must be a string.]], Category, "string")
    end

    if ( Category == "" ) then
        self:Error([[The second argument of Gemini:SetConfig() must not be empty.]], Category, "string")
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    end

    if not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    if not GeminiCFG[Category][Name][2](Value) then
        -- self:Error([[The value doesn't match the verification function.]], Value, "any")
        self:Print("The value doesn't match the verification function. Skipping...")
        return
    end

    local ConvarValue = self:ToConvar(Name, Category, Value)
    GeminiCFG[Category][Name][1]:SetString( ConvarValue )

    hook.Run("Gemini:ConfigChanged", Name, Category, Value, ConvarValue)
end

function Gemini:ResetConfig(Name, Category, SkipValidation)
    if ( SkipValidation == true ) then
        GeminiCFG[Category][Name][1]:Revert()
        return
    end

    if not isstring(Name) then
        self:Error([[The first argument of Gemini:ResetConfig() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:ResetConfig() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:ResetConfig() must be a string.]], Category, "string")
    end

    if ( Category == "" ) then
        self:Error([[The second argument of Gemini:ResetConfig() must not be empty.]], Category, "string")
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not GeminiCFG[Category] then
        self:Error([[The category doesn't exist.]], Category, "string")
    end

    if not GeminiCFG[Category][Name] then
        self:Error([[The config doesn't exist.]], Name, "string")
    end

    GeminiCFG[Category][Name][1]:Revert()
end


function Gemini:PreInit()
    local Print = self:GeneratePrint({prefix = ""})

    Print("==[[==================================")
    Print("       Loading Gemini Automod...")
    Print("==================================]]==")

    self:Print("Generating Default Config " .. (SERVER and "[SV]" or "[CL]"))

    self.VERIFICATION_TYPE = VERIFICATION_TYPE

    if SERVER then
        self:CreateConfig("Enabled", "General", self.VERIFICATION_TYPE.bool, true, true)
        self:CreateConfig("Debug", "General", self.VERIFICATION_TYPE.bool, false)
    end

    self:CreateConfig("Language", "General", self.VERIFICATION_TYPE.string, "Spanish")

    if SERVER then
        AddCSLuaFile("gemini/sh_util.lua")      self:Print("File \"gemini/sh_util.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_language.lua")  self:Print("File \"gemini/sh_language.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_rules.lua")     self:Print("File \"gemini/sh_rules.lua\" has been send to client.")
        AddCSLuaFile("gemini/cl_gemini_panel.lua") self:Print("File \"gemini/cl_gemini_panel.lua\" has been send to client.")
        include("gemini/sh_util.lua")           self:Print("File \"gemini/sh_util.lua\" has been loaded.")
        include("gemini/sh_language.lua")       self:Print("File \"gemini/sh_language.lua\" has been loaded.")
        include("gemini/sv_sandbox.lua")        self:Print("File \"gemini/sv_sandbox.lua\" has been loaded.")
        include("gemini/sv_logger.lua")         self:Print("File \"gemini/sv_logger.lua\" has been loaded.")
        include("gemini/sv_gemini.lua")         self:Print("File \"gemini/sv_gemini.lua\" has been loaded.")
        include("gemini/sv_httpcode.lua")       self:Print("File \"gemini/sv_httpcode.lua\" has been loaded.")
        include("gemini/sv_gemini.lua")         self:Print("File \"gemini/sv_gemini.lua\" has been loaded.")
        include("gemini/sv_train.lua")          self:Print("File \"gemini/sv_train.lua\" has been loaded.")
        include("gemini/sv_playground.lua")     self:Print("File \"gemini/sv_playground.lua\" has been loaded.")
    else
        include("gemini/sh_util.lua")           self:Print("File \"gemini/sh_util.lua\" has been loaded.")
        include("gemini/sh_language.lua")       self:Print("File \"gemini/sh_language.lua\" has been loaded.")
    end

    include("gemini/sh_rules.lua")              self:Print("File \"gemini/sh_rules.lua\" has been loaded.")

    hook.Run("Gemini.PreInit")
    Gemini:Init()
end


function Gemini:Init()
    file.CreateDir("gemini")

    if isfunction(self.HookPoblate) then
        self:HookPoblate()
    else
        self:Error([[The function "PoblateHooks" has been replaced by another third-party addon!!!]], self.HookPoblate, "function")
    end

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

        -- AddCSLua file to all files inside "gemini/module"
        local LuaCSFiles, LuaSubFolder = file.Find("gemini/module/*.lua", "LUA")
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
        include("gemini/cl_gemini_panel.lua")      self:Print("File \"gemini/cl_gemini_panel.lua\" has been loaded.")
    end

    hook.Run("Gemini.Init")
    Gemini:PostInit()
end


function Gemini:PostInit()
    local Print = Gemini:GeneratePrint({prefix = ""})

    Print("==[[==================================")
    Print("         Gemini Automod Loaded")
    Print("==================================]]==")
    print("")

    hook.Run("Gemini.PostInit")
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
    elseif Gemini:CanUse("gemini_config") then
        net.Start("Gemini:ReplicateConfig")
        net.SendToServer()
    else
        Gemini:Print("You are not a superadmin.")
    end
end)


--[[------------------------
       Credits Command
------------------------]]--

concommand.Add("gemini_credits", function()
    Gemini:Print("==== Gemini Automod ====")
    Gemini:Print("Version:   ", Gemini.Version)
    Gemini:Print("Author:    ", Gemini.Author)
    Gemini:Print("(DEV) URL: ", Gemini.URL)
    Gemini:Print("==== Gemini Automod ====")
end)