--[[----------------------------------------------------------------------------
                 Google Gemini Automod - Gemini Panel Menu (CL)
----------------------------------------------------------------------------]]--

local GeminiDermaSkin = GeminiDermaSkin or {}

--[[------------------------
          Variables
------------------------]]--

local ColorCyan = Color( 0, 165, 157)

-- Button
local ButtonHoverColor = Color( 1, 78, 129)
local ButtonNoHoverColor = Color( 70, 70, 70)
local ButtonDisabledColor = Color( 60, 60, 60)
local ButtonDisabledOutlineColor = Color( 37, 59, 56)
local ButtonDisabledTextColor = Color( 180, 180, 180)

-- DPanel
local PanelBackgroundColor = Color( 41, 41, 41, 255)
local PanelOutlineColor = Color( 80, 80, 80, 255)

local PanelOutlineWidth = 3

-- DTextEntry
local TextEntryBackgroundColor = Color( 60, 60, 60)
local TextEntryDisabled = Color( 50, 50, 50)

--[[------------------------
          Functions
------------------------]]--

function Gemini:ReloadDermaSkin()
    GeminiDermaSkin = table.Copy( derma.GetDefaultSkin() )

    GeminiDermaSkin.Author = "vicentefelipechile"

    -- Button
    GeminiDermaSkin.Colours.Button.Normal = color_white
    GeminiDermaSkin.Colours.Button.Hover = color_white
    GeminiDermaSkin.Colours.Button.Down = color_white
    GeminiDermaSkin.Colours.Button.Disabled = ButtonDisabledTextColor
    GeminiDermaSkin.PaintButton = function(DermaSkin, SubSelf, w, h)
        if SubSelf:IsEnabled() then -- Enabled
            if SubSelf:IsHovered() then
                draw.RoundedBox( 0, 0, 0, w, h, ButtonHoverColor )
                draw.RoundedBox( 0, 0, h - 2, w, 2, ColorCyan )
            else
                draw.RoundedBox( 0, 0, 0, w, h, ButtonNoHoverColor )
            end
        else
            draw.RoundedBox( 0, 0, 0, w, h, ButtonNoHoverColor )
        end
    end

    -- DPanel
    GeminiDermaSkin.colMenuBG = text_dark

    derma.DefineSkin("Gemini:DermaSkin", "Gemini Derma Skin", GeminiDermaSkin)
end

hook.Add("PostGamemodeLoaded", "GeminiDermaSkin:Initialize", function()
    Gemini:ReloadDermaSkin()
end)

concommand.Add("gemini_reloadskin", function()
    Gemini:ReloadDermaSkin()
end)