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

function Gemini.GeminiReceiveModels()
    local ModelsSize = net.ReadUInt( Gemini.Util.DefaultNetworkUInt )
    local Models = util.JSONToTable( util.Decompress( net.ReadData( ModelsSize ) ) )
    if ( Models == nil ) then return end

    GeminiModels = Models

    hook.Run("Gemini:ModelsReceived", Models)
end
net.Receive("Gemini:SendGeminiModules", Gemini.GeminiReceiveModels)