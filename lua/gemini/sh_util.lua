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
    return string.format("(%s, %s, %s)", math.Round(vec.x, 2), math.Round(vec.y, 2), math.Round(vec.z, 2))
end