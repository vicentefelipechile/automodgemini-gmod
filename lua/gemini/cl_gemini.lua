--[[----------------------------------------------------------------------------
                   Google Gemini Automod - Gemini Module (CL)
----------------------------------------------------------------------------]]--

local GeminiModels = GeminiModels or {}

--[[------------------------
       Gemini Models
------------------------]]--

function Gemini:GeminiGetModels()
    return table.Copy(GeminiModels)
end

--[[------------------------
       Network Receive
------------------------]]--

net.Receive("Gemini:SendGeminiModules", function()
    print("Received Gemini Models")
    local ModelsSize = net.ReadUInt( Gemini.Util.DefaultNetworkUInt )
    local Models = util.JSONToTable( util.Decompress( net.ReadData( ModelsSize ) ) )
    if ( Models == nil ) then return end

    GeminiModels = Models
    hook.Run("Gemini:ModelsReceived", Models)
end)


net.Receive("Gemini:Formatter", function()
    local Formatter = net.ReadString()
    local CompressedSize = net.ReadUInt( Gemini.Util.DefaultNetworkUIntBig )
    local Text = util.Decompress( net.ReadData( CompressedSize ) )

    hook.Run("Gemini:Formatter", Formatter, Text)
end)