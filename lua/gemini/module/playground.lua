--[[----------------------------------------------------------------------------
                     Google Gemini Automod - Playground API
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/bug.png" }
local BlackColor = COLOR_BLACK
local GrayColor = COLOR_GRAY

local AlphaColor = Color(255, 255, 255, 100)

local PanelOffset = 20

local AllowedRoles = {
    ["user"] = true,
    ["model"] = true
}

local UserIcon = "icon16/user.png"
local ModelIcon = "icon16/server.png"
-- local ContextIcon = "icon16/application_view_detail.png"

local PromptHistory = {}
local PromptExists = false

local LastRequest = 0

local NewGetContentSize = function(self)
    surface.SetFont( self:GetFont() )
    return surface.GetTextSize( self:GetText() )
end

--[[------------------------
           Convars
------------------------]]--

Gemini:CreateConfig("PlayerTarget", "Playground", Gemini.VERIFICATION_TYPE.number, 0)
Gemini:CreateConfig("MaxLogs", "Playground", Gemini.VERIFICATION_TYPE.number, 10)
Gemini:CreateConfig("BetweenLogs", "Playground", Gemini.VERIFICATION_TYPE.bool, false)
Gemini:CreateConfig("BetweenLogsMin", "Playground", Gemini.VERIFICATION_TYPE.number, 5)
Gemini:CreateConfig("BetweenLogsMax", "Playground", Gemini.VERIFICATION_TYPE.number, 10)
Gemini:CreateConfig("AttachContext", "Playground", Gemini.VERIFICATION_TYPE.bool, false)

--[[------------------------
        Prompt Logic
------------------------]]--

function MODULE:ResetPrompt()
    table.Empty(PromptHistory)
    self.PromptHistory:Clear()

    if not Gemini:CanUse("gemini_playground") then return end

    net.Start("Gemini:PlaygroundResetRequest")
    net.SendToServer()
end

function MODULE:PoblatePrompt()
    if PromptExists then return end

    local PromptHistoryCopy = table.Copy(PromptHistory)
    table.Empty(PromptHistory)

    for i, v in ipairs(PromptHistoryCopy) do
        self:AddMessagePrompt(v.Role, v.Text)
    end

    PromptExists = true
end

function MODULE:AddMessagePrompt(Role, Text)
    if not IsValid(self.PromptHistory) then return end
    if not AllowedRoles[Role] then return end
    Text = string.Trim(Text)

    -- BreakLine
    if ( #PromptHistory ~= 0 ) then
        local HorizontalLine = vgui.Create("DPanel")
        HorizontalLine:DockMargin(8, 0, 8, 0)
        HorizontalLine:Dock(TOP)
        HorizontalLine:SetTall(1)
        HorizontalLine.Paint = function(_, w, h)
            draw.RoundedBox(0, 0, 0, w, h, GrayColor)
        end

        self.PromptHistory:AddItem(HorizontalLine)
    else
        -- Pick last item
        local LastItem = self.PromptHistory:GetCanvas():GetChildren()[1]
        if IsValid(LastItem) then
            LastItem.Paint = function(_, w, h)
                draw.RoundedBox(0, 0, 0, w, h, BlackColor)
            end
        end
    end

    local PromptMessage = vgui.Create("DPanel")
    PromptMessage:DockMargin(5, 5, 5, 5)
    PromptMessage:Dock(TOP)
    -- PromptMessage.Paint = Gemini.Util.ReturnNoneFunction

    local PromptLeftPanel = vgui.Create("DPanel", PromptMessage)
    PromptLeftPanel:Dock(LEFT)
    PromptLeftPanel:SetWide(20)
    PromptLeftPanel.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, GrayColor)
    end

    local PromptIcon = vgui.Create("DImage", PromptLeftPanel)
    PromptIcon:SetImage( Role == "user" and UserIcon or ModelIcon )
    PromptIcon:SizeToContents()
    PromptIcon:SetPos( PromptLeftPanel:GetWide() / 2 - PromptIcon:GetWide() / 2, PromptLeftPanel:GetTall() / 2 - PromptIcon:GetTall() / 2 )

    local PromptRightPanel = vgui.Create("DPanel", PromptMessage)
    PromptRightPanel:Dock(FILL)
    PromptRightPanel.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, AlphaColor)
    end

    local PromptText = vgui.Create("DLabel", PromptRightPanel)
    PromptText.GetContentSize = NewGetContentSize
    PromptText:SetWrap(true)
    PromptText:SetText(Text)
    PromptText:Dock(FILL)
    PromptText:DockMargin(8, 8, 8, 8)
    PromptText:SetTextColor(BlackColor)

    timer.Simple(0, function()
        -- Si el texto supera los 17 caracteres, suma 20px al alto del panel
        -- What is going on the server?
        local HowManyLines = math.ceil( PromptText:GetContentSize() / 16 ) * 2.2
        local HowManyBreaklines = #( string.Explode("\n", Text) )
        local NewHeight = HowManyLines + ( HowManyBreaklines * 19.2 )

        PromptText:SetTall(NewHeight)

        PromptRightPanel:SizeToChildren(false, true)
        PromptMessage:SizeToChildren(false, true)

        timer.Simple(0.1, function()
            if IsValid(PromptMessage) then
                self.PromptHistory:ScrollToChild(PromptMessage)
            end
        end)
    end)

    self.PromptHistory:AddItem(PromptMessage)

    -- HorizontalLine
    local HorizontalLine = vgui.Create("DPanel")
    HorizontalLine:DockMargin(5, 0, 5, 0)
    HorizontalLine:Dock(TOP)
    HorizontalLine:SetTall(1)
    HorizontalLine.Paint = Gemini.Util.ReturnNoneFunction

    self.PromptHistory:AddItem(HorizontalLine)

    table.insert(PromptHistory, { ["Role"] = Role, ["Text"] = Text })
end

function MODULE:SendMessagePrompt(Text)
    local Status = net.Start("Gemini:PlaygroundMakeRequest")
        net.WriteString(Text)
    net.SendToServer()

    if ( Status == true ) then
        LastRequest = CurTime()
        self:SetMessageLog( Gemini:GetPhrase("Playground.Prompt.Sended") )

        self.PromptInputSend:SetDisabled(true)
    end
end

--[[------------------------
           Logger
------------------------]]--

function MODULE:AskLogs(Limit, Target, IsPlayer, Between)
    Target = Target or 0
    IsPlayer = IsPlayer or false

    self.LAST_REQUEST = CurTime()

    local Status = net.Start("Gemini:AskLogs:Playground")
    net.SendToServer()

    if ( Status == true ) then
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

function MODULE:UpdateTable(Logs)
    if IsValid(self.TablePanel) then
        self.TablePanel:Clear()

        for k, Data in ipairs(Logs) do
            self:AddNewLog(Data["geminilog_id"], Data["geminilog_log"])
        end

        self.TablePanel:SortByColumn( self.TablePanel.CurrentColumn:GetColumnID(), true )
    end
end

function MODULE:AddNewLog(ID, Log)
    if IsValid(self.TablePanel) then
        self.TablePanel:AddLine(ID, Log):SetSortValue(1, tonumber(ID))
    end
end

--[[------------------------
        Main Function
------------------------]]--

function MODULE:SetMessageLog(Message)
    if IsValid(self.OutputMSG) then
        self.OutputMSG:SetText(Message)
    end
end

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_playground") then return false end

    --[[------------------------
           Output Message
    ------------------------]]--

    local OutputMSG = vgui.Create("DTextEntry", OurTab)
    OutputMSG:SetSize(OurTab:GetWide() - 68, 20)
    OutputMSG:SetPos(518, OurTab:GetTall() - 68)
    OutputMSG:SetEditable(false)

    self.OutputMSG = OutputMSG

    local _, OutputY = OutputMSG:GetPos()

    --[[------------------------
           Settings Panel
    ------------------------]]--

    local SettingsPanel = vgui.Create("DPanel", OurTab)
    SettingsPanel:SetSize(170, OutputY + 4)
    SettingsPanel:SetPos(10, 15)

    local SettingsLabel = vgui.Create("DLabel", SettingsPanel)
    SettingsLabel:SetText( Gemini:GetPhrase("Config") )
    SettingsLabel:SetTextColor(BlackColor)
    SettingsLabel:SetFont("Frutiger:Normal")
    SettingsLabel:SizeToContents()
    SettingsLabel:SetPos(SettingsPanel:GetWide() / 2 - SettingsLabel:GetWide() / 2, 6)

    local PlayerIDInput = vgui.Create("DTextEntry", SettingsPanel)
    PlayerIDInput:SetSize(SettingsPanel:GetWide() - 20, 20)
    PlayerIDInput:SetPos(10, 40)
    PlayerIDInput:SetNumeric(true)
    PlayerIDInput:SetPlaceholderText( Gemini:GetPhrase("Logger.PlayerID") )

    if ( Gemini:GetConfig("PlayerTarget", "Playground") ~= 0 ) then
        PlayerIDInput:SetValue( Gemini:GetConfig("PlayerTarget", "Playground") )
    end

    PlayerIDInput.OnEnter = function(SubSelf)
        local PlayerID = tonumber(SubSelf:GetValue()) or 0
        Gemini:SetConfig("PlayerTarget", "Playground", PlayerID)
    end

    PlayerIDInput.OnLoseFocus = function(SubSelf)
        local PlayerID = tonumber(SubSelf:GetValue()) or 0
        Gemini:SetConfig("PlayerTarget", "Playground", PlayerID)
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
    MaxLogs:SetMax(1000)
    MaxLogs:SetValue( Gemini:GetConfig("MaxLogs", "Playground") )

    MaxLogs.OnValueChanged = function(_, value)
        Gemini:SetConfig("MaxLogs", "Playground", value)
    end

    local BetweenLogsLabel = vgui.Create("DLabel", SettingsPanel)
    BetweenLogsLabel:SetText( Gemini:GetPhrase("Logger.BetweenLogs") )
    BetweenLogsLabel:SetTextColor(BlackColor)
    BetweenLogsLabel:SetFont("Frutiger:Small")
    BetweenLogsLabel:SizeToContents()
    BetweenLogsLabel:SetPos(SettingsPanel:GetWide() / 2 - BetweenLogsLabel:GetWide() / 2, 110)

    local BetweenLogsMin = vgui.Create("DNumberWang", SettingsPanel)
    BetweenLogsMin:SetUpdateOnType(false)
    BetweenLogsMin:SetSize( ( SettingsPanel:GetWide() - 20 ) / 2 - 4, 20)
    BetweenLogsMin:SetPos(10, 124)
    BetweenLogsMin:SetMin(1)
    BetweenLogsMin:SetMax(1000000)
    BetweenLogsMin:SetValue( Gemini:GetConfig("BetweenLogsMin", "Playground") )

    local BetweenLogsMax = vgui.Create("DNumberWang", SettingsPanel)
    BetweenLogsMax:SetUpdateOnType(false)
    BetweenLogsMax:SetSize( ( SettingsPanel:GetWide() - 20 ) / 2 - 4, 20)
    BetweenLogsMax:SetPos( ( SettingsPanel:GetWide() - 20 ) / 2 + 14, 124)
    BetweenLogsMax:SetMin(1)
    BetweenLogsMax:SetMax(1000000)
    BetweenLogsMax:SetValue( Gemini:GetConfig("BetweenLogsMax", "Playground") )

    BetweenLogsMin.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMin", "Playground", value)

        if ( BetweenLogsMax:GetValue() < value ) then
            BetweenLogsMax:SetValue(value)
        end
    end

    BetweenLogsMax.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMax", "Playground", value)

        if ( BetweenLogsMin:GetValue() > value ) then
            BetweenLogsMin:SetValue(value)
        end
    end

    local EnableBetweenLogs = vgui.Create("DCheckBoxLabel", SettingsPanel)
    EnableBetweenLogs:SetSize(SettingsPanel:GetWide() - 20, 20)
    EnableBetweenLogs:SetPos(10, 150)
    EnableBetweenLogs:SetText( Gemini:GetPhrase("Logger.EnableBetweenLogs") )
    EnableBetweenLogs:SetTextColor(BlackColor)
    EnableBetweenLogs:SetValue( Gemini:GetConfig("BetweenLogs", "Playground") )

    EnableBetweenLogs.OnChange = function(_, value)
        Gemini:SetConfig("BetweenLogs", "Playground", value)
    end

    self.IsBetweenLogs = EnableBetweenLogs

    local AskLogsButton = vgui.Create("DButton", SettingsPanel)
    AskLogsButton:SetSize(SettingsPanel:GetWide() - 20, 20)
    AskLogsButton:SetPos(10, 180)
    AskLogsButton:SetText( Gemini:GetPhrase("Logger.RequestLogs") )
    AskLogsButton:SetFont("Frutiger:Small")

    AskLogsButton.DoClick = function()
        local PlayerID = Gemini:GetConfig("PlayerTarget", "Playground")

        PlayerID = ( PlayerID ~= 0 ) and PlayerID or nil

        local LogsMax = Gemini:GetConfig("MaxLogs", "Playground")
        local LogsAmount = math.min(LogsMax, 200)
        local Between = Gemini:GetConfig("BetweenLogs", "Playground")

        self:AskLogs(LogsAmount, PlayerID, PlayerID ~= nil, Between)
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

    local AttachContextCheckbox = vgui.Create("DCheckBoxLabel", SettingsPanel)
    AttachContextCheckbox:SetSize(SettingsPanel:GetWide() - 20, 20)
    AttachContextCheckbox:SetPos(10, 250)
    AttachContextCheckbox:SetText( Gemini:GetPhrase("Playground.AttachContext") )
    AttachContextCheckbox:SetTextColor(BlackColor)
    AttachContextCheckbox:SetValue( Gemini:GetConfig("AttachContext", "Playground") )

    AttachContextCheckbox.OnChange = function(_, value)
        Gemini:SetConfig("AttachContext", "Playground", value)
    end

    self.HasContext = AttachContextCheckbox


    local ResetPromptButton = vgui.Create("DButton", SettingsPanel)
    ResetPromptButton:SetSize(SettingsPanel:GetWide() - 20, 20)
    ResetPromptButton:SetPos(10, 280)
    ResetPromptButton:SetText( Gemini:GetPhrase("Playground.Prompt.Reset") )
    ResetPromptButton:SetFont("Frutiger:Small")

    ResetPromptButton.DoClick = function()
        self:ResetPrompt()
        self.PromptInputSend:SetDisabled(false)
    end

    --[[------------------------
            Prompt Panel
    ------------------------]]--

    local PromptPanel = vgui.Create("DPanel", OurTab)
    PromptPanel:SetSize(320, OutputY + 4)
    PromptPanel:SetPos( SettingsPanel:GetWide() + PanelOffset, 15 )

    local PromptTitlePanel = vgui.Create("DPanel", PromptPanel)
    PromptTitlePanel:SetSize(PromptPanel:GetWide() - 10, 30)
    PromptTitlePanel:SetPos(5, 5)
    PromptTitlePanel.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, BlackColor)
    end

    local PromptTitleLabel = vgui.Create("DLabel", PromptTitlePanel)
    PromptTitleLabel:SetText( Gemini:GetPhrase("Playground.Prompt") )
    PromptTitleLabel:SetFont("Frutiger:Normal")
    PromptTitleLabel:SizeToContents()
    PromptTitleLabel:SetPos(PromptTitlePanel:GetWide() / 2 - PromptTitleLabel:GetWide() / 2, 6)

    local PromptHistoryPanel = vgui.Create("DScrollPanel", PromptPanel)
    PromptHistoryPanel:SetSize(PromptPanel:GetWide() - 10, PromptPanel:GetTall() - 83)
    PromptHistoryPanel:SetPos(5, 40)
    PromptHistoryPanel.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, BlackColor)
    end

    self.PromptHistory = PromptHistoryPanel

    local PromptInput = vgui.Create("DTextEntry", PromptPanel)
    PromptInput:SetSize(PromptPanel:GetWide() - 42, 28)
    PromptInput:SetPos(5, PromptPanel:GetTall() - 38)
    PromptInput:SetFont("Frutiger:Small")
    PromptInput:SetPlaceholderText( Gemini:GetPhrase("Playground.Prompt.Placeholder") )

    local PromptInputSend = vgui.Create("DButton", PromptPanel)
    PromptInputSend:SetSize(28, 28)
    PromptInputSend:SetPos(PromptPanel:GetWide() - 33, PromptPanel:GetTall() - 38)
    PromptInputSend:SetText(">")
    PromptInputSend.DoClick = function(InputSelf)
        local Text = PromptInput:GetText()
        PromptInput:SetText("")

        Text = string.Trim(Text)
        if Text == "" then return end

        self:AddMessagePrompt("user", Text)
        self:SendMessagePrompt(Text)
    end

    self.PromptInputSend = PromptInputSend

    --[[------------------------
            Context Panel
    ------------------------]]--

    local PromptX = PromptPanel:GetPos()
    local PromptWide = PromptPanel:GetWide()

    local HistoryPanel = vgui.Create("DListView", OurTab)
    HistoryPanel:SetSize(( OurTab:GetWide() - 28 ) - ( PromptX + PromptWide + 8 ), OurTab:GetTall() - 92)
    HistoryPanel:SetPos( PromptX + PromptWide + 8, 15 )
    HistoryPanel:SetMultiSelect(false)
    HistoryPanel:SetHeaderHeight(20)

    OutputMSG:SetWide(HistoryPanel:GetWide())

    self.List = {}
    self.List["ID"] = HistoryPanel:AddColumn("ID")
    self.List["Log"] = HistoryPanel:AddColumn("Log")

    self.List["ID"]:SetWidth( 48 )
    self.List["Log"]:SetWidth( HistoryPanel:GetWide() - 52 )

    HistoryPanel.CurrentColumn = self.List["ID"]

    self.TablePanel = HistoryPanel
