--[[----------------------------------------------------------------------------
                      Google Gemini Automod - Logger Module
----------------------------------------------------------------------------]]--

local sql_Query = sql.Query
local sql_TableExists = sql.TableExists

local PlayerTarget = "gemini_%s_playertarget"
local MaxLogs = "gemini_%s_maxlogs"
local BetweenLogs = "gemini_%s_betweenlogs"
local BetweenLogsMin = "gemini_%s_betweenlogsmin"
local BetweenLogsMax = "gemini_%s_betweenlogsmax"
local DefaultAlternative = "logger"

local Formating = function(str, ...)
    return sql_Query( string.format(str, ...) )
end

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
Gemini:CreateConfig("Multithreading", "Logger", Gemini.VERIFICATION_TYPE.boolean, true)

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
    LoggerSQL[SQLName] = string.Trim( string.gsub( string.Replace( SQLSentence, "\n", "" ), "[%s]+", " " ) )
end

function Gemini:LoggerGetSQL(SQLSentence)
    return LoggerSQL[SQLSentence] or ""
end



--[[------------------------
        SQL Functions
------------------------]]--

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



--[[------------------------
      Player Functions
------------------------]]--

function Gemini:PlayerToID(ply)
    if not ( IsValid(ply) and ply:IsPlayer() ) then return nil end

    if isnumber(ply.GEMINI_ID) then
        return ply.GEMINI_ID
    end

    local PlayerSteamID, PlayerSteamID64 = ply:SteamID(), ply:SteamID64()

    local QueryResult = Formating(self:LoggerGetSQL("GETUSER"), PlayerSteamID, PlayerSteamID64)
    local Result = nil

    if ( QueryResult ~= nil ) then
        Result = tonumber(QueryResult[1]["geminiuser_id"])
    else
        Formating(self:LoggerGetSQL("INSERTUSER"), PlayerSteamID, PlayerSteamID64)
        Result = tonumber( Formating(self:LoggerGetSQL("GETUSER"), PlayerSteamID, PlayerSteamID64)[1]["geminiuser_id"] )
    end

    if not isnumber(Result) then
        self:Error("There was an error trying to get the player ID.", Result, "number")
    end

    ply.GEMINI_ID = Result
    return Result
end

function Gemini:PlayerFromID(id)
    if not isnumber(id) then
        self:Error("The first argument of Gemini:PlayerFromID must be a number.", id, "number")
    end

    for _, ply in ipairs(player.GetHumans()) do
        if ( ply.GEMINI_ID == id ) then
            return ply
        end
    end

    return nil
end
Gemini.GetPlayerID = Gemini.PlayerToID



--[[------------------------
       Logs Functions
------------------------]]--

function Gemini:GetPlayerLogs(ply, Limit, FormatedLogs)
    local PlayerID = isnumber(ply) and ply or self:PlayerToID(ply)

    if not isnumber(PlayerID) then
        self:Error("There was an error trying to get the player ID.", PlayerID, "number")
    end

    self:Checker({Limit, "number", 2})

    local QuerySyntax = ( FormatedLogs == true ) and
        self:LoggerGetSQL("GETONLYLOGS")
        or
        self:LoggerGetSQL("GETPLAYERLOGS")

    return sql_Query(QuerySyntax, PlayerID, PlayerID, PlayerID, PlayerID, Limit) or {}
end
Gemini.GetPlayerLog = Gemini.GetPlayerLogs

function Gemini:GetLogs(Limit, FormatedLogs)
    self:Checker({Limit, "number", 1})

    local QuerySyntax = ( FormatedLogs == true ) and
        self:LoggerGetSQL("GETALLLOGS")
        or
        self:LoggerGetSQL("GETALLLOGSLIMIT")

    return sql_Query(QuerySyntax, Limit) or {}
end

