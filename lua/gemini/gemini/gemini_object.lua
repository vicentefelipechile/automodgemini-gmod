--[[----------------------------------------------------------------------------
                         Gemini Automod - Gemini Object
----------------------------------------------------------------------------]]--

-- localize global functions
local util_IsBinaryModuleInstalled = util.IsBinaryModuleInstalled -- Yes, this order is made on purpose
local table_IsSequential = table.IsSequential
local util_TableToJSON = util.TableToJSON
local util_JSONToTable = util.JSONToTable
local string_Replace = string.Replace
local concommand_Add = concommand.Add
local table_IsEmpty = table.IsEmpty
local table_insert = table.insert
local string_lower = string.lower
local table_Copy = table.Copy
local isstring = isstring
local hook_Add = hook.Add
local istable = istable
local require = require
local Promise = Promise
local ipairs = ipairs

--[[------------------------
       Local Variables
------------------------]]--

local CachedModels = {} -- After the game loads, we will add the models
local AllowedModels = {}

local AllowedMimeType = {
    ["image/png"] = true,
    ["image/jpeg"] = true,
    ["image/webp"] = true,
    ["image/heic"] = true,
    ["image/heif"] = true,
}

local AllowedRoles = {
    ["user"] = true,
    ["model"] = true,
}

local AllowedHTTPMethods = {
    ["GET"] = true,
    ["POST"] = true,
}

local AllowedSafetySettings = {
    -- Most used
    [HARM_CATEGORY_SEXUALLY_EXPLICIT] = true,
    [HARM_CATEGORY_DANGEROUS_CONTENT] = true,
    [HARM_CATEGORY_HARASSMENT] = true,
    [HARM_CATEGORY_HATE_SPEECH] = true,

    -- Lest used
    [HARM_CATEGORY_UNSPECIFIED] = true,
    [HARM_CATEGORY_DEROGATORY] = true,
    [HARM_CATEGORY_TOXICITY] = true,
    [HARM_CATEGORY_VIOLENCE] = true,
    [HARM_CATEGORY_SEXUAL] = true,
    [HARM_CATEGORY_MEDICAL] = true,
    [HARM_CATEGORY_DANGEROUS] = true
}

local AllowedLevels = {
    [BLOCK_NONE] = true,
    [BLOCK_LOW_AND_ABOVE] = true,
    [BLOCK_MEDIUM_AND_ABOVE] = true,
    [BLOCK_ONLY_HIGH] = true,
    [HARM_BLOCK_THRESHOLD_UNSPECIFIED] = true
}

--[[------------------------
    Third-Party Libraries
------------------------]]--

local HTTP = HTTP
do
    if util_IsBinaryModuleInstalled("reqwest") then
        HTTP = require("reqwest")
    elseif util_IsBinaryModuleInstalled("chttp") then
        HTTP = require("chttp")
    end
end

--[[------------------------
        Gemini Object
------------------------]]--

local GEMINI_OOP = {
    __requestbody = {
        ["contents"] = {},
        ["safetySettings"] = table_Copy(DefaultSafetySettings),
        ["generationConfig"] = {}
    },
    __resturl = "https://generativelanguage.googleapis.com/$REST_VER$/$METHOD$",
    __restver = "v1beta",
    __method = "models/$MODEL_VERSION$",
    __params = {},
    __httpmethod = "POST",
    __silent = false,
}

--[[------------------------
    Gemini Object Methods
------------------------]]--

