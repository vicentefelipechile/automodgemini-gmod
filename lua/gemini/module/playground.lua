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

local ScrollbarPaint = function(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )

    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverLineColor )
    end
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
    self.PromptPanel.PromptHistory:Clear()

    -- if not Gemini:CanUse("gemini_playground") then return end

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
    if not IsValid(self.PromptPanel.PromptHistory) then return end
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

        self.PromptPanel.PromptHistory:AddItem(HorizontalLine)
    else
        -- Pick last item
        local LastItem = self.PromptPanel.PromptHistory:GetCanvas():GetChildren()[1]
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
        local HowManyLines = math.ceil( PromptText:GetContentSize() / 15 ) * 2.2
        local HowManyBreaklines = #( string.Explode("\n", Text) )
        local NewHeight = HowManyLines + ( HowManyBreaklines * 19.2 )

        PromptText:SetTall(NewHeight)

        PromptRightPanel:SizeToChildren(false, true)
        PromptMessage:SizeToChildren(false, true)

        timer.Simple(0.1, function()
            if IsValid(PromptMessage) then
                self.PromptPanel.PromptHistory:ScrollToChild(PromptMessage)
            end
        end)
    end)

    self.PromptPanel.PromptHistory:AddItem(PromptMessage)

    -- HorizontalLine
    local HorizontalLine = vgui.Create("DPanel")
    HorizontalLine:DockMargin(5, 0, 5, 0)
    HorizontalLine:Dock(TOP)
    HorizontalLine:SetTall(1)
    HorizontalLine.Paint = Gemini.Util.ReturnNoneFunction

    self.PromptPanel.PromptHistory:AddItem(HorizontalLine)

    table.insert(PromptHistory, { ["Role"] = Role, ["Text"] = Text })
end

function MODULE:SendMessagePrompt(Text)
    local Status = net.Start("Gemini:PlaygroundMakeRequest")
        net.WriteString(Text)
    net.SendToServer()

    if ( Status == true ) then
        LastRequest = CurTime()
        self:SetMessageLog( Gemini:GetPhrase("Playground.Prompt.Sended") )

        self.PromptPanel.Input:SetDisabled(true)
    end
end

--[[------------------------
           Logger
------------------------]]--

function MODULE:AskLogs()
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
    if IsValid(self.HistoryPanel) then
        self.HistoryPanel:Clear()

        for k, Data in ipairs(Logs) do
            self:AddNewLog(Data["geminilog_id"], Data["geminilog_log"])
        end

        self.HistoryPanel:SortByColumn( self.HistoryPanel.CurrentColumn:GetColumnID(), true )
    end
end

