

local listContainer
local memberKey = GetUnitName("player")
local members = {}
local Settings

FarmingPartyMemberItems = ZO_Object:Subclass()
function FarmingPartyMemberItems:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

function FarmingPartyMemberItems:Initialize()

    members = FarmingParty.Modules.Members

    listContainer = FarmingPartyMemberItemsWindow:GetNamedChild("List")
    
    FarmingPartyMemberItemsWindow:ClearAnchors()
    Settings = FarmingParty.Settings
    FarmingPartyMemberItemsWindow:SetAnchor(
        TOPLEFT,
        GuiRoot,
        TOPLEFT,
        Settings:ItemsWindow().positionLeft,
        Settings:ItemsWindow().positionTop
    )

    FarmingPartyMemberItemsWindow:SetDimensions(Settings:ItemsWindow().width, Settings:ItemsWindow().height)
    FarmingPartyMemberItemsWindow:SetHandler("OnResizeStop", function(...)self:WindowResizeHandler(...) end)
    FarmingPartyMemberItemsWindow.onResize = self.onResize

    self:SetWindowTransparency()
    self:SetWindowBackgroundTransparency()
    
    self:SetTitle()
    self:SetupScrollList()
    self:UpdateScrollList()
    
    members:RegisterCallback("OnKeysUpdated", self.UpdateScrollList)
end

function FarmingPartyMemberItems:Finalize()
    local _, _, _, _, offsetX, offsetY = FarmingPartyMemberItemsWindow:GetAnchor(0)
    
    Settings:ItemsWindow().positionLeft = FarmingPartyMemberItemsWindow:GetLeft()
    Settings:ItemsWindow().positionTop = FarmingPartyMemberItemsWindow:GetTop()
    Settings:ItemsWindow().width = FarmingPartyMemberItemsWindow:GetWidth()
    Settings:ItemsWindow().height = FarmingPartyMemberItemsWindow:GetHeight()
end

function FarmingPartyMemberItems:SetupScrollList()
    ZO_ScrollList_AddResizeOnScreenResize(listContainer)
    ZO_ScrollList_AddDataType(
        listContainer,
        FarmingParty.DataTypes.MEMBER_ITEM,
        "FarmingPartyItemDataRow",
        20,
        function(listControl, data)
            self:SetupItemRow(listControl, data)
        end
)
end

function FarmingPartyMemberItems:UpdateScrollList()
    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Clear(listContainer)
    
    local member = members:GetMember(memberKey)
    -- We're probably in the middle of resetting members,
    -- so leave before things explode
    if (member == nil) then
        return
    end
    local memberItems = members:GetItemsForMember(memberKey)
    local memberItemArray = {}
    for key, value in pairs(memberItems) do
        value.itemLink = key
        memberItemArray[#memberItemArray + 1] = value
    end
    table.sort(memberItemArray, function(a, b)
        if (a.totalValue == b.totalValue) then
            return a.itemLink < b.itemLink
        end
        return a.totalValue > b.totalValue
    end)
    for i = 1, #memberItemArray do
        scrollData[#scrollData + 1] =
            ZO_ScrollList_CreateDataEntry(FarmingParty.DataTypes.MEMBER_ITEM, {rawData = memberItemArray[i]})
    end
    
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberItems:SetupItemRow(rowControl, rowData)
    rowControl.data = rowData
    local data = rowData.rawData
    local itemName = GetControl(rowControl, "ItemName")
    local itemCount = GetControl(rowControl, "Count")
    local totalValue = GetControl(rowControl, "TotalValue")
    
    itemName:SetText(data.itemLink)
    itemCount:SetText(data.count)
    totalValue:SetText(FarmingParty.FormatNumber(data.totalValue, 2) .. 'g')
end

function FarmingPartyMemberItems.onResize()
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberItems:WindowResizeHandler(control)
    local width, height = control:GetDimensions()
    Settings:ItemsWindow().width = width
    Settings:ItemsWindow().height = height
    
    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberItems:SetAndToggle(key)
    if (memberKey == key) then
        FarmingPartyMemberItems:ToggleWindow()
    else
        memberKey = key
        self:SetTitle()
        self.OpenWindow()
        self.UpdateScrollList()
    end
end

function FarmingPartyMemberItems:SetTitle()
    local title = FarmingPartyMemberItemsWindow:GetNamedChild("Title")
    local member = members:GetMember(memberKey)
    title:SetText(member.displayName .. "'s Farmed Items")
end

function FarmingPartyMemberItems:ToggleWindow()
    FarmingPartyMemberItemsWindow:SetHidden(not FarmingPartyMemberItemsWindow:IsHidden())
end

function FarmingPartyMemberItems:OpenWindow()
    FarmingPartyMemberItemsWindow:SetHidden(false)
end

function FarmingPartyMemberItems:SetWindowTransparency(value)
    if value ~= nil then
        Settings:ItemsWindow().transparency = value
    end
    FarmingPartyMemberItemsWindow:SetAlpha(Settings:ItemsWindow().transparency / 100)
end

function FarmingPartyMemberItems:SetWindowBackgroundTransparency(value)
    if value ~= nil then
        Settings:ItemsWindow().backgroundTransparency = value
    end
    FarmingPartyMemberItemsWindow:GetNamedChild("BG"):SetAlpha(Settings:ItemsWindow().backgroundTransparency / 100)
end
