--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Logger Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/page_white_text.png" }
local BlackColor = COLOR_BLACK

local DefaultNetworkUInt = 16
local DefaultNetworkUIntBig = 32

--[[------------------------
           Convars
------------------------]]--

Gemini:CreateConfig("RequestInitialLogs", "Logger", Gemini.VERIFICATION_TYPE.number, 10)
Gemini:CreateConfig("AsyncLogs", "Logger", Gemini.VERIFICATION_TYPE.bool, true)
Gemini:CreateConfig("PlayerTarget", "Logger", Gemini.VERIFICATION_TYPE.number, 0)
Gemini:CreateConfig("MaxLogs", "Logger", Gemini.VERIFICATION_TYPE.number, 10)
Gemini:CreateConfig("BetweenLogs", "Logger", Gemini.VERIFICATION_TYPE.bool, false)
Gemini:CreateConfig("BetweenLogsMin", "Logger", Gemini.VERIFICATION_TYPE.number, 5)
Gemini:CreateConfig("BetweenLogsMax", "Logger", Gemini.VERIFICATION_TYPE.number, 10)

--[[------------------------
           Logger
------------------------]]--

function MODULE:AskLogs(Limit, Target, IsPlayer, Between)
    Target = Target or 0
    IsPlayer = IsPlayer or false

    local Status = net.Start("Gemini:AskLogs")
        net.WriteBool(false) -- IsPlayground
        net.WriteUInt(Limit, DefaultNetworkUInt)
        net.WriteBool(IsPlayer)
        net.WriteUInt(Target, DefaultNetworkUInt)
        net.WriteBool(Between or false)
        if ( Between ) then
            net.WriteUInt(Gemini:GetConfig("BetweenLogsMin", "Logger"), DefaultNetworkUIntBig)
            net.WriteUInt(Gemini:GetConfig("BetweenLogsMax", "Logger"), DefaultNetworkUIntBig)
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

        -- Sort by ID
        self.TablePanel:SortByColumn( self.TablePanel.CurrentColumn:GetColumnID(), true )
        self.TablePanel.CurrentColumn:SetDescending(false)
    end
end

