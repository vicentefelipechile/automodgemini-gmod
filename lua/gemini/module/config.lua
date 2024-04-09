--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/cog.png" }

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_credits") then return false end

    local sheet = vgui.Create( "DColumnSheet", OurTab )
    sheet:Dock( FILL )
    sheet:DockMargin( 10, 10, 10, 10 )

    local panel1 = vgui.Create( "DPanel", sheet )
    panel1:Dock( FILL )
    sheet:AddSheet( "test", panel1, "icon16/cross.png" )

    local panel2 = vgui.Create( "DPanel", sheet )
    panel2:Dock( FILL )
    sheet:AddSheet( "test 2", panel2, "icon16/tick.png" )
end


Gemini:ModuleCreate(Gemini:GetPhrase("Config"), MODULE)