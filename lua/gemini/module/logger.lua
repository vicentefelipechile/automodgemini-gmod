--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Logger Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/page_white_text.png" }
local BlackColor = Color(0, 0, 0)

local DefaultNetworkUInt = 16
local DefaultNetworkUIntBig = 32

local SortByIDLog = function(self)

    self:GetParent():SortByColumn( self:GetColumnID(), self:GetDescending() )
    self:SetDescending( !self:GetDescending() )

    self:GetParent().CurrentColumn = self
end

--[[------------------------
           Convars
------------------------]]--

local CVAR_RequestInitialLogs = CreateClientConVar("gemini_logger_requestinitiallogs", 10, true, true)
local CVAR_PlayerTarget = CreateClientConVar("gemini_logger_playertarget", 0, true, true, Gemini:GetPhrase("Logger.PlayerID"))
local CVAR_MaxLogs = CreateClientConVar("gemini_logger_maxlogs", 10, true, true, Gemini:GetPhrase("Logger.MaxLogs"))
local CVAR_BetweenLogs = CreateClientConVar("gemini_logger_betweenlogs", 0, true, true, Gemini:GetPhrase("Logger.BetweenLogs"))
local CVAR_BetweenLogsMin = CreateClientConVar("gemini_logger_betweenlogs_min", 5, true, true, Gemini:GetPhrase("Logger.BetweenLogs"))
local CVAR_BetweenLogsMax = CreateClientConVar("gemini_logger_betweenlogs_max", 10, true, true, Gemini:GetPhrase("Logger.BetweenLogs"))


--[[------------------------
           Logger
------------------------]]--

function MODULE:AskLogs(Limit, Target, IsPlayer, Between)
    Target = Target or 0
    IsPlayer = IsPlayer or false

    local Status = net.Start("Gemini:AskLogs")
        net.WriteUInt(Limit, DefaultNetworkUInt)
        net.WriteBool(IsPlayer)
        net.WriteUInt(Target, DefaultNetworkUInt)
        net.WriteBool(Between or false)
        if ( Between ) then
            net.WriteUInt(CVAR_BetweenLogsMin:GetInt(), DefaultNetworkUIntBig)
            net.WriteUInt(CVAR_BetweenLogsMax:GetInt(), DefaultNetworkUIntBig)
        end
    net.SendToServer()

    if ( Status == true ) then
        self.LAST_REQUEST = CurTime()
        self:SetMessageLog( Gemini:GetPhrase("Logger.Requesting") )
    else
        self:SetMessageLog( Gemini:GetPhrase("Logger.RequestFailed") )
    end
end