function MODULE:AddNewLog(ID, Log)
    if IsValid(self.HistoryPanel) then
        self.HistoryPanel:AddLine(ID, Log):SetSortValue(1, tonumber(ID))
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

    self.OutputMSG = vgui.Create("DTextEntry", OurTab)
    self.OutputMSG:SetSize(OurTab:GetWide() - 68, 20)
    self.OutputMSG:SetPos(518, OurTab:GetTall() - 68)
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

    if ( Gemini:GetConfig("PlayerTarget", "Playground") ~= 0 ) then
        self.SettingsPanel.PlayerIDInput:SetValue( Gemini:GetConfig("PlayerTarget", "Playground") )
    end

    self.SettingsPanel.PlayerIDInput.OnEnter = function(SubSelf)
        local PlayerID = SubSelf:GetInt() or 0
        Gemini:SetConfig("PlayerTarget", "Playground", PlayerID)
    end

    self.SettingsPanel.PlayerIDInput.OnLoseFocus = function(SubSelf)
        local PlayerID = SubSelf:GetInt() or 0
        Gemini:SetConfig("PlayerTarget", "Playground", PlayerID)
    end

    self.SettingsPanel.MaxLogsLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.MaxLogsLabel:SetText( Gemini:GetPhrase("Logger.MaxLogs") )
    self.SettingsPanel.MaxLogsLabel:Dock(TOP)
    self.SettingsPanel.MaxLogsLabel:SetContentAlignment(5)
    self.SettingsPanel.MaxLogsLabel:DockMargin( 10, 10, 10, 0 )

    self.SettingsPanel.MaxLogs = vgui.Create("DNumberWang", self.SettingsPanel)
    self.SettingsPanel.MaxLogs:SetMin(1)
    self.SettingsPanel.MaxLogs:SetValue( Gemini:GetConfig("MaxLogs", "Playground") )
    self.SettingsPanel.MaxLogs:Dock(TOP)
    self.SettingsPanel.MaxLogs:DockMargin( 10, 0, 10, 0 )

    self.SettingsPanel.MaxLogs.OnValueChanged = function(_, value)
        Gemini:SetConfig("MaxLogs", "Playground", value)
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
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin:SetValue( Gemini:GetConfig("BetweenLogsMin", "Playground") )
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin:Dock(LEFT)

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax = vgui.Create("DNumberWang", self.SettingsPanel.BetweenLogsInputs)
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax:SetMin(2)
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax:SetValue( Gemini:GetConfig("BetweenLogsMax", "Playground") )
    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax:Dock(RIGHT)

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMin.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMin", "Playground", value)
    end

    self.SettingsPanel.BetweenLogsInputs.BetweenLogsMax.OnValueChanged = function(_, value)
        Gemini:SetConfig("BetweenLogsMax", "Playground", value)
    end

    self.SettingsPanel.EnableBetweenLogsLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.EnableBetweenLogsLabel:SetText( Gemini:GetPhrase("Logger.EnableBetweenLogs") )
    self.SettingsPanel.EnableBetweenLogsLabel:Dock(TOP)
    self.SettingsPanel.EnableBetweenLogsLabel:SetContentAlignment(5)
    self.SettingsPanel.EnableBetweenLogsLabel:DockMargin( 10, 5, 10, 0 )

    self.SettingsPanel.EnableBetweenLogs = vgui.Create("DCheckBox", self.SettingsPanel)
    self.SettingsPanel.EnableBetweenLogs:SetValue( Gemini:GetConfig("BetweenLogs", "Playground") )
    self.SettingsPanel.EnableBetweenLogs:Dock(TOP)
    self.SettingsPanel.EnableBetweenLogs:DockMargin( 10, 0, 10, 0 )
    self.SettingsPanel.EnableBetweenLogs:SetTall( 20 )
    self.SettingsPanel.EnableBetweenLogs.Paint = ButtonBooleanPaint

    self.SettingsPanel.EnableBetweenLogs.OnChange = function(_, value)
        Gemini:SetConfig("BetweenLogs", "Playground", value)
    end

    self.SettingsPanel.AskLogsButton = vgui.Create("DButton", self.SettingsPanel)
    self.SettingsPanel.AskLogsButton:SetText( Gemini:GetPhrase("Logger.RequestLogs") )
    self.SettingsPanel.AskLogsButton:Dock(TOP)
    self.SettingsPanel.AskLogsButton:DockMargin( 10, 20, 10, 2 )

    self.SettingsPanel.AskLogsButton.DoClick = function()
        self:AskLogs()
    end

    self.SettingsPanel.ClearLogsButton = vgui.Create("DButton", self.SettingsPanel)
    self.SettingsPanel.ClearLogsButton:SetText( Gemini:GetPhrase("Logger.ClearLogs") )
    self.SettingsPanel.ClearLogsButton:Dock(TOP)
    self.SettingsPanel.ClearLogsButton:DockMargin( 10, 2, 10, 10 )

    self.SettingsPanel.ClearLogsButton.DoClick = function()
        self:UpdateTable({})
        self:SetMessageLog( Gemini:GetPhrase("Logger.ClearedLogs") )
    end

    self.SettingsPanel.AttachContextLabel = vgui.Create("DLabel", self.SettingsPanel)
    self.SettingsPanel.AttachContextLabel:SetText( Gemini:GetPhrase("Playground.AttachContext") )
    self.SettingsPanel.AttachContextLabel:Dock(TOP)
    self.SettingsPanel.AttachContextLabel:SetContentAlignment(5)
    self.SettingsPanel.AttachContextLabel:DockMargin( 10, 15, 10, 0 )

    self.SettingsPanel.AttachContext = vgui.Create("DCheckBox", self.SettingsPanel)
    self.SettingsPanel.AttachContext:SetValue( Gemini:GetConfig("AttachContext", "Playground") )
    self.SettingsPanel.AttachContext:Dock(TOP)
    self.SettingsPanel.AttachContext:DockMargin( 10, 0, 10, 0 )
    self.SettingsPanel.AttachContext:SetTall( 20 )
    self.SettingsPanel.AttachContext.Paint = ButtonBooleanPaint

    self.SettingsPanel.AttachContext.OnChange = function(_, value)
        Gemini:SetConfig("AttachContext", "Playground", value)
    end

    self.SettingsPanel.ResetPromptButton = vgui.Create("DButton", self.SettingsPanel)
    self.SettingsPanel.ResetPromptButton:SetText( Gemini:GetPhrase("Playground.Prompt.Reset") )
    self.SettingsPanel.ResetPromptButton:Dock(TOP)
    self.SettingsPanel.ResetPromptButton:DockMargin( 10, 10, 10, 10 )

    self.SettingsPanel.ResetPromptButton.DoClick = function()
        self:ResetPrompt()
        self.PromptPanel.Input:SetDisabled(false)
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

    --[[------------------------
           Prompt Panel
    ------------------------]]--

    self.PromptPanel = vgui.Create("DPanel", OurTab)
    self.PromptPanel:SetSize(320, OutputY + 4)
    self.PromptPanel:SetPos( self.SettingsPanel:GetWide() + PanelOffset, 15 )
    self.PromptPanel.Paint = BackgroundPaint

    self.PromptPanel.Title = vgui.Create("DLabel", self.PromptPanel)
    self.PromptPanel.Title:SetText( Gemini:GetPhrase("Playground.Prompt") )
    self.PromptPanel.Title:Dock(TOP)
    self.PromptPanel.Title:SetFont("Frutiger:Normal")
    self.PromptPanel.Title:SetContentAlignment(5)
    self.PromptPanel.Title:DockMargin( 10, 10, 10, 0 )

    self.PromptPanel.PromptHistory = vgui.Create("DScrollPanel", self.PromptPanel)
    self.PromptPanel.PromptHistory:Dock(FILL)
    self.PromptPanel.PromptHistory:DockMargin( 10, 10, 10, 4 )
    self.PromptPanel.PromptHistory.Paint = BackgroundPaint

    self.PromptPanel.Prompt = vgui.Create("DPanel", self.PromptPanel)
    self.PromptPanel.Prompt:Dock(BOTTOM)
    self.PromptPanel.Prompt:SetTall( 30 )
    self.PromptPanel.Prompt:DockMargin( 10, 4, 10, 10 )
    self.PromptPanel.Prompt.Paint = Gemini.Util.EmptyFunction

    self.PromptPanel.Send = vgui.Create("DButton", self.PromptPanel.Prompt)
    self.PromptPanel.Send:SetText(">")
    self.PromptPanel.Send:Dock(RIGHT)
    self.PromptPanel.Send:DockMargin( 10, 0, 0, 0 )
    self.PromptPanel.Send:SetTall( 30 )
    self.PromptPanel.Send:SetWide( 30 )

    self.PromptPanel.Input = vgui.Create("DTextEntry", self.PromptPanel.Prompt)
    self.PromptPanel.Input:SetPlaceholderText( Gemini:GetPhrase("Playground.Prompt.Placeholder") )
    self.PromptPanel.Input:Dock(FILL)

    self.PromptPanel.Send.DoClick = function(InputSelf)
        local Text = self.PromptPanel.Input:GetText()
        self.PromptPanel.Input:SetText("")

        Text = string.Trim(Text)
        if Text == "" then return end

        self:AddMessagePrompt("user", Text)
        self:SendMessagePrompt(Text)
    end

    --[[------------------------
           Context Panel
    ------------------------]]--

    self.HistoryPanel = vgui.Create("DListView", OurTab)
    self.HistoryPanel:SetSize(( OurTab:GetWide() - 28 ) - ( self.PromptPanel:GetX() + self.PromptPanel:GetWide() + 8 ), OurTab:GetTall() - 92)
    self.HistoryPanel:SetPos( self.PromptPanel:GetX() + self.PromptPanel:GetWide() + 8, 15 )
    self.HistoryPanel:SetMultiSelect(false)
    self.HistoryPanel:SetHeaderHeight(20)

    self.OutputMSG:SetWide(self.HistoryPanel:GetWide())

    self.List = {}

    self.List["ID"] = self.HistoryPanel:AddColumn("ID")
    self.List["Log"] = self.HistoryPanel:AddColumn("Log")

    self.List["ID"]:SetName(Gemini:GetPhrase("Logger.Column.ID"))
    self.List["Log"]:SetName(Gemini:GetPhrase("Logger.Column.Log"))

    self.List["ID"]:SetWidth( 48 )
    self.List["Log"]:SetWidth( self.HistoryPanel:GetWide() - 52 )

    self.HistoryPanel.CurrentColumn = self.List["ID"]

    local NewPostOutputX = self.SettingsPanel:GetWide() + self.PromptPanel:GetWide() + PanelOffset + 8
    self.OutputMSG:SetX(NewPostOutputX)
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
    if IsValid(MODULE.PromptPanel.Input) then
        MODULE.PromptPanel.Input:SetDisabled(false)
    end
end)

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate(Gemini:GetPhrase("Playground"), MODULE)