--[[----------------------------------------------------------------------------
                       Google Gemini Automod - Logger Menu
----------------------------------------------------------------------------]]--

local MODULE = { ["Icon"] = "icon16/page_white_text.png" }

local AltDoClickColumn = function(self)

    self:GetParent():SortByColumn( self:GetColumnID(), self:GetDescending() )
    self:SetDescending( !self:GetDescending() )

    self:GetParent().CurrentColumn = self
end

--[[------------------------
           Logger
------------------------]]--

function MODULE:AskLogs(Limit, Target, IsPlayer)
    Target = Target or NULL
    IsPlayer = IsPlayer or false

    local NetSended = net.Start("Gemini:AskLogs")
        net.WriteUInt(Limit, 16)
        net.WriteBool(IsPlayer)
        net.WriteEntity(Target)
    net.SendToServer()

    self:SetMessageLog("Message Status: " .. tostring(NetSended))
end

function MODULE:RetrieveNetwork(Success, Message, Logs)
    self:SetMessageLog( Gemini:GetPhrase(Message) )

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
        self.TablePanel:AddLine(ID, Log, Time, User):SetID(tonumber(ID))

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
    TablePanel:SetSize(OurTab:GetWide() - 200, OurTab:GetTall() - 100)
    TablePanel:SetPos(170, 15)
    TablePanel:SetMultiSelect(false)

    local WidthList = TablePanel:GetWide()

    self.List = {}
    self.List["ID"] = TablePanel:AddColumn("ID", 1)
    self.List["Log"] = TablePanel:AddColumn("Log", 2)
    self.List["Date"] = TablePanel:AddColumn("Date", 3)
    self.List["PlayerID"] = TablePanel:AddColumn("Player ID", 4)

    self.List["ID"]:SetWidth( WidthList * 0.05 )
    self.List["Log"]:SetWidth( WidthList * 0.74 )
    self.List["Date"]:SetWidth( WidthList * 0.15 )
    self.List["PlayerID"]:SetWidth( WidthList * 0.06 )

    self.List["ID"]:SetDescending( true )
    TablePanel.CurrentColumn = self.List["ID"]

    -- Settings Panel
    local SettingsPanel = vgui.Create("DPanel", OurTab)
    SettingsPanel:SetSize(150, OurTab:GetTall() - 100)
    SettingsPanel:SetPos(10, 15)

    self.OutputMSG = OutputMSG
    self.TablePanel = TablePanel
end

function MODULE:OnFocus()
    self:AskLogs(10)

    net.Start("Gemini:StartAsyncronousLogs")
    net.SendToServer()
end

function MODULE:OnLostFocus()
    net.Start("Gemini:StopAsyncronousLogs")
    net.SendToServer()
end

--[[------------------------
           Network
------------------------]]--

net.Receive("Gemini:AskLogs", function(len)
    local Success = net.ReadBool()
    local Message = net.ReadString()
    local Logs = {}

    if ( Success == true ) then
        Logs = net.ReadTable()
    end

    MODULE:RetrieveNetwork(Success, Message, Logs)
end)

net.Receive("Gemini:ReplicateLog", function(len)
    local ID = net.ReadUInt(16)
    local Log = net.ReadString()
    local Time = net.ReadString()
    local User = net.ReadString()

    MODULE:AddNewLog(ID, Log, Time, User)
end)

--[[------------------------
       Register Module
------------------------]]--

Gemini:ModuleCreate("Registros", MODULE)