--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Util Module
----------------------------------------------------------------------------]]--

Gemini.Util = Gemini.Util or {}

if SERVER then
    util.AddNetworkString("Gemini:SendMessage")
    util.AddNetworkString("Gemini:BroadcastMessage")
    util.AddNetworkString("Gemini:PlayerFullyConnected")
end

--[[------------------------
          Variables
------------------------]]--

-- Old (2 ^ 16) - 1024 = 63KB
Gemini.Util.MaxBandwidth = (2 ^ 13) -- 8KB
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

function Gemini:LogsToText(Logs)
    if not istable(Logs) then
        self:Error("The first argument of Gemini:LogsToText() must be a table.", Logs, "table")
    elseif table.IsEmpty(Logs) then
        self:Error("The table is empty", Logs, "table")
    end

    local _, FirstValue = next(Logs)
    if istable(FirstValue) then
        local Text = ""
        for i, LogData in ipairs(Logs) do
            Text = Text .. LogData["log"] .. "\n"
        end
        return Text
    else
        return table.concat(Logs, "\n")
    end
end

--[[------------------------
     Player Fully Joined
------------------------]]--

if SERVER then
    net.Receive("Gemini:PlayerFullyConnected", function(_, ply)
        hook.Run("Gemini:PlayerFullyConnected", ply)
    end)
else
    hook.Add("InitPostEntity", "Gemini:PlayerFullyConnected", function()
        net.Start("Gemini:PlayerFullyConnected")
        net.SendToServer()
    end)
end

--[[------------------------
       Send Message
------------------------]]--

if SERVER then
    function Gemini:SendMessage(ply, msg, index, extra)
        if not IsValid(ply) then
            self:Error("The first argument of Gemini:SendMessage() must be a player.", ply, "player")
        end

        self:Checker({msg, "string", 2})

        net.Start("Gemini:SendMessage")
            net.WriteString(msg)
            net.WriteString(index or "")
            net.WriteString(extra or "")
        net.Send(ply)
    end

    function Gemini:BroadcastMessage(msg, index, extra)
        self:Checker({msg, "string", 1})
        self:Checker({index, "string", 2})

        net.Start("Gemini:BroadcastMessage")
            net.WriteString(msg)
            net.WriteString(index)
            net.WriteString(extra or "")
        net.Broadcast()
    end
else
    net.Receive("Gemini:SendMessage", function()
        hook.Run("Gemini:SendMessage", net.ReadString(), net.ReadString())
    end)

    net.Receive("Gemini:BroadcastMessage", function()
        hook.Run("Gemini:BroadcastMessage", net.ReadString(), net.ReadString(), net.ReadString())
    end)
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

    self:Checker({permission, "string", 2})

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
        MinAccess = "superadmin"
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