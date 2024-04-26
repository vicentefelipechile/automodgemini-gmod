--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/cog.png" }

local GCLOUD_ICON = "materials/gemini/gcloud.png"

local HoverColor = Color( 0, 0, 0, 196)
local NoHoverColor = Color( 41, 41, 41, 206)

local ButtonPaint = function(self, w, h)
    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverColor )
    else
        draw.RoundedBox( 0, 0, 0, w, h, NoHoverColor )
    end
end

--[[------------------------
       Main Functions
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_credits") then return false end

    self.ConfigPanel = vgui.Create( "DColumnSheet", OurTab )
    self.ConfigPanel.Navigation:SetWide( 160 )
    self.ConfigPanel:Dock( FILL )
    self.ConfigPanel:DockMargin( 10, 10, 10, 10 )

    self.ConfigPanel.GoogleCloud = vgui.Create( "DPanel", self.ConfigPanel )
    self.ConfigPanel.GoogleCloud:Dock( FILL )
    self.ConfigPanel:AddSheet( "Google Cloud", self.ConfigPanel.GoogleCloud, GCLOUD_ICON ).Button.Paint = ButtonPaint

    PrintTable(self.ConfigPanel.Items)
end


Gemini:ModuleCreate(Gemini:GetPhrase("Config"), MODULE)