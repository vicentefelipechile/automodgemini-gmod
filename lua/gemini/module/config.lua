--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local ModelPrefix = "models/gemini-1."
local CurrentModel = CurrentModel or {}

local MODULE = { ["Icon"] = "icon16/cog.png" }

local GCLOUD_ICON = "materials/gemini/gcloud.png"
local CONFIG_ICON = "icon16/cog.png"

local HoverColor = Color( 0, 0, 0, 200)
local NoHoverColor = Color( 41, 41, 41, 200)
local BackgroundColor = Color( 41, 41, 41, 200)
local OutlineColor = Color( 80, 80, 80, 200)

local OutlineWidth = 3

local function FN(n)
    return string.Comma(n, ".")
end

--[[------------------------
          Functions
------------------------]]--

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
    self.ConfigPanel.Gemini:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Gemini.Paint = BackgroundPaint

    self.ConfigPanel.Gemini.ModelNameTitle = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelNameTitle:Dock( TOP )
    self.ConfigPanel.Gemini.ModelNameTitle:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.Gemini.ModelNameTitle:SetText( "Model Name" )
    self.ConfigPanel.Gemini.ModelNameTitle:SetFont("Frutiger:Big")

    self.ConfigPanel.Gemini.ModelName = vgui.Create( "DComboBox", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelName:Dock( TOP )
    self.ConfigPanel.Gemini.ModelName:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Gemini.ModelName:SetSkin("Gemini:DermaSkin")
    self.ConfigPanel.Gemini.ModelName:SetValue( "models/" .. GetGlobal2String("Gemini:ModelName") )

    for _, ModelTbl in ipairs( Gemini:GeminiGetModels() ) do
        if not string.StartsWith( ModelTbl["name"], ModelPrefix ) then continue end

        self.ConfigPanel.Gemini.ModelName:AddChoice( ModelTbl["name"], ModelTbl )
    end

    -- Info model
    self.ConfigPanel.Gemini.ModelInfo = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelInfo:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.ModelInfo:SetTall( 110 )
    self.ConfigPanel.Gemini.ModelInfo.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end

    self.ConfigPanel.Gemini.ModelInfo.ModelName = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:SetText( "Model Name: " .. CurrentModel["displayName"] )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelDescription = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:SetText( "Description: " .. CurrentModel["description"] )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetText( "Max Input Tokens: " .. FN( CurrentModel["inputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["inputTokenLimit"] ) * 0.75 ) ) .. " words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetText( "Max Output Tokens: " .. FN( CurrentModel["outputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["outputTokenLimit"] ) * 0.75 ) ) .. " words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetFont("HudHintTextLarge")

    -- update
    self.ConfigPanel.Gemini.ModelName.OnSelect = function( SubSelf, index, value, data )
        CurrentModel = data

        self.ConfigPanel.Gemini.ModelInfo.ModelName:SetText( "Model Name: " .. CurrentModel["displayName"] )
        self.ConfigPanel.Gemini.ModelInfo.ModelDescription:SetText( "Description: " .. CurrentModel["description"] )
        self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetText( "Max Input Tokens: " .. FN( CurrentModel["inputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["inputTokenLimit"] ) * 0.75 ) ) .. " words)" )
        self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetText( "Max Output Tokens: " .. FN( CurrentModel["outputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["outputTokenLimit"] ) * 0.75 ) ) .. " words)" )
    end

    self.Items["Gemini"] = self.ConfigPanel:AddSheet("Gemini", self.ConfigPanel.Gemini, CONFIG_ICON)

    --[[------------------------
            Google Cloud
    ------------------------]]--

    self.ConfigPanel.GoogleCloud = vgui.Create( "DPanel", self.ConfigPanel )
    self.ConfigPanel.GoogleCloud:Dock( FILL )
    self.ConfigPanel.GoogleCloud:DockMargin( 10, 10, 10, 10 )
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

--[[------------------------
        Post Hook
------------------------]]--

hook.Add("Gemini:ModelsReceived", "Gemini:ConfigPostEntity", function(Models)
    local CurrentModelName = "models/" .. GetGlobal2String("Gemini:ModelName")

    for _, ModelTbl in ipairs( Models ) do
        print( ModelTbl["name"], CurrentModelName )
        if ( ModelTbl["name"] == CurrentModelName ) then
            CurrentModel = ModelTbl
            break
        end
    end
end)