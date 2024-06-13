--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Logger Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/page_white_text.png" }
local STRING_REPLACE = "[%s] %s - %s (%s)"

--[[------------------------
       Paint Functions
------------------------]]--

local BackgroundColor = Color( 45, 45, 45 )
local OutlineColor = Color( 80, 80, 80, 200 )

local CheckedColor = Color( 94, 94, 94)
local UncheckedColor = Color( 32, 32, 32)

local HoverColor = Color( 0, 0, 0, 50 )
local HoverLineColor = Color( 1, 129, 123)

local OutlineWidth = 3

local function BackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, OutlineWidth, OutlineWidth, w - (OutlineWidth * 2), h - (OutlineWidth * 2), BackgroundColor )
end

local function ButtonBooleanPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, self:GetChecked() and CheckedColor or UncheckedColor )
    draw.SimpleText( self:GetChecked() and Gemini:GetPhrase("Logger.BetweenLogs.Enabled") or Gemini:GetPhrase("Logger.BetweenLogs.Disabled"), "Frutiger:Small", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverColor )
        draw.RoundedBox( 0, 0, h - 2, w, 2, HoverLineColor )
    end
end

local function HorizontalPaint(_, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, HoverLineColor )
end

local ScrollbarPaint = function(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )

    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverLineColor )
    end
end

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

function MODULE:AskLogs(Limit, Target, IsPlayer, InitialLogs)
    Target = Target or 0
    IsPlayer = IsPlayer or false

    local Status = net.Start("Gemini:AskLogs")
        net.WriteBool(InitialLogs ~= nil)
    net.SendToServer()

    if ( Status == true ) then
        self.LAST_REQUEST = CurTime()
        self:SetMessageLog( Gemini:GetPhrase("Logger.Requesting") )
    else
        self:SetMessageLog( Gemini:GetPhrase("Logger.RequestFailed") )
    end
end

