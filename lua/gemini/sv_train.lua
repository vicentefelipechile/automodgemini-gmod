--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Train Module
----------------------------------------------------------------------------]]--

local sql_Query = sql.Query

--[[------------------------
        SQL Database
------------------------]]--

local TrainSQL = {
    ["GEMINI_TRAIN"] = [[
        CREATE TABLE IF NOT EXITS gemini_train (
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
    SQLSentence = string.Trim( string.gsub( string.Replace( SQLSentence, "\n", "" ), "[%s]+", " " ) )
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