--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Rules Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/page_edit.png" }
local COMPILED_HTML = COMPILED_HTML or ""
local ReplaceAceEditor = [[ace.edit("editor").setValue("%s")]]

local function ReplaceCoincidences(Text, Replacements)
    for FromReplace, ToReplace in pairs(Replacements) do
        Text = string.Replace(Text, "$" .. FromReplace .. "$", ToReplace)
    end

    return Text
end

-- https://github.com/WilliamVenner/SQLWorkbench/blob/master/lua/sqlworkbench/menu.lua#L421-L592
function MODULE:GetAceScript(File)
    return include("gemini/module/ace/" .. File .. ".lua")
end

function MODULE:CompileHTML(InitialValue, ReadOnly, UseCache)
    InitialValue = InitialValue or "# Test Script"
    ReadOnly = (ReadOnly or false) and "true" or "false"

    if UseCache and ( COMPILED_HTML ~= "" ) then
        return ReplaceCoincidences(COMPILED_HTML, {
            ["InitialValue"] = InitialValue,
            ["ReadOnly"] = ReadOnly
        })
    end

    local Embedding = self:GetAceScript("embedding")

    local Ace = self:GetAceScript("ace.js")
    local Extension = self:GetAceScript("ext-language_tools.js")
    local Theme = self:GetAceScript("theme-monokai.js")
    local Mode = self:GetAceScript("mode-markdown.js")
    local Snippets = self:GetAceScript("snippets-markdown.js")
    local Gmod = self:GetAceScript("gmod.js")

    COMPILED_HTML = ReplaceCoincidences(Embedding, {
        ["AceScript"] = Ace,
        ["Extension"] = Extension,
        ["Theme"] = Theme,
        ["Mode"] = Mode,
        ["Snippets"] = Snippets,
        ["GmodScript"] = Gmod
    })

    return ReplaceCoincidences(COMPILED_HTML, {
        ["InitialValue"] = InitialValue,
        ["ReadOnly"] = ReadOnly
    })
end

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_rules") then return false end

    local CanEdit = not Gemini:CanUse("gemini_rules_set")
    self:CompileHTML(nil, CanEdit)

    --[[------------------------
           All the Panels
    ------------------------]]--

    self.MainSheet = vgui.Create( "DColumnSheet", OurTab )
    self.MainSheet:Dock( FILL )
    self.MainSheet:DockMargin( 10, 10, 10, 10 )

    --[[------------------------
           Server Info
    ------------------------]]--

    self.ServerInfoPanel = vgui.Create( "DPanel", self.MainSheet )
    self.ServerInfoPanel:Dock( FILL )

    self.ServerInfoPanel.TextEditor = vgui.Create( "DHTML", self.ServerInfoPanel )
    self.ServerInfoPanel.TextEditor:Dock( FILL )

    -- Main Functions
    self.ServerInfoPanel.TextEditor:AddFunction("gmod", "SuppressConsole", function()
        gui.HideGameUI()
    end)

    self.ServerInfoPanel.TextEditor:AddFunction("gmod", "SetClipboardText", function(text)
        SetClipboardText(text)
    end)

    self.ServerInfoPanel.TextEditor:SetHTML( self:CompileHTML(Gemini:GetServerInfo(), CanEdit, true) )
    self.ServerInfoPanel.TextEditor.FullyLoaded = true

    self.ServerInfoPanel.ActionPanel = vgui.Create( "DPanel", self.ServerInfoPanel )
    self.ServerInfoPanel.ActionPanel:Dock( BOTTOM )
    self.ServerInfoPanel.ActionPanel:SetTall( 30 )

    self.MainSheet:AddSheet( "Server Info", self.ServerInfoPanel, "icon16/information.png" )

    --[[------------------------
           Server Rules
    ------------------------]]--

    self.ServerRulesPanel = vgui.Create( "DPanel", self.MainSheet )
    self.ServerRulesPanel:Dock( FILL )

    self.ServerRulesPanel.TextEditor = vgui.Create( "DHTML", self.ServerRulesPanel )
    self.ServerRulesPanel.TextEditor:Dock( FILL )

    -- Main Functions
    self.ServerRulesPanel.TextEditor:AddFunction("gmod", "SuppressConsole", function()
        gui.HideGameUI()
    end)

    self.ServerRulesPanel.TextEditor:AddFunction("gmod", "SetClipboardText", function(text)
        SetClipboardText(text)
    end)

    self.ServerRulesPanel.TextEditor:SetHTML( self:CompileHTML(Gemini:GetRules(), CanEdit, true) )
    self.ServerRulesPanel.TextEditor.FullyLoaded = true

    self.ServerRulesPanel.ActionPanel = vgui.Create( "DPanel", self.ServerRulesPanel )
    self.ServerRulesPanel.ActionPanel:Dock( BOTTOM )
    self.ServerRulesPanel.ActionPanel:SetTall( 30 )

    self.MainSheet:AddSheet( "Server Rules", self.ServerRulesPanel, "icon16/page_white_text.png" )
end


Gemini:ModuleCreate(Gemini:GetPhrase("Rules"), MODULE)

--[[------------------------
        Asynchronous
------------------------]]--

hook.Add("Gemini:ReceivedServerRules", "Gemini:RulesPanel", function(Rules, ServerInfo)
    if IsValid(MODULE.ServerRulesPanel) then
        MODULE.ServerInfoPanel.TextEditor:Call(string.format(ReplaceAceEditor, ServerInfo))
    end

    if IsValid(MODULE.ServerRulesPanel) then
        MODULE.ServerRulesPanel.TextEditor:Call(string.format(ReplaceAceEditor, Rules))
    end
end)