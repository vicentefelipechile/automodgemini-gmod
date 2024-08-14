--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Train Module
----------------------------------------------------------------------------]]-- BG

util.AddNetworkString("Gemini:GetTrain")
util.AddNetworkString("Gemini:GetAllTrain")
util.AddNetworkString("Gemini:AddNewTrain")

local MethodGenerateContent = "models/%s:generateContent"

--[[------------------------
          Settings
------------------------]]--

Gemini:CreateConfig("Temperature", "Train", Gemini.VERIFICATION_TYPE.number, 0.4)

--[[------------------------
        SQL Database
------------------------]]--

local sql_Query = sql.Query

local TrainSQL = {
    ["GEMINI_TRAIN"] = [[
        CREATE TABLE IF NOT EXISTS gemini_train (
            train_id INTEGER PRIMARY KEY AUTOINCREMENT,
            train_playerid INTEGER NOT NULL,
            train_start INTEGER NOT NULL,
            train_end INTEGER NOT NULL,
            train_result BOOLEAN DEFAULT 0,
            train_description TEXT,
            train_name TEXT NOT NULL,
            FOREIGN KEY (train_playerid) REFERENCES gemini_user(geminiuser_id),
            FOREIGN KEY (train_start) REFERENCES gemini_log(gemini_id),
            FOREIGN KEY (train_end) REFERENCES gemini_log(gemini_id)
        )
    ]],
    ["INSERT"] = [[
        INSERT INTO
            gemini_train (train_playerid, train_start, train_end, train_result, train_description, train_name)
        VALUES
            ('%s', '%s', '%s', '%s', '%s', '%s')
    ]],
    ["REPLACE"] = [[
        REPLACE INTO
            gemini_train (train_playerid, train_start, train_end, train_result, train_description, train_name)
        VALUES
            ('%s', '%s', '%s', '%s', '%s', '%s')
        WHERE
            train_name = '%s'
    ]],
    ["GETALL"] = [[
        SELECT
            *
        FROM
            gemini_train
    ]],
    ["GETLAST"] = [[
        SELECT
            *
        FROM
            gemini_train
        ORDER BY
            train_id DESC
        LIMIT 1
    ]],
    ["GETTRAIN"] = [[
        SELECT
            *
        FROM
            gemini_train
        WHERE
            train_id = '%s'
    ]],
    ["GETTRAINBYNAME"] = [[
        SELECT
            *
        FROM
            gemini_train
        WHERE
            train_name = '%s'
    ]]
}

-- Sanitize SQL
for SQLName, SQLSentence in pairs(TrainSQL) do
    TrainSQL[SQLName] = string.Trim( string.gsub( string.Replace( SQLSentence, "\n", "" ), "[%s]+", " " ) )
end

--[[------------------------
         Poblate SQL
------------------------]]--

function Gemini:TrainGetSQL(SQLSentence)
    return TrainSQL[SQLSentence] or ""
end

function Gemini:TrainPoblate()
    sql_Query(self:TrainGetSQL("GEMINI_TRAIN"))
end

function Gemini:GetAllTrain()
    return sql_Query(self:TrainGetSQL("GETALL")) or {}
end

function Gemini:GetLastTrain()
    return sql_Query(self:TrainGetSQL("GETLAST"))[1] or {}
end

--[[------------------------
        Train Module
------------------------]]--

function Gemini:GenerateTrainOutput(PlayerID, LogStart, LogEnd)
    local AllPreviousTrain = {}

    for k, TrainData in ipairs( self:GetAllTrain() ) do
        local LogsTrain = self:GetPlayerLogsRange(tonumber(TrainData["train_playerid"]), tonumber(TrainData["train_start"]), tonumber(TrainData["train_end"]), true)
        local LogsFormated = self:LogsToText(LogsTrain)

        local Output = {
            ["result"] = (TrainData["train_result"] == 1) and "GUILTY" or "NOT GUILTY",
            ["description"] = TrainData["train_description"],
        }

        table.insert(AllPreviousTrain, {["text"] = "input: " .. LogsFormated})
        table.insert(AllPreviousTrain, {["text"] = "output: " .. util.TableToJSON(Output)})
    end

    local Logs = self:GetPlayerLogsRange(PlayerID, LogStart, LogEnd, true)
    local LogsFormated = self:LogsToText(Logs)

    table.insert(AllPreviousTrain, {["text"] = "input: " .. LogsFormated})
    table.insert(AllPreviousTrain, {["text"] = "output: "})

    local NewRequest = Gemini:NewRequest()
    NewRequest:AddContent(AllPreviousTrain, "user")
    NewRequest:SetMethod( string.format(MethodGenerateContent, self:GetConfig("ModelName", "Gemini")) )
    NewRequest:SetGenerationConfig("temperature", self:GetConfig("Temperature", "Train"))

    file.Write("gemini/debug/train_request.json", util.TableToJSON(NewRequest:GetBody(), true))
end

function Gemini:AddNewTrain(PlayerID, LogStart, LogEnd, Result, Description, Name)
    self:Checker({PlayerID, "number", 1})
    self:Checker({LogStart, "number", 2})
    self:Checker({LogEnd, "number", 3})
    self:Checker({Result, "boolean", 4})
    self:Checker({Description, "string", 5})
    self:Checker({Name, "string", 6})

    sql_Query( string.format(self:TrainGetSQL("INSERT"), PlayerID, LogStart, LogEnd, Result and 1 or 2, Description, Name) )
end


--[[------------------------
         Networking
------------------------]]--

net.Receive("Gemini:GetTrain", function(_, ply)
    if not Gemini:CanUse(ply, "gemini_train") then return end

    local PlayerID = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local LogStart = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local LogEnd = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)

    local Logs = Gemini:GetPlayerLogsRange(PlayerID, LogStart, LogEnd)
    local LogsCompressed = util.Compress(util.TableToJSON(Logs))
    local LogsLength = #LogsCompressed

    net.Start("Gemini:GetTrain")
        net.WriteUInt(LogsLength, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(LogsCompressed, LogsLength)
    net.Send(ply)
end)

-- When i was coding this, i feel so ansious
-- but then, the music reminds me why i'm doing this
-- and now i feel so grateful for the opportunity

net.Receive("Gemini:GetAllTrain", function(_, ply)
    if not Gemini:CanUse(ply, "gemini_train") then return end

    local AllTrainCompressed = util.Compress(util.TableToJSON(Gemini:GetAllTrain()))
    local AllTrainLength = #AllTrainCompressed

    net.Start("Gemini:GetAllTrain")
        net.WriteUInt(AllTrainLength, Gemini.Util.DefaultNetworkUInt)
        net.WriteData(AllTrainCompressed, AllTrainLength)
    net.Send(ply)
end)

net.Receive("Gemini:AddNewTrain", function(_, ply)
    if not Gemini:CanUse(ply, "gemini_train") then return end

    local PlayerID = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local LogStart = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local LogEnd = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local Result = net.ReadBool()
    local Description = net.ReadString()
    local Name = net.ReadString()

    Gemini:AddNewTrain(PlayerID, LogStart, LogEnd, Result, Description, Name)

    timer.Simple(0.1, function()
        local NewTrainCompressed = util.Compress(util.TableToJSON(Gemini:GetLastTrain()))
        local NewTrainLength = #NewTrainCompressed

        net.Start("Gemini:AddNewTrain")
            net.WriteUInt(NewTrainLength, Gemini.Util.DefaultNetworkUInt)
            net.WriteData(NewTrainCompressed, NewTrainLength)
        net.Send(ply)
    end)
end)