--[[------------------------
        Main Function
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_logger") then return false end

    --[[------------------------
           Output Message
    ------------------------]]--

    local OutputMSG = vgui.Create("DTextEntry", OurTab)
    OutputMSG:SetSize(OurTab:GetWide() - 40, 20)
    OutputMSG:SetPos(10, OurTab:GetTall() - 68)
    OutputMSG:SetEditable(false)

    self.OutputMSG = OutputMSG
    local OutputY = OutputMSG:GetY()

    --[[------------------------
             Table Panel
    ------------------------]]--

    local TablePanel = vgui.Create("DListView", OurTab)
    TablePanel:SetSize(OurTab:GetWide() - 230, OutputY - 25)
    TablePanel:SetPos(200, 15)
    TablePanel:SetMultiSelect(false)

    self.List = {}
    self.List["ID"] = TablePanel:AddColumn("ID", 1)
    self.List["Log"] = TablePanel:AddColumn("Log", 2)
    self.List["Date"] = TablePanel:AddColumn("Date", 3)
    self.List["PlayerID"] = TablePanel:AddColumn("Player ID", 4)


    local WidthLog = TablePanel:GetWide() - ( 52 + 124 + 63 )

    self.List["ID"]:SetWidth( 52 )
    self.List["Log"]:SetWidth( WidthLog )
    self.List["Date"]:SetWidth( 128 )
    self.List["PlayerID"]:SetWidth( 63 )

    self.List["ID"]:SetDescending( true )
    TablePanel.CurrentColumn = self.List["ID"]

    self.TablePanel = TablePanel

    --[[------------------------
           Settings Panel
    ------------------------]]--

    local SettingsPanel = vgui.Create("DPanel", OurTab)
    SettingsPanel:SetSize(180, OutputY - 25)
    SettingsPanel:SetPos(10, 15)

    local SettingsLabel = vgui.Create("DLabel", SettingsPanel)
    SettingsLabel:SetText( Gemini:GetPhrase("Logger") )
    SettingsLabel:SetTextColor(BlackColor)
    SettingsLabel:SetFont("Frutiger:Normal")
    SettingsLabel:SizeToContents()
    SettingsLabel:SetPos(SettingsPanel:GetWide() / 2 - SettingsLabel:GetWide() / 2, 6)

    local PlayerIDInput = vgui.Create("DTextEntry", SettingsPanel)
    PlayerIDInput:SetSize(SettingsPanel:GetWide() - 20, 20)
    PlayerIDInput:SetPos(10, 40)
    PlayerIDInput:SetNumeric(true)
    PlayerIDInput:SetPlaceholderText( Gemini:GetPhrase("Logger.PlayerID") )

    if ( Gemini:GetConfig("PlayerTarget", "Logger") ~= 0 ) then
        PlayerIDInput:SetValue( Gemini:GetConfig("PlayerTarget", "Logger") )
    end

    PlayerIDInput.OnEnter = function(SubSelf)
        local PlayerID = tonumber(SubSelf:GetValue()) or 0
        Gemini:SetConfig("PlayerTarget", "Logger", PlayerID)
    end

    PlayerIDInput.OnLoseFocus = function(SubSelf)
        local PlayerID = tonumber(SubSelf:GetValue()) or 0
        Gemini:SetConfig("PlayerTarget", "Logger", PlayerID)
    end

    local MaxLogsLabel = vgui.Create("DLabel", SettingsPanel)
    MaxLogsLabel:SetText( Gemini:GetPhrase("Logger.MaxLogs") )
    MaxLogsLabel:SetTextColor(BlackColor)
    MaxLogsLabel:SetFont("Frutiger:Small")
    MaxLogsLabel:SizeToContents()
    MaxLogsLabel:SetPos(SettingsPanel:GetWide() / 2 - MaxLogsLabel:GetWide() / 2, 70)

    local MaxLogs = vgui.Create("DNumberWang", SettingsPanel)
    MaxLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    MaxLogs:SetPos(10, 84)
    MaxLogs:SetMin(1)
    MaxLogs:SetMax(200)
    MaxLogs:SetValue( Gemini:GetConfig("MaxLogs", "Logger") )

    MaxLogs.OnValueChanged = function(_, value)
        Gemini:SetConfig("MaxLogs", "Logger", value)
    end

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
    BetweenLogsMin:SetValue( Gemini:GetConfig("BetweenLogsMin", "Logger") )

    local BetweenLogsMax = vgui.Create("DNumberWang", SettingsPanel)
    BetweenLogsMax:SetSize( ( SettingsPanel:GetWide() - 20 ) / 2 - 4, 20)
    BetweenLogsMax:SetPos( ( SettingsPanel:GetWide() - 20 ) / 2 + 14, 124)
    BetweenLogsMax:SetMin(1)
    BetweenLogsMax:SetMax(1000000)
    BetweenLogsMax:SetValue( Gemini:GetConfig("BetweenLogsMax", "Logger") )

    BetweenLogsMin.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMin", "Logger", value)

        if ( BetweenLogsMax:GetValue() < value ) then
            BetweenLogsMax:SetValue(value)
        end
    end

    BetweenLogsMax.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMax", "Logger", value)

        if ( BetweenLogsMin:GetValue() > value ) then
            BetweenLogsMin:SetValue(value)
        end
    end

    local EnableBetweenLogs = vgui.Create("DCheckBoxLabel", SettingsPanel)
    EnableBetweenLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    EnableBetweenLogs:SetPos(10, 150)
    EnableBetweenLogs:SetText( Gemini:GetPhrase("Logger.EnableBetweenLogs") )
    EnableBetweenLogs:SetTextColor(BlackColor)
    EnableBetweenLogs:SetValue( Gemini:GetConfig("BetweenLogs", "Logger") )

    EnableBetweenLogs.OnChange = function(_, value)
        Gemini:SetConfig("BetweenLogs", "Logger", value)
    end

    local AskLogsButton = vgui.Create("DButton", SettingsPanel)
    AskLogsButton:SetSize(SettingsPanel:GetWide() - 20, 20)
    AskLogsButton:SetPos(10, 180)
    AskLogsButton:SetText( Gemini:GetPhrase("Logger.RequestLogs") )
    AskLogsButton:SetFont("Frutiger:Small")

    AskLogsButton.DoClick = function()
        local PlayerID = Gemini:GetConfig("PlayerTarget", "Logger")

        PlayerID = ( PlayerID ~= 0 ) and PlayerID or nil

        local LogsMax = Gemini:GetConfig("MaxLogs", "Logger")
        local LogsAmount = math.min(LogsMax, 200)
        local Between = Gemini:GetConfig("BetweenLogs", "Logger")

        self:AskLogs(LogsAmount, PlayerID, PlayerID ~= nil, Between)

        if Between or PlayerID then
            self:SetAsynconousLogs(false)
        else
            self:SetAsynconousLogs(true)
        end
    end

    local ClearLogsButton = vgui.Create("DButton", SettingsPanel)
    ClearLogsButton:SetSize(SettingsPanel:GetWide() - 20, 20)
    ClearLogsButton:SetPos(10, 204)
    ClearLogsButton:SetText( Gemini:GetPhrase("Logger.ClearLogs") )
    ClearLogsButton:SetFont("Frutiger:Small")

    ClearLogsButton.DoClick = function()
        self:UpdateTable({})
        self:SetMessageLog( Gemini:GetPhrase("Logger.ClearedLogs") )
    end

    local InitialLogsLabel = vgui.Create("DLabel", SettingsPanel)
    InitialLogsLabel:SetText( Gemini:GetPhrase("Logger.InitialLogs") )
    InitialLogsLabel:SetTextColor(BlackColor)
    InitialLogsLabel:SetFont("Frutiger:Small")
    InitialLogsLabel:SizeToContents()
    InitialLogsLabel:SetPos(SettingsPanel:GetWide() / 2 - InitialLogsLabel:GetWide() / 2, 240)

    local InitialLogs = vgui.Create("DNumberWang", SettingsPanel)
    InitialLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    InitialLogs:SetPos(10, 254)
    InitialLogs:SetMin(1)
    InitialLogs:SetMax(200)
    InitialLogs:SetValue( Gemini:GetConfig("RequestInitialLogs", "Logger") )

    InitialLogs.OnValueChanged = function(_, value)
        Gemini:SetConfig("RequestInitialLogs", "Logger", value)
    end

    local AsyncLogs = vgui.Create("DCheckBoxLabel", SettingsPanel)
    AsyncLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    AsyncLogs:SetPos(10, 280)
    AsyncLogs:SetText( Gemini:GetPhrase("Logger.AsyncLogs") )
    AsyncLogs:SetTextColor(BlackColor)
    AsyncLogs:SetValue( Gemini:GetConfig("AsyncLogs", "Logger") )

    AsyncLogs.OnChange = function(_, value)
        Gemini:SetConfig("AsyncLogs", "Logger", value)

        self:SetAsynconousLogs(value)
    end
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
    local EnableAsync = Gemini:GetConfig("AsyncLogs", "Logger")
    local LogsMax = Gemini:GetConfig("MaxLogs", "Logger")
    local LogsAmount = Gemini:GetConfig("RequestInitialLogs", "Logger")

    if ( LogsAmount < 1 ) then return end
    LogsAmount = math.min(LogsAmount, LogsMax)

    self:AskLogs(LogsAmount)
    if ( EnableAsync == true ) then
        self:SetAsynconousLogs(true)
    end
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
    if ( Gemini:GetConfig("AsyncLogs", "Logger") == false ) then return end

    local ID = net.ReadUInt(DefaultNetworkUInt)
    local Log = net.ReadString()
    local Time = net.ReadString()
    local User = net.ReadString()

    MODULE:AddNewLog(ID, Log, Time, User)
end)

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate(Gemini:GetPhrase("Logger"), MODULE)