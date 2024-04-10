--[[----------------------------------------------------------------------------
                       Google Gemini Automod - ULX Module
----------------------------------------------------------------------------]]--

-- https://ulyssesmod.net/docs/files/lua/ulib/server/ucl-lua.html#ucl.registerAccess
if SERVER then
    ULib.ucl.registerAccess("gemini_credits",       ULib.DEFAULT_ACCESS, "Allows access to the Gemini Credits menu.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_playground",    ULib.ACCESS_ADMIN, "Allows access to the Gemini Playground menu.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_logger",        ULib.ACCESS_ADMIN, "Allows access to the Gemini Logger menu.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_train",         ULib.ACCESS_ADMIN, "Allows access to the Gemini Train menu.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_automod",       ULib.ACCESS_SUPERADMIN, "Allows access to the Gemini Automod menu.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_config",        ULib.DEFAULT_ACCESS, "Allows to change the Gemini configuration.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_config_set",    ULib.ACCESS_SUPERADMIN, "Allows to change the Gemini server configuration.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_rules",         ULib.ACCESS_ADMIN, "Allows to change the Gemini server rules.", Gemini.Name)
    ULib.ucl.registerAccess("gemini_rules_set",     ULib.ACCESS_SUPERADMIN, "Allows to change the Gemini server rules.", Gemini.Name)
end