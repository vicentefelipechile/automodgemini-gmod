--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Train Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/wrench.png" }

local BackgroundColor = Color( 45, 45, 45 )
local OutlineColor = Color( 70, 70, 70, 200)
local OutlineColorOpaque = Color( 70, 70, 70 )
local HoverLineColor = Color( 1, 129, 123)

local OutlineWidth = 3

local function SmallBackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, 1, 1, w - 2, h - 2, BackgroundColor )
end

local function BorderBackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, OutlineWidth, OutlineWidth, w - (OutlineWidth * 2), h - (OutlineWidth * 2), BackgroundColor )
end

local function SubDComboBoxPaint( SubSubSelf, w, h )
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColorOpaque )
end

local function DComboBoxPaint( SubSelf, SubPanel )
    SubPanel.Paint = SubDComboBoxPaint
end

local ScrollbarPaint = function(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )

    if self:IsHovered() then
        draw.RoundedBox( 0, 0, 0, w, h, HoverLineColor )
    end
end

local ALL_TRAINS = {}
local GUILTY = true
local NOT_GUILTY = false

--[[------------------------
       Train Functions
------------------------]]--

function MODULE:GetTrainID()
end

function MODULE:AddTrainButton(DataTrain)
    if IsValid(self.TrainingList.List) then
        local Train = self.TrainingList.List:Add("DButton")
        Train:SetSize(self.TrainingList.List:GetWide(), 28)
        Train:SetText(DataTrain["train_name"])
        Train:Dock(TOP)
        Train:DockMargin(9, 4, 9, 0)
        Train:SetIcon("icon16/page_white_edit.png")
        Train.DoClick = function()
            self:SetDataTrain(DataTrain["train_playerid"], DataTrain["train_start"], DataTrain["train_end"])

        end
    end
end

function MODULE:ClearDataTrain()
    if IsValid(self.TrainingMenu) then
        self.TrainingMenu.InputPlayer:SetText("")
        self.TrainingMenu.InputLogStart:SetText("")
        self.TrainingMenu.InputLogEnd:SetText("")

        self.TrainingMenu.Result:ChooseOptionID(2)
        self.TrainingMenu.ResultDescription:SetText("")
        self.TrainingMenu.InputName:SetText("")
    end
end

function MODULE:SetDataTrain(PlayerID, LogStart, LogEnd)
    if IsValid(self.TrainingMenu) then
        self.TrainingMenu.InputPlayer:SetText(PlayerID)
        self.TrainingMenu.InputLogStart:SetText(LogStart)
        self.TrainingMenu.InputLogEnd:SetText(LogEnd)
    end
end

function MODULE:UpdateTrainList()
    if table.IsEmpty(ALL_TRAINS) then return end
    if not IsValid(self.TrainingList.List) then return end

    for k, Data in ipairs(ALL_TRAINS) do
        local Train = self.TrainingList.List:Add("DButton")
        Train:SetSize(self.TrainingList.List:GetWide(), 28)
        Train:SetText(Data["train_name"])
        Train:Dock(TOP)
        Train:DockMargin(9, 4, 9, 0)
        Train:SetIcon("icon16/page_white_edit.png")
        Train.DoClick = function()
            self:SetDataTrain(Data["train_playerid"], Data["train_start"], Data["train_end"])
            self.TrainingMenu.Result:ChooseOptionID(Data["train_result"] and 1 or 2)
            self.TrainingMenu.ResultDescription:SetText(Data["train_description"])
            self.TrainingMenu.InputName:SetText(Data["train_name"])

            self.TrainingMenu.GetLogs:DoClick()
        end
    end

    table.Empty(ALL_TRAINS)
end

--[[------------------------
           Logger
------------------------]]--

