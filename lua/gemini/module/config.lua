--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/cog.png" }

local GCLOUD_ICON = "materials/gemini/gcloud.png"
local CONFIG_ICON = "icon16/cog.png"

local HoverColor = Color( 0, 0, 0, 200)
local NoHoverColor = Color( 41, 41, 41, 200)
local BackgroundColor = Color( 41, 41, 41, 200)
local OutlineColor = Color( 80, 80, 80, 200)

local OutlineWidth = 3

local ButtonPaint = function(self, w, h)
    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverColor )
    else
        draw.RoundedBox( 0, 0, 0, w, h, NoHoverColor )
    end
end

function BackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, OutlineWidth, OutlineWidth, w - (OutlineWidth * 2), h - (OutlineWidth * 2), BackgroundColor )
end

--[[------------------------
       Main Functions
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_config") then return false end

    self.Items = {}

    --[[------------------------
            Configuration
    ------------------------]]--

    self.ConfigPanel = vgui.Create( "DColumnSheet", OurTab )
    self.ConfigPanel.Navigation:SetWide( 160 )
    self.ConfigPanel:Dock( FILL )
    self.ConfigPanel:DockMargin( 10, 10, 10, 10 )

    --[[------------------------
               Gemini
    ------------------------]]--

    self.ConfigPanel.Gemini = vgui.Create( "DPanel", self.ConfigPanel )
    self.ConfigPanel.Gemini:Dock( FILL )
    self.ConfigPanel.Gemini.Paint = BackgroundPaint

    self.Items["Gemini"] = self.ConfigPanel:AddSheet("Gemini", self.ConfigPanel.Gemini, CONFIG_ICON)

    --[[------------------------
            Google Cloud
    ------------------------]]--

    self.ConfigPanel.GoogleCloud = vgui.Create( "DPanel", self.ConfigPanel )
    self.ConfigPanel.GoogleCloud:Dock( FILL )
    self.ConfigPanel.GoogleCloud.Paint = BackgroundPaint

    self.Items["GoogleCloud"] = self.ConfigPanel:AddSheet( "Google Cloud", self.ConfigPanel.GoogleCloud, GCLOUD_ICON )

    --[[------------------------
                Style
    ------------------------]]--

    for _, v in pairs( self.Items ) do
        v.Button.Paint = ButtonPaint
        v.Button:SetSkin("Gemini:DermaSkin")
    end
end


Gemini:ModuleCreate(Gemini:GetPhrase("Config"), MODULE)