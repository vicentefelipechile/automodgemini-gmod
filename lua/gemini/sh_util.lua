--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Util Module
----------------------------------------------------------------------------]]--

Gemini.Util = Gemini.Util or {}

--[[------------------------
            Variables
------------------------]]--

Gemini.Util.MaxBandwidth = (2 ^ 16) - 1024 -- 63KB
Gemini.Util.DefaultNetworkUInt = 16
Gemini.Util.DefaultNetworkUIntBig = 32

--[[------------------------
       Main Functions
------------------------]]--

function Gemini.Util.ReturnNoneFunction()
    return
end

function Gemini.Util.ReturnAnyFunction(...)
    return ...
end

function Gemini.Util.EmptyFunction()
    -- Nothing, TADA!
end

--[[------------------------
       Util Functions
------------------------]]--

function Gemini:VectorToString(vec)
    return string.format("(%s, %s, %s)", math.Round(vec.x, 0), math.Round(vec.y, 0), math.Round(vec.z, 0))
end

function Gemini:LogsToText(logs)
    local text = ""
    for i, log in ipairs(logs) do
        text = text .. log .. "\n"
    end
    return text
end

--[[------------------------
    Permission Functions
------------------------]]--

function Gemini:CanUse(ply, permission)
    permission = CLIENT and ply or permission
    ply = CLIENT and LocalPlayer() or ply

    if SERVER and not ( IsValid(ply) and ply:IsPlayer() ) then
        self:Error("The first argument of Gemini:CanUse() must be a valid player entity.", ply, "player")
    end

    if not isstring(permission) then
        self:Error("The second argument of Gemini:CanUse() must be a string.", permission, "string")
    elseif permission == "" then
        self:Error("The second argument of Gemini:CanUse() must not be an empty string.", permission, "string")
    end

    local CanUse = false

    if ( ULib ~= nil ) then
        CanUse = ULib.ucl.query(ply, permission) or CanUse
    elseif ( sam ~= nil ) then
        CanUse = sam.player.hasPermission(ply, permission)
    elseif ( CAMI ~= nil ) then
        if CAMI.ULX_TOKEN then
            -- Ulysses, you really screwed up
            CanUse = hook.Run("CAMI.PlayerHasAccess", ply, permission, Gemini.Util.ReturnAnyFunction)
        else
            CAMI.PlayerHasAccess(ply, permission, function(HasAccess, Reason)
                CanUse = HasAccess
            end)
        end
    else
        CanUse = ply:IsSuperAdmin()
    end

    return CanUse
end

-- https://github.com/glua/CAMI
if CAMI then
    CAMI.RegisterPrivilege({
        Name = "gemini_credits",
        MinAccess = "user"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_playground",
        MinAccess = "admin"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_logger",
        MinAccess = "admin"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_train",
        MinAccess = "superadmin"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_automod",
        MinAccess = "superadmin"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_config",
        MinAccess = "user"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_config_set",
        MinAccess = "superadmin"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_rules",
        MinAccess = "user"
    })

    CAMI.RegisterPrivilege({
        Name = "gemini_rules_set",
        MinAccess = "superadmin"
    })
end

-- Where is the documentation sam? where is it?
if sam and sam.permission and sam.permissions.add then
    sam.command.set_category("Gemini")
    sam.permissions.add("gemini_credits", "Gemini", "user")
    sam.permissions.add("gemini_playground", "Gemini", "admin")
    sam.permissions.add("gemini_logger", "Gemini", "admin")
    sam.permissions.add("gemini_train", "Gemini", "superadmin")
    sam.permissions.add("gemini_automod", "Gemini", "superadmin")
    sam.permissions.add("gemini_config", "Gemini", "superadmin")
    sam.permissions.add("gemini_config_set", "Gemini", "superadmin")
    sam.permissions.add("gemini_rules", "Gemini", "user")
    sam.permissions.add("gemini_rules_set", "Gemini", "superadmin")
end