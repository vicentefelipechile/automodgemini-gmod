--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Rules Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/page_edit.png" }

-- https://github.com/WilliamVenner/SQLWorkbench/blob/master/lua/sqlworkbench/menu.lua#L421-L592
function MODULE:GetAceScript(File)
    return include("gemini/module/ace/" .. File .. ".lua")
end

function MODULE:CompileHTML(InitialValue)
    InitialValue = InitialValue or "# Test Script"

    local Embedding = self:GetAceScript("embedding")

    local Ace = self:GetAceScript("ace.js")
    local Extension = self:GetAceScript("ext-language_tools.js")
    local Theme = self:GetAceScript("theme-monokai.js")
    local Mode = self:GetAceScript("mode-markdown.js")
    local Snippets = self:GetAceScript("snippets-markdown.js")

    return string.format(Embedding, Ace, Extension, Theme, Mode, Snippets, InitialValue)
end

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_credits") then return false end

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
    self.ServerInfoPanel.TextEditor:AddFunction("gmod", "SuppressConsole", function(text)
        gui.HideGameUI()
    end)
    self.ServerInfoPanel.TextEditor:SetHTML( self:CompileHTML() )

    self.MainSheet:AddSheet( "Server Info", self.ServerInfoPanel, "icon16/information.png" )

    --[[------------------------
           Server Rules
    ------------------------]]--

    self.ServerRulesPanel = vgui.Create( "DPanel", self.MainSheet )
    self.ServerRulesPanel:Dock( FILL )
    self.MainSheet:AddSheet( "Server Rules", self.ServerRulesPanel, "icon16/page_white_text.png" )
end


Gemini:ModuleCreate(Gemini:GetPhrase("Rules"), MODULE)