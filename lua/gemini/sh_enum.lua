--[[----------------------------------------------------------------------------
                    Google Gemini Automod - Hooks Enumeration
----------------------------------------------------------------------------]]--

Gemini.HOOK_ENUM = {}


function Gemini:AddHook( HookName, HookFunction )
    if not isstring( HookName ) then
        self:Error( "The first argument of Gemini:AddHook() must be a string", HookName, "string" )
    elseif ( HookName == "" ) then
        self:Error( "The first argument of Gemini:AddHook() must not be an empty string", HookName, "string" )
    elseif isfunction( Gemini.HOOK_ENUM[HookName] ) then
        self:Error( "The hook name '" .. HookName .. "' is already in use", HookName, "string" )
    end

    if not isfunction( HookFunction ) then
        self:Error( "The second argument of Gemini:AddHook() must be a function", HookFunction, "function" )
    end

    Gemini.HOOK_ENUM[HookName] = HookFunction
end

function Gemini:RemoveHook( HookName )
    if not isstring( HookName ) then
        self:Error( "The first argument of Gemini:RemoveHook() must be a string", HookName, "string" )
    elseif ( HookName == "" ) then
        self:Error( "The first argument of Gemini:RemoveHook() must not be an empty string", HookName, "string" )
    elseif not isfunction( Gemini.HOOK_ENUM[HookName] ) then
        self:Error( "The hook name '" .. HookName .. "' does not exist", HookName, "string" )
    end

    Gemini.HOOK_ENUM[HookName] = nil
end

function Gemini:PoblateHooks()
    for HookName, HookFunc in pairs( Gemini.HOOK_ENUM ) do
        hook.Add( HookName, "Gemini:" .. HookName, HookFunc )
        self:Print( "Hook \"" .. HookName .. "\" has been added")
    end
end