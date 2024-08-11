--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Train Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/wrench.png" }

local BackgroundColor = Color( 45, 45, 45 )
local OutlineColor = Color( 80, 80, 80, 200)

local OutlineWidth = 3

local function BorderBackgroundPaint(self, w, h)
    draw.RoundedBox( 0, 0, 0, w, h, OutlineColor )
    draw.RoundedBox( 0, OutlineWidth, OutlineWidth, w - (OutlineWidth * 2), h - (OutlineWidth * 2), BackgroundColor )
end

--[[------------------------
       Train Functions
------------------------]]--

function MODULE:GetTrainID()
end

function MODULE:ClearDataTrain()
    if IsValid(self.TrainingMenu) then
        self.TrainingMenu.InputPlayer:SetText("")
        self.TrainingMenu.InputLogStart:SetText("")
        self.TrainingMenu.InputLogEnd:SetText("")
    end
end

function MODULE:SetDataTrain(PlayerID, LogStart, LogEnd)
    if IsValid(self.TrainingMenu) then
        self.TrainingMenu.InputPlayer:SetText(PlayerID)
        self.TrainingMenu.InputLogStart:SetText(LogStart)
        self.TrainingMenu.InputLogEnd:SetText(LogEnd)
    end
end

--[[------------------------
       Main Functions
------------------------]]--

function MODULE:MainFunc(RootPanel, Tabs, OurTab)
    if not Gemini:CanUse("gemini_train") then return false end

    --[[------------------------
           Output Message
    ------------------------]]--

    self.OutputMSG = vgui.Create("DTextEntry", OurTab)
    self.OutputMSG:SetSize(OurTab:GetWide() - ( 40 + 200 + 400 ), 20)
    self.OutputMSG:SetPos(630, OurTab:GetTall() - 68)
    self.OutputMSG:SetEditable(false)

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
    end

    --[[------------------------
            Training Menu
    ------------------------]]--

    self.TrainingMenu = vgui.Create("DScrollPanel", OurTab)
    self.TrainingMenu:SetSize(400, OurTab:GetTall() - 57)
    self.TrainingMenu:SetPos(220, 10)
    self.TrainingMenu.Paint = BorderBackgroundPaint

    self.TrainingMenu.InputPlayerTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputPlayerTitle:SetFont("Frutiger:Big")
    self.TrainingMenu.InputPlayerTitle:SetTall(30)
    self.TrainingMenu.InputPlayerTitle:SetText(Gemini:GetPhrase("Train.InputPlayer"))
    self.TrainingMenu.InputPlayerTitle:SetContentAlignment(4)
    self.TrainingMenu.InputPlayerTitle:Dock(TOP)
    self.TrainingMenu.InputPlayerTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.InputPlayerDescription = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputPlayerDescription:SetText(Gemini:GetPhrase("Train.InputPlayer.Description"))
    self.TrainingMenu.InputPlayerDescription:SetContentAlignment(4)
    self.TrainingMenu.InputPlayerDescription:Dock(TOP)
    self.TrainingMenu.InputPlayerDescription:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputPlayerDescription:SetWrap(true)
    self.TrainingMenu.InputPlayerDescription:SetTall(30)

    self.TrainingMenu.InputPlayer = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputPlayer:SetPos(8, 50)
    self.TrainingMenu.InputPlayer:SetNumeric(true)
    self.TrainingMenu.InputPlayer:Dock(TOP)
    self.TrainingMenu.InputPlayer:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputPlayer:SetPlaceholderText(Gemini:GetPhrase("Logger.PlayerID"))

    self.TrainingMenu.InputLogStartTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogStartTitle:SetFont("Frutiger:Big")
    self.TrainingMenu.InputLogStartTitle:SetTall(30)
    self.TrainingMenu.InputLogStartTitle:SetText(Gemini:GetPhrase("Train.InputLogStart"))
    self.TrainingMenu.InputLogStartTitle:SetContentAlignment(4)
    self.TrainingMenu.InputLogStartTitle:Dock(TOP)
    self.TrainingMenu.InputLogStartTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.InputLogStartDesc = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogStartDesc:SetText(Gemini:GetPhrase("Train.InputLogStart.Desc"))
    self.TrainingMenu.InputLogStartDesc:SetContentAlignment(4)
    self.TrainingMenu.InputLogStartDesc:Dock(TOP)
    self.TrainingMenu.InputLogStartDesc:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputLogStartDesc:SetWrap(true)
    self.TrainingMenu.InputLogStartDesc:SetTall(30)

    self.TrainingMenu.InputLogStart = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputLogStart:SetPos(8, 50)
    self.TrainingMenu.InputLogStart:SetNumeric(true)
    self.TrainingMenu.InputLogStart:Dock(TOP)
    self.TrainingMenu.InputLogStart:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputLogStart:SetPlaceholderText(Gemini:GetPhrase("Train.InputLogStart"))

    self.TrainingMenu.InputLogEndTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogEndTitle:SetFont("Frutiger:Big")
    self.TrainingMenu.InputLogEndTitle:SetTall(30)
    self.TrainingMenu.InputLogEndTitle:SetText(Gemini:GetPhrase("Train.InputLogEnd"))
    self.TrainingMenu.InputLogEndTitle:SetContentAlignment(4)
    self.TrainingMenu.InputLogEndTitle:Dock(TOP)
    self.TrainingMenu.InputLogEndTitle:DockMargin(8, 8, 8, 4)

    self.TrainingMenu.InputLogEndDesc = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.InputLogEndDesc:SetText(Gemini:GetPhrase("Train.InputLogEnd.Desc"))
    self.TrainingMenu.InputLogEndDesc:SetContentAlignment(4)
    self.TrainingMenu.InputLogEndDesc:Dock(TOP)
    self.TrainingMenu.InputLogEndDesc:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputLogEndDesc:SetWrap(true)
    self.TrainingMenu.InputLogEndDesc:SetTall(30)

    self.TrainingMenu.InputLogEnd = vgui.Create("DTextEntry", self.TrainingMenu)
    self.TrainingMenu.InputLogEnd:SetPos(8, 50)
    self.TrainingMenu.InputLogEnd:SetNumeric(true)
    self.TrainingMenu.InputLogEnd:Dock(TOP)
    self.TrainingMenu.InputLogEnd:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputLogEnd:SetPlaceholderText(Gemini:GetPhrase("Train.InputLogEnd"))

    self.TrainingMenu.PasteDataTitle = vgui.Create("DLabel", self.TrainingMenu)
    self.TrainingMenu.PasteDataTitle:SetFont("Frutiger:Big")
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
            self.OutputMSG:SetText(Gemini:GetPhrase("Train.NoData"))
            return
        end

        local Data = string.Explode(":", GlobalData)
        if (#Data ~= 3) then
            self.OutputMSG:SetText(Gemini:GetPhrase("Train.InvalidData"))
            return
        end

        self:SetDataTrain(Data[1], Data[2], Data[3])
        self.OutputMSG:SetText(Gemini:GetPhrase("Train.PastedData"))
    end
end

Gemini:ModuleCreate(Gemini:GetPhrase("Train"), MODULE)