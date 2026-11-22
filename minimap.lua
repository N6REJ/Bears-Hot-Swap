-- minimap.lua: movable minimap button for Bears Hot Swap

local ADDON = BHS.ADDON

local btn
local angle = 45

local function UpdatePosition()
    if not btn then return end
    local rad = math.rad(angle)
    local x = math.cos(rad) * 80
    local y = math.sin(rad) * 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateButton()
    if btn then return btn end
    btn = CreateFrame("Button", "BHS_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(btn)
    icon:SetTexture(BHS.ClassIcon or "Interface\\Icons\\Ability_Racial_BearForm")
    btn.icon = icon

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(btn)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if BHS.ToggleUI then BHS.ToggleUI() end
        elseif button == "RightButton" then
            if BHS.ToggleDebug then BHS.ToggleDebug() end
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            angle = math.deg(math.atan2(cy - my, cx - mx))
            UpdatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        if BearsHotSwapDB then BearsHotSwapDB.minimapAngle = angle end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Bears Hot Swap")
        GameTooltip:AddLine("Left-click: Open UI", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Debug", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move button", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return btn
end

local evt = CreateFrame("Frame")
evt:RegisterEvent("PLAYER_LOGIN")
evt:SetScript("OnEvent", function()
    if BHS.InitDB then BHS.InitDB() end
    if BearsHotSwapDB and BearsHotSwapDB.minimapAngle then
        angle = BearsHotSwapDB.minimapAngle
    else
        angle = 45
        if BearsHotSwapDB then BearsHotSwapDB.minimapAngle = angle end
    end
    CreateButton()
    UpdatePosition()
end)