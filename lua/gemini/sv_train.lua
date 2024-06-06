--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Train Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:GetTrain")

--[[------------------------
        SQL Database
------------------------]]--

local sql_Query = sql.Query

local TrainSQL = {
    ["GEMINI_TRAIN"] = [[
        CREATE TABLE IF NOT EXISTS gemini_train (
            train_id INTEGER PRIMARY KEY AUTOINCREMENT,
            train_gamemode TEXT NOT NULL DEFAULT 'default',
            train_data TEXT NOT NULL,
            train_result TEXT NOT NULL
        )
    ]],
    ["INSERT"] = [[
        INSERT INTO
            gemini_train (train_gamemode, train_data, train_result)
        VALUES
            ('%s', '%s', '%s')
    ]],
    ["GETALL"] = [[
        SELECT
            *
        FROM
            gemini_train
        WHERE
            train_gamemode = '%s'
    ]],
    ["GETTRAIN"] = [[
        SELECT
            train_data,
            train_result
        FROM
            gemini_train
        WHERE
            train_id = '%s' AND
            train_gamemode = '%s'
        LIMIT
            %s
    ]],
    ["GETTRAINRANGE"] = [[
        SELECT
            train_data,
            train_result
        FROM
            gemini_train
        WHERE
            train_id BETWEEN '%s' AND '%s' AND
            train_gamemode = '%s'
    ]]
    ["GETALLTRAIN"] = [[
        SELECT
            train_data,
            train_result
        FROM
            gemini_train
        WHERE
            train_gamemode = '%s'
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