function MODULE:RetrieveNetwork(Success, Logs)
    if ( Success == true ) then
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

        local TimeLapse = math.Round(CurTime() - MODULE.LAST_REQUEST, 4)
        MODULE:SetMessageLog( string.format( Gemini:GetPhrase("Logger.LogsSended"), #Logs, TimeLapse ) )
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

    self.OutputMSG = vgui.Create("DTextEntry", OurTab)
    self.OutputMSG:SetSize(OurTab:GetWide() - 40, 20)
    self.OutputMSG:SetPos(10, OurTab:GetTall() - 68)
    self.OutputMSG:SetEditable(false)

    local OutputY = self.OutputMSG:GetY()

    --[[------------------------
           Settings Panel
    ------------------------]]--

    self.SettingsPanel = vgui.Create("DScrollPanel", OurTab)
    self.SettingsPanel:SetSize(195, OutputY + 4)
    self.SettingsPanel:SetPos(10, 15)
    self.SettingsPanel.Paint = BackgroundPaint

    self.SettingsPanel.Title = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.Title:SetText( Gemini:GetPhrase("Logger.Settings") )
    self.SettingsPanel.Title:Dock(TOP)
    self.SettingsPanel.Title:SetFont("Frutiger:Normal")
    self.SettingsPanel.Title:SetContentAlignment(5)
    self.SettingsPanel.Title:DockMargin( 10, 10, 10, 0 )
    self.SettingsPanel.Title:SetHeight( 16 )

    self.SettingsPanel.PlayerIDLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.PlayerIDLabel:SetText( Gemini:GetPhrase("Logger.Column.PlayerID") )
    self.SettingsPanel.PlayerIDLabel:Dock(TOP)
    self.SettingsPanel.PlayerIDLabel:SetContentAlignment(5)
    self.SettingsPanel.PlayerIDLabel:DockMargin( 10, 10, 10, 0 )

    self.SettingsPanel.PlayerIDInput = vgui.Create("DTextEntry", self.SettingsPanel)
    self.SettingsPanel.PlayerIDInput:SetNumeric(true)
    self.SettingsPanel.PlayerIDInput:SetPlaceholderText( Gemini:GetPhrase("Logger.PlayerID") )
    self.SettingsPanel.PlayerIDInput:Dock(TOP)
    self.SettingsPanel.PlayerIDInput:DockMargin( 10, 0, 10, 0 )

    if ( Gemini:GetConfig("PlayerTarget", "Logger") ~= 0 ) then
        self.SettingsPanel.PlayerIDInput:SetValue( Gemini:GetConfig("PlayerTarget", "Logger") )
    end

    self.SettingsPanel.PlayerIDInput.OnEnter = function(SubSelf)
        local PlayerID = SubSelf:GetInt() or 0
        Gemini:SetConfig("PlayerTarget", "Logger", PlayerID)
    end

    self.SettingsPanel.PlayerIDInput.OnLoseFocus = function(SubSelf)
        local PlayerID = SubSelf:GetInt() or 0
        Gemini:SetConfig("PlayerTarget", "Logger", PlayerID)
    end

    self.SettingsPanel.MaxLogsLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.MaxLogsLabel:SetText( Gemini:GetPhrase("Logger.MaxLogs") )
    self.SettingsPanel.MaxLogsLabel:Dock(TOP)
    self.SettingsPanel.MaxLogsLabel:SetContentAlignment(5)
    self.SettingsPanel.MaxLogsLabel:DockMargin( 10, 10, 10, 0 )

    self.SettingsPanel.MaxLogs = vgui.Create("DNumberWang", self.SettingsPanel)
    self.SettingsPanel.MaxLogs:SetMin(1)
    self.SettingsPanel.MaxLogs:SetValue( Gemini:GetConfig("MaxLogs", "Logger") )
    self.SettingsPanel.MaxLogs:Dock(TOP)
    self.SettingsPanel.MaxLogs:DockMargin( 10, 0, 10, 0 )

    self.SettingsPanel.MaxLogs.OnValueChanged = function(_, value)
        Gemini:SetConfig("MaxLogs", "Logger", value)
    end

    self.SettingsPanel.BetweenLogsLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.BetweenLogsLabel:SetText( Gemini:GetPhrase("Logger.BetweenLogs") )
    self.SettingsPanel.BetweenLogsLabel:Dock(TOP)
    self.SettingsPanel.BetweenLogsLabel:SetContentAlignment(5)
    self.SettingsPanel.BetweenLogsLabel:DockMargin( 10, 20, 10, 0 )

    self.SettingsPanel.BetweenLogsInputs = vgui.Create("DPanel", self.SettingsPanel)
    self.SettingsPanel.BetweenLogsInputs:Dock(TOP)
    self.SettingsPanel.BetweenLogsInputs:SetHeight( 20 )
    self.SettingsPanel.BetweenLogsInputs:DockMargin( 10, 0, 10, 0 )
    self.SettingsPanel.BetweenLogsInputs.Paint = Gemini.Util.EmptyFunction

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin = vgui.Create("DNumberWang", self.SettingsPanel.BetweenLogsInputs)
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin:SetMin(1)
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin:SetValue( Gemini:GetConfig("BetweenLogsMin", "Logger") )
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin:Dock(LEFT)

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax = vgui.Create("DNumberWang", self.SettingsPanel.BetweenLogsInputs)
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax:SetMin(2)
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax:SetValue( Gemini:GetConfig("BetweenLogsMax", "Logger") )
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax:Dock(RIGHT)

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMin", "Logger", value)
    end

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMax", "Logger", value)
    end

    self.SettingsPanel.EnableBetweenLogsLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.EnableBetweenLogsLabel:SetText( Gemini:GetPhrase("Logger.EnableBetweenLogs") )
    self.SettingsPanel.EnableBetweenLogsLabel:Dock(TOP)
    self.SettingsPanel.EnableBetweenLogsLabel:SetContentAlignment(5)
    self.SettingsPanel.EnableBetweenLogsLabel:DockMargin( 10, 5, 10, 0 )

    self.SettingsPanel.EnableBetweenLogs = vgui.Create("DCheckBox", self.SettingsPanel)
    self.SettingsPanel.EnableBetweenLogs:SetValue( Gemini:GetConfig("BetweenLogs", "Logger") )
    self.SettingsPanel.EnableBetweenLogs:Dock(TOP)
    self.SettingsPanel.EnableBetweenLogs:DockMargin( 10, 0, 10, 0 )
    self.SettingsPanel.EnableBetweenLogs:SetTall( 20 )
    self.SettingsPanel.EnableBetweenLogs.Paint = ButtonBooleanPaint

    self.SettingsPanel.AskLogsButton = vgui.Create("DButton", self.SettingsPanel)
    self.SettingsPanel.AskLogsButton:SetText( Gemini:GetPhrase("Logger.RequestLogs") )
    self.SettingsPanel.AskLogsButton:SetFont("Frutiger:Small")
    self.SettingsPanel.AskLogsButton:Dock(TOP)
    self.SettingsPanel.AskLogsButton:SetTall( 20 )
    self.SettingsPanel.AskLogsButton:DockMargin( 10, 30, 10, 0 )

    self.SettingsPanel.AskLogsButton.DoClick = function()
        local PlayerID = Gemini:GetConfig("PlayerTarget", "Logger")

        PlayerID = ( PlayerID ~= 0 ) and PlayerID or nil

        local LogsMax = Gemini:GetConfig("MaxLogs", "Logger")
        local LogsAmount = math.min(LogsMax, 200)

        self:AskLogs(LogsAmount, PlayerID, PlayerID ~= nil)

        if Between or PlayerID then
            self:SetAsynchronousLogs(false)
        else
            self:SetAsynchronousLogs(true)
        end
    end

    self.SettingsPanel.ClearLogsButton = vgui.Create("DButton", self.SettingsPanel)
    self.SettingsPanel.ClearLogsButton:SetText( Gemini:GetPhrase("Logger.ClearLogs") )
    self.SettingsPanel.ClearLogsButton:SetFont("Frutiger:Small")
    self.SettingsPanel.ClearLogsButton:Dock(TOP)
    self.SettingsPanel.ClearLogsButton:SetTall( 20 )
    self.SettingsPanel.ClearLogsButton:DockMargin( 10, 5, 10, 0 )

    self.SettingsPanel.ClearLogsButton.DoClick = function()
        self:UpdateTable({})
        self:SetMessageLog( Gemini:GetPhrase("Logger.ClearedLogs") )
    end

    -- Horizontal line
    self.SettingsPanel.HorizontalLine = vgui.Create("DPanel", self.SettingsPanel)
    self.SettingsPanel.HorizontalLine:Dock(TOP)
    self.SettingsPanel.HorizontalLine:SetHeight( 2 )
    self.SettingsPanel.HorizontalLine:DockMargin( 10, 20, 10, 5 )
    self.SettingsPanel.HorizontalLine.Paint = HorizontalPaint

    -- More settings
    self.SettingsPanel.MoreSettings = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.MoreSettings:SetText( Gemini:GetPhrase("Logger.MoreSettings") )
    self.SettingsPanel.MoreSettings:SetFont("Frutiger:Normal")
    self.SettingsPanel.MoreSettings:Dock(TOP)
    self.SettingsPanel.MoreSettings:SetContentAlignment(5)
    self.SettingsPanel.MoreSettings:DockMargin( 10, 0, 10, 0 )

    self.SettingsPanel.InitialLogsLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.InitialLogsLabel:SetText( Gemini:GetPhrase("Logger.InitialLogs") )
    self.SettingsPanel.InitialLogsLabel:Dock(TOP)
    self.SettingsPanel.InitialLogsLabel:SetContentAlignment(5)
    self.SettingsPanel.InitialLogsLabel:DockMargin( 10, 20, 10, 0 )

    self.SettingsPanel.InitialLogs = vgui.Create("DNumberWang", self.SettingsPanel)
    self.SettingsPanel.InitialLogs:SetMin(1)
    self.SettingsPanel.InitialLogs:SetValue( Gemini:GetConfig("RequestInitialLogs", "Logger") )
    self.SettingsPanel.InitialLogs:Dock(TOP)
    self.SettingsPanel.InitialLogs:DockMargin( 10, 0, 10, 0 )

    self.SettingsPanel.InitialLogs.OnValueChanged = function(_, value)
        Gemini:SetConfig("RequestInitialLogs", "Logger", value)
    end

    self.SettingsPanel.AsyncLogsTitle = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.AsyncLogsTitle:SetText( Gemini:GetPhrase("Logger.AsyncLogs") )
    self.SettingsPanel.AsyncLogsTitle:Dock(TOP)
    self.SettingsPanel.AsyncLogsTitle:SetContentAlignment(5)
    self.SettingsPanel.AsyncLogsTitle:DockMargin( 10, 20, 10, 0 )

    self.SettingsPanel.AsyncLogs = vgui.Create("DCheckBox", self.SettingsPanel)
    self.SettingsPanel.AsyncLogs:SetValue( Gemini:GetConfig("AsyncLogs", "Logger") )
    self.SettingsPanel.AsyncLogs:Dock(TOP)
    self.SettingsPanel.AsyncLogs:DockMargin( 10, 0, 10, 0 )
    self.SettingsPanel.AsyncLogs:SetTall( 20 )
    self.SettingsPanel.AsyncLogs.Paint = ButtonBooleanPaint

    self.SettingsPanel.AsyncLogs.OnChange = function(_, value)
        Gemini:SetConfig("AsyncLogs", "Logger", value)

        self:SetAsynchronousLogs(value)
    end

    -- Empty space
    self.SettingsPanel.EmptySpace = vgui.Create("DPanel", self.SettingsPanel)
    self.SettingsPanel.EmptySpace:Dock(TOP)
    self.SettingsPanel.EmptySpace:SetHeight( 60 )
    self.SettingsPanel.EmptySpace.Paint = Gemini.Util.EmptyFunction

    -- Scrollbar
    self.SettingsPanel.VBar.Paint = Gemini.Util.EmptyFunction
    self.SettingsPanel.VBar.btnGrip.Paint = ScrollbarPaint
    self.SettingsPanel.VBar:SetWide( 14 )
    self.SettingsPanel.VBar:SetHideButtons(true)

    local SettingsPanelWidth = self.SettingsPanel:GetWide()
    self.OutputMSG:SetWide(OurTab:GetWide() - SettingsPanelWidth - 50)
    self.OutputMSG:SetX(SettingsPanelWidth + 20)

    --[[------------------------
             Table Panel
    ------------------------]]--

    local TablePos = self.SettingsPanel:GetWide() + 20

    self.TablePanel = vgui.Create("DListView", OurTab)
    self.TablePanel:SetSize(OurTab:GetWide() - TablePos - 30, OutputY - 25)
    self.TablePanel:SetPos(TablePos, 15)
    -- self.TablePanel:SetMultiSelect(false)
    self.TablePanel:SetHeaderHeight(20)

    self.TablePanel.OnRowRightClick = function(SubSelf, LineID, Line)
        local Menu = DermaMenu()

        Menu:AddOption(Gemini:GetPhrase("Logger.CopyWholeLog"), function()
            SetClipboardText( string.format(STRING_REPLACE, Line:GetColumnText(1), Line:GetColumnText(3), Line:GetColumnText(2), Line:GetColumnText(4)) )
        end)

        Menu:AddOption(Gemini:GetPhrase("Logger.CopyLog"), function()
            SetClipboardText(Line:GetColumnText(2))
        end)

        Menu:AddOption(Gemini:GetPhrase("Logger.CopyDate"), function()
            SetClipboardText(Line:GetColumnText(3))
        end)

        Menu:AddOption(Gemini:GetPhrase("Logger.CopyPlayerID"), function()
            SetClipboardText(Line:GetColumnText(4))
        end)

        local CacheSelected = SubSelf:GetSelected()
        if #CacheSelected > 1 then
            Menu:AddSpacer()

            Menu:AddOption(Gemini:GetPhrase("Logger.CopyAllLogs"), function()
                local Text = ""

                for _, SubLine in ipairs(CacheSelected) do
                    Text = Text .. string.format(STRING_REPLACE, SubLine:GetColumnText(1), SubLine:GetColumnText(3), SubLine:GetColumnText(2), SubLine:GetColumnText(4)) .. "\n"
                end

                SetClipboardText(Text)
            end)

            Menu:AddOption(Gemini:GetPhrase("Logger.CopyEqualID"), function()
                local EqualID = CacheSelected[#CacheSelected]:GetColumnText(1) .. "-" .. CacheSelected[1]:GetColumnText(1)
                SetClipboardText(EqualID)
            end)
        end

        Menu:Open()
    end

    -- Scrollbar
    self.TablePanel:SetSkin("Gemini:DermaSkin")

    self.List = {}
    self.List["ID"] = self.TablePanel:AddColumn("ID", 1)
    self.List["Log"] = self.TablePanel:AddColumn("Log", 2)
    self.List["Date"] = self.TablePanel:AddColumn("Date", 3)
    self.List["PlayerID"] = self.TablePanel:AddColumn("Player ID", 4)


    local WidthLog = self.TablePanel:GetWide() - ( 52 + 124 + 63 )

    self.List["ID"]:SetWidth( 52 )
    self.List["Log"]:SetWidth( WidthLog )
    self.List["Date"]:SetWidth( 128 )
    self.List["PlayerID"]:SetWidth( 63 )

    self.List["ID"]:SetName(Gemini:GetPhrase("Logger.Column.ID"))
    self.List["Log"]:SetName(Gemini:GetPhrase("Logger.Column.Log"))
    self.List["Date"]:SetName(Gemini:GetPhrase("Logger.Column.Date"))
    self.List["PlayerID"]:SetName(Gemini:GetPhrase("Logger.Column.PlayerID"))

    self.List["ID"]:SetDescending( true )
    self.TablePanel.CurrentColumn = self.List["ID"]
end

function MODULE:SetAsynchronousLogs(Active)
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

    self:AskLogs(LogsAmount, nil, nil, true)
    if ( EnableAsync == true ) then
        self:SetAsynchronousLogs(true)
    end
end

function MODULE:OnLostFocus()
    self:SetAsynchronousLogs(false)
end

--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:AskLogs", function(len)
    local Success = net.ReadBool()
    local Logs = {}

    if ( Success == true ) then
        local CompressedSize = net.ReadUInt(Gemini.Util.DefaultNetworkUIntBig)
        local Data = net.ReadData(CompressedSize)

        Logs = util.JSONToTable(util.Decompress(Data))
    end

    MODULE:RetrieveNetwork(Success, Logs)
end)

net.Receive("Gemini:ReplicateLog", function(len)
    if ( Gemini:GetConfig("AsyncLogs", "Logger") == false ) then return end

    local ID = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local Log = net.ReadString()
    local Time = net.ReadString()
    local User = net.ReadString()

    MODULE:AddNewLog(ID, Log, Time, User)
end)

hook.Add("Gemini:SendMessage", "Gemini:Logger.SendMessage", function(Message)
    MODULE:SetMessageLog(string.format(Message))
end)

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate(Gemini:GetPhrase("Logger"), MODULE)