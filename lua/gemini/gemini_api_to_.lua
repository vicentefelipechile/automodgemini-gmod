--[[----------------------------------------------------------------------------
                  Google Gemini Automod - All Enums and Objects
----------------------------------------------------------------------------]]--

-- Cuando un objeto diga:
-- ["array"] = { ...Objeto }
-- Significa que es una tabla del tipo de objeto que se encuentra dentro de las llaves


Gemini.__TYPE_PRIMITIVES = Gemini.__TYPE_PRIMITIVES or {}
Gemini.__TYPE_ENUM = Gemini.__TYPE_ENUM or {}
Gemini.__TYPE = Gemini.__TYPE or {}

--[[------------------------
        Enumerations
------------------------]]--

Gemini.__TYPE_ENUM["FinishReason"] = {
    FINISH_REASON_UNSPECIFIED   = [[Default value. This value is unused.]],
    MAX_TOKENS  = [[The maximum number of tokens as specified in the request was reached.]],
    RECITATION  = [[The candidate content was flagged for recitation reasons.]],
    SAFETY  = [[The candidate content was flagged for safety reasons.]],
    STOP    = [[Natural stop point of the model or provided stop sequence.]],
    OTHER   = [[Unknown reason.]]
}

Gemini.__TYPE_ENUM["HarmCategory"] = {
    HARM_CATEGORY_UNSPECIFIED   = [[Category is unspecified.]],
    HARM_CATEGORY_DEROGATORY    = [[Negative or harmful comments targeting identity and/or protected attribute.]],
    HARM_CATEGORY_TOXICITY  = [[Content that is rude, disrespectful, or profane.]],
    HARM_CATEGORY_VIOLENCE  = [[Describes scenarios depicting violence against an individual or group, or general descriptions of gore.]],
    HARM_CATEGORY_SEXUAL    = [[Contains references to sexual acts or other lewd content.]],
    HARM_CATEGORY_MEDICAL   = [[Promotes unchecked medical advice.]],
    HARM_CATEGORY_DANGEROUS     = [[Dangerous content that promotes, facilitates, or encourages harmful acts.]],
    HARM_CATEGORY_HARASSMENT    = [[Harasment content.]],
    HARM_CATEGORY_HATE_SPEECH   = [[Hate speech and content.]],
    HARM_CATEGORY_DANGEROUS_CONTENT     = [[Dangerous content.]],
    HARM_CATEGORY_SEXUALLY_EXPLICIT     = [[Sexually explicit content.]],
}

Gemini.__TYPE_ENUM["HarmProbability"] = {
    HARM_PROBABILITY_UNSPECIFIED  = [[Default value. This value is unused.]],
    NEGLIGIBLE  = [[Content has a negligible chance of being unsafe.]],
    LOW     = [[Content has a low chance of being unsafe.]],
    MEDIUM  = [[Content has a medium chance of being unsafe.]],,
    HIGH    = [[Content has a high chance of being unsafe.]],
}

Gemini.__TYPE_ENUM["HarmBlockThreshold"] = {
    HARM_BLOCK_THRESHOLD_UNSPECIFIED  = [[Threshold is unspecified.]],
    BLOCK_LOW_AND_ABOVE     = [[Content with NEGLIGIBLE will be allowed.]],
    BLOCK_MEDIUM_AND_ABOVE  = [[Content with NEGLIGIBLE and LOW will be allowed.]],
    BLOCK_ONLY_HIGH         = [[Content with NEGLIGIBLE, LOW, and MEDIUM will be allowed.]],
    BLOCK_NONE              = [[All content will be allowed.]],
}

Gemini.__TYPE_ENUM["BlockReason"] = {
    BLOCK_REASON_UNSPECIFIED   = [[Default value. This value is unused.]],
    SAFETY  = [[Prompt was blocked due to safety reasons. You can inspect safetyRatings to understand which safety category blocked it.]],
    OTHER   = [[Prompt was blocked due to unknown reasons.]]
}

Gemini.__TYPE_ENUM["TaskType"] = {
    TASK_TYPE_UNSPECIFIED   = [[Unset value, which will default to one of the other enum values.]],
    RETRIEVAL_QUERY     = [[Specifies the given text is a query in a search/retrieval setting.]],
    RETRIEVAL_DOCUMENT  = [[Specifies the given text is a document from the corpus being searched.]],
    SEMANTIC_SIMILARITY = [[Specifies the given text will be used for STS.]],
    CLASSIFICATION  = [[Specifies that the given text will be classified.]],
    CLUSTERING      = [[Specifies that the embeddings will be used for clustering.]]
}



