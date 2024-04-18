--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Logger Module
----------------------------------------------------------------------------]]--

local sql_Query = sql.Query
local sql_TableExists = sql.TableExists

local PlayerTarget = "gemini_logger_playertarget"
local MaxLogs = "gemini_logger_maxlogs"
local BetweenLogs = "gemini_logger_betweenlogs"
local BetweenLogsMin = "gemini_logger_betweenlogsmin"
local BetweenLogsMax = "gemini_logger_betweenlogsmax"

local Formating = string.format

local AsynchronousPlayers = {}

--[[------------------------
        Network Strings
------------------------]]--

util.AddNetworkString("Gemini:AskLogs")
util.AddNetworkString("Gemini:ReplicateLog")
util.AddNetworkString("Gemini:StartAsynchronousLogs")
util.AddNetworkString("Gemini:StopAsynchronousLogs")

--[[------------------------
           Config
------------------------]]--

Gemini:CreateConfig("MaxLogsRequest", "Logger", Gemini.VERIFICATION_TYPE.number, 500)

--[[------------------------
        SQL Database
------------------------]]--

local LoggerSQL = {
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
    ["GEMINI_LOG_CLEAR"] = [[DELETE FROM gemini_log]],
    ["GEMINI_LOG_CLEAR_POST"] = [[DELETE FROM sqlite_sequence WHERE name = 'gemini_log']],
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
            strftime('DAY_NAME %%d %%H:%%M:%%S', geminilog_time) || ' - ' || geminilog_log AS geminilog_log
        FROM
            gemini_log
        WHERE
            geminilog_user1 = %s OR geminilog_user2 = %s OR geminilog_user3 = %s OR geminilog_user4 = %s
        ORDER BY
            geminilog_id DESC
        LIMIT
            %s
    ]],
    ["GETALLPLAYERS"] = [[
        SELECT
            *
        FROM
            gemini_user
    ]],
    ["GETALLLOGS"] = [[
        SELECT
            *
        FROM
            gemini_log
    ]],
    ["GETALLLOGSLIMIT"] = [[
        SELECT
            *
        FROM
            gemini_log
        ORDER BY
            geminilog_id DESC
        LIMIT
            %s
    ]],
    ["GETALLLOGSRANGE"] = [[
        SELECT
            *
        FROM
            gemini_log
        WHERE
            geminilog_id BETWEEN %s AND %s
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

-- Sanitize SQL
for SQLName, SQLSentence in pairs(LoggerSQL) do
    SQLSentence = string.Trim( string.gsub( string.Replace( SQLSentence, "\n", "" ), "[%s]+", " " ) )
end

--[[------------------------
        SQL Functions
------------------------]]--

function Gemini:LoggerGetSQL(SQLSentence)
    return LoggerSQL[SQLSentence] or ""
end

function Gemini:LoggerCreateTable()
    LoggerSQL["GETONLYLOGS"] = string.Replace(self:LoggerGetSQL("GETONLYLOGS"), "DAY_NAME", self.DayName)

    sql_Query(self:LoggerGetSQL("GEMINI_USER"))
    sql_Query(self:LoggerGetSQL("GEMINI_LOG"))
end

function Gemini:LoggerCheckTable()
    self.DayName = self:GetPhrase("day")

    if not ( sql_TableExists("gemini_user") or sql_TableExists("gemini_log") ) then
        Gemini:LoggerCreateTable()
    end
end

function Gemini:LoggerPlayerToID(ply)
    if not ( IsValid(ply) and ply:IsPlayer() ) then
        self:Error([[The first argument of Gemini:LoggerPlayerToID() is not a Player]], ply, "Player")
    end

    if isnumber(ply.__LOGGER_ID) then return ply.__LOGGER_ID end

    local SteamID = ply:SteamID()
    local SteamID64 = ply:SteamID64()

    local QueryResult = Formating(self:LoggerGetSQL("GETUSER"), SteamID, SteamID64)
    local Result = nil

    if QueryResult ~= nil then
        Result = tonumber(QueryResult)
    else
        Formating(self:LoggerGetSQL("INSERTUSER"), SteamID, SteamID64)
        Result = tonumber( Formating(self:LoggerGetSQL("GETUSER"), SteamID, SteamID64) )
    end

    if isnumber(Result) then
        ply.__LOGGER_ID = Result
    end

    return Result
end

function Gemini:LoggerFindPlayerLogs(ply, Limit, OnlyLogs)
    if not ( isnumber(ply) or IsValid(ply) and ply:IsPlayer() ) then
        self:Error([[The first argument of Gemini:LoggerFindPlayerLogs() is not a Player or number]], PhraseName, "Player or number")
    end

    if not isnumber(Limit) then
        self:Error([[The second argument of Gemini:LoggerFindPlayerLogs() is not a number]], PhraseName, "number")
    end

    local UserID = isnumber(ply) and ply or Gemini:LoggerPlayerToID(ply)

    return sql_Query( string.format(
        OnlyLogs and self:LoggerGetSQL("GETONLYLOGS") or self:LoggerGetSQL("GETPLAYERLOGS"),
        UserID, UserID, UserID, UserID, Limit)
    ) or {}
end

function Gemini:LoggerGetLogsLimit(Limit)
    return sql_Query( string.format(self:LoggerGetSQL("GETALLLOGSLIMIT"), Limit) )
end

--[[------------------------
      Logger Functions
------------------------]]--

function Gemini:LoggerAddLog(LogString, LogUser1, LogUser2, LogUser3, LogUser4)
    LogUser1 = LogUser1 and Gemini:LoggerPlayerToID(LogUser1)
    LogUser2 = LogUser2 and Gemini:LoggerPlayerToID(LogUser2)
    LogUser3 = LogUser3 and Gemini:LoggerPlayerToID(LogUser3)
    LogUser4 = LogUser4 and Gemini:LoggerPlayerToID(LogUser4)

    Formating(self:LoggerGetSQL("INSERTLOG"), LogString, LogUser1, LogUser2, LogUser3, LogUser4)

    if #AsynchronousPlayers > 0 then
        Gemini:LoggerSendAsynchronousLogs()
    end
end

hook.Add("Gemini.Log", "Gemini:Log", function(...)
    Gemini:LoggerAddLog(...)
end)

--[[------------------------
      Network Functions
------------------------]]--

function Gemini.LoggerAskLogs(len, ply)
    if not Gemini:CanUse(ply, "gemini_logger") then
        Gemini:SendMessage(ply, "Logger.DontAllowed")
        return
    end

    local IsBetween = Gemini:GetPlayerInfo(ply, BetweenLogs)
    local Limit = math.min(
        Gemini:GetConfig("MaxLogsRequest", "Logger"),
        Gemini:GetPlayerInfo(ply, MaxLogs)
    )
    local Logs = {}

    if IsBetween then
        local Min = Gemini:GetPlayerInfo(ply, BetweenLogsMin)
        local Max = Gemini:GetPlayerInfo(ply, BetweenLogsMax)
        Logs = sql.Query( string.format(Gemini:LoggerGetSQL("GETALLLOGSRANGE"), Min, Max, Limit) )

        Logs = ( Logs == nil ) and {} or Logs
    else
        local PlayerID = Gemini:GetPlayerInfo(ply, PlayerTarget)

        if ( PlayerID == 0 ) then
            Logs = Gemini:LoggerGetLogsLimit(Limit)
        else
            Logs = Gemini:LoggerFindPlayerLogs(PlayerID, Limit)
        end
    end

    local CompressesLogs = util.Compress( util.TableToJSON(Logs) )
    local CompressedSize = #CompressesLogs

    net.Start("Gemini:AskLogs")
        net.WriteBool(true)
        net.WriteString("Logger.LogsSended")
        net.WriteUInt(CompressedSize, Gemini.Util.DefaultNetworkUIntBig)
        net.WriteData(CompressesLogs, CompressedSize)
    net.Send(ply)
end
net.Receive("Gemini:AskLogs", Gemini.LoggerAskLogs)

function Gemini:LoggerSendAsynchronousLogs()
    local LastLog = Gemini:LoggerGetLogsLimit(1)[1]

    local ID = LastLog["geminilog_id"]
    local Log = LastLog["geminilog_log"]
    local Date = LastLog["geminilog_time"]
    local PlayerID = LastLog["geminilog_user1"]

    net.Start("Gemini:ReplicateLog")
        net.WriteUInt(ID, Gemini.Util.DefaultNetworkUInt)
        net.WriteString(Log)
        net.WriteString(Date)
        net.WriteString(PlayerID)
    net.Send(AsynchronousPlayers)
end

function Gemini.LoggerStartAsynchronousLogs(len, ply)
    if not Gemini:CanUse(ply, "gemini_logger") then return end

    table.insert(AsynchronousPlayers, ply)
    Gemini:Print( string.format("Asynchronous logs started for \"%s\"", ply:Nick()) )
end

function Gemini.LoggerStopAsynchronousLogs(len, ply)
    table.RemoveByValue(AsynchronousPlayers, ply)
    Gemini:Print( string.format("Asynchronous logs stopped for \"%s\"", ply:Nick()) )
end

net.Receive("Gemini:StartAsynchronousLogs", Gemini.LoggerStartAsynchronousLogs)
net.Receive("Gemini:StopAsynchronousLogs", Gemini.LoggerStopAsynchronousLogs)

hook.Add("PlayerDisconnected", "Gemini:LoggerAsynchronousLogs", function(ply)
    Gemini.LoggerStopAsynchronousLogs(0, ply)
end)

--[[------------------------
   Miscellaneous Functions
------------------------]]--

function Gemini:LoggerClearLogs()
    sql.Begin()
    sql_Query(LoggerSQL.GEMINI_LOG_CLEAR)
    sql_Query(LoggerSQL.GEMINI_LOG_CLEAR_POST)
    sql.Commit()

    self:Print("Logs cleared successfully.")
end