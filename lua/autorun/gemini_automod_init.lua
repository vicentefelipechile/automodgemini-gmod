include("enum_color.lua")

--[[----------------------------------------------------------------------------
                              Google Gemini Automod
----------------------------------------------------------------------------]]--

if Gemini and ( Gemini.Version == nil ) then
    print("Error: Something else is using the Gemini name.")

    return
end

local isstring = isstring

Gemini = Gemini or {
    __cfg = {["general"] = {}},
    Version = "1.0",
    Author = "vicentefelipechile",
    URL = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s"
}

--[[------------------------
       Main Functions
------------------------]]--

if SERVER then
    util.AddNetworkString("Gemini:ReplicateConfig")
    util.AddNetworkString("Gemini:SetConfig")
end

local FCVAR_PRIVATE = bit.bor(FCVAR_ARCHIVE, FCVAR_PROTECTED)
local FCVAR_PUBLIC = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)


local print = print
local EmptyFunc = function() end

local isfunction = isfunction
local isentity = isentity
local isnumber = isnumber
local isangle = isangle
local istable = istable
local IsColor = IsColor
local isbool = isbool

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

function Gemini:Error(Message, Value, Expected)
    local Data = debug.getinfo(3)

    local FilePath = ( Data["source"] == "@lua_run" ) and "Console" or "lua/" .. string.match(Data["source"], "lua/(.*)")
    local File = ( FilePath == "Console" ) and "Console" or file.Read(FilePath, "GAME")
    local Line = string.Trim( string.Explode("\n", File)[Data["currentline"]] )

    local ErrorLine = "\t\t" .. Data["currentline"]
    local ErrorPath = "\t" .. FilePath
    local ErrorFunc = ""
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

function Gemini:FromConvar(Name, Category)
    -- Extraer las variables de un convar
    if not isstring(Name) then
        self:Error([[The first argument of Gemini:FromConvar() must be a string.]], Name, "string")
    elseif ( Name == "" ) then
        self:Error([[The first argument of Gemini:FromConvar() must not be empty.]], Name, "string")
    end

    if ( Category == nil ) then
        Category = string.lower( self.__cfg["general"]["defaultcategory"][1]:GetString() )
    else
        if not isstring(Category) then
            self:Error([[The second argument of Gemini:FromConvar() must be a string.]], Category, "string")
        elseif ( Category == "" ) then
            self:Error([[The second argument of Gemini:FromConvar() must not be empty.]], Category, "string")
        end
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not self.__cfg[Category] then
        self:Error([[The category does not exist.]], Category, "string")
    elseif not self.__cfg[Category][Name] then
        if CLIENT then
            self:Error([[The config does not exist in the CLIENT-SIDE.]], Name, "string")
        end
        self:Error([[The config does not exist.]], Name, "string")
    end

    -- if the value is a PROTECTED convar, it will return the default value
    if ( CLIENT and self.__cfg[Category][Name][1]:GetFlags() == FCVAR_PRIVATE ) then
        return "PROTECTED_CONVAR"
    end

    local Value = self.__cfg[Category][Name][1]:GetString()

    if ( Value == "" ) then
        self:Error([[The convar value is empty.]], Value, "string")
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

function Gemini:ToConvar(Name, Value, Category)
    if not isstring(Name) then
        self:Error([[The first argument of Gemini:ToConvar() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:ToConvar() must not be empty.]], Name, "string")
    end

    if ( Category == nil ) then
        Category = string.lower( self.__cfg["general"]["defaultcategory"][1]:GetString() )
    else
        if not isstring(Category) then
            self:Error([[The second argument of Gemini:ToConvar() must be a string.]], Category, "string")
        end

        if ( Category == "" ) then
            self:Error([[The second argument of Gemini:ToConvar() must not be empty.]], Category, "string")
        end
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not self.__cfg[Category] then
        self.__cfg[Category] = {}
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


