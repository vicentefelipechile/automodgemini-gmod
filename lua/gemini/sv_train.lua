--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Train Module
----------------------------------------------------------------------------]]-- BG

util.AddNetworkString("Gemini:GetTrain")

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
            FOREIGN KEY (train_playerid) REFERENCES gemini_user(geminiuser_id),
            FOREIGN KEY (train_start) REFERENCES gemini_log(gemini_id),
            FOREIGN KEY (train_end) REFERENCES gemini_log(gemini_id)
        )
    ]],
    ["INSERT"] = [[
        INSERT INTO
            gemini_train (train_playerid, train_start, train_end)
        VALUES
            ('%s', '%s', '%s')
    ]],
    ["GETALL"] = [[
        SELECT
            *
        FROM
            gemini_train
    ]],
    ["GETTRAIN"] = [[
        SELECT
            *
        FROM
            gemini_train
        WHERE
            train_id = '%s'
    ]],
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

--[[------------------------
        Train Module
------------------------]]--


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