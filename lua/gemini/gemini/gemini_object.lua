--[[----------------------------------------------------------------------------
                         Gemini Automod - Gemini Object
----------------------------------------------------------------------------]]-- BG

include("response.lua")

-- localize global functions
local util_IsBinaryModuleInstalled = util.IsBinaryModuleInstalled -- Yes, this order was made on purpose
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

local CachedModels = CachedModels or {} -- After the game loads, we will add the models

--[[------------------------
      Allowed Constants
------------------------]]--

local AllowedModels = AllowedModels or {}

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
    [GEMINI_ENUM.HARM_CATEGORY_SEXUALLY_EXPLICIT] = true,
    [GEMINI_ENUM.HARM_CATEGORY_DANGEROUS_CONTENT] = true,
    [GEMINI_ENUM.HARM_CATEGORY_HARASSMENT] = true,
    [GEMINI_ENUM.HARM_CATEGORY_HATE_SPEECH] = true,

    -- Lest used
    [GEMINI_ENUM.HARM_CATEGORY_UNSPECIFIED] = true,
    [GEMINI_ENUM.HARM_CATEGORY_DEROGATORY] = true,
    [GEMINI_ENUM.HARM_CATEGORY_TOXICITY] = true,
    [GEMINI_ENUM.HARM_CATEGORY_VIOLENCE] = true,
    [GEMINI_ENUM.HARM_CATEGORY_SEXUAL] = true,
    [GEMINI_ENUM.HARM_CATEGORY_MEDICAL] = true,
    [GEMINI_ENUM.HARM_CATEGORY_DANGEROUS] = true
}

local AllowedLevels = {
    [GEMINI_ENUM.BLOCK_NONE] = true,
    [GEMINI_ENUM.BLOCK_LOW_AND_ABOVE] = true,
    [GEMINI_ENUM.BLOCK_MEDIUM_AND_ABOVE] = true,
    [GEMINI_ENUM.BLOCK_ONLY_HIGH] = true,
    [GEMINI_ENUM.HARM_BLOCK_THRESHOLD_UNSPECIFIED] = true
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
        ["generationConfig"] = {},
        ["safetySettings"] = {},
        ["contents"] = {}
    },
    __resturl = "https://generativelanguage.googleapis.com/$REST_VER$/$METHOD$",
    __restver = "v1beta",
    __method = "models/$MODEL_VERSION$",
    __params = {},
    __httpmethod = "POST",
    __silent = false,
    __outputjson = false,
}

--[[------------------------
    Gemini Object Methods
------------------------]]--

function GEMINI_OOP:AddContent(Part, Role)
    if isstring(Part) then
        Part = { ["text"] = Part }
    end

    if not istable(Part) then
        Gemini:Error("The first argument of GEMINI_OOP:AddContent must be a table.", Part, "table")
    elseif table_IsEmpty(Part) then
        Gemini:Error("The first argument of GEMINI_OOP:AddContent must not be empty.", Part, "table")
    end

    if table_IsSequential(Part) then
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
    end

    local Content = {
        ["parts"] = Part
    }

    if Role ~= nil then
        if not isstring(Role) then
            Gemini:Error("The second argument of GEMINI_OOP:AddContent must be a string.", Role, "user/model")
        elseif AllowedRoles[Role] == nil then
            Gemini:Error("The second argument of GEMINI_OOP:AddContent is not a valid role.", Role, "user/model")
        end

        Content["role"] = Role
    end

    table_insert(self.__requestbody["contents"], Content)

    return Content
end

function GEMINI_OOP:GetContents()
    return self.__requestbody["contents"]
end

function GEMINI_OOP:ClearContent()
    self.__requestbody["contents"] = {}
end

function GEMINI_OOP:ClearBody()
    self.__requestbody = {}
end

function GEMINI_OOP:GetBody()
    return self.__requestbody
end

function GEMINI_OOP:SetBody(NewBody)
    if not istable(NewBody) then
        Gemini:Error("The first argument of GEMINI_OOP:SetBody must be a table.", NewBody, "table")
    elseif table_IsEmpty(NewBody) then
        Gemini:Error("The first argument of GEMINI_OOP:SetBody must not be empty.", NewBody, "table")
    end

    self.__requestbody = NewBody
end

function GEMINI_OOP:SetSafetySettings(SafetySettings, Level)
    if not isstring(SafetySettings) then
        Gemini:Error("The first argument of GEMINI_OOP:SetSafetySettings must be a string.", SafetySettings, "Harm Category")
    elseif not AllowedSafetySettings[SafetySettings] then
        Gemini:Error("The first argument of GEMINI_OOP:SetSafetySettings is not a valid Harm Category.", SafetySettings, "Harm Category")
    end

    if not isstring(Level) then
        Gemini:Error("The second argument of GEMINI_OOP:SetSafetySettings must be a string.", Level, "Block Level")
    elseif not AllowedLevels[Level] then
        Gemini:Error("The second argument of GEMINI_OOP:SetSafetySettings is not a valid Block Level.", Level, "Block Level")
    end

    self.__requestbody["safetySettings"][SafetySettings] = Level
end

function GEMINI_OOP:GetSafetySettings()
    return self.__requestbody["safetySettings"]