end

function MODULE:OnFocus()
    self:PoblatePrompt()
end

function MODULE:OnLostFocus()
    self:ResetPrompt()
end

--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:AskLogs:Playground", function(len)
    local Success = net.ReadBool()
    local Message = net.ReadString()
    local Logs = {}

    if ( Success == true ) then
        local CompressedSize = net.ReadUInt(Gemini.Util.DefaultNetworkUIntBig)
        local Data = net.ReadData(CompressedSize)

        Logs = util.JSONToTable(util.Decompress(Data))
    end

    MODULE:RetrieveNetwork(Success, Message, Logs)
end)

net.Receive("Gemini:PlaygroundSendMessage", function(len)
    local Message = net.ReadString()
    local Argument = net.ReadString()

    Message = Argument ~= "" and string.format( Gemini:GetPhrase(Message), Argument ) or Gemini:GetPhrase(Message)

    MODULE:SetMessageLog( Message )
end)

net.Receive("Gemini:PlaygroundMakeRequest", function(len)
    local CompressSize = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local CompressData = net.ReadData(CompressSize)

    local Message = util.Decompress(CompressData)
    MODULE:AddMessagePrompt("model", Message)

    MODULE:SetMessageLog( string.format( Gemini:GetPhrase("Playground.Prompt.Received"), math.Round(CurTime() - LastRequest , 2) ) )
    if IsValid(MODULE.PromptInputSend) then
        MODULE.PromptInputSend:SetDisabled(false)
    end
end)

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate(Gemini:GetPhrase("Playground"), MODULE)