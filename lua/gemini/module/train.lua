--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Train Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/wrench.png" }

function MODULE:MainFunc(RootPanel, Tabs, OurTab)

    -- Print a dlabel to all OurTab
    local Label = vgui.Create("DLabel", OurTab)
    Label:SetText( Gemini:GetPhrase("Train") )
    Label:SetFont("DermaLarge")
    Label:SizeToContents()
    Label:SetPos(OurTab:GetWide() / 2 - Label:GetWide() / 2, 10)

end

--[[
function MODULE:OnFocus()
    print("THEY CLICK ME :D")
end

function MODULE:OnLostFocus()
    print(":C")
end
--]]


Gemini:ModuleCreate("Entrenamiento", MODULE)