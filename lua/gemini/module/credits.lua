--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Credits Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/heart.png" }
local COLOR_BACKGROUND = Color( 20, 20, 20, 255 )
local COLOR_RIGHTPANEL = Color( 30, 30, 30, 255 )

local BACKGROUND_HTML = [[
<style>
.b {
background: rgb(2,0,36);
background: -moz-linear-gradient(128deg, rgba(2,0,36,1) 0%, rgba(9,9,107,1) 70%, rgba(0,104,125,1) 100%);
background: -webkit-linear-gradient(128deg, rgba(2,0,36,1) 0%, rgba(9,9,107,1) 70%, rgba(0,104,125,1) 100%);
background: linear-gradient(128deg, rgba(2,0,36,1) 0%, rgba(9,9,107,1) 70%, rgba(0,104,125,1) 100%);
filter: progid:DXImageTransform.Microsoft.gradient(startColorstr="#020024",endColorstr="#00687d",GradientType=1);
}
</style>
<body class="b"></body>
]]

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_credits") then return false end

    self.Background = vgui.Create("DHTML", OurTab)
    self.Background:Dock(FILL)
    self.Background:SetHTML(BACKGROUND_HTML)

    self.Title = vgui.Create("DLabel", self.Background)
    self.Title:SetText("Gemini Automod by\nvicentefelipechile\n\nTo Gemini API\nDeveloper Competition")
    self.Title:SetFont("GoogleSans:Big")
    self.Title:SizeToContents()
    self.Title:SetTextColor(color_white)
    self.Title:Dock(LEFT)
    self.Title:DockMargin(20, 0, 20, 0)
    self.Title:SetContentAlignment(4)

    self.RightPanel = vgui.Create("Panel", self.Background)
    self.RightPanel:Dock(RIGHT)
    self.RightPanel:SetWide( OurTab:GetWide() - ( self.Title:GetWide() + 120 ) )
    self.RightPanel.Paint = function(SubSelf, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COLOR_RIGHTPANEL)
    end

    self.VerticalLine = vgui.Create("DPanel", self.Background)
    self.VerticalLine:Dock(RIGHT)
    self.VerticalLine:SetWide(8)
    self.VerticalLine.Paint = function(SubSelf, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COLOR_RIGHTPANEL)
    end

    -- check if the player is running the x86-64 version of Garry's Mod
    if ( jit.arch ~= "x64" ) then
        self.Warning = vgui.Create("DLabel", self.RightPanel)
        self.Warning:SetText("I found that you aren't running the x86-64 version of Garry's Mod.\n\nFor that reason, unfortunately,\nI can't show it to you. :(")
        self.Warning:SetFont("GoogleSans:Normal")
        self.Warning:SizeToContents()
        self.Warning:SetTextColor(color_white)
        self.Warning:Dock(FILL)
        self.Warning:DockMargin(20, 20, 20, 20)
        return
    end

    self.WebPage = vgui.Create("DHTML", self.RightPanel)
    self.WebPage:Dock(FILL)
    self.WebPage:OpenURL("https://www.google.com")
end


Gemini:ModuleCreate(Gemini:GetPhrase("Credits"), MODULE)