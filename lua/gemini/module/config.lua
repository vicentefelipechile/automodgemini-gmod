--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Configuration Menu
----------------------------------------------------------------------------]]--

local ModelPrefix = "models/gem"
local CurrentModel = CurrentModel or {}

local MODULE = { ["Icon"] = "icon16/cog.png" }

local GENERATION_ICON = "icon16/page_white_gear.png"
local GEMINI_ICON = "gemini/gemini_icon.png"
local CONFIG_ICON = "icon16/cog.png"

local function FN(n)
    return string.Comma(n, ".")
end

local DefaultModelTbl = {
    ["displayName"] = Gemini:GetPhrase("Config.Default.DisplayName"),
    ["description"] = Gemini:GetPhrase("Config.Default.Description"),
    ["inputTokenLimit"] = -1,
    ["outputTokenLimit"] = -1
}

local HTMLCONFIG = include("config/gemini_spread.html.lua")

--[[------------------------
      Generation Config
------------------------]]--

local GENERATION_CONFIG = {
    { ["Name"] = "Temperature", ["Decimals"] = 2, ["Min"] = 0, ["Max"] = 1 },
    { ["Name"] = "TopK", ["Decimals"] = 0, ["Min"] = 1, ["Max"] = 100 },
    { ["Name"] = "TopP", ["Decimals"] = 2, ["Min"] = 0, ["Max"] = 1 }
}

--[[------------------------
       Paint Functions
------------------------]]--

local BackgroundColor = Color( 45, 45, 45 )
local OutlineColor = Color( 80, 80, 80, 200 )
local OutlineColorOpaque = Color( 80, 80, 80 )
local HoverLineColor = Color( 1, 129, 123)

local OutlineWidth = 3

local function BackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, OutlineWidth, OutlineWidth, w - (OutlineWidth * 2), h - (OutlineWidth * 2), BackgroundColor )
end

local function SmallBackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, 1, 1, w - 2, h - 2, BackgroundColor )
end

local function SubDComboBoxPaint( SubSubSelf, w, h )
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColorOpaque )
end

local function DComboBoxPaint( SubSelf, SubPanel )
    SubPanel.Paint = SubDComboBoxPaint
end

local ScrollbarPaint = function(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )

    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverLineColor )
    end
end

--[[------------------------
       Safety Settings
------------------------]]--

local SAFETY_ENUM = {
    [1] = {["Name"] = BLOCK_NONE, ["Icon"] = "icon16/page.png"},
    [2] = {["Name"] = BLOCK_ONLY_HIGH, ["Icon"] = "icon16/page_key.png"},
    [3] = {["Name"] = BLOCK_MEDIUM_AND_ABOVE, ["Icon"] = "icon16/page_link.png"},
    [4] = {["Name"] = BLOCK_LOW_AND_ABOVE, ["Icon"] = "icon16/page_find.png"}
}