function GEMINI_OOP:AddContent(Part, Role)
    if not istable(Part) then
        Gemini:Error("The first argument of GEMINI_OOP:AddContent must be a table.", Part, "table")
    elseif table_IsEmpty(Part) then
        Gemini:Error("The first argument of GEMINI_OOP:AddContent must not be empty.", Part, "table")
    elseif not table_IsSequential(Part) then
        Gemini:Error("The first argument of GEMINI_OOP:AddContent must be an array.", Part, "table[Array]")
    end

    for index, SubPart in ipairs(Part) do -- This maybe can be expensive
        if not isstring(SubPart["text"]) then
            Gemini:Error("There is not valid string in " .. index .. " of the first argument of GEMINI_OOP:AddContent.", SubPart, "table[text]")
        end

        if ( SubPart["inlineData"] ~= nil ) then -- There is a blob data
            if not isstring(SubPart["inlineData"]["mimeType"]) then
                Gemini:Error("The mimeType of the inlineData in " .. index .. " of the first argument of GEMINI_OOP:AddContent must be a string.", SubPart, "table[inlineData][mimeType]")
            elseif not AllowedMimeType[SubPart["inlineData"]["mimeType"]] then
                Gemini:Error("The mimeType of the inlineData in " .. index .. " of the first argument of GEMINI_OOP:AddContent is not allowed.", SubPart, "table[inlineData][mimeType]")
            end

            if not isstring(SubPart["inlineData"]["data"]) then
                Gemini:Error("The data of the inlineData in " .. index .. " of the first argument of GEMINI_OOP:AddContent must be a string.", SubPart, "table[inlineData][data]")
            elseif ( #SubPart["inlineData"]["data"] == 0 ) then
                Gemini:Error("The data of the inlineData in " .. index .. " of the first argument of GEMINI_OOP:AddContent must not be empty.", SubPart, "table[inlineData][data]")
            end
        end
    end

    if Role ~= nil then
        if not isstring(Role) then
            Gemini:Error("The second argument of GEMINI_OOP:AddContent must be a string.", Role, "user/model")
        elseif AllowedRoles[Role] == nil then
            Gemini:Error("The second argument of GEMINI_OOP:AddContent is not a valid role.", Role, "user/model")
        end

        table_insert(self.__requestbody["contents"], {
            ["parts"] = Part,
            ["role"] = Role
        })
    else
        table_insert(self.__requestbody["contents"], {
            ["parts"] = Part
        })
    end
end

function GEMINI_OOP:GetContents()
    return table_Copy(self.__requestbody["contents"])
end

function GEMINI_OOP:ClearContent()
    self.__requestbody["contents"] = {}
end

function GEMINI_OOP:ClearBody()
    self.__requestbody = {}
end

function GEMINI_OOP:GetBody()
    return table_Copy(self.__requestbody)
end

function GEMINI_OOP:SetSafetySettings(SafetySettings, Level)
    if not isstring(SafetySettings) then
        Gemini:Error("The first argument of GEMINI_OOP:SetSafetySettings must be a string.", SafetySettings, "Harm Category")
    elseif not AllowedSafetySettings[SafetySettings] then
        Gemini:Error("The first argument of GEMINI_OOP:SetSafetySettings is not a valid Harm Category.", SafetySettings, "Harm Category")
    end

    if Level ~= nil then
        if not isstring(Level) then
            Gemini:Error("The second argument of GEMINI_OOP:SetSafetySettings must be a string.", Level, "Block Level")
        elseif not AllowedLevels[Level] then
            Gemini:Error("The second argument of GEMINI_OOP:SetSafetySettings is not a valid Block Level.", Level, "Block Level")
        end

        self.__requestbody["safetySettings"][SafetySettings] = Level
    else
        self.__requestbody["safetySettings"][SafetySettings] = BLOCK_NONE
    end
end

function GEMINI_OOP:GetSafetySettings()
    return table_Copy(self.__requestbody["safetySettings"])
end

function GEMINI_OOP:SetVersion(Version)
    if not isstring(Version) then
        Gemini:Error("The first argument of GEMINI_OOP:SetVersion must be a string.", Version, "string")
    elseif ( #Version == 0 ) then
        Gemini:Error("The first argument of GEMINI_OOP:SetVersion must not be empty.", Version, "string")
    end

    self.__restver = Version
end

function GEMINI_OOP:GetVersion()
    return self.__restver
end

function GEMINI_OOP:SetMethod(Method)
    if not isstring(Method) then
        Gemini:Error("The first argument of GEMINI_OOP:SetMethod must be a string.", Method, "string")
    elseif ( #Method == 0 ) then
        Gemini:Error("The first argument of GEMINI_OOP:SetMethod must not be empty.", Method, "string")
    end

    self.__method = Method
end

function GEMINI_OOP:GetMethod()
    return self.__method
end

function GEMINI_OOP:AddParam(Param)
    if not istable(Param) then
        Gemini:Error("The first argument of GEMINI_OOP:AddParam must be a table.", Param, "table")
    elseif table_IsEmpty(Param) then
        Gemini:Error("The first argument of GEMINI_OOP:AddParam must not be empty.", Param, "table")
    end

    table_insert(self.__params, Param)
end

function GEMINI_OOP:GetParam()
    return self.__param
end

function GEMINI_OOP:SetHTTPMethod(Method)
    if not isstring(Method) then
        Gemini:Error("The first argument of GEMINI_OOP:SetHTTPMethod must be a string.", Method, "string")
    elseif ( #Method == 0 ) then
        Gemini:Error("The first argument of GEMINI_OOP:SetHTTPMethod must not be empty.", Method, "string")
    elseif AllowedHTTPMethods[Method] == nil then
        Gemini:Error("The first argument of GEMINI_OOP:SetHTTPMethod is not a valid HTTP method.", Method, "GET/POST")
    end

    self.__httpmethod = Method
end

function GEMINI_OOP:GetHTTPMethod()
    return self.__httpmethod
end

function GEMINI_OOP:Silent()
    self.__silent = true
end

function GEMINI_OOP:MakeRequest()
    local RequestBody = util_TableToJSON(self.__requestbody)
    local RequestURL = string_Replace(self.__resturl, "$REST_VER$", self.__restver)
    RequestURL = string_Replace(RequestURL, "$METHOD$", self.__method) .. "?"

    self:AddParam({
        ["key"] = "key",
        ["value"] = Gemini:GetConfig("APIKey", "Gemini")
    })

    for _, Param in ipairs(self.__params) do
        RequestURL = RequestURL .. Param["key"] .. "=" .. Param["value"] .. "&"
    end

    RequestURL = RequestURL:sub(1, -2)

    file.Write("gemini/debug/gemini_request.txt", util_TableToJSON(self.__requestbody, true))

    local promise = Promise()
    HTTP({
        ["url"] = RequestURL,
        ["method"] = self.__httpmethod,
        ["body"] = RequestBody,
        ["success"] = function(Code, Body, Headers)
            if not self.__silent then
                Gemini:GetHTTPDescription(Code)
            end

            file.Write("gemini/debug/gemini_response.txt", Body)
            local BodyTable = util_JSONToTable(Body)

            if not ( Code >= 200 and Code < 300 ) then
                promise:Reject("There was an error with the request to the url")
            else
                promise:Resolve({["Code"] = Code, ["Body"] = BodyTable, ["Headers"] = Headers})
            end
        end,
        ["failed"] = function(Error)
            promise:Reject("The request to the url failed")
        end
    })

    return promise
end


--[[------------------------
       Retrieve Models
------------------------]]--

local function RetrieveModels()
    file.CreateDir("gemini/debug")

    local NewRequest = Gemini:NewRequest()
    NewRequest:ClearBody()
    NewRequest:SetMethod("models")
    NewRequest:SetHTTPMethod("GET")
    NewRequest:Silent()

    local NewPromise = NewRequest:MakeRequest()
    NewPromise:Then(function(DataInfo)
        Gemini:Print("Retreived " .. #DataInfo["Body"]["models"] .. " models.")
        CachedModels = DataInfo["Body"]["models"]

        for index, modeldata in ipairs(CachedModels) do
            AllowedModels[ modeldata["name"] ] = true
        end

        file.Write("gemini/gemini_models.json", util_TableToJSON(CachedModels, true))

    end):Catch(function(Error)
        Gemini:Print("Failed to retreive models. Error: " .. Error)
    end)
end

hook_Add("Gemini:HTTPLoaded", "Gemini:ObjectModels", RetrieveModels)

hook_Add("Gemini:ConfigChanged", "Gemini:UpdateModels", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string_lower(Name) ~= "apikey" ) then return end

    Gemini:ReloadModels()
end)

concommand_Add("gemini_reloadmodels", function(ply)
    if not Gemini:CanUse(ply, "gemini_automod") then return end

    RetrieveModels()
end)


--[[------------------------
       Global Methods
------------------------]]--

function Gemini:NewRequest()
    return table_Copy(GEMINI_OOP)
end

function Gemini:GetModels()
    return table_Copy(AllowedModels)
end

function Gemini:ReloadModels()
    RetrieveModels()
end