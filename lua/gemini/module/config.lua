--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local ModelPrefix = "models/gemini-1."
local CurrentModel = CurrentModel or {}

local MODULE = { ["Icon"] = "icon16/cog.png" }

local GCLOUD_ICON = "materials/gemini/gcloud.png"
local CONFIG_ICON = "icon16/cog.png"

local BackgroundColor = Color( 45, 45, 45 )
local OutlineColor = Color( 80, 80, 80, 200 )
local OutlineColorOpaque = Color( 80, 80, 80 )

local OutlineWidth = 3

local function FN(n)
    return string.Comma(n, ".")
end

local DefaultModelTbl = {
    ["displayName"] = "No Model Selected",
    ["description"] = "Currently the model is not selected or isn't available.",
    ["inputTokenLimit"] = -1,
    ["outputTokenLimit"] = -1
}

--[[------------------------
          Functions
------------------------]]--

local function BackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, OutlineWidth, OutlineWidth, w - (OutlineWidth * 2), h - (OutlineWidth * 2), BackgroundColor )
end

local function SmallBackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, 1, 1, w - 2, h - 2, BackgroundColor )
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
    self.ConfigPanel:Dock( FILL )
    self.ConfigPanel:DockMargin( 5, 5, 5, 5 )

    --[[------------------------
               Gemini
    ------------------------]]--

    self.ConfigPanel.Gemini = vgui.Create( "DScrollPanel", self.ConfigPanel )
    self.ConfigPanel.Gemini:Dock( FILL )
    self.ConfigPanel.Gemini:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Gemini.Paint = BackgroundPaint

    self.ConfigPanel.Gemini.APIKeyTitle = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKeyTitle:Dock( TOP )
    self.ConfigPanel.Gemini.APIKeyTitle:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.Gemini.APIKeyTitle:SetHeight( 40 )
    self.ConfigPanel.Gemini.APIKeyTitle:SetText( "API Key" )
    self.ConfigPanel.Gemini.APIKeyTitle:SetFont("Frutiger:Big")

    self.ConfigPanel.Gemini.APIKey = vgui.Create( "DTextEntry", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKey:Dock( TOP )
    self.ConfigPanel.Gemini.APIKey:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Gemini.APIKey:SetSkin("Gemini:DermaSkin")

    local APIKeyIsSetted = GetGlobal2Bool("Gemini:APIKeyEnabled", true)
    if APIKeyIsSetted then
        self.ConfigPanel.Gemini.APIKey:SetEnabled( false )
        self.ConfigPanel.Gemini.APIKey:SetText( "This field is disabled, because the API Key is already setted. To enable it, click on the checkbox below to allow edit." )
    end

    self.ConfigPanel.Gemini.APIKeyEnabled = vgui.Create( "DCheckBoxLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKeyEnabled:Dock( TOP )
    self.ConfigPanel.Gemini.APIKeyEnabled:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.APIKeyEnabled:SetSkin("Gemini:DermaSkin")
    self.ConfigPanel.Gemini.APIKeyEnabled:SetText( "Allow edit the API Key" )

    self.ConfigPanel.Gemini.APIKeyEnabled:SetValue( not APIKeyIsSetted )

    local OldText = self.ConfigPanel.Gemini.APIKey:GetText()
    self.ConfigPanel.Gemini.APIKeyEnabled.OnChange = function( SubSelf, bVal )
        self.ConfigPanel.Gemini.APIKey:SetEnabled( bVal )

        if ( bVal == true ) then
            self.ConfigPanel.Gemini.APIKey:SetText("")
        else
            self.ConfigPanel.Gemini.APIKey:SetText(OldText)
        end
    end

    self.ConfigPanel.Gemini.APIKeyExplanation = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKeyExplanation:Dock( TOP )
    self.ConfigPanel.Gemini.APIKeyExplanation:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.APIKeyExplanation:SetText( "For security reasons you can't see the API Key, only set it. If you want to see it, too bad." )


    -- Horizontal Line
    self.ConfigPanel.Gemini.HLine = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.HLine:Dock( TOP )
    self.ConfigPanel.Gemini.HLine:DockMargin( 10, 8, 10, 8 )
    self.ConfigPanel.Gemini.HLine:SetTall( 4 )
    self.ConfigPanel.Gemini.HLine.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end


    -- Model Name
    self.ConfigPanel.Gemini.ModelNameTitle = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelNameTitle:Dock( TOP )
    self.ConfigPanel.Gemini.ModelNameTitle:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.Gemini.ModelNameTitle:SetText( "Current AI Model" )
    self.ConfigPanel.Gemini.ModelNameTitle:SetFont("Frutiger:Big")


    -- Info Model
    self.ConfigPanel.Gemini.ModelInfo = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelInfo:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo:DockMargin( 10, 15, 10, 10 )
    self.ConfigPanel.Gemini.ModelInfo:SetTall( 240 )
    self.ConfigPanel.Gemini.ModelInfo.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end

    self.ConfigPanel.Gemini.ModelInfo.ModelName = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:SetText( "Model Name:" )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetText( "> ..." )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetText( "Max Input Tokens:" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetText( "> ... (... words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetText( "Max Output Tokens:" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetText( "> ... (... words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelDescription = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:SetText( "Description:" )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:DockMargin( 10, 5, 10, 0)
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetText( "..." )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetFont("HudHintTextLarge")
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetTall( 30 )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetWrap(true)

    self.ConfigPanel.Gemini.ModelName = vgui.Create( "DComboBox", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelName:Dock( TOP )
    self.ConfigPanel.Gemini.ModelName:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.ModelName:SetSkin("Gemini:DermaSkin")

    self.ConfigPanel.Gemini.ModelName.Paint = SmallBackgroundPaint

    self.ConfigPanel.Gemini.ModelName.OnMenuOpened = function( SubSelf, SubPanel )
        -- Change background color
        SubPanel.Paint = function( SubSubSelf, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, OutlineColorOpaque )
        end
    end

    local CurrentModelSelected = "models/" .. GetGlobal2String("Gemini:ModelName", "nil")
    local CurrentModelExists = false
    for _, ModelTbl in ipairs( Gemini:GeminiGetModels() ) do
        if not string.StartsWith( ModelTbl["name"], ModelPrefix ) then continue end

        self.ConfigPanel.Gemini.ModelName:AddChoice( ModelTbl["name"], ModelTbl )

        if ( ModelTbl["name"] == CurrentModelSelected ) then
            CurrentModelExists = true
            CurrentModel = ModelTbl
        end
    end

    if not CurrentModelExists then
        CurrentModel = DefaultModelTbl
        self.ConfigPanel.Gemini.ModelName:SetValue( CurrentModel["displayName"] )
    else
        self.ConfigPanel.Gemini.ModelName:SetValue( CurrentModel["name"] )
    end

    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetText( "> " .. CurrentModel["displayName"] )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetText( CurrentModel["description"] )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetText( "> " .. FN( CurrentModel["inputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["inputTokenLimit"] ) * 0.75 ) ) .. " words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetText( "> " .. FN( CurrentModel["outputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["outputTokenLimit"] ) * 0.75 ) ) .. " words)" )

    self.ConfigPanel.Gemini.ModelName.OnSelect = function( SubSelf, index, value, data )
        CurrentModel = data

        self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetText( "> " .. CurrentModel["displayName"] )
        self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetText( CurrentModel["description"] )
        self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetText( "> " .. FN( CurrentModel["inputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["inputTokenLimit"] ) * 0.75 ) ) .. " words)" )
        self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetText( "> " .. FN( CurrentModel["outputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["outputTokenLimit"] ) * 0.75 ) ) .. " words)" )

        if Gemini:CanUse("gemini_config_set") then
            local ModelName = string.Replace( CurrentModel["name"], "models/", "" )

            net.Start("Gemini:SetGeminiModel")
                net.WriteString( ModelName )
            net.SendToServer()
        end
    end

    -- Empty content
    self.ConfigPanel.Gemini.EmptyContent = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.EmptyContent:Dock( FILL )
    self.ConfigPanel.Gemini.EmptyContent:DockMargin( 0, 140, 0, 0 )
    self.ConfigPanel.Gemini.EmptyContent.Paint = Gemini.Util.ReturnNoneFunction

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


    self.ConfigPanel.Navigation:SetWide( 140 )
    self.ConfigPanel.Navigation:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Navigation.Paint = BackgroundPaint

    for PanelName, PanelButton in pairs( self.Items ) do
        PanelButton.Button:SetTall( 32 )
        PanelButton.Button:DockMargin( 5, 5, 5, 0 )
    end

    --[[
    for _, v in pairs( self.Items ) do
        v.Button.Paint = ButtonPaint
        v.Button:SetSkin("Gemini:DermaSkin")
    end
    --]]
end


Gemini:ModuleCreate(Gemini:GetPhrase("Config"), MODULE)

--[[------------------------
        Post Hook
------------------------]]--

hook.Add("Gemini:ModelsReceived", "Gemini:ConfigPostEntity", function(Models)
    local CurrentModelName = "models/" .. GetGlobal2String("Gemini:ModelName")

    for _, ModelTbl in ipairs( Models ) do
        if ( ModelTbl["name"] == CurrentModelName ) then
            CurrentModel = ModelTbl
            break
        end
    end
end)