function Gemini:AddConfig(Name, Category, Verification, Default, Private)
    if CLIENT then return end

    if not isstring(Name) then
        self:Error([[The first argument of Gemini:AddConfig() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:AddConfig() must not be empty.]], Name, "string")
    end

    if not isstring(Category) then
        self:Error([[The second argument of Gemini:AddConfig() must be a string.]], Category, "string")
    end

    if ( Category == "" ) then
        self:Error([[The second argument of Gemini:AddConfig() must not be empty.]], Category, "string")
    end

    if not isfunction(Verification) then
        self:Error([[The third argument of Gemini:AddConfig() must be a function.]], Verification, "function")
    end

    if not Verification(Default) then
        self:Error([[The fourth argument of Gemini:AddConfig() must be the same type as the return of the third argument.]], Default, "any")
    end

    -- Eliminar todos los espacios y caracteres especiales
    local Flags = ( Private == true ) and FCVAR_PRIVATE or FCVAR_PUBLIC
    local Value = self:ToConvar(Name, Default, Category)
    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    self.__cfg[Category] = self.__cfg[Category] or {}
    self.__cfg[Category][Name] = {CreateConVar("gemini_" .. Category .. "_" .. Name, Value, Flags), Verification}
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

    if ( Category == nil ) then
        Category = string.lower( self.__cfg["general"]["defaultcategory"][1]:GetString() )
    else
        if not isstring(Category) then
            self:Error([[The second argument of Gemini:GetConfig() must be a string.]], Category, "string")
        end

        if ( Category == "" ) then
            self:Error([[The second argument of Gemini:GetConfig() must not be empty.]], Category, "string")
        end
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not self.__cfg[Category] then
        self:Error([[The category does not exist.]], Category, "string")
    end

    if not self.__cfg[Category][Name] then
        self:Error([[The config does not exist.]], Name, "string")
    end

    return self:FromConvar(Name, Category)
end


function Gemini:SetConfig(Name, Value, Category)
    if ( CLIENT and not LocalPlayer():IsSuperAdmin() ) then return end

    if CLIENT then
        net.Start("Gemini:SetConfig")
            net.WriteString(Name)
            net.WriteType(Value)
            net.WriteString(Category)
        net.SendToServer()

        return
    end

    if not isstring(Name) then
        self:Error([[The first argument of Gemini:SetConfig() must be a string.]], Name, "string")
    end

    if ( Name == "" ) then
        self:Error([[The first argument of Gemini:SetConfig() must not be empty.]], Name, "string")
    end

    if ( Category == nil ) then
        Category = string.lower( self.__cfg["general"]["defaultcategory"][1]:GetString() )
    else
        if not isstring(Category) then
            self:Error([[The second argument of Gemini:SetConfig() must be a string.]], Category, "string")
        end

        if ( Category == "" ) then
            self:Error([[The second argument of Gemini:SetConfig() must not be empty.]], Category, "string")
        end
    end

    Category = string.lower( string.gsub(Category, "%W", "") )
    Name = string.lower( string.gsub(Name, "%W", "") )

    if not self.__cfg[Category] then
        self:Error([[The category does not exist.]], Category, "string")
    end

    if not self.__cfg[Category][Name] then
        self:Error([[The config does not exist.]], Name, "string")
    end

    if not self.__cfg[Category][Name][2](Value) then
        self:Error([[The value does not match the verification function.]], Value, "any")
    end

    local ConvarValue = self:ToConvar(Name, Value, Category)
    self.__cfg[Category][Name][1]:SetString( ConvarValue )

    hook.Run("Gemini:ConfigChanged", Name, Value, Category, ConvarValue)
end


