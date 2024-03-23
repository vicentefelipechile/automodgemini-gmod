--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Playground API
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/bug.png" }

--[[------------------------
        Main Function
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)

       -- Print a dlabel to all OurTab
       local Label = vgui.Create("DLabel", OurTab)
       Label:SetText( Gemini:GetPhrase("Playground") )
       Label:SetFont("Frutiger:Big-Shadow")
       Label:SizeToContents()
       Label:SetPos(OurTab:GetWide() / 2 - Label:GetWide() / 2, 10)

end

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate("Playground", MODULE)