function Gemini:GetLogsFromPlayerSettings(ply, AlternativeInfo)
    AlternativeInfo = AlternativeInfo or DefaultAlternative

    local IsBetween = self:GetPlayerInfo(ply, BetweenLogs, AlternativeInfo)
    local Limit = math.min( self:GetConfig("MaxLogsRequest", "Logger"), self:GetPlayerInfo(ply, MaxLogs, AlternativeInfo) )
    local Logs = {}

    if IsBetween then
        local Min = self:GetPlayerInfo(ply, BetweenLogsMin, AlternativeInfo)
        local Max = self:GetPlayerInfo(ply, BetweenLogsMax, AlternativeInfo)
        Logs = sql_Query( string.format(self:LoggerGetSQL("GETALLLOGSRANGE"), Min, Max, Limit) )

        Logs = ( Logs == nil ) and {} or Logs
    else
        local PlayerID = self:GetPlayerInfo(ply, PlayerTarget, AlternativeInfo)

        if ( PlayerID == 0 ) then
            Logs = self:GetLogs(Limit)
        else
            Logs = self:GetPlayerLogs(PlayerID, Limit)
        end
    end

    table.sort(Logs, function(a, b) return a["geminilog_time"] < b["geminilog_time"] end)

    return Logs
end



--[[------------------------
            Hooks
------------------------]]--

function Gemini:AddNewLog(LogString, LogUser1, LogUser2, LogUser3, LogUser4)
    LogUser1 = self:PlayerToID(LogUser1)
    LogUser2 = self:PlayerToID(LogUser2)
    LogUser3 = self:PlayerToID(LogUser3)
    LogUser4 = self:PlayerToID(LogUser4)

    Formating(self:LoggerGetSQL("INSERTLOG"), LogString, LogUser1, LogUser2, LogUser3, LogUser4)

    if #AsynchronousPlayers > 0 then
        Gemini:LoggerSendAsynchronousLogs()
    end
end

hook.Add("Gemini:Log", "Gemini:Log", function(...)
    Gemini:AddNewLog(...)
end)

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



--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:AskLogs", function(len, ply)
    if not Gemini:CanUse(ply, "gemini_logger") then
        Gemini:SendMessage(ply, "Logger.DontAllowed", "Logger")
        return
    end

    local InitialLogs = net.ReadBool()

    local Logs = {}
    if InitialLogs then
        Logs = Gemini:GetLogs( Gemini:GetPlayerInfo(ply, "gemini_logger_requestinitiallogs") )
    else
        Logs = Gemini:GetLogsFromPlayerSettings(ply)
    end

    local CompressesLogs = util.Compress( util.TableToJSON(Logs) )
    local CompressedSize = #CompressesLogs

    net.Start("Gemini:AskLogs")
        net.WriteBool(true)
        net.WriteUInt(CompressedSize, Gemini.Util.DefaultNetworkUIntBig)
        net.WriteData(CompressesLogs, CompressedSize)
    net.Send(ply)
end)

local function LoggerStartAsynchronousLogs(_, ply)
    if not Gemini:CanUse(ply, "gemini_logger") then return end

    table.insert(AsynchronousPlayers, ply)
    Gemini:Debug( string.format("Asynchronous logs started for \"%s\"", ply:Nick()) )
end

local function LoggerStopAsynchronousLogs(_, ply)
    if not table.HasValue(AsynchronousPlayers, ply) then return end

    table.RemoveByValue(AsynchronousPlayers, ply)
    Gemini:Debug( string.format("Asynchronous logs stopped for \"%s\"", ply:Nick()) )
end

net.Receive("Gemini:StartAsynchronousLogs", LoggerStartAsynchronousLogs)
net.Receive("Gemini:StopAsynchronousLogs", LoggerStopAsynchronousLogs)

hook.Add("PlayerDisconnected", "Gemini:LoggerAsynchronousLogs", function(ply)
    if not table.HasValue(AsynchronousPlayers, ply) then return end -- i know i know, but it's a small table

    LoggerStopAsynchronousLogs(0, ply)
end)