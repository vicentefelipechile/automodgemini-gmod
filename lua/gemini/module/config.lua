--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/cog.png" }

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_credits") then return false end

    self.MainConfig = vgui.Create( "DColumnSheet", OurTab )
    self.MainConfig:Dock( FILL )
    self.MainConfig:DockMargin( 10, 10, 10, 10 )

    for MainCategory, Setting in pairs( Gemini:GetAllConfigs() ) do
        local NewCategory = vgui.Create( "DPanel", self.MainConfig )
        NewCategory:Dock( FILL )
        self.MainConfig:AddSheet( MainCategory, NewCategory, "icon16/tick.png" )
    end
end


Gemini:ModuleCreate(Gemini:GetPhrase("Config"), MODULE)