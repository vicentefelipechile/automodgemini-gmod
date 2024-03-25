--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Util Module
----------------------------------------------------------------------------]]--

--[[------------------------
       Main Functions
------------------------]]--

function Gemini.ReturnNoneFunction()
    return
end

function Gemini.ReturnAnyFunction(...)
    return ...
end

--[[------------------------
       Util Functions
------------------------]]--

function Gemini:VectorToString(vec)
    return string.format("(%s, %s, %s)", math.Round(vec.x, 0), math.Round(vec.y, 0), math.Round(vec.z, 0))
end

function Gemini:LogsToText(logs)
    local text = ""
    for i, log in ipairs(logs) do
        text = text .. log .. "\n"
    end
    return text
end