function MODULE:UpdateTable(Logs)
    if IsValid(self.HistoryPanel) then
        self.HistoryPanel:Clear()

        for k, Data in ipairs(Logs) do
            self.HistoryPanel:AddLine(Data["geminilog_log"])
        end

        self:SetOutputMSG( string.format(Gemini:GetPhrase("Logger.LogsSended"), #Logs, math.Round(CurTime() - self.TIME_REQUEST, 2)) )
    end
end

--[[------------------------
       Main Functions
------------------------]]--

function MODULE:SetOutputMSG(Text)
    if IsValid(self.OutputMSG) then
        self.OutputMSG:SetText(Text)
    end
end

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_train") then return false end

    self.TIME_REQUEST = 0

    --[[------------------------
          Previous Training
    ------------------------]]--

    self.TrainingList = vgui.Create("DPanel", OurTab)
    self.TrainingList:SetSize(200, OurTab:GetTall() - 82)
    self.TrainingList:SetPos(10, 35)
    self.TrainingList.Paint = BorderBackgroundPaint

    self.TrainingTitle = vgui.Create("DLabel", OurTab)
    self.TrainingTitle:SetSize(self.TrainingList:GetWide(), 20)
    self.TrainingTitle:SetPos(10, 10)
    self.TrainingTitle:SetFont("Frutiger:Normal")
    self.TrainingTitle:SetText(Gemini:GetPhrase("Train.PreviousTraining"))
    self.TrainingTitle:SetContentAlignment(5)

    self.TrainingList.List = vgui.Create("DScrollPanel", self.TrainingList)
    self.TrainingList.List:SetSize(self.TrainingList:GetWide(), self.TrainingList:GetTall())
    self.TrainingList.List:SetPos(0, 0)

    -- New train
    self.TrainingList.NewTrain = self.TrainingList.List:Add("DButton")
    self.TrainingList.NewTrain:SetSize(self.TrainingList.List:GetWide(), 28)
    self.TrainingList.NewTrain:SetText(Gemini:GetPhrase("Train.NewTraining"))
    self.TrainingList.NewTrain:Dock(TOP)
    self.TrainingList.NewTrain:DockMargin(9, 9, 9, 0)
    self.TrainingList.NewTrain:SetIcon("icon16/add.png")
    self.TrainingList.NewTrain.DoClick = function()
        self:ClearDataTrain()
        self.TrainingMenu.ClearLogs:DoClick()
    end

    self.TrainingList.SaveTrain = self.TrainingList.List:Add("DButton")
    self.TrainingList.SaveTrain:SetSize(self.TrainingList.List:GetWide() - 16, 28)
    self.TrainingList.SaveTrain:SetText(Gemini:GetPhrase("Train.SaveTraining"))
    self.TrainingList.SaveTrain:SetPos(8, self.TrainingList:GetTall() - 36)
    self.TrainingList.SaveTrain:SetIcon("icon16/disk.png")
    self.TrainingList.SaveTrain.DoClick = function()
        if not Gemini:CanUse("gemini_train") then
            self:SetOutputMSG(Gemini:GetPhrase("Logger.DontAllowed"))
            return
        end

        local PlayerID = self.TrainingMenu.InputPlayer:GetInt()
        local LogStart = self.TrainingMenu.InputLogStart:GetInt()
        local LogEnd = self.TrainingMenu.InputLogEnd:GetInt()
        local Result = self.TrainingMenu.Result:GetOptionData(self.TrainingMenu.Result:GetSelectedID())
        local Description = self.TrainingMenu.ResultDescription:GetText()
        local Name = self.TrainingMenu.InputName:GetText()

        if ( PlayerID == nil or LogStart == nil or LogEnd == nil ) then
            self:SetOutputMSG(Gemini:GetPhrase("Train.NotEnoughData"))
            return
        end

        if ( Description == "" or Name == "" ) then
            self:SetOutputMSG(Gemini:GetPhrase("Train.NotEnoughData"))
            return
        end

        net.Start("Gemini:AddNewTrain")
            net.WriteUInt(PlayerID, Gemini.Util.DefaultNetworkUInt)
            net.WriteUInt(LogStart, Gemini.Util.DefaultNetworkUInt)
            net.WriteUInt(LogEnd, Gemini.Util.DefaultNetworkUInt)
            net.WriteBool(Result)
            net.WriteString(Description)
            net.WriteString(Name)
        net.SendToServer()

        self:SetOutputMSG(Gemini:GetPhrase("Train.SavedTraining"))
    end

    --[[------------------------
            Training Menu
    ------------------------]]--

    self.TrainingMenu = vgui.Create("DScrollPanel", OurTab)
    self.TrainingMenu:SetSize(320, OurTab:GetTall() - 57)
    self.TrainingMenu:SetPos(220, 10)
    self.TrainingMenu.Paint = BorderBackgroundPaint

    self.TrainingMenu.VBar.Paint = Gemini.Util.ReturnNoneFunction
    self.TrainingMenu.VBar.btnGrip.Paint = ScrollbarPaint
    self.TrainingMenu.VBar:SetHideButtons( true )

    self.TrainingMenu.InputPlayerTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputPlayerTitle:SetFont("Frutiger:Medium")
    self.TrainingMenu.InputPlayerTitle:SetText(Gemini:GetPhrase("Train.InputPlayer"))
    self.TrainingMenu.InputPlayerTitle:SetContentAlignment(4)
    self.TrainingMenu.InputPlayerTitle:Dock(TOP)
    self.TrainingMenu.InputPlayerTitle:DockMargin(8, 16, 8, 4)

    self.TrainingMenu.InputPlayerDescription = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputPlayerDescription:SetText(Gemini:GetPhrase("Train.InputPlayer.Desc"))
    self.TrainingMenu.InputPlayerDescription:Dock(TOP)
    self.TrainingMenu.InputPlayerDescription:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputPlayerDescription:SetAutoStretchVertical(true)
    self.TrainingMenu.InputPlayerDescription:SetWrap(true)

    self.TrainingMenu.InputPlayer = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputPlayer:SetPos(8, 50)
    self.TrainingMenu.InputPlayer:SetNumeric(true)
    self.TrainingMenu.InputPlayer:Dock(TOP)
    self.TrainingMenu.InputPlayer:DockMargin(8, 0, 8, 12)
    self.TrainingMenu.InputPlayer:SetPlaceholderText(Gemini:GetPhrase("Logger.PlayerID"))

    self.TrainingMenu.InputLogStartTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogStartTitle:SetFont("Frutiger:Medium")
    self.TrainingMenu.InputLogStartTitle:SetText(Gemini:GetPhrase("Train.InputLogStart"))
    self.TrainingMenu.InputLogStartTitle:SetContentAlignment(4)
    self.TrainingMenu.InputLogStartTitle:Dock(TOP)
    self.TrainingMenu.InputLogStartTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.InputLogStartDesc = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogStartDesc:SetText(Gemini:GetPhrase("Train.InputLogStart.Desc"))
    self.TrainingMenu.InputLogStartDesc:Dock(TOP)
    self.TrainingMenu.InputLogStartDesc:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputLogStartDesc:SetAutoStretchVertical(true)
    self.TrainingMenu.InputLogStartDesc:SetWrap(true)

    self.TrainingMenu.InputLogStart = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputLogStart:SetPos(8, 50)
    self.TrainingMenu.InputLogStart:SetNumeric(true)
    self.TrainingMenu.InputLogStart:Dock(TOP)
    self.TrainingMenu.InputLogStart:DockMargin(8, 0, 8, 12)
    self.TrainingMenu.InputLogStart:SetPlaceholderText(Gemini:GetPhrase("Train.InputLogStart"))

    self.TrainingMenu.InputLogEndTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogEndTitle:SetFont("Frutiger:Medium")
    self.TrainingMenu.InputLogEndTitle:SetText(Gemini:GetPhrase("Train.InputLogEnd"))
    self.TrainingMenu.InputLogEndTitle:SetContentAlignment(4)
    self.TrainingMenu.InputLogEndTitle:Dock(TOP)
    self.TrainingMenu.InputLogEndTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.InputLogEndDesc = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogEndDesc:SetText(Gemini:GetPhrase("Train.InputLogEnd.Desc"))
    self.TrainingMenu.InputLogEndDesc:Dock(TOP)
    self.TrainingMenu.InputLogEndDesc:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputLogEndDesc:SetWrap(true)
    self.TrainingMenu.InputLogEndDesc:SetAutoStretchVertical(true)

    self.TrainingMenu.InputLogEnd = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputLogEnd:SetPos(8, 50)
    self.TrainingMenu.InputLogEnd:SetNumeric(true)
    self.TrainingMenu.InputLogEnd:Dock(TOP)
    self.TrainingMenu.InputLogEnd:DockMargin(8, 0, 8, 12)
    self.TrainingMenu.InputLogEnd:SetPlaceholderText(Gemini:GetPhrase("Train.InputLogEnd"))

    self.TrainingMenu.ResultTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.ResultTitle:SetFont("Frutiger:Medium")
    self.TrainingMenu.ResultTitle:SetText(Gemini:GetPhrase("Train.Result"))
    self.TrainingMenu.ResultTitle:SetContentAlignment(4)
    self.TrainingMenu.ResultTitle:Dock(TOP)
    self.TrainingMenu.ResultTitle:DockMargin(8, 8, 8, 6)

    self.TrainingMenu.Result = vgui.Create("DComboBox", self.TrainingMenu)
    self.TrainingMenu.Result:Dock(TOP)
    self.TrainingMenu.Result:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.Result:SetValue(Gemini:GetPhrase("Train.Result.Guilty"))
    self.TrainingMenu.Result:AddChoice(Gemini:GetPhrase("Train.Result.Guilty"), GUILTY)
    self.TrainingMenu.Result:AddChoice(Gemini:GetPhrase("Train.Result.NotGuilty"), NOT_GUILTY)
    self.TrainingMenu.Result.Paint = SmallBackgroundPaint
    self.TrainingMenu.Result.OnMenuOpened = DComboBoxPaint

    self.TrainingMenu.ResultDescription = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.ResultDescription:SetTall(28)
    self.TrainingMenu.ResultDescription:Dock(TOP)
    self.TrainingMenu.ResultDescription:DockMargin(8, 4, 8, 12)
    self.TrainingMenu.ResultDescription:SetPlaceholderText(Gemini:GetPhrase("Train.Result.Example"))
    self.TrainingMenu.ResultDescription:SetTextColor(color_black)
    self.TrainingMenu.ResultDescription:SetWrap(true)
    self.TrainingMenu.ResultDescription:SetContentAlignment(1)

    self.TrainingMenu.InputNameTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputNameTitle:SetFont("Frutiger:Medium")
    self.TrainingMenu.InputNameTitle:SetText(Gemini:GetPhrase("Train.InputName"))
    self.TrainingMenu.InputNameTitle:SetContentAlignment(4)
    self.TrainingMenu.InputNameTitle:Dock(TOP)
    self.TrainingMenu.InputNameTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.InputNameDesc = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputNameDesc:SetText(Gemini:GetPhrase("Train.InputName.Desc"))
    self.TrainingMenu.InputNameDesc:Dock(TOP)
    self.TrainingMenu.InputNameDesc:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputNameDesc:SetAutoStretchVertical(true)
    self.TrainingMenu.InputNameDesc:SetWrap(true)

    self.TrainingMenu.InputName = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputName:Dock(TOP)
    self.TrainingMenu.InputName:DockMargin(8, 8, 8, 12)
    self.TrainingMenu.InputName:SetPlaceholderText(Gemini:GetPhrase("Train.InputName"))


    self.TrainingMenu.GetLogs = vgui.Create("DButton", self.TrainingMenu)
    self.TrainingMenu.GetLogs:SetText(Gemini:GetPhrase("Logger.RequestLogs"))
    self.TrainingMenu.GetLogs:Dock(TOP)
    self.TrainingMenu.GetLogs:DockMargin(8, 0, 8, 4)

    self.TrainingMenu.GetLogs.DoClick = function()
        if not Gemini:CanUse("gemini_train") then
            self:SetOutputMSG(Gemini:GetPhrase("Logger.DontAllowed"))
            return
        end

        local PlayerID = self.TrainingMenu.InputPlayer:GetInt()
        local LogStart = self.TrainingMenu.InputLogStart:GetInt()
        local LogEnd = self.TrainingMenu.InputLogEnd:GetInt()

        if ( PlayerID == nil or LogStart == nil or LogEnd == nil ) then
            self:SetOutputMSG(Gemini:GetPhrase("Logger.NoLogs"))
            return
        end

        self:SetOutputMSG(Gemini:GetPhrase("Logger.Requesting"))

        self.TIME_REQUEST = CurTime()
        net.Start("Gemini:GetTrain")
            net.WriteUInt(PlayerID, Gemini.Util.DefaultNetworkUInt)
            net.WriteUInt(LogStart, Gemini.Util.DefaultNetworkUInt)
            net.WriteUInt(LogEnd, Gemini.Util.DefaultNetworkUInt)
        net.SendToServer()
    end

    self.TrainingMenu.ClearLogs = vgui.Create("DButton", self.TrainingMenu)
    self.TrainingMenu.ClearLogs:SetText(Gemini:GetPhrase("Logger.ClearLogs"))
    self.TrainingMenu.ClearLogs:Dock(TOP)
    self.TrainingMenu.ClearLogs:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.ClearLogs.DoClick = function()
        self.HistoryPanel:Clear()
        self:SetOutputMSG(Gemini:GetPhrase("Logger.ClearedLogs"))
    end

    local HorizontalLine = vgui.Create("Panel", self.TrainingMenu)
    HorizontalLine:Dock(TOP)
    HorizontalLine:DockMargin(8, 8, 8, 4)
    HorizontalLine:SetTall(4)
    HorizontalLine.Paint = function(SubSelf, w, h)
        draw.RoundedBox(0, 0, 0, w, h, OutlineColor)
    end

    self.TrainingMenu.PasteDataTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.PasteDataTitle:SetFont("Frutiger:Medium")
    self.TrainingMenu.PasteDataTitle:SetTall(30)
    self.TrainingMenu.PasteDataTitle:SetText(Gemini:GetPhrase("Train.DataTrain"))
    self.TrainingMenu.PasteDataTitle:SetContentAlignment(4)
    self.TrainingMenu.PasteDataTitle:Dock(TOP)
    self.TrainingMenu.PasteDataTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.PasteData = vgui.Create("DButton", self.TrainingMenu)
    self.TrainingMenu.PasteData:SetText(Gemini:GetPhrase("Train.PasteData"))
    self.TrainingMenu.PasteData:Dock(TOP)
    self.TrainingMenu.PasteData:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.PasteData.DoClick = function()
        local GlobalData = GetGlobalString("Gemini:TrainData", "")
        if ( GlobalData == "" ) then
            self.OutputMSG:SetText(Gemini:GetPhrase("Logger.NoLogs"))
            return
        end

        local Data = string.Explode(":", GlobalData)
        if (#Data ~= 3) then
            self.OutputMSG:SetText(Gemini:GetPhrase("Train.InvalidData"))
            return
        end

        self:SetDataTrain(Data[1], Data[2], Data[3])
        self.OutputMSG:SetText(Gemini:GetPhrase("Train.PastedData"))
        self.TrainingMenu.GetLogs:DoClick()
    end

    local EmptySpace = vgui.Create("Panel", self.TrainingMenu)
    EmptySpace:Dock(TOP)
    EmptySpace:SetTall(70)
    EmptySpace.Paint = Gemini.Util.ReturnNoneFunction

    --[[------------------------
           Output Message
    ------------------------]]--
    local TablePos = self.TrainingList:GetWide() + self.TrainingMenu:GetWide() + 26
    local TableSize = OurTab:GetWide() - self.TrainingList:GetWide() - self.TrainingMenu:GetWide() - 48

    self.OutputMSG = vgui.Create("DTextEntry", OurTab)
    self.OutputMSG:SetSize( TableSize, 20 )
    self.OutputMSG:SetPos( TablePos, OurTab:GetTall() - 66)
    self.OutputMSG:SetEditable(false)

    --[[------------------------
                Logs
    ------------------------]]--

    self.HistoryPanel = vgui.Create("DListView", OurTab)
    self.HistoryPanel:SetSize( self.OutputMSG:GetWide(), OurTab:GetTall() - 82 )
    self.HistoryPanel:SetPos(TablePos, 10)
    self.HistoryPanel:SetHeaderHeight(20)
    self.HistoryPanel:SetSortable(false)

    local Column = self.HistoryPanel:AddColumn("Log")
    Column:SetName( Gemini:GetPhrase("Logger.Column.Log") )
end

function MODULE:OnFocus()
    if not Gemini:CanUse("gemini_train") then return end

    self:UpdateTrainList()
end

function MODULE:FirstFocus()
    if not Gemini:CanUse("gemini_train") then return end

    net.Start("Gemini:GetAllTrain")
    net.SendToServer()
end

Gemini:ModuleCreate(Gemini:GetPhrase("Train"), MODULE)

--[[------------------------
         Networking
------------------------]]--

net.Receive("Gemini:GetTrain", function(len)
    Gemini:Debug("GetTrain Length:", len)

    local CompressedSize = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local CompressedData = net.ReadData(CompressedSize)

    local Logs = util.JSONToTable(util.Decompress(CompressedData))
    MODULE:UpdateTable(Logs)
end)

net.Receive("Gemini:GetAllTrain", function(len)
    Gemini:Debug("GetAllTrain Length:", len)

    local CompressedSize = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local CompressedData = net.ReadData(CompressedSize)

    ALL_TRAINS = util.JSONToTable(util.Decompress(CompressedData))
end)

net.Receive("Gemini:AddNewTrain", function(len)
    Gemini:Debug("AddNewTrain Length:", len)

    local CompressedSize = net.ReadUInt(Gemini.Util.DefaultNetworkUInt)
    local CompressedData = net.ReadData(CompressedSize)

    local NewTrain = util.JSONToTable(util.Decompress(CompressedData))
    MODULE:AddTrainButton(NewTrain)
end)