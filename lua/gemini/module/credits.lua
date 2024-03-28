--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Credits Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/heart.png" }

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse(nil, "gemini_credits") then return false end

    -- Print a dlabel to all OurTab
    local Label = vgui.Create("DLabel", OurTab)
    Label:SetText( Gemini:GetPhrase("Credits") )
    Label:SetFont("Frutiger:Big-Shadow")
    Label:SizeToContents()
    Label:SetPos(OurTab:GetWide() / 2 - Label:GetWide() / 2, 10)

end


Gemini:ModuleCreate("Creditos", MODULE)