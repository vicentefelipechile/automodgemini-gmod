--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Train Module
----------------------------------------------------------------------------]]--

--[[------------------------
        SQL Database
------------------------]]--

Gemini.__TRAIN_SQL = {
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
    ["GET"] = [[
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
    ]]
}