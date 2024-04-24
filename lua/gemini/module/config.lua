--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/cog.png" }

--[[------------------------
       Main Functions
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_credits") then return false end

    self.MainConfig = vgui.Create( "DColumnSheet", OurTab )
    self.MainConfig:Dock( FILL )
    self.MainConfig:DockMargin( 10, 10, 10, 10 )

    local GoogleCloud = vgui.Create( "DPanel", self.MainConfig )
    GoogleCloud:Dock( FILL )
    self.MainConfig:AddSheet( "Google Cloud", GoogleCloud, "icon16/cog.png" )
end


Gemini:ModuleCreate(Gemini:GetPhrase("Config"), MODULE)