--[[------------------------
       Primitive Types
------------------------]]--

Gemini.__TYPE_PRIMITIVES["Blob"] = {
    ["mimeType"] = {
        ["image/png"] = true,
        ["image/jpeg"] = true,
        ["image/heic"] = true,
        ["image/heif"] = true,
        ["image/webp"] = true
    },
    ["data"] = function(data)
        return util.Base64Encode(data)
    end
}

Gemini.__TYPE_PRIMITIVES["Part"] = {
    ["text"] = "string",
    ["inlineData"] = {
        Gemini.__TYPE_PRIMITIVES["Blob"]
    }
}



--[[------------------------
         Low-Objects
------------------------]]--

Gemini.__TYPE["SafetyRating"] = {
    ["category"] = Gemini.__TYPE_ENUM["HarmCategory"],
    ["probability"] = Gemini.__TYPE_ENUM["HarmProbability"],
    ["blocked"] = "boolean"
}

Gemini.__TYPE["CitationSource"] = {
    ["startIndex"] = "number",
    ["endIndex"] = "number",
    ["uri"] = "string",
    ["license"] = "string"
}

Gemini.__TYPE["Status"] = {
    ["code"] = "integer",
    ["message"] = "string",
    ["details"] = {
        ["array"] = {
            ["@type"] = "string",
            ["field1"] = "unknown",
            ["..."] = "unknown"
        }
    }
}



--[[------------------------
         Mid-Objects
------------------------]]--

Gemini.__TYPE["CitationMetadata"] = {
    ["citationSources"] = {
        ["array"] = {Gemini.__TYPE["CitationSource"]}
    }
}

Gemini.__TYPE["Candidate"] = {
    ["content"] = {
        Gemini.__TYPE["Content"]
    },
    ["finishReason"] = Gemini.__TYPE_ENUM["FinishReason"],
    ["safetyRatings"] = {
        ["array"] = {Gemini.__TYPE["SafetyRating"]}
    },
    ["citationMetadata"] = {
        Gemini.__TYPE["CitationMetadata"]
    },
    ["tokenCount"] = "integer",
    ["index"] = "integer"
}

Gemini.__TYPE["PromptFeedback"] = {
    ["blockReason"] = Gemini.__TYPE_ENUM["BlockReason"]
    ["safetyRatings"] = {
        ["array"] = {Gemini.__TYPE["SafetyRating"]}
    }
}

Gemini.__TYPE["Operation"] = {
    ["name"] = "string",
    ["metadata"] = {
        ["@type"] = "string",
        ["field1"] = "unknown",
        ["..."] = "unknown"
    },
    ["done"] = "boolean",

    -- Union field result can be only one of the following:
    ["error"] = {
        Gemini.__TYPE["Status"]
    },
    ["response"] = {
        ["@type"] = "string",
        ["field1"] = "unknown",
        ["..."] = "unknown"
    }
    -- End of list of possible types for union field result.
}



--[[------------------------
           Objects
------------------------]]--

Gemini.__TYPE["Content"] = {
    ["parts"] = {
        ["array"] = {Gemini.__TYPE_PRIMITIVES["Part"]}
    },
    ["role"] = {["user"] = true, ["model"] = true}
}

Gemini.__TYPE["ContentEmbedding"] = {
    ["values"] = {
        ["array"] = {"number"}
    }
}

Gemini.__TYPE["GenerateContentResponse"] = {
    ["candidates"] = {
        ["array"] = {Gemini.__TYPE["Candidate"]}
    },
    ["promptFeedback"] = {
        Gemini.__TYPE["PromptFeedback"]
    }
}

Gemini.__TYPE["GenerationConfig"] = {
    ["stopSequences"] = {
        ["array"] = {"string"}
    },
    ["candidateCount"] = "integer",
    ["maxOutputTokens"] = "integer",
    ["temperature"] = "number",
    ["topP"] = "number",
    ["topK"] = "integer",
}

Gemini.__TYPE["ListOperationsResponse"] = {
    ["operations"] = {
        ["array"] = {Gemini.__TYPE["Operation"]}
    },
    ["nextPageToken"] = "string"
}

Gemini.__TYPE["SafetySettings"] = {
    ["category"] = Gemini.__TYPE_ENUM["HarmCategory"],
    ["threshold"] = Gemini.__TYPE_ENUM["HarmBlockThreshold"]
}