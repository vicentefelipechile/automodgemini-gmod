--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Logger Module
----------------------------------------------------------------------------]]--

util.AddNetworkString("Gemini:AskLogs")
util.AddNetworkString("Gemini:AskLogs:Playground")
util.AddNetworkString("Gemini:ReplicateLog")
util.AddNetworkString("Gemini:StartAsynchronousLogs")
util.AddNetworkString("Gemini:StopAsynchronousLogs")

local sql_Query = sql.Query
local sql_QueryValue = sql.QueryValue
local sql_TableExists = sql.TableExists

local DefaultNetworkUInt = 16
local DefaultNetworkUIntBig = 32

local function Formating(str, ...)
    local new = string.Trim( string.gsub( string.Replace( str, "\n", "" ), "[%s]+", " " ) )
    return sql_QueryValue( string.format( new, ... ) )
end

local AsynchronousPlayers = {}

Gemini.LoggerServerID = 1

--[[------------------------
        SQL Database
------------------------]]--

Gemini.__LOGGER = {
    ["GEMINI_USER"] = [[
        CREATE TABLE IF NOT EXISTS gemini_user (
            geminiuser_id INTEGER PRIMARY KEY AUTOINCREMENT,
            geminiuser_steamid TEXT NOT NULL,
            geminiuser_steamid64 TEXT NOT NULL UNIQUE
        )
    ]],
    ["GEMINI_USER_SERVER"] = [[
        INSERT INTO
            gemini_user (geminiuser_steamid, geminiuser_steamid64)
        VALUES
            ('SERVER', 'SERVER')
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

--[[------------------------
        SQL Functions
------------------------]]--

function Gemini:LoggerCreateTable()
    self.DayName = self:GetPhrase("day")

    self.__LOGGER["GETONLYLOGS"] = string.Replace(self.__LOGGER["GETONLYLOGS"], "DAY_NAME", self.DayName)

    -- Table of player info
    sql_Query(self.__LOGGER.GEMINI_USER)
    sql_Query(self.__LOGGER.GEMINI_USER_SERVER)

    -- Table of logs
    sql_Query(self.__LOGGER.GEMINI_LOG)
end

function Gemini:LoggerCheckTable()
    if not ( sql_TableExists("gemini_user") or sql_TableExists("gemini_log") ) then
        Gemini:LoggerCreateTable()
    end

    self:AddConfig("BackupEnabled",         "Logger", self.VERIFICATION_TYPE.bool,  true)
    self:AddConfig("BackupIntervalEnabled", "Logger", self.VERIFICATION_TYPE.bool,  false)
    self:AddConfig("BackupInterval",        "Logger", self.VERIFICATION_TYPE.number, 120)
    self:AddConfig("CompressedBackup",      "Logger", self.VERIFICATION_TYPE.bool,  true)
    self:AddConfig("RawBackup",             "Logger", self.VERIFICATION_TYPE.bool,  false)

    self:AddConfig("MaxLogsRequest",        "Logger", self.VERIFICATION_TYPE.number, 500)
end

function Gemini:LoggerSetPlayer(ply, id, target)
    if not ( IsValid(ply) and ply:IsPlayer() ) then
        self:Error([[The first argument of Gemini:LoggerSetPlayer() is not a Player]], PhraseName, "Player")
    end

    if not isnumber(id) then
        self:Error([[The second argument of Gemini:LoggerSetPlayer() is not a number]], PhraseName, "number")
    end
end

function Gemini:LoggerGetPlayer(ply)
    if not ( IsValid(ply) and ply:IsPlayer() ) then
        self:Error([[The first argument of Gemini:LoggerGetPlayer() is not a Player]], ply, "Player")
    end

    if ply.__LOGGER_ID then return ply.__LOGGER_ID end

    local SteamID = ply:SteamID()
    local SteamID64 = ply:SteamID64()

    local QueryResult = Formating(self.__LOGGER.GETUSER, SteamID, SteamID64)

    if QueryResult ~= nil then
        QueryResult = tonumber(QueryResult)

        return QueryResult
    else
        Formating(self.__LOGGER.INSERTUSER, SteamID, SteamID64)

        local NewID = tonumber( Formating(self.__LOGGER.GETUSER, SteamID, SteamID64) )
        return NewID
    end
end

function Gemini:LoggerGetLogsPlayer(ply, Limit, OnlyLogs)
    if not ( isnumber(ply) or IsValid(ply) and ply:IsPlayer() ) then
        self:Error([[The first argument of Gemini:LoggerGetLogsPlayer() is not a Player or number]], PhraseName, "Player or number")
    end

    if not isnumber(Limit) then
        self:Error([[The second argument of Gemini:LoggerGetLogsPlayer() is not a number]], PhraseName, "number")
    end

    OnlyLogs = OnlyLogs or false

    local UserID = isnumber(ply) and ply or Gemini:LoggerGetPlayer(ply)
    local SQLScript = OnlyLogs and self.__LOGGER.GETONLYLOGS or self.__LOGGER.GETPLAYERLOGS

    local QueryResult = sql_Query( string.format(SQLScript, UserID, UserID, UserID, UserID, Limit) )

    if ( QueryResult == nil ) then
        return {}
    end

    return QueryResult
end

function Gemini:LoggerGetLogsLimit(Limit)
    local QueryResult = sql_Query( string.format(self.__LOGGER.GETALLLOGSLIMIT, Limit) )

    return QueryResult
end

--[[------------------------
      Logger Functions
------------------------]]--

function Gemini:LoggerAddLog(log, ply, ply2, ply3, ply4)
    local UserID = ( ply ~= 1 ) and Gemini:LoggerGetPlayer(ply) or Gemini.LoggerServerID

    local LogString = log
    local LogUser1 = UserID
    local LogUser2 = ply2 and Gemini:LoggerGetPlayer(ply2) or nil
    local LogUser3 = ply3 and Gemini:LoggerGetPlayer(ply3) or nil
    local LogUser4 = ply4 and Gemini:LoggerGetPlayer(ply4) or nil

    Formating(self.__LOGGER.INSERTLOG, LogString, LogUser1, LogUser2, LogUser3, LogUser4)

    -- Asynchronous logs
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
        net.Start("Gemini:AskLogs")
            net.WriteBool(false)
            net.WriteString("Logger.DontAllowed")
        net.Send(ply)

        return
    end

    local IsPlayground = net.ReadBool()

    local Limit = net.ReadUInt(DefaultNetworkUInt)
    local IsPlayer = net.ReadBool()
    local PlayerID = net.ReadUInt(DefaultNetworkUInt)
    local IsBetween = net.ReadBool()

    Limit = math.min(Limit, Gemini:GetConfig("MaxLogsRequest", "Logger"))

    local Logs = {}

    if IsBetween == true then
        local Min = net.ReadUInt(DefaultNetworkUIntBig)
        local Max = net.ReadUInt(DefaultNetworkUIntBig)
        Logs = sql_Query( string.format(Gemini.__LOGGER.GETALLLOGSRANGE, Min, Max, Limit) )

        Logs = ( Logs == nil ) and {} or Logs
    else
        if ( IsPlayer == false ) then
            Logs = Gemini:LoggerGetLogsLimit(Limit)
        else
            Logs = Gemini:LoggerGetLogsPlayer(PlayerID, Limit)
        end
    end

    local CompressesLogs = util.Compress( util.TableToJSON(Logs) )
    local CompressedSize = #CompressesLogs

    local NetworkTarget = IsPlayground and "Gemini:AskLogs:Playground" or "Gemini:AskLogs"

    net.Start(NetworkTarget)
        net.WriteBool(true)
        net.WriteString( "Logger.LogsSended" )
        net.WriteUInt( CompressedSize, DefaultNetworkUIntBig )
        net.WriteData( CompressesLogs, CompressedSize )
    net.Send(ply)
end
net.Receive("Gemini:AskLogs", Gemini.LoggerAskLogs)
net.Receive("Gemini:AskLogs:Playground", Gemini.LoggerAskLogs)

function Gemini:LoggerSendAsynchronousLogs()
    local LastLog = Gemini:LoggerGetLogsLimit(1)[1]

    local ID = LastLog["geminilog_id"]
    local Log = LastLog["geminilog_log"]
    local Date = LastLog["geminilog_time"]
    local PlayerID = LastLog["geminilog_user1"]

    net.Start("Gemini:ReplicateLog")
        net.WriteUInt(ID, DefaultNetworkUInt)
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
    table.RemoveByValue(AsynchronousPlayers, ply)
end)

--[[------------------------
    Free Space Functions
------------------------]]--

function Gemini:LoggerClearLogs()
    sql.Begin()
    sql_Query(self.__LOGGER.GEMINI_LOG_CLEAR)
    sql_Query(self.__LOGGER.GEMINI_LOG_CLEAR_POST)
    sql.Commit()

    self:Print("Logs cleared successfully.")
end