local SaffetySetting = {
    "Harrassment",
    "HateSpeech",
    "SexuallyExplicit",
    "DangerousContent"
}

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
               General
    ------------------------]]--

    self.ConfigPanel.General = vgui.Create( "DScrollPanel", self.ConfigPanel )
    self.ConfigPanel.General:Dock( FILL )
    self.ConfigPanel.General:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.General.Paint = BackgroundPaint

    self.ConfigPanel.General.LanguageTitle = vgui.Create( "DLabel", self.ConfigPanel.General )
    self.ConfigPanel.General.LanguageTitle:Dock( TOP )
    self.ConfigPanel.General.LanguageTitle:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.General.LanguageTitle:SetHeight( 40 )
    self.ConfigPanel.General.LanguageTitle:SetText( Gemini:GetPhrase("Config.Language") )
    self.ConfigPanel.General.LanguageTitle:SetFont("Frutiger:Big")

    self.ConfigPanel.General.Language = vgui.Create( "DComboBox", self.ConfigPanel.General )
    self.ConfigPanel.General.Language:Dock( TOP )
    self.ConfigPanel.General.Language:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.General.Language.Paint = SmallBackgroundPaint
    self.ConfigPanel.General.Language.OnMenuOpened = DComboBoxPaint

    for _, Language in ipairs( Gemini:GetLanguages() ) do
        self.ConfigPanel.General.Language:AddChoice( Language["Name"], Language["Code"] )
    end

    self.ConfigPanel.General.Language:SetValue( Gemini:GetConfig("Language", "General", true) )

    self.Items["General"] = self.ConfigPanel:AddSheet("General", self.ConfigPanel.General, CONFIG_ICON)

    --[[------------------------
               Gemini
    ------------------------]]--

    self.ConfigPanel.Gemini = vgui.Create( "DScrollPanel", self.ConfigPanel )
    self.ConfigPanel.Gemini:Dock( FILL )
    self.ConfigPanel.Gemini:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Gemini.Paint = BackgroundPaint

    self.ConfigPanel.Gemini.VBar.Paint = Gemini.Util.ReturnNoneFunction
    self.ConfigPanel.Gemini.VBar.btnGrip.Paint = ScrollbarPaint
    self.ConfigPanel.Gemini.VBar:SetHideButtons( true )

    self.ConfigPanel.Gemini.APIKeyTitle = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKeyTitle:Dock( TOP )
    self.ConfigPanel.Gemini.APIKeyTitle:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.Gemini.APIKeyTitle:SetHeight( 40 )
    self.ConfigPanel.Gemini.APIKeyTitle:SetText( Gemini:GetPhrase("Config.APIKey") )
    self.ConfigPanel.Gemini.APIKeyTitle:SetFont("Frutiger:Big")

    self.ConfigPanel.Gemini.APIKey = vgui.Create( "DTextEntry", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKey:Dock( TOP )
    self.ConfigPanel.Gemini.APIKey:DockMargin( 10, 10, 10, 10 )

    local APIKeyIsSetted = GetGlobal2Bool("Gemini:APIKeyEnabled", true)
    if APIKeyIsSetted then
        self.ConfigPanel.Gemini.APIKey:SetEnabled( false )
        self.ConfigPanel.Gemini.APIKey:SetText( Gemini:GetPhrase("Config.APIKey.Disabled") )
    end

    self.ConfigPanel.Gemini.APIKeyEnabled = vgui.Create( "DCheckBoxLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKeyEnabled:Dock( TOP )
    self.ConfigPanel.Gemini.APIKeyEnabled:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.APIKeyEnabled:SetText( Gemini:GetPhrase("Config.APIKey.Checkbox") )

    self.ConfigPanel.Gemini.APIKeyEnabled:SetValue( not APIKeyIsSetted )

    local OldText = self.ConfigPanel.Gemini.APIKey:GetText()
    self.ConfigPanel.Gemini.APIKeyEnabled.OnChange = function( SubSelf, bVal )
        self.ConfigPanel.Gemini.APIKey:SetEnabled( bVal )
        self.ConfigPanel.Gemini.ApiKeyButton:SetEnabled( bVal )

        if ( bVal == true ) then
            self.ConfigPanel.Gemini.APIKey:SetText("")
        else
            self.ConfigPanel.Gemini.APIKey:SetText(OldText)
        end
    end

    self.ConfigPanel.Gemini.APIKeyExplanation = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.APIKeyExplanation:Dock( TOP )
    self.ConfigPanel.Gemini.APIKeyExplanation:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.APIKeyExplanation:SetText( Gemini:GetPhrase("Config.APIKey.Note") )

    self.ConfigPanel.Gemini.ApiKeyButton = vgui.Create( "DButton", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ApiKeyButton:Dock( TOP )
    self.ConfigPanel.Gemini.ApiKeyButton:DockMargin( 10, 0, 10, 10 )
    self.ConfigPanel.Gemini.ApiKeyButton:SetWide( 100 )
    self.ConfigPanel.Gemini.ApiKeyButton:SetText( Gemini:GetPhrase("Config.Apply") )
    self.ConfigPanel.Gemini.ApiKeyButton:SetEnabled( not APIKeyIsSetted )

    self.ConfigPanel.Gemini.ApiKeyButton.DoClick = function( SubSelf )
        if not Gemini:CanUse("gemini_config_set") then return end

        local APIKEY = self.ConfigPanel.Gemini.APIKey:GetText()
        net.Start("Gemini:SetAPIKey")
            net.WriteString( APIKEY )
        net.SendToServer()
    end


    local HorizonalLine = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    HorizonalLine:Dock( TOP )
    HorizonalLine:DockMargin( 10, 8, 10, 8 )
    HorizonalLine:SetTall( 2 )
    HorizonalLine.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end

    self.ConfigPanel.Gemini.SafetySettingsTitle = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.SafetySettingsTitle:Dock( TOP )
    self.ConfigPanel.Gemini.SafetySettingsTitle:DockMargin( 10, 0, 10, 0 )
    self.ConfigPanel.Gemini.SafetySettingsTitle:SetText( Gemini:GetPhrase("Config.SafetySetting") )
    self.ConfigPanel.Gemini.SafetySettingsTitle:SetFont("Frutiger:Big")
    self.ConfigPanel.Gemini.SafetySettingsTitle:SetHeight( 40 )

    self.ConfigPanel.Gemini.SafetySettings = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.SafetySettings:Dock( TOP )
    self.ConfigPanel.Gemini.SafetySettings:DockMargin( 10, 4, 10, 10 )
    self.ConfigPanel.Gemini.SafetySettings:SetTall( 270 )
    self.ConfigPanel.Gemini.SafetySettings.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end

    for _, Category in ipairs(SaffetySetting) do
        self.ConfigPanel.Gemini.SafetySettings[Category] = vgui.Create("DPanel", self.ConfigPanel.Gemini.SafetySettings)
        self.ConfigPanel.Gemini.SafetySettings[Category]:Dock( TOP )
        self.ConfigPanel.Gemini.SafetySettings[Category]:DockMargin( 5, 10, 10, 5 )
        self.ConfigPanel.Gemini.SafetySettings[Category]:SetTall( 48 )
        self.ConfigPanel.Gemini.SafetySettings[Category].Paint = Gemini.Util.ReturnNoneFunction

        self.ConfigPanel.Gemini.SafetySettings[Category].Title = vgui.Create( "DLabel", self.ConfigPanel.Gemini.SafetySettings[Category] )
        self.ConfigPanel.Gemini.SafetySettings[Category].Title:Dock( TOP )
        self.ConfigPanel.Gemini.SafetySettings[Category].Title:DockMargin( 5, 0, 5, 0 )
        self.ConfigPanel.Gemini.SafetySettings[Category].Title:SetText( Gemini:GetPhrase("Config.SafetySetting." .. Category) )
        self.ConfigPanel.Gemini.SafetySettings[Category].Title:SetFont("HudHintTextLarge")
        self.ConfigPanel.Gemini.SafetySettings[Category].Title:SetWide( 160 )

        self.ConfigPanel.Gemini.SafetySettings[Category].Option = vgui.Create( "DComboBox", self.ConfigPanel.Gemini.SafetySettings[Category] )
        self.ConfigPanel.Gemini.SafetySettings[Category].Option:Dock( FILL )
        self.ConfigPanel.Gemini.SafetySettings[Category].Option:DockMargin( 5, 0, 5, 0 )
        self.ConfigPanel.Gemini.SafetySettings[Category].Option.Paint = SmallBackgroundPaint
        self.ConfigPanel.Gemini.SafetySettings[Category].Option.OnMenuOpened = DComboBoxPaint

        for Key, Safety in ipairs( SAFETY_ENUM ) do
            self.ConfigPanel.Gemini.SafetySettings[Category].Option:AddChoice( Gemini:GetPhrase("SafetySetting." .. Safety["Name"]), Key, false, Safety["Icon"] )
        end

        self.ConfigPanel.Gemini.SafetySettings[Category].Option:SetSortItems( false )
        self.ConfigPanel.Gemini.SafetySettings[Category].Option:ChooseOptionID( GetGlobal2Int("Gemini:Safety" .. Category, 1) )
    end


    local AnotherHorizonalLine = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    AnotherHorizonalLine:Dock( TOP )
    AnotherHorizonalLine:DockMargin( 10, 8, 10, 8 )
    AnotherHorizonalLine:SetTall( 2 )
    AnotherHorizonalLine.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end


    -- Model Name
    self.ConfigPanel.Gemini.ModelNameTitle = vgui.Create( "DLabel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelNameTitle:Dock( TOP )
    self.ConfigPanel.Gemini.ModelNameTitle:DockMargin( 10, 0, 0, 0 )
    self.ConfigPanel.Gemini.ModelNameTitle:SetText( Gemini:GetPhrase("Config.AIModel") )
    self.ConfigPanel.Gemini.ModelNameTitle:SetFont("Frutiger:Big")
    self.ConfigPanel.Gemini.ModelNameTitle:SetHeight( 40 )


    -- Info Model
    self.ConfigPanel.Gemini.ModelInfo = vgui.Create( "DPanel", self.ConfigPanel.Gemini )
    self.ConfigPanel.Gemini.ModelInfo:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo:DockMargin( 10, 4, 10, 10 )
    self.ConfigPanel.Gemini.ModelInfo:SetTall( 240 )
    self.ConfigPanel.Gemini.ModelInfo.Paint = function( SubSelf, w, h )
        draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    end

    self.ConfigPanel.Gemini.ModelInfo.ModelName = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:SetText( Gemini:GetPhrase("Config.AIModel.Name") )
    self.ConfigPanel.Gemini.ModelInfo.ModelName:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetText( "> ..." )
    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetText( Gemini:GetPhrase("Config.AIModel.InputTokens") )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokens:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetText( "> ... (... words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetText( Gemini:GetPhrase("Config.AIModel.OutputTokens") )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokens:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:DockMargin( 10, 5, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetText( "> ... (... words)" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetFont("HudHintTextLarge")

    self.ConfigPanel.Gemini.ModelInfo.ModelDescription = vgui.Create( "DLabel", self.ConfigPanel.Gemini.ModelInfo )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:Dock( TOP )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:DockMargin( 10, 10, 10, 0 )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescription:SetText( Gemini:GetPhrase("Config.AIModel.Description") )
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

    self.ConfigPanel.Gemini.ModelName.Paint = SmallBackgroundPaint
    self.ConfigPanel.Gemini.ModelName.OnMenuOpened = DComboBoxPaint

    local CurrentModelSelected = "models/" .. GetGlobal2String("Gemini:ModelName", "nil")
    local CurrentModelExists = false
    -- local OnDebugMode = not ( Gemini:CanUse("gemini_config_set") and Gemini:IsDebug() )
    local OnDebugMode = false

    local function AllowModel(name)
        if OnDebugMode then
            return true
        else
            return string.StartWith( name, ModelPrefix )
        end
    end

    for _, ModelTbl in ipairs( Gemini:GeminiGetModels() ) do
        if not AllowModel( ModelTbl["name"] ) then continue end

        local IsADebugOnlyModel = not string.StartWith( ModelTbl["name"], ModelPrefix )
        self.ConfigPanel.Gemini.ModelName:AddChoice( ModelTbl["displayName"] .. ( IsADebugOnlyModel and " (Debug)" or "" ), ModelTbl )

        if ( ModelTbl["name"] == CurrentModelSelected ) then
            CurrentModelExists = true
            CurrentModel = ModelTbl
        end
    end

    if not CurrentModelExists then
        CurrentModel = DefaultModelTbl
        self.ConfigPanel.Gemini.ModelName:SetValue( CurrentModel["displayName"] )
    else
        self.ConfigPanel.Gemini.ModelName:SetValue( CurrentModel["displayName"] )
    end

    self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetText( "> " .. CurrentModel["displayName"] )
    self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetText( CurrentModel["description"] )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetText( "> " .. FN( CurrentModel["inputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["inputTokenLimit"] ) * 0.75 ) ) .. " " .. Gemini:GetPhrase("Config.AIModel.Words") .. ")" )
    self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetText( "> " .. FN( CurrentModel["outputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["outputTokenLimit"] ) * 0.75 ) ) .. " " .. Gemini:GetPhrase("Config.AIModel.Words") .. ")" )

    self.ConfigPanel.Gemini.ModelName.OnSelect = function( SubSelf, index, value, data )
        CurrentModel = data

        self.ConfigPanel.Gemini.ModelInfo.ModelNameOutput:SetText( "> " .. CurrentModel["displayName"] )
        self.ConfigPanel.Gemini.ModelInfo.ModelDescriptionOutput:SetText( CurrentModel["description"] )
        self.ConfigPanel.Gemini.ModelInfo.ModelMaxInputTokensOutput:SetText( "> " .. FN( CurrentModel["inputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["inputTokenLimit"] ) * 0.75 ) ) .. " " .. Gemini:GetPhrase("Config.AIModel.Words") .. ")" )
        self.ConfigPanel.Gemini.ModelInfo.ModelMaxOutputTokensOutput:SetText( "> " .. FN( CurrentModel["outputTokenLimit"] ) .. " (" .. ( FN( math.floor( CurrentModel["outputTokenLimit"] ) * 0.75 ) ) .. " " .. Gemini:GetPhrase("Config.AIModel.Words") .. ")" )

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

    self.Items["Gemini"] = self.ConfigPanel:AddSheet("Gemini", self.ConfigPanel.Gemini, GEMINI_ICON)

    --[[------------------------
            Google Cloud
    ------------------------]+]--

    self.ConfigPanel.GoogleCloud = vgui.Create( "DPanel", self.ConfigPanel )
    self.ConfigPanel.GoogleCloud:Dock( FILL )
    self.ConfigPanel.GoogleCloud:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.GoogleCloud.Paint = BackgroundPaint

    -- self.Items["GoogleCloud"] = self.ConfigPanel:AddSheet( "Google Cloud", self.ConfigPanel.GoogleCloud, GCLOUD_ICON )

    --[[------------------------
          Generation Config
    ------------------------]]--

    self.ConfigPanel.Generation = vgui.Create( "DPanel", self.ConfigPanel )
    self.ConfigPanel.Generation:Dock( FILL )
    self.ConfigPanel.Generation:DockMargin( 10, 10, 10, 10 )
    self.ConfigPanel.Generation.Paint = BackgroundPaint

    self.ConfigPanel.Generation.Preview = vgui.Create( "DHTML", self.ConfigPanel.Generation )
    self.ConfigPanel.Generation.Preview:Dock( RIGHT )
    self.ConfigPanel.Generation.Preview:DockMargin( 0, OutlineWidth, OutlineWidth, OutlineWidth )
    self.ConfigPanel.Generation.Preview:SetWide( 240 )
    self.ConfigPanel.Generation.Preview:SetHTML( HTMLCONFIG )
    self.ConfigPanel.Generation.Preview:Call("SetResolution(250," .. self.ConfigPanel.Generation.Preview:GetTall() .. ")")
    self.ConfigPanel.Generation.Preview:Call("SetTemperature(" .. GetGlobal2Float("Gemini:Temperature", 0.5) .. ")")
    self.ConfigPanel.Generation.Preview:Call("SetTopK(" .. GetGlobal2Int("Gemini:TopK", 30) .. ")")
    self.ConfigPanel.Generation.Preview:Call("SetTopP(" .. GetGlobal2Float("Gemini:TopP", 0.5) .. ")")

    self.ConfigPanel.Generation.Options = vgui.Create( "DScrollPanel", self.ConfigPanel.Generation )
    self.ConfigPanel.Generation.Options:Dock( FILL )
    self.ConfigPanel.Generation.Options:DockMargin( 0, 0, 0, 0 )
    self.ConfigPanel.Generation.Options.Paint = BackgroundPaint

    self.ConfigPanel.Generation.Options.Header = vgui.Create( "DPanel", self.ConfigPanel.Generation.Options )
    self.ConfigPanel.Generation.Options.Header:Dock( TOP )
    self.ConfigPanel.Generation.Options.Header:DockMargin( 10, 10, 10, 20 )
    self.ConfigPanel.Generation.Options.Header:SetHeight( 40 )
    self.ConfigPanel.Generation.Options.Header.Paint = Gemini.Util.ReturnNoneFunction

    self.ConfigPanel.Generation.Options.Header.Title = vgui.Create( "DLabel", self.ConfigPanel.Generation.Options.Header )
    self.ConfigPanel.Generation.Options.Header.Title:Dock( FILL )
    self.ConfigPanel.Generation.Options.Header.Title:DockMargin( 10, 0, 0, 0 )
    self.ConfigPanel.Generation.Options.Header.Title:SetText( Gemini:GetPhrase("Config.Generation") )
    self.ConfigPanel.Generation.Options.Header.Title:SetFont("Frutiger:Big")

    self.ConfigPanel.Generation.Options.Header.ApplyButton = vgui.Create( "DButton", self.ConfigPanel.Generation.Options.Header )
    self.ConfigPanel.Generation.Options.Header.ApplyButton:Dock( RIGHT )
    self.ConfigPanel.Generation.Options.Header.ApplyButton:DockMargin( 0, 0, 10, 0 )
    self.ConfigPanel.Generation.Options.Header.ApplyButton:SetText( Gemini:GetPhrase("Rules.ToolBar.Save") )
    self.ConfigPanel.Generation.Options.Header.ApplyButton:SetWide( 100 )

    self.ConfigPanel.Generation.Options.Header.ApplyButton.DoClick = function( SubSelf )
        local NewGeneration = {}
        for _, GenerationTbl in ipairs(GENERATION_CONFIG) do
            NewGeneration[GenerationTbl["Name"]] = self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:GetValue()

            if ( GenerationTbl["Decimals"] == 0 ) then
                NewGeneration[GenerationTbl["Name"]] = math.Round( NewGeneration[GenerationTbl["Name"]] )
            else
                NewGeneration[GenerationTbl["Name"]] = math.Round( NewGeneration[GenerationTbl["Name"]], GenerationTbl["Decimals"] )
            end

            NewGeneration[GenerationTbl["Name"]] = math.Clamp( NewGeneration[GenerationTbl["Name"]], GenerationTbl["Min"], GenerationTbl["Max"] )
        end

        if Gemini:CanUse("gemini_config_set") then
            net.Start("Gemini:SetGeminiGeneration")
                net.WriteTable( NewGeneration )
            net.SendToServer()
        end
    end

    for index, GenerationTbl in ipairs(GENERATION_CONFIG) do
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Title"] = vgui.Create( "DLabel", self.ConfigPanel.Generation.Options )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Title"]:Dock( TOP )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Title"]:DockMargin( 10, 10, 10, 0 )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Title"]:SetText( Gemini:GetPhrase("Config.Generation." .. GenerationTbl["Name"]) )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Title"]:SetFont("HudHintTextLarge")

        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]] = vgui.Create( "DNumSlider", self.ConfigPanel.Generation.Options )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:Dock( TOP )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:DockMargin( 10, 10, 10, 10 )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:SetText( Gemini:GetPhrase("Config.Generation." .. GenerationTbl["Name"]) )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:SetMin( GenerationTbl["Min"] )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:SetMax( GenerationTbl["Max"] )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:SetDecimals( GenerationTbl["Decimals"] )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]]:SetValue( GetGlobal2Float("Gemini:" .. GenerationTbl["Name"], 0.5) )

        self.ConfigPanel.Generation.Options[GenerationTbl["Name"]].OnValueChanged = function( SubSelf, fVal )
            self.ConfigPanel.Generation.Preview:Call("Set" .. GenerationTbl["Name"] .. "(" .. fVal .. ")")
        end

        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "High"] = vgui.Create( "DLabel", self.ConfigPanel.Generation.Options )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "High"]:Dock( TOP )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "High"]:DockMargin( 10, 0, 10, 12 )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "High"]:SetText( Gemini:GetPhrase("Config.Generation." .. GenerationTbl["Name"] .. ".High") )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "High"]:SetWrap(true)
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "High"]:SetAutoStretchVertical(true)

        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Low"] = vgui.Create( "DLabel", self.ConfigPanel.Generation.Options )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Low"]:Dock( TOP )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Low"]:DockMargin( 10, 0, 10, 24 )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Low"]:SetText( Gemini:GetPhrase("Config.Generation." .. GenerationTbl["Name"] .. ".Low") )
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Low"]:SetWrap(true)
        self.ConfigPanel.Generation.Options[GenerationTbl["Name"] .. "Low"]:SetAutoStretchVertical(true)

        if ( index ~= #GENERATION_CONFIG ) then
            local BHorizonalLine = vgui.Create( "DPanel", self.ConfigPanel.Generation.Options )
            BHorizonalLine:Dock( TOP )
            BHorizonalLine:DockMargin( 10, 8, 10, 8 )
            BHorizonalLine:SetTall( 2 )
            BHorizonalLine.Paint = function( SubSelf, w, h )
                draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
            end
        end
    end

    -- Empty space
    self.ConfigPanel.Generation.Options.EmptyContent = vgui.Create( "DPanel", self.ConfigPanel.Generation.Options )
    self.ConfigPanel.Generation.Options.EmptyContent:SetTall( 70 )
    self.ConfigPanel.Generation.Options.EmptyContent:Dock( TOP )
    self.ConfigPanel.Generation.Options.EmptyContent.Paint = Gemini.Util.ReturnNoneFunction

    -- Scrollbar paint
    self.ConfigPanel.Generation.Options.VBar.Paint = Gemini.Util.ReturnNoneFunction
    self.ConfigPanel.Generation.Options.VBar.btnGrip.Paint = ScrollbarPaint
    self.ConfigPanel.Generation.Options.VBar:SetHideButtons( true )

    self.Items["Generation"] = self.ConfigPanel:AddSheet( Gemini:GetPhrase("Config.Generation"), self.ConfigPanel.Generation, GENERATION_ICON )

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

net.Receive("Gemini:SetAPIKey", function()
    if IsValid(MODULE.ConfigPanel) then
        MODULE.ConfigPanel.Gemini.APIKey:SetEnabled( false )
        MODULE.ConfigPanel.Gemini.APIKey:SetText( Gemini:GetPhrase("Config.APIKey.Disabled") )
    end
end)