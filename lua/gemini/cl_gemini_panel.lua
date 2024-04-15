--[[----------------------------------------------------------------------------
                 Google Gemini Automod - Gemini Panel Menu (CL)
----------------------------------------------------------------------------]]--

-- This is my best attempt to replicate the frutiger aero style
-- Source: https://frutiger-aero.neocities.org/

local GeminiModule = GeminiModule or {}

local CachedModules = {}
function Gemini:ModuleCreate(Name, TableModule)
    local Pos = nil
    if CachedModules[Name] then
        Pos = CachedModules[Name]
    end

    TableModule["__name"] = Name
    TableModule["OnFocus"] = TableModule["OnFocus"] or Gemini.ReturnNoneFunction
    TableModule["OnLostFocus"] = TableModule["OnLostFocus"] or Gemini.ReturnNoneFunction

    if ( Pos ~= nil ) then
        GeminiModule[Pos] = TableModule
    else
        Pos = table.insert(GeminiModule, TableModule)
    end

    CachedModules[Name] = Pos
end

--[[------------------------
          Variables
------------------------]]--

-- CVars
Gemini:CreateConfig("EnableAnimation", "Panel", Gemini.VERIFICATION_TYPE.bool, true)

-- Colors
-- local WhiteColor = Color(255, 255, 255)
-- local BlackColor = Color(0, 0, 0)
local BackgroundColor = Color(40, 40, 40)
local BackgroundColor1 = Color(60, 60, 60)
local BackgroundColor2 = Color(30, 30, 30)
local BodyHeight = 24

-- Fonts
local FrutigerFontData = {
    font = "Frutiger",
    size = 16,
    weight = 500,
    antialias = true,
    shadow = false,
    blursize = 0
}

surface.CreateFont("Frutiger:Normal", FrutigerFontData)

FrutigerFontData.shadow = true
surface.CreateFont("Frutiger:Normal-Shadow", FrutigerFontData)

FrutigerFontData.shadow = false
FrutigerFontData.blursize = 2
surface.CreateFont("Frutiger:Normal-Blur", FrutigerFontData)

FrutigerFontData.blursize = 0
FrutigerFontData.shadow = false
FrutigerFontData.size = 32
surface.CreateFont("Frutiger:Big", FrutigerFontData)

FrutigerFontData.shadow = true
surface.CreateFont("Frutiger:Big-Shadow", FrutigerFontData)

FrutigerFontData.shadow = false
FrutigerFontData.blursize = 2
surface.CreateFont("Frutiger:Big-Blur", FrutigerFontData)

FrutigerFontData.shadow = false
FrutigerFontData.blursize = 0
FrutigerFontData.size = 13
surface.CreateFont("Frutiger:Small", FrutigerFontData)

FrutigerFontData.shadow = true
surface.CreateFont("Frutiger:Small-Shadow", FrutigerFontData)

FrutigerFontData.shadow = false
FrutigerFontData.blursize = 2
surface.CreateFont("Frutiger:Small-Blur", FrutigerFontData)


--[[------------------------
          Functions
------------------------]]--

local function SelfPaint(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, BackgroundColor1)
end

local function DisabledModule(self, w, h)
    draw.RoundedBoxEx(3, 1, 1, w, h, BackgroundColor2, true, true)
end

--[[------------------------
           DFrame
------------------------]]--

local GEMINIPANEL = {}

function GEMINIPANEL:PoblateItems()
    local AtLeastOneTab = false

    for Key, Module in pairs(GeminiModule) do
        local Tab = vgui.Create("DPanel", self.Tabs)
        Tab:SetSize(self.Tabs:GetWide(), self.Tabs:GetTall())
        Tab.Paint = SelfPaint

        local Result = Module:MainFunc(self, self.Tabs, Tab)
        local NewTab = self.Tabs:AddSheet("  " .. Module["__name"] .. "  ", Tab, Module.Icon)["Tab"]

        if ( Result == false ) then
            NewTab:SetEnabled(false)

            -- Make the button darker
            NewTab.Paint = DisabledModule

            continue
        end

        NewTab.__MODULE = Module
        NewTab.OnFocus = Module.OnFocus
        NewTab.OnLostFocus = Module.OnLostFocus

        AtLeastOneTab = true
    end

    self.ACTIVE_PANEL = nil

    if not AtLeastOneTab then
        local DefaultTab = vgui.Create("DPanel", self.Tabs)
        DefaultTab.DefaultTab = true
        DefaultTab:SetSize(self.Tabs:GetWide(), self.Tabs:GetTall())
        DefaultTab.Paint = SelfPaint

        local NotModulesAvailable = vgui.Create("DLabel", DefaultTab)
        NotModulesAvailable:SetText("No modules available.")
        NotModulesAvailable:SetFont("Frutiger:Big")
        NotModulesAvailable:SizeToContents()
        NotModulesAvailable:Center()

        self.Tabs:AddSheet("  No Modules  ", DefaultTab, "icon16/cross.png")
        self.ACTIVE_PANEL = DefaultTab
    end

    self.Tabs.OnActiveTabChanged = function(selfTabs, OldTab, NewTab)
        if isfunction(OldTab.OnLostFocus) and ( OldTab.OnLostFocus ~= Gemini.ReturnNoneFunction ) then
            OldTab.__MODULE:OnLostFocus(self, self.Tabs)
        end

        if isfunction(OldTab.OnFocus) and ( NewTab.OnFocus ~= Gemini.ReturnNoneFunction ) then
            NewTab.__MODULE:OnFocus(self, self.Tabs)
        end

        self.ACTIVE_PANEL = NewTab
    end

    -- Pick the first tab
    for _, Tab in pairs(self.Tabs.Items) do
        if Tab.Tab:IsEnabled() then
            self.Tabs:SetActiveTab(Tab.Tab)
            break
        end
    end
