--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Hooks Module
----------------------------------------------------------------------------]]--

Gemini.HOOK_ENUM = {}


function Gemini:HookAdd( HookName, HookFunction )
    if not isstring( HookName ) then
        self:Error( "The first argument of Gemini:HookAdd() must be a string", HookName, "string" )
    elseif ( HookName == "" ) then
        self:Error( "The first argument of Gemini:HookAdd() must not be an empty string", HookName, "string" )
    end

    if not isfunction( HookFunction ) then
        self:Error( "The second argument of Gemini:HookAdd() must be a function", HookFunction, "function" )
    end

    Gemini.HOOK_ENUM[HookName] = HookFunction
end

function Gemini:HookPoblate()
    for HookName, HookFunc in pairs( Gemini.HOOK_ENUM ) do
        hook.Add( HookName, "Gemini:" .. HookName, HookFunc )
        self:Print( "Hook \"" .. HookName .. "\" has been added")
    end
end