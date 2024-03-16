--[[----------------------------------------------------------------------------
                Google Gemini Automod - Server Owner Config (CL)
----------------------------------------------------------------------------]]--

-- This is my best attempt to replicate the frutiger aero style
-- Source: https://frutiger-aero.neocities.org/

--[[------------------------
          Variables
------------------------]]--

-- Colors
local WhiteColor = Color(255, 255, 255)
local BackgroundColor = Color(40, 40, 40)
local BackgroundColor1 = Color(60, 60, 60)
local BackgroundColor2 = Color(30, 30, 30)
local BodyHeight = 24

-- Materials

-- TODO

-- Fonts
local FrutigerFontData = {
    font = "Frutiger",
    size = 16,
    weight = 500,
    antialias = true,
    shadow = false
}

surface.CreateFont("Frutiger:Normal", FrutigerFontData)
FrutigerFontData.size = 24
surface.CreateFont("Frutiger:Big", FrutigerFontData)


--[[------------------------
          Functions
------------------------]]--

local function SelfPaint(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, BackgroundColor1)
end

--[[------------------------
           DFrame
------------------------]]--

local GEMINIPANEL = {}

function GEMINIPANEL:PoblateItems()
    local CreditsTab = vgui.Create("DPanel", self.Tabs)
    CreditsTab:SetSize(self.Tabs:GetWide(), self.Tabs:GetTall())
    CreditsTab.Paint = SelfPaint

    -- Title
    local TitleLabel = vgui.Create("DLabel", CreditsTab)
    TitleLabel:SetFont("Frutiger:Big")
    TitleLabel:SetText("Google Gemini Automod")
    TitleLabel:SetTextColor(WhiteColor)
    TitleLabel:SizeToContents()
    TitleLabel:SetPos(CreditsTab:GetWide() * 0.5 - TitleLabel:GetWide() * 0.5, 16)

    self.Tabs:AddSheet("  Creditos  ", CreditsTab, "icon16/heart.png")

    --[[ TO DO
    for k, Module in ipairs(Gemini.__MODULE) then
        local Tab = vgui.Create("DPanel", self.Tabs)
        Tab:SetSize(self.Tabs:GetWide(), self.Tabs:GetTall())
        Tab.Paint = Module.Paint or SelfPaint

        -- Title
        local TitleLabel = vgui.Create("DLabel", Tab)
        TitleLabel:SetFont("Frutiger:Big")
        TitleLabel:SetText("Google Gemini Automod")
        TitleLabel:SetTextColor(WhiteColor)
        TitleLabel:SizeToContents()
        TitleLabel:SetPos(Tab:GetWide() * 0.5 - TitleLabel:GetWide() * 0.5, 16)

        self.Tabs:AddSheet("  " .. Module.Nombre .. "  ", Tab, "icon16/heart.png")
    end
    --]]
end

function GEMINIPANEL:Init()
    self:SetSize(math.max(ScrW() * 0.5, 800), math.max(ScrH() * 0.2, 400))
    self:Center()
    self:MakePopup()
    self:SetTitle("Google Gemini Automod - Server Owner Config")
    self:ShowCloseButton(true)
    self:SetDraggable(true)
    self:DockPadding(5, 5, 5, 5)

    self.Tabs = vgui.Create("DPropertySheet", self)
    self.Tabs:SetSize(self:GetWide() - 16, self:GetTall() - (BodyHeight * 2.5 + 8))
    self.Tabs:SetPos(8, BodyHeight + 8)

    self:PoblateItems()
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

vgui.Register("Gemini:ConfigPanel", GEMINIPANEL, "DFrame")

concommand.Add("gemini_config_panel", function()
    local panel = vgui.Create("Gemini:ConfigPanel")
    panel:MakePopup()
end)

-- on say !config
hook.Add("OnPlayerChat", "Gemini:ConfigPanel", function(ply, text)
    if ply == LocalPlayer() and text == "a" then
        RunConsoleCommand("gemini_config_panel")
        return true
    end
end)