end

function GEMINI_OOP:ClearSafetySettings()
    self.__requestbody["safetySettings"] = {}
end

function GEMINI_OOP:SetGenerationConfig(Key, DaValue)
    self.__requestbody["generationConfig"][Key] = DaValue
end

function GEMINI_OOP:GetGenerationConfig()
    return istable(self.__requestbody["generationConfig"]) and self.__requestbody["generationConfig"] or nil
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

function GEMINI_OOP:ResponseWithJson()
    self.__outputjson = true
end

function GEMINI_OOP:MakeRequest()
    local RequestBody = util_TableToJSON(self.__requestbody)
    local RequestURL = string_Replace(self.__resturl, "$REST_VER$", self.__restver)
    RequestURL = string_Replace(RequestURL, "$METHOD$", self.__method) .. "?"

    local IsGeneratingContent = not not string.find(RequestURL, ":generateContent")

    --[[ Params ]]--
    self:AddParam({
        ["key"] = "key",
        ["value"] = Gemini:GetConfig("APIKey", "Gemini")
    })

    for _, Param in ipairs(self.__params) do
        RequestURL = RequestURL .. Param["key"] .. "=" .. Param["value"] .. "&"
    end

    --[[ URL Request ]]--
    RequestURL = RequestURL:sub(1, -2)

    file.Write("gemini/debug/gemini_request.json", util_TableToJSON(self.__requestbody, true))
    file.Write("gemini/debug/gemini_request_raw.json", util_TableToJSON(self, true))

    local promise = Promise()
    HTTP({
        ["url"] = RequestURL,
        ["method"] = self.__httpmethod,
        ["body"] = RequestBody,
        ["success"] = function(Code, Body, Headers)
            if not self.__silent or Gemini:IsDebug() then
                Gemini:GetHTTPDescription(Code)
            end

            file.Write("gemini/debug/gemini_response.json", Body)
            file.Write("gemini/debug/gemini_response_headers.json", util_TableToJSON(Headers, true))
            local BodyTable = util_JSONToTable(Body)

            if not ( Code >= 200 and Code < 300 ) then
                promise:Reject("There was an error with the request to the url")
            else
                if IsGeneratingContent then
                    promise:Resolve(Gemini:CreateResponseObject({
                        ["code"] = Code,
                        ["body"] = BodyTable,
                        ["headers"] = Headers
                    }))
                else
                    promise:Resolve({["Code"] = Code, ["Body"] = BodyTable, ["Headers"] = Headers})
                end
            end
        end,
        ["failed"] = function(Error)
            promise:Reject("The request to the url failed")
        end
    })

    return promise
end
GEMINI_OOP.SendRequest = GEMINI_OOP.MakeRequest


--[[------------------------
       Retrieve Models
------------------------]]--

local function RetrieveModels()
    file.CreateDir("gemini/debug")

    local LoadAllModels = Gemini:NewRequest()
    LoadAllModels:ClearBody()
    LoadAllModels:SetMethod("models")
    LoadAllModels:SetHTTPMethod("GET")
    LoadAllModels:SetVersion("v1")
    LoadAllModels:Silent()

    local AllModelsPromise = LoadAllModels:MakeRequest()
    AllModelsPromise:Then(function(DataInfo)
        Gemini:Print("Retreived " .. #DataInfo["Body"]["models"] .. " models.")
        CachedModels = DataInfo["Body"]["models"]

        for index, modeldata in ipairs(CachedModels) do
            AllowedModels[ modeldata["name"] ] = true
        end

        file.Write("gemini/gemini_models.json", util_TableToJSON(CachedModels, true))

        hook.Run("Gemini:ModelsReloaded", CachedModels)
    end):Catch(function(Error)
        Gemini:Print("Failed to retreive models. Error: " .. Error)

        if file.Exists("gemini/gemini_models.json", "DATA") then
            CachedModels = util_JSONToTable(file.Read("gemini/gemini_models.json", "DATA"))
            Gemini:Print("Loading chached models.")
        end

        hook.Run("Gemini:ModelsReloaded", CachedModels)
    end)
end

hook_Add("Gemini:HTTPLoaded", "Gemini:ObjectModels", RetrieveModels)

hook_Add("Gemini:ConfigChanged", "Gemini:UpdateModels", function(Name, Category, Value, ConvarValue)
    if ( Category ~= "Gemini" ) then return end
    if ( string_lower(Name) ~= "apikey" ) then return end

    RetrieveModels()
end)

concommand_Add("gemini_reloadmodels", function(ply)
    if not Gemini:CanUse(ply, "gemini_automod") then return end

    RetrieveModels()
end)


--[[------------------------
       Global Methods
------------------------]]--

function Gemini:NewRequest()
    local NewRequest = table_Copy(GEMINI_OOP)
    NewRequest.__requestbody["generationConfig"] = self:GeminiGetGeneration()
    NewRequest.__requestbody["safetySettings"] = self:GeminiGetSafety()
    NewRequest.__silent = not self:GetConfig("Debug", "General")

    return NewRequest
end

function Gemini:GetModels()
    return table_Copy(CachedModels)
end

function Gemini:ReloadModels()
    RetrieveModels()
end