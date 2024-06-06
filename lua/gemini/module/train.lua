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

function MODULE:ClearTrainMenu()
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
    self.OutputMSG:SetSize(OurTab:GetWide() - 40, 20)
    self.OutputMSG:SetPos(10, OurTab:GetTall() - 68)
    self.OutputMSG:SetEditable(false)

    --[[------------------------
          Previous Training
    ------------------------]]--

    self.TrainingList = vgui.Create("DPanel", OurTab)
    self.TrainingList:SetSize(200, OurTab:GetTall() - 110)
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
        self:ClearTrainMenu()
    end

    --[[------------------------
            Training Menu
    ------------------------]]--

    self.TrainingMenu = vgui.Create("DScrollPanel", OurTab)
    self.TrainingMenu:SetSize(400, OurTab:GetTall() - 110)
    self.TrainingMenu:SetPos(220, 35)
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
    self.TrainingMenu.InputPlayer:SetSize(self.TrainingMenu:GetWide() - 16, 20)
    self.TrainingMenu.InputPlayer:SetPos(8, 50)
    self.TrainingMenu.InputPlayer:SetNumeric(true)
    self.TrainingMenu.InputPlayer:Dock(TOP)
    self.TrainingMenu.InputPlayer:DockMargin(8, 0, 8, 4)
    self.TrainingMenu.InputPlayer:SetPlaceholderText(Gemini:GetPhrase("Logger.PlayerID"))


end

Gemini:ModuleCreate(Gemini:GetPhrase("Train"), MODULE)