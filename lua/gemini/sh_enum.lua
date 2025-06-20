--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Enum Module
----------------------------------------------------------------------------]]--

module( "GEMINI_ENUM", package.seeall )

--[[------------------------
        Harm Category
------------------------]]--

-- Most used
HARM_CATEGORY_SEXUALLY_EXPLICIT = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
HARM_CATEGORY_DANGEROUS_CONTENT = "HARM_CATEGORY_DANGEROUS_CONTENT"
HARM_CATEGORY_HARASSMENT = "HARM_CATEGORY_HARASSMENT"
HARM_CATEGORY_HATE_SPEECH = "HARM_CATEGORY_HATE_SPEECH"

-- Less used
HARM_CATEGORY_UNSPECIFIED = "HARM_CATEGORY_UNSPECIFIED"
HARM_CATEGORY_DEROGATORY = "HARM_CATEGORY_DEROGATORY"
HARM_CATEGORY_TOXICITY = "HARM_CATEGORY_TOXICITY"
HARM_CATEGORY_VIOLENCE = "HARM_CATEGORY_VIOLENCE"
HARM_CATEGORY_SEXUAL = "HARM_CATEGORY_SEXUAL"
HARM_CATEGORY_MEDICAL = "HARM_CATEGORY_MEDICAL"
HARM_CATEGORY_DANGEROUS = "HARM_CATEGORY_DANGEROUS"


--[[------------------------
        Block Reason
------------------------]]--

BLOCK_NONE = "BLOCK_NONE"
BLOCK_LOW_AND_ABOVE = "BLOCK_LOW_AND_ABOVE"
BLOCK_MEDIUM_AND_ABOVE = "BLOCK_MEDIUM_AND_ABOVE"
BLOCK_ONLY_HIGH	= "BLOCK_ONLY_HIGH"


--[[------------------------
            Extra
------------------------]]--

HARM_BLOCK_THRESHOLD_UNSPECIFIED = "HARM_BLOCK_THRESHOLD_UNSPECIFIED"
HARM_PROBABILITY_UNSPECIFIED = "HARM_PROBABILITY_UNSPECIFIED"
BLOCK_REASON_UNSPECIFIED = "BLOCK_REASON_UNSPECIFIED"
FINISH_REASON_UNSPECIFIED = "FINISH_REASON_UNSPECIFIED"

NEGLIGIBLE = "NEGLIGIBLE"
SAFETY = "SAFETY"
OTHER = "OTHER"
STOP = "STOP"
MAX_TOKENS = "MAX_TOKENS"
RECITATION = "RECITATION"

LOW = "LOW"
MEDIUM = "MEDIUM"
HIGH = "HIGH"