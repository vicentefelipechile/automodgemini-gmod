--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Rules Menu
----------------------------------------------------------------------------]]--

local ACE_CDN = "https://cdnjs.cloudflare.com/ajax/libs/ace/1.35.4/ace.min.js"

local BackgroundColor = Color( 39, 39, 39)
local BackgroundPaint = function(SubSelf, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, BackgroundColor )
end

local HorizontalLineColor = Color( 48, 48, 48)
local HorizontalLine = function(SubSelf, w, h)
    draw.RoundedBox( 0, 0, 0, w, 4, HorizontalLineColor )
end

local ForegroundColor = Color( 48, 48, 48)
local ForegroundPaint = function(SubSelf, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, ForegroundColor )
end

local MODULE = { ["Icon"] = "icon16/page_edit.png" }
local COMPILED_HTML = COMPILED_HTML or ""
local ReplaceAceEditor = [[ace.edit("editor").setValue("%s")]]

local function ReplaceCoincidences(Text, Replacements)
    for FromReplace, ToReplace in pairs(Replacements) do
        Text = string.Replace(Text, "$" .. FromReplace .. "$", ToReplace)
    end

    return Text
end

local AllowedFormatters = {
    ["ServerInfo"] = true,
}

local PromptFormatterColor = Color( 75, 75, 75)
local function PromptFormatterPaint(self, w, h)
    draw.RoundedBox( 8, 0, 0, w, h, PromptFormatterColor )
end

--[[------------------------
       Extra Functions
------------------------]]--

function MODULE:AceCore()
    if not file.Exists("gemini/ace.txt", "DATA") then
        http.Fetch(ACE_CDN, function(Body)
            file.Write("gemini/ace.txt", Body)
        end)
        return false
    end

    return true
end

-- https://github.com/WilliamVenner/SQLWorkbench/blob/master/lua/sqlworkbench/menu.lua#L421-L592
function MODULE:GetAceScript(File)
    return include("gemini/module/ace/" .. File .. ".lua")
end

