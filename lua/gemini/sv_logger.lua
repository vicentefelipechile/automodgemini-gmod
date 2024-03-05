--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Logger Module
----------------------------------------------------------------------------]]--

local sql_Query = sql.Query
local sql_QueryValue = sql.QueryValue
local sql_TableExists = sql.TableExists

local function Formating(str, ...)
    local new = string.Trim( string.gsub( string.Replace( str, "\n", "" ), "[%s]+", " " ) )
    return sql_QueryValue( string.format( new, ... ) )
end


Gemini.__LOGGER = {
    ["GEMINI_USER"] = [[
        CREATE TABLE IF NOT EXISTS gemini_user (
            geminiuser_id INTEGER PRIMARY KEY AUTOINCREMENT,
            geminiuser_steamid TEXT NOT NULL,
            geminiuser_steamid64 TEXT NOT NULL UNIQUE
        )
    ]],
    ["GEMINI_LOG"] = [[
        CREATE TABLE IF NOT EXISTS gemini_log (
            geminilog_id INTEGER PRIMARY KEY AUTOINCREMENT,
            geminilog_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            geminilog_log TEXT NOT NULL,
            geminilog_user1 INTEGER NOT NULL,
            geminilog_user2 INTEGER DEFAULT NULL,
            geminilog_user3 INTEGER DEFAULT NULL,
            geminilog_user4 INTEGER DEFAULT NULL,
            FOREIGN KEY (geminilog_user1) REFERENCES gemini_user (geminiuser_id)
        )
    ]],
    ["GETUSER"] = [[
        SELECT
            geminiuser_id
        FROM
            gemini_user
        WHERE
            geminiuser_steamid = '%s' AND geminiuser_steamid64 = '%s'
    ]],
    ["INSERTUSER"] = [[
        INSERT INTO
            gemini_user (geminiuser_steamid, geminiuser_steamid64)
        VALUES
            ('%s', '%s')
    ]],
    ["GETPLAYERLOGS"] = [[
        SELECT
            *
        FROM
            gemini_log
        WHERE
            geminilog_user1 = %s OR geminilog_user2 = %s OR geminilog_user3 = %s OR geminilog_user4 = %s
        ORDER BY
            geminilog_id DESC
        LIMIT
            %s
    ]],
    ["GETONLYLOGS"] = [[
        SELECT
            strftime('Day %%d %%H:%%M:%%S', geminilog_time) || ' - ' || geminilog_log AS geminilog_log
        FROM
            gemini_log
        WHERE
            geminilog_user1 = %s OR geminilog_user2 = %s OR geminilog_user3 = %s OR geminilog_user4 = %s
        ORDER BY
            geminilog_id DESC
        LIMIT
            %s
    ]],
    ["INSERTLOG"] = [[
        INSERT INTO
            gemini_log (geminilog_log, geminilog_user1, geminilog_user2, geminilog_user3, geminilog_user4)
        VALUES
            ('%s', '%s', '%s', '%s', '%s')
    ]]
}


function Gemini:LoggerCreateTable()
    -- Table of player info
    sql_Query(self.__LOGGER.GEMINI_USER)

    -- Table of logs
    sql_Query(self.__LOGGER.GEMINI_LOG)
end

function Gemini:LoggerCheckTable()
    if not ( sql_TableExists("gemini_user") or sql_TableExists("gemini_log") ) then
        Gemini:LoggerCreateTable()
    end
end

function Gemini:LoggerGetPlayer(ply)
    if ply.__LOGGER_ID then
        return ply.__LOGGER_ID
    end

    local SteamID = ply:SteamID()
    local SteamID64 = ply:SteamID64()

    local QueryResult = Formating(self.__LOGGER.GETUSER, SteamID, SteamID64)

    if QueryResult ~= nil then
        ply.__LOGGER_ID = tonumber(QueryResult)
        return tonumber(QueryResult)
    else
        Formating(self.__LOGGER.INSERTUSER, SteamID, SteamID64)

        local NewID = Formating(self.__LOGGER.GETUSER, SteamID, SteamID64)
        return tonumber(NewID)
    end
end

function Gemini:LoggerGetLogsPlayer(ply, Limit, OnlyLogs)
    local UserID = isnumber(ply) and ply or Gemini:LoggerGetPlayer(ply)
    local SQLScript = OnlyLogs and self.__LOGGER.GETONLYLOGS or self.__LOGGER.GETPLAYERLOGS

    local QueryResult = sql_Query( string.format(SQLScript, UserID, UserID, UserID, UserID, Limit) )

    return QueryResult
end

function Gemini:LoggerAddLog(log, ply, ply2, ply3, ply4)
    local UserID = Gemini:LoggerGetPlayer(ply)

    local LogString = log
    local LogUser1 = UserID
    local LogUser2 = ply2 and Gemini:LoggerGetPlayer(ply2) or nil
    local LogUser3 = ply3 and Gemini:LoggerGetPlayer(ply3) or nil
    local LogUser4 = ply4 and Gemini:LoggerGetPlayer(ply4) or nil

    Formating(self.__LOGGER.INSERTLOG, LogString, LogUser1, LogUser2, LogUser3, LogUser4)
end

hook.Add("Gemini.Log", "Gemini:Log", function(...)
    Gemini:LoggerAddLog(...)
end)