end

function GEMINIPANEL:Init()
    self:SetSize(math.max(ScrW() * 0.8, 800), math.max(ScrH() * 0.6, 500))
    self:MakePopup()
    self:SetTitle("Google Gemini Automod - Server Owner Config")
    self:ShowCloseButton(true)
    self:SetDraggable(true)
    self:DockPadding(5, 5, 5, 5)

    self.Tabs = vgui.Create("DPropertySheet", self)
    self.Tabs:SetSize(self:GetWide() - 16, self:GetTall() - (BodyHeight * 2.5 + 8))
    self.Tabs:SetPos(8, BodyHeight + 8)

    self:PoblateItems()

    -- Animate to the center of the screen
    self:OpenAnimation()
    self:SetKeyboardInputEnabled(true)
end

local function DeleteOnCloseFunc(SelfPanel)
    if SelfPanel:GetDeleteOnClose() then
        SelfPanel:Remove()
    end

    SelfPanel:OnClose()

    return
end

function GEMINIPANEL:Close()
    if ispanel(self.ACTIVE_PANEL) and IsValid(self.ACTIVE_PANEL.__MODULE) and isfunction(self.ACTIVE_PANEL.__MODULE.OnLostFocus) then
        self.ACTIVE_PANEL.__MODULE:OnLostFocus(self, self.Tabs)
    end

    -- self:SetVisible( true )
    self:CloseAnimation(self)
end

-- Trying to replicate the frutiger aero style
function GEMINIPANEL:Paint(w, h)
    draw.RoundedBoxEx(8, 0, 0, w, BodyHeight, BackgroundColor, true, true)
    draw.RoundedBoxEx(8, 0, h - BodyHeight, w, BodyHeight, BackgroundColor2, false, false, true, true)
    draw.RoundedBox(0, 0, BodyHeight, w, h - BodyHeight * 2, BackgroundColor1)
end

--[[------------------------
       Register Derma
------------------------]]--

function GEMINIPANEL:OpenAnimation()
    if ( Gemini:GetConfig("EnableAnimation", "Panel") == false ) then self:Center() return end

    self:ShowCloseButton(false)
    self:Center()

    self:SlideDown(0.3)

    timer.Simple(0.301, function()
        self:ShowCloseButton(true)
    end)
end

function GEMINIPANEL:CloseAnimation(DeleteOnClose)
    if ( Gemini:GetConfig("EnableAnimation", "Panel") == false ) then
        DeleteOnCloseFunc(self, DeleteOnClose)
        return
    end

    self:SlideUp(0.3)
    timer.Simple(0.301, function()
        DeleteOnCloseFunc(self, DeleteOnClose)
    end)
end

vgui.Register("Gemini:ConfigPanel", GEMINIPANEL, "DFrame")

--[[------------------------
        Load Modules
------------------------]]--

for _, File in ipairs(file.Find("gemini/module/*.lua", "LUA")) do
    include("gemini/module/" .. File)
    Gemini:Print("Loaded module: " .. File)
end

--[[------------------------
          Debugging
------------------------]]--

concommand.Add("gemini_panel", function()
    if ( ScrW() < 800 ) or ( ScrH() < 600 ) then
        chat.AddText("The screen resolution is too small to open the config panel.")
    else
        vgui.Create("Gemini:ConfigPanel")
    end
end)

-- on say !config
hook.Add("OnPlayerChat", "Gemini:ConfigPanel", function(ply, text)
    if ( ply == LocalPlayer() ) and ( string.Trim(text) == "!gemini" ) then
        RunConsoleCommand("gemini_panel")
        return true
    end
end)