function Gemini:PreInit()
    local Print = self:GeneratePrint({prefix = ""})

    Print("==[[==================================")
    Print("       Loading Gemini Automod...")
    Print("==================================]]==")

    self:Print("Generating Default Config " .. (SERVER and "[CL]" or "[SV]"))

    self.VERIFICATION_TYPE = {
        ["function"] = isfunction,
        ["entity"] = isentity,
        ["string"] = isstring,
        ["number"] = isnumber,
        ["Angle"] = isangle,
        ["table"] = istable,
        ["color"] = IsColor,
        ["bool"] = isbool
    }

    self:AddConfig("DefaultCategory", "General", self.VERIFICATION_TYPE.string, "General")
    self:AddConfig("DefaultAPI", "General", self.VERIFICATION_TYPE.string, "Gemini")
    self:AddConfig("Language", "General", self.VERIFICATION_TYPE.string, "Spanish")
    self:AddConfig("Enabled", "General", self.VERIFICATION_TYPE.bool, true)
    self:AddConfig("Debug", "General", self.VERIFICATION_TYPE.bool, false)

    if SERVER then
        AddCSLuaFile("gemini/sh_util.lua")      self:Print("File \"gemini/sh_util.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_enum.lua")      self:Print("File \"gemini/sh_enum.lua\" has been send to client.")
        AddCSLuaFile("gemini/sh_language.lua")  self:Print("File \"gemini/sh_language.lua\" has been send to client.")
        include("gemini/sh_util.lua")           self:Print("File \"gemini/sh_util.lua\" has been loaded.")
        include("gemini/sh_enum.lua")           self:Print("File \"gemini/sh_enum.lua\" has been loaded.")
        include("gemini/sv_sandbox.lua")        self:Print("File \"gemini/sv_sandbox.lua\" has been loaded.")
        include("gemini/sv_logger.lua")         self:Print("File \"gemini/sv_logger.lua\" has been loaded.")
        include("gemini/sv_gemini.lua")         self:Print("File \"gemini/sv_gemini.lua\" has been loaded.")
        include("gemini/sv_httpcode.lua")       self:Print("File \"gemini/sv_httpcode.lua\" has been loaded.")
        include("gemini/sv_gemini.lua")         self:Print("File \"gemini/sv_gemini.lua\" has been loaded.")
    else
        include("gemini/sh_util.lua")           self:Print("File \"gemini/sh_util.lua\" has been loaded.")
        include("gemini/sh_enum.lua")           self:Print("File \"gemini/sh_enum.lua\" has been loaded.")
        include("gemini/sh_language.lua")       self:Print("File \"gemini/sh_language.lua\" has been loaded.")
        include("gemini/sh_sandbox.lua")        self:Print("File \"gemini/sh_sandbox.lua\" has been loaded.")
    end

    hook.Run("Gemini.PreInit")
    hook.Add("PreGamemodeLoaded", "Gemini.PreInit_TO_Init", function()
        Gemini:Init()
    end)
end


function Gemini:Init()
    file.CreateDir("gemini")

    if self.HookPoblate then
        self:HookPoblate()
    else
        self:Error([[The function "PoblateHooks" has been replaced by another third-party addon!!!]], "HookPoblate", "function")
    end

    if self.LanguagePoblate then
        self:LanguagePoblate()
    else
        self:Error([[The function "PoblateLanguages" has been replaced by another third-party addon!!!]], "LanguagePoblate", "function")
    end

    if SERVER then
        if self.LoggerCheckTable then
            self:LoggerCheckTable()
        else
            self:Error([[The function "LoggerCheckTable" has been replaced by another third-party addon!!!]], "LoggerCheckTable", "function")
        end

        if self.GeminiPoblate then
            self:GeminiPoblate()
        else
            self:Error([[The function "GeminiPoblate" has been replaced by another third-party addon!!!]], "GeminiPoblate", "function")
        end

        if self.TrainPoblate then
            self:TrainPoblate()
        else
            self:Error([[The function "TrainPoblate" has been replaced by another third-party addon!!!]], "TrainPoblate", "function")
        end
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
        if not ply:IsSuperAdmin() then return end

        Gemini:Print("Reloading Gemini Automod...")
        Gemini:PreInit()
    end)

    net.Receive("Gemini:SetConfig", function(len, ply)
        if not ply:IsSuperAdmin() then return end

        local Name = net.ReadString()
        local Value = net.ReadType()
        local Category = net.ReadString()

        Gemini:SetConfig(Name, Value, Category)
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
    elseif ply:IsSuperAdmin() then
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