function MODULE:ApplyFormat(Text, Formatter)
    if not Gemini:CanUse("gemini_rules_set") then return end
    local CompressedText = util.Compress(Text)
    local CompressedSize = #CompressedText

    if CompressedSize > Gemini.Util.MaxBandwidth then
        Gemini:Error("The text is too large to be sent", CompressedSize, Gemini.Util.MaxBandwidth)
    end

    net.Start("Gemini:Formatter")
        net.WriteString(Formatter)
        net.WriteUInt(CompressedSize, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(CompressedText, CompressedSize)
    net.SendToServer()
end

--[[------------------------
       HTML Functions
------------------------]]--

function MODULE:CompileHTML(InitialValue, ReadOnly, UseCache)
    InitialValue = InitialValue or "# Test Script"
    ReadOnly = tostring(ReadOnly)

    if UseCache and ( COMPILED_HTML ~= "" ) then
        return ReplaceCoincidences(COMPILED_HTML, {
            ["InitialValue"] = InitialValue,
            ["ReadOnly"] = ReadOnly
        })
    end

    local Embedding = self:GetAceScript("embedding")

    -- local Ace = self:GetAceScript("ace.js")
    local Ace = file.Read("gemini/ace.txt", "DATA")

    local Extension = self:GetAceScript("ext-language_tools.js")
    local Theme = self:GetAceScript("theme-monokai.js")
    local Mode = self:GetAceScript("mode-markdown.js")
    local Gmod = self:GetAceScript("gmod.js")

    COMPILED_HTML = ReplaceCoincidences(Embedding, {
        ["AceScript"] = Ace,
        ["Extension"] = Extension,
        ["Theme"] = Theme,
        ["Mode"] = Mode,
        ["GmodScript"] = Gmod
    })

    return ReplaceCoincidences(COMPILED_HTML, {
        ["InitialValue"] = InitialValue,
        ["ReadOnly"] = ReadOnly
    })
end

--[[------------------------
      Editor Functions
------------------------]]--

local OffsetX, OffsetY = 12, 42
function MODULE:CreatePromptFormatter(RootPanel)
    if IsValid( self.PromptFormatterMenu ) then
        self.PromptFormatterMenu:Remove()
    end

    self.PromptFormatterMenu = vgui.Create("DFrame", RootPanel)
    self.PromptFormatterMenu:SetSize( 300, 200 )
    self.PromptFormatterMenu:SetMinimumSize( 250, 150 )
    self.PromptFormatterMenu:Center()
    self.PromptFormatterMenu:SetScreenLock(true)
    self.PromptFormatterMenu:SetSizable(true)
    self.PromptFormatterMenu:SetTitle( Gemini:GetPhrase("Rules.ToolBar.Formatter") )
    self.PromptFormatterMenu.Paint = PromptFormatterPaint

    self.PromptFormatterMenu.Editor = vgui.Create("DHTML", self.PromptFormatterMenu)
    self.PromptFormatterMenu.Editor:Dock( FILL )
    self.PromptFormatterMenu.Editor:DockMargin( 4, 4, 4, 4 )
    self.PromptFormatterMenu.Editor:SetTall( 100 )
    self.PromptFormatterMenu.Editor:SetAllowLua(true)
    self.PromptFormatterMenu.Editor:SetHTML( self:CompileHTML(Gemini:GetPhrase("Rules.Formatter.Use"), false, true ) )
    self.PromptFormatterMenu.Editor:Call([[SetEditorOption("showGutter", false)]])
    self.PromptFormatterMenu.Editor:Call([[SetEditorOption("showPrintMargin", false)]])

    self.PromptFormatterMenu.ApplyButton = vgui.Create("DButton", self.PromptFormatterMenu)
    self.PromptFormatterMenu.ApplyButton:SetSize( 100, 30 )
    self.PromptFormatterMenu.ApplyButton:SetPos( OffsetX, 200 - OffsetY )
    self.PromptFormatterMenu.ApplyButton:SetText( Gemini:GetPhrase("Config.Apply") )
    self.PromptFormatterMenu.ApplyButton:SetZPos( 100 )

    self.PromptFormatterMenu.OnSizeChanged = function(SubSelf, w, h)
        self.PromptFormatterMenu.ApplyButton:SetPos( OffsetX, h - OffsetY )
    end
end

function MODULE:ClosePromptFormatter()
    if IsValid( self.PromptFormatterMenu ) then
        self.PromptFormatterMenu:Remove()
    end
end


--[[------------------------
       Main Functions
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_rules") then return false end
    if not self:AceCore() then return false end

    local CanEdit = Gemini:CanUse("gemini_rules_set")
    self:CompileHTML(nil, not CanEdit, true)

    --[[------------------------
           All the Panels
    ------------------------]]--

    self.MainSheet = vgui.Create( "DColumnSheet", OurTab )
    self.MainSheet.Navigation:SetWide( 110 )
    self.MainSheet:Dock( FILL )

    -- Black Foreground to make a transition when changing tabs
    self.MainSheet.Foreground = vgui.Create( "DPanel", self.MainSheet )
    self.MainSheet.Foreground:Dock( FILL )
    self.MainSheet.Foreground.Paint = ForegroundPaint
    self.MainSheet.Foreground:SetVisible( false )


    --[[------------------------
           Server Info
    ------------------------]]--

    self.ServerInfoPanel = vgui.Create( "DPanel", self.MainSheet )
    self.ServerInfoPanel:Dock( FILL )

    self.ServerInfoPanel.Panel = vgui.Create( "DPanel", self.ServerInfoPanel )
    self.ServerInfoPanel.Panel:Dock( FILL )

    self.ServerInfoPanel.Panel.TextEditor = vgui.Create( "DHTML", self.ServerInfoPanel.Panel )
    self.ServerInfoPanel.Panel.TextEditor:Dock( FILL )

    -- Main Functions
    self.ServerInfoPanel.Panel.TextEditor:AddFunction("gmod", "SuppressConsole", function()
        gui.HideGameUI()
    end)

    self.ServerInfoPanel.Panel.TextEditor:AddFunction("gmod", "SetClipboardText", function(text)
        SetClipboardText(text)
    end)

    self.ServerInfoPanel.Panel.TextEditor:AddFunction("gmod", "SaveServerInfoLua", function(text)
        Gemini:SetServerInfoClient(text)
    end)

    self.ServerInfoPanel.Panel.TextEditor:AddFunction("gmod", "InfoFullyLoaded", function()
        self.ServerInfoPanel.Panel.TextEditor.FullyLoaded = true

        if not CanEdit then return end

        self.ServerInfoPanel.ToolBar.SaveButton:SetEnabled( CanEdit )
    end)

    self.ServerInfoPanel.Panel.TextEditor:SetHTML( self:CompileHTML(Gemini:GetServerInfo(), not CanEdit, true) )
    self.ServerInfoPanel.Panel.TextEditor:Call([[SetEditorOption("showPrintMargin", false)]])

    if CanEdit then
        self.ServerInfoPanel.ToolBar = vgui.Create( "DPanel", self.ServerInfoPanel )
        self.ServerInfoPanel.ToolBar:Dock( LEFT )
        self.ServerInfoPanel.ToolBar:SetWide( 115 )
        self.ServerInfoPanel.ToolBar.Paint = BackgroundPaint

        self.ServerInfoPanel.ToolBar.SaveButton = vgui.Create( "DButton", self.ServerInfoPanel.ToolBar )
        self.ServerInfoPanel.ToolBar.SaveButton:Dock( TOP )
        self.ServerInfoPanel.ToolBar.SaveButton:DockMargin( 4, 4, 4, 4 )
        self.ServerInfoPanel.ToolBar.SaveButton:SetTall( 28 )
        self.ServerInfoPanel.ToolBar.SaveButton:SetText( Gemini:GetPhrase("Rules.ToolBar.Save") )
        self.ServerInfoPanel.ToolBar.SaveButton:SetEnabled( false )
        self.ServerInfoPanel.ToolBar.SaveButton:SetIcon( "icon16/disk.png" )

        self.ServerInfoPanel.ToolBar.SaveButton.DoClick = function()
            self.ServerInfoPanel.TextEditor:Call([[gmod.SaveServerInfoJS()]])
        end

        self.ServerInfoPanel.ToolBar.PromptButton = vgui.Create( "DButton", self.ServerInfoPanel.ToolBar )
        self.ServerInfoPanel.ToolBar.PromptButton:Dock( TOP )
        self.ServerInfoPanel.ToolBar.PromptButton:DockMargin( 4, 4, 4, 4 )
        self.ServerInfoPanel.ToolBar.PromptButton:SetTall( 28 )
        self.ServerInfoPanel.ToolBar.PromptButton:SetText( Gemini:GetPhrase("Rules.ToolBar.Formatter") )
        self.ServerInfoPanel.ToolBar.PromptButton:SetIcon( "icon16/application_edit.png" )

        self.ServerInfoPanel.ToolBar.PromptButton.DoClick = function()
            self:CreatePromptFormatter(RootPanel)
        end
    end

    self.MainSheet:AddSheet( Gemini:GetPhrase("Rules.ServerInfo"), self.ServerInfoPanel, "icon16/information.png" )

    --[[------------------------
           Server Rules
    ------------------------]]--

    self.ServerRulesPanel = vgui.Create( "DPanel", self.MainSheet )
    self.ServerRulesPanel:Dock( FILL )

    self.ServerRulesPanel.TextEditor = vgui.Create( "DHTML", self.ServerRulesPanel )
    self.ServerRulesPanel.TextEditor:Dock( FILL )
    self.ServerRulesPanel.TextEditor:SetVisible( false )

    -- Main Functions
    self.ServerRulesPanel.TextEditor:AddFunction("gmod", "SuppressConsole", function()
        gui.HideGameUI()
    end)

    self.ServerRulesPanel.TextEditor:AddFunction("gmod", "SetClipboardText", function(text)
        SetClipboardText(text)
    end)

    self.ServerRulesPanel.TextEditor:AddFunction("gmod", "RulesFullyLoaded", function()
        self.ServerRulesPanel.TextEditor.FullyLoaded = true
        self.ServerRulesPanel.ActionPanel.SaveButton:SetEnabled( CanEdit )

        self.ServerRulesPanel.TextEditor:SetVisible( true )
    end)

    self.ServerRulesPanel.TextEditor:AddFunction("gmod", "SaveServerRulesLua", function(text)
        Gemini:SetServerRulesClient(text)
    end)

    self.ServerRulesPanel.TextEditor:SetHTML( self:CompileHTML(Gemini:GetRules(), not CanEdit, true) )

    self.ServerRulesPanel.ActionPanel = vgui.Create( "DPanel", self.ServerRulesPanel )
    self.ServerRulesPanel.ActionPanel:Dock( BOTTOM )
    self.ServerRulesPanel.ActionPanel:SetTall( 40 )
    self.ServerRulesPanel.ActionPanel.Paint = BackgroundPaint

    self.ServerRulesPanel.ActionPanel.SaveButton = vgui.Create( "DButton", self.ServerRulesPanel.ActionPanel )
    self.ServerRulesPanel.ActionPanel.SaveButton:Dock( LEFT )
    self.ServerRulesPanel.ActionPanel.SaveButton:DockMargin( 4, 4, 4, 4 )
    self.ServerRulesPanel.ActionPanel.SaveButton:SetWide( 100 )
    self.ServerRulesPanel.ActionPanel.SaveButton:SetText( Gemini:GetPhrase("Rules.ToolBar.Save") )
    self.ServerRulesPanel.ActionPanel.SaveButton:SetEnabled( false )

    self.ServerRulesPanel.ActionPanel.SaveButton.DoClick = function()
        self.ServerRulesPanel.TextEditor:Call([[gmod.SaveServerRulesJS()]])
    end

    self.MainSheet:AddSheet( Gemini:GetPhrase("Rules.Rules"), self.ServerRulesPanel, "icon16/page_white_text.png" )
end

function MODULE:OnLostFocus()
    self:ClosePromptFormatter()
end


Gemini:ModuleCreate(Gemini:GetPhrase("Rules"), MODULE)

--[[------------------------
        Asynchronous
------------------------]]--

hook.Add("Gemini:ReceivedServerRules", "Gemini:RulesPanel", function(Rules, ServerInfo)
    if IsValid(MODULE.ServerInfoPanel.Panel) then
        MODULE.ServerInfoPanel.Panel.TextEditor:Call(string.format(ReplaceAceEditor, ServerInfo))
    end

    if IsValid(MODULE.ServerRulesPanel) then
        MODULE.ServerRulesPanel.TextEditor:Call(string.format(ReplaceAceEditor, Rules))
    end
end)

--[[------------------------
        Networking
------------------------]]--

hook.Add("Gemini:Formatter", "Gemini:Rules", function(Formatter, Text)
    if not AllowedFormatters[Formatter] then return end

    if IsValid(MODULE.ServerInfoPanel.Panel) and MODULE.ServerInfoPanel.Panel.TextEditor.FullyLoaded then
        MODULE.ServerInfoPanel.Panel.TextEditor:Call(string.format(ReplaceAceEditor, Text))
    end
end)