function MODULE:RetrieveNetwork(Success, Message, Logs)
    if ( Success == true ) then
        local TimeLapse = math.Round(CurTime() - self.LAST_REQUEST, 4)
    
        self:SetMessageLog( string.format( Gemini:GetPhrase(Message), #Logs, TimeLapse ) )
        self:UpdateTable(Logs)
    end
end

function MODULE:SetMessageLog(Message)
    if IsValid(self.OutputMSG) then
        self.OutputMSG:SetText(Message)
    end
end

function MODULE:AddNewLog(ID, Log, Time, User)
    if IsValid(self.TablePanel) then
        self.TablePanel:AddLine(ID, Log, Time, User):SetSortValue(1, tonumber(ID))

        -- Sort by ID
        self.TablePanel:SortByColumn( self.TablePanel.CurrentColumn:GetColumnID(), self.TablePanel.CurrentColumn:GetDescending() )
    end
end

function MODULE:UpdateTable(Logs)
    if IsValid(self.TablePanel) then
        self.TablePanel:Clear()

        for k, Data in ipairs(Logs) do
            self:AddNewLog(Data["geminilog_id"], Data["geminilog_log"], Data["geminilog_time"], Data["geminilog_user1"])
        end
    end
end

--[[------------------------
        Main Function
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)

    -- Print a dlabel to all OurTab
    local Label = vgui.Create("DLabel", OurTab)
    Label:SetText( Gemini:GetPhrase("Logger") )
    Label:SetFont("Frutiger:Big-Shadow")
    Label:SizeToContents()
    Label:SetPos(OurTab:GetWide() / 2 - Label:GetWide() / 2, 10)

    -- Output Message
    local OutputMSG = vgui.Create("DTextEntry", OurTab)
    OutputMSG:SetSize(OurTab:GetWide() - 40, 20)
    OutputMSG:SetPos(10, OurTab:GetTall() - 70)
    OutputMSG:SetEditable(false)

    -- Table Panel
    local TablePanel = vgui.Create("DListView", OurTab)
    TablePanel:SetSize(OurTab:GetWide() - 230, OurTab:GetTall() - 100)
    TablePanel:SetPos(200, 15)
    TablePanel:SetMultiSelect(false)

    local WidthList = TablePanel:GetWide()

    self.List = {}
    self.List["ID"] = TablePanel:AddColumn("ID", 1)
    self.List["Log"] = TablePanel:AddColumn("Log", 2)
    self.List["Date"] = TablePanel:AddColumn("Date", 3)
    self.List["PlayerID"] = TablePanel:AddColumn("Player ID", 4)

    self.List["ID"]:SetWidth( WidthList * 0.05 )
    self.List["Log"]:SetWidth( WidthList * 0.78 )
    self.List["Date"]:SetWidth( 128 )
    self.List["PlayerID"]:SetWidth( WidthList * 0.06 )

    self.List["ID"]:SetDescending( true )
    TablePanel.CurrentColumn = self.List["ID"]

    -- self.List["ID"].DoClick = SortByIDLog

    -- Settings Panel
    local SettingsPanel = vgui.Create("DPanel", OurTab)
    SettingsPanel:SetSize(180, OurTab:GetTall() - 100)
    SettingsPanel:SetPos(10, 15)

    local SettingsLabel = vgui.Create("DLabel", SettingsPanel)
    SettingsLabel:SetText( Gemini:GetPhrase("Logger") )
    SettingsLabel:SetTextColor(BlackColor)
    SettingsLabel:SetFont("Frutiger:Normal")
    SettingsLabel:SizeToContents()
    SettingsLabel:SetPos(SettingsPanel:GetWide() / 2 - SettingsLabel:GetWide() / 2, 6)

    -- Player ID Input
    local PlayerIDInput = vgui.Create("DTextEntry", SettingsPanel)
    PlayerIDInput:SetSize(SettingsPanel:GetWide() - 20, 20)
    PlayerIDInput:SetPos(10, 40)
    PlayerIDInput:SetNumeric(true)
    PlayerIDInput:SetPlaceholderText( Gemini:GetPhrase("Logger.PlayerID") )

    if ( CVAR_PlayerTarget:GetInt() ~= 0 ) then
        PlayerIDInput:SetValue( CVAR_PlayerTarget:GetInt() )
    end

    PlayerIDInput.OnEnter = function(self)
        local PlayerID = tonumber(self:GetValue()) or 0
        CVAR_PlayerTarget:SetInt(PlayerID)
    end

    PlayerIDInput.OnLoseFocus = function(self)
        local PlayerID = tonumber(self:GetValue()) or 0
        CVAR_PlayerTarget:SetInt(PlayerID)
    end

    -- Max Logs Label
    local MaxLogsLabel = vgui.Create("DLabel", SettingsPanel)
    MaxLogsLabel:SetText( Gemini:GetPhrase("Logger.MaxLogs") )
    MaxLogsLabel:SetTextColor(BlackColor)
    MaxLogsLabel:SetFont("Frutiger:Small")
    MaxLogsLabel:SizeToContents()
    MaxLogsLabel:SetPos(SettingsPanel:GetWide() / 2 - MaxLogsLabel:GetWide() / 2, 70)

    -- Max Logs (DNumberWang)
    local MaxLogs = vgui.Create("DNumberWang", SettingsPanel)
    MaxLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    MaxLogs:SetPos(10, 84)
    MaxLogs:SetMin(1)
    MaxLogs:SetMax(200)
    MaxLogs:SetValue( CVAR_MaxLogs:GetInt() )

    MaxLogs.OnValueChanged = function(self, value)
        CVAR_MaxLogs:SetInt(value)
    end

    -- Between Logs (2 DNumberWang)
    local BetweenLogsLabel = vgui.Create("DLabel", SettingsPanel)
    BetweenLogsLabel:SetText( Gemini:GetPhrase("Logger.BetweenLogs") )
    BetweenLogsLabel:SetTextColor(BlackColor)
    BetweenLogsLabel:SetFont("Frutiger:Small")
    BetweenLogsLabel:SizeToContents()
    BetweenLogsLabel:SetPos(SettingsPanel:GetWide() / 2 - BetweenLogsLabel:GetWide() / 2, 110)

    local BetweenLogsMin = vgui.Create("DNumberWang", SettingsPanel)
    BetweenLogsMin:SetSize( ( SettingsPanel:GetWide() - 20 ) / 2 - 4, 20)
    BetweenLogsMin:SetPos(10, 124)
    BetweenLogsMin:SetMin(1)
    BetweenLogsMin:SetMax(1000000)
    BetweenLogsMin:SetValue( CVAR_BetweenLogsMin:GetInt() )

    local BetweenLogsMax = vgui.Create("DNumberWang", SettingsPanel)
    BetweenLogsMax:SetSize( ( SettingsPanel:GetWide() - 20 ) / 2 - 4, 20)
    BetweenLogsMax:SetPos( ( SettingsPanel:GetWide() - 20 ) / 2 + 14, 124)
    BetweenLogsMax:SetMin(1)
    BetweenLogsMax:SetMax(1000000)
    BetweenLogsMax:SetValue( CVAR_BetweenLogsMax:GetInt() )

    -- Between Logs Function
    BetweenLogsMin.OnValueChanged = function(self, value)
        CVAR_BetweenLogsMin:SetInt(value)

        -- if the max is lower than the min, set the max to the min
        if ( BetweenLogsMax:GetValue() < value ) then
            BetweenLogsMax:SetValue(value)
        end
    end

    BetweenLogsMax.OnValueChanged = function(self, value)
        CVAR_BetweenLogsMax:SetInt(value)

        -- if the min is higher than the max, set the min to the max
        if ( BetweenLogsMin:GetValue() > value ) then
            BetweenLogsMin:SetValue(value)
        end
    end

    -- Enable Between Logs
    local EnableBetweenLogs = vgui.Create("DCheckBoxLabel", SettingsPanel)
    EnableBetweenLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    EnableBetweenLogs:SetPos(10, 150)
    EnableBetweenLogs:SetText( Gemini:GetPhrase("Logger.EnableBetweenLogs") )
    EnableBetweenLogs:SetTextColor(BlackColor)
    EnableBetweenLogs:SetValue( CVAR_BetweenLogs:GetBool() )

    EnableBetweenLogs.OnChange = function(self, value)
        CVAR_BetweenLogs:SetBool(value)
    end


    -- Ask Logs Button
    local AskLogsButton = vgui.Create("DButton", SettingsPanel)
    AskLogsButton:SetSize(SettingsPanel:GetWide() - 20, 20)
    AskLogsButton:SetPos(10, 180)
    AskLogsButton:SetText( Gemini:GetPhrase("Logger.RequestLogs") )
    AskLogsButton:SetFont("Frutiger:Small")

    AskLogsButton.DoClick = function()
        local PlayerID = CVAR_PlayerTarget:GetInt()

        PlayerID = ( PlayerID ~= 0 ) and PlayerID or nil

        local LogsMax = CVAR_MaxLogs:GetInt()
        local LogsAmount = math.min(LogsMax, 200)
        local Between = CVAR_BetweenLogs:GetBool()

        self:AskLogs(LogsAmount, PlayerID, PlayerID ~= nil, Between)

        if Between or PlayerID then
            self:SetAsynconousLogs(false)
        else
            self:SetAsynconousLogs(true)
        end
    end


    -- Initial Ask
    local InitialLogsLabel = vgui.Create("DLabel", SettingsPanel)
    InitialLogsLabel:SetText( Gemini:GetPhrase("Logger.InitialLogs") )
    InitialLogsLabel:SetTextColor(BlackColor)
    InitialLogsLabel:SetFont("Frutiger:Small")
    InitialLogsLabel:SizeToContents()
    InitialLogsLabel:SetPos(SettingsPanel:GetWide() / 2 - InitialLogsLabel:GetWide() / 2, 220)

    local InitialLogs = vgui.Create("DNumberWang", SettingsPanel)
    InitialLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    InitialLogs:SetPos(10, 234)
    InitialLogs:SetMin(1)
    InitialLogs:SetMax(200)
    InitialLogs:SetValue( CVAR_RequestInitialLogs:GetInt() )

    InitialLogs.OnValueChanged = function(self, value)
        CVAR_RequestInitialLogs:SetInt(value)
    end

    -- Globalize
    self.OutputMSG = OutputMSG
    self.TablePanel = TablePanel
end

function MODULE:SetAsynconousLogs(Active)
    if ( Active == true ) then
        net.Start("Gemini:StartAsynchronousLogs")
        net.SendToServer()
    else
        net.Start("Gemini:StopAsynchronousLogs")
        net.SendToServer()
    end
end

function MODULE:OnFocus()
    local LogsMax = CVAR_MaxLogs:GetInt()
    local LogsAmount = CVAR_RequestInitialLogs:GetInt()

    LogsAmount = math.min(LogsAmount, LogsMax)

    self:AskLogs(LogsAmount)
    self:SetAsynconousLogs(true)
end

function MODULE:OnLostFocus()
    self:SetAsynconousLogs(false)
end

--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:AskLogs", function(len)
    local Success = net.ReadBool()
    local Message = net.ReadString()
    local Logs = {}

    if ( Success == true ) then
        local CompressedSize = net.ReadUInt(DefaultNetworkUIntBig)
        local Data = net.ReadData(CompressedSize)

        Logs = util.JSONToTable(util.Decompress(Data))
    end

    MODULE:RetrieveNetwork(Success, Message, Logs)
end)

net.Receive("Gemini:ReplicateLog", function(len)
    local ID = net.ReadUInt(DefaultNetworkUInt)
    local Log = net.ReadString()
    local Time = net.ReadString()
    local User = net.ReadString()

    MODULE:AddNewLog(ID, Log, Time, User)
end)

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate("Registros", MODULE)