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

--[[------------------------
         Poblate SQL
------------------------]]--

function Gemini:TrainGetSQL(SQLSentence)
    return ( SQLSentence ~= "" ) and TrainSQL[SQLSentence] or ""
end

function Gemini:TrainPoblate()
    sql_Query(TrainSQL["GEMINI_TRAIN"])
end