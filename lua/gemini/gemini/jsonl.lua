--[[----------------------------------------------------------------------------
                        Gemini Automod - JSONL Converter
----------------------------------------------------------------------------]]--

--[[

    array = [
        table[ string || 1 ] = string
    ]

--]]

--[[------------------------
        JSONL Object
------------------------]]--

local JSONL = {
    __content = {
        {
            ["messages"] = {}
        }
    }
}

function JSONL:ImportContent(Content)
    if not istable(Content) then
        Gemini:Error("First argument of JSONL:ImportContent must be a table.", Content, "array/table")
    elseif table.IsEmpty(Content) then
       Gemini:Error("First argument of JSONL:ImportContent must not be empty.", Content, "array/table")
    elseif not table.IsSequential(Content) then
        Gemini:Error("First argument of JSONL:ImportContent must be a sequential table.", Content, "array/table")
    end

    -- Content check
    for index, content in ipairs(Content) do
        if not istable(content) then
            Gemini:Error("Content at index " .. index .. " must be a table.", content, "array[" .. index .. "] = [table]")
        end

        if ( content["text"] ~= nil ) then
            continue
        end

        local FirstItem = next(content)
        local OnlyHasOneItem = ( #content == 1 )

        if not isstring(FirstItem) then
            Gemini:Error("First item of content at index " .. index .. " must be a string.", FirstItem, "array[" .. index .. "] = [table]")
        elseif not OnlyHasOneItem then
            Gemini:Error("Content at index " .. index .. " must only have one item.", content, "array[" .. index .. "] = [table]")
        end

        -- if is impair then is the user input
        local ContentIndex = math.ceil(index / 2)
        if ( index % 2 == 1 ) then
            self.__content[ ContentIndex ] = {
                ["messages"] = {
                    {
                        ["role"] = "user",
                        ["content"] = string.JavascriptSafe(FirstItem)
                    }
                }
            }
        else
            table.insert(self.__content[ ContentIndex ]["messages"], {
                ["role"] = "model",
                ["content"] = string.JavascriptSafe(FirstItem)
            })
        end
    end
end
JSONL.AddContents = JSONL.ImportContent

function JSONL:AddContent(Content, Role)
    if not isstring(Content) then
        Gemini:Error("First argument of JSONL:AddContent must be a string.", Content, "string")
    elseif ( #Content == 0 ) then
        Gemini:Error("First argument of JSONL:AddContent must not be empty.", Content, "string")
    end

    if not isstring(Role) then
        Gemini:Error("Second argument of JSONL:AddContent must be a string.", Role, "string")
    elseif ( #Role == 0 ) then
        Gemini:Error("Second argument of JSONL:AddContent must not be empty.", Role, "string")
    elseif not (Role == "user" or Role == "model") then
        Gemini:Error("Second argument of JSONL:AddContent must be either 'user' or 'model'.", Role, "user/model")
    end

    local ContentIndex = #self.__content
    if ( #self.__content[ ContentIndex ]["messages"] == 2 ) then
        table.insert(self.__content, {
            ["messages"] = {}
        })
        ContentIndex = #self.__content
    end

    table.insert(self.__content[ ContentIndex ]["messages"], {
        ["role"] = Role,
        ["content"] = string.JavascriptSafe(Content):gsub("\\'", "'")
    })
end

function JSONL:Export(PrettyFormat)
    local JSONLContent = ""

    if ( PrettyFormat == true ) then
        for index, content in ipairs(self.__content) do
            JSONLContent = JSONLContent .. "{\n\t\"messages\": [\n"
            local MessagesTable = content["messages"]

            for subindex, message in ipairs(MessagesTable) do
                JSONLContent = JSONLContent .. "\t\t{\n\t\t\t\"role\": \"" .. message["role"] .. "\",\n\t\t\t\"content\": \"" .. message["content"] .. "\"\n\t\t}" .. ( subindex % 2 == 0 and "," or "") .. "\n"
            end

            JSONLContent = JSONLContent .. "\t]\n}\n"
        end
    else
        for index, content in ipairs(self.__content) do
            JSONLContent = JSONLContent .. [[{"messages": []]
            local MessagesTable = content["messages"]

            for subindex, message in ipairs(MessagesTable) do
                JSONLContent = JSONLContent .. [[{"role": "]] .. message["role"] .. [[", "content": "]] .. message["content"] .. [["}]] .. ( subindex % 2 == 1 and "," or "")
            end

            JSONLContent = JSONLContent .. "]}" .. "\n"
        end
    end

    return JSONLContent
end

function Gemini.JSONL()
    return table.Copy(JSONL)
end

--[[Test command]]--

concommand.Add("gemini_jsonl_test", function()
    local NewJSONL = Gemini:JSONL()

    NewJSONL:AddContent("Hello", "user")
    NewJSONL:AddContent("World", "model")

    NewJSONL:AddContent("How are you?", "user")
    NewJSONL:AddContent("I'm fine, thank you.", "model")

    NewJSONL:AddContent("What's your name?", "user")
    NewJSONL:AddContent("My name is Gemini.", "model")

    NewJSONL:AddContent("Nice to meet you.\nThis is a new line", "user")
    NewJSONL:AddContent("Nice to meet you too.", "model")

    PrintTable(NewJSONL.__content)
    print(NewJSONL:Export(true))
    print(NewJSONL:Export(false))
end)