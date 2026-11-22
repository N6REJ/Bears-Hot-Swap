-- ui.lua: clean, non-overlapping Bears Hot Swap window

local ADDON = BHS.ADDON
local TEAL = "|cff2fd5c5"
local QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local BEAR = "Interface\\Icons\\Ability_Racial_BearForm"

local frame, tabs, pages
local sets, triggers, debugs

local function Boxed(parent, w, h)
    local f = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(w or 560, h or 340)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0, 0, 0, 0.55)
        f:SetBackdropBorderColor(0.4, 0.4, 0.4)
    end
    return f
end

local function Button(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 100, h or 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Edit(parent, w, h)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(w or 120, h or 20)
    e:SetAutoFocus(false)
    return e
end

local function Header(parent, text, point)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    fs:SetText(text)
    if point then fs:SetPoint(unpack(point)) end
    return fs
end

local function Tooltip(f, title, body)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if body then GameTooltip:AddLine(body, nil, nil, nil, true) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Refresh()
    if not frame or not frame:IsShown() or not BearsHotSwapDB then return end
    if sets and sets.Refresh then sets.Refresh() end
    if triggers and triggers.Refresh then triggers.Refresh() end
    if debugs and debugs.Refresh then debugs.Refresh() end
end

local function SelectPage(key)
    for k, p in pairs(pages) do if k == key then p:Show() else p:Hide() end end
    for k, t in pairs(tabs) do if t.SetButtonState then t:SetButtonState(k == key and "Pushed" or "Normal") end end
end

-- ---------------------------------------------------------------- sets page
local function SetsPage(p)
    local box = Boxed(p, 560, 340)
    box:SetPoint("TOPLEFT", 10, -70)

    local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -26, 6)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(520, 10)
    sf:SetScrollChild(child)
    sets.child = child

    local empty = child:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    empty:SetPoint("TOPLEFT", 6, -10)
    empty:SetWidth(500)
    empty:SetJustifyH("LEFT")
    empty:SetText("No sets yet. Put on the gear you want, then type a name below and click Save.")
    sets.empty = empty

    local rows = {}
    function sets.GetRow(i)
        if rows[i] then return rows[i] end
        local row = CreateFrame("Button", nil, child)
        row:SetSize(520, 30)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 32)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.08)
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24); icon:SetPoint("LEFT", 4, -3)
        icon:SetTexture(BHS.ClassIcon or BEAR)
        row.icon = icon
        local name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        name:SetJustifyH("LEFT")
        row.name = name
        local status = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("LEFT", name, "RIGHT", 10, 0)
        status:SetJustifyH("LEFT")
        row.status = status
        local del = Button(row, "Delete", 60, 18, function()
            BearsHotSwapDB.sets[row.setName] = nil
            if type(DeleteEquipmentSet) == "function" then pcall(DeleteEquipmentSet, row.setName:gsub("^%l", string.upper)) end
            Refresh()
        end)
        del:SetPoint("RIGHT", -4, 0)
        local reset = Button(row, "Reset", 60, 18, function()
            if BHS.SaveSet then BHS.SaveSet(row.setName) end
            sets.selected = row.setName
            Refresh()
        end)
        reset:SetPoint("RIGHT", del, "LEFT", -4, 0)
        local equip = Button(row, "Equip", 60, 18, function() if BHS.EquipSet then BHS.EquipSet(row.setName) end end)
        equip:SetPoint("RIGHT", reset, "LEFT", -4, 0)
        row:SetScript("OnClick", function(self, button)
            if button ~= "RightButton" and BHS.EquipSet then BHS.EquipSet(self.setName) end
            sets.selected = self.setName
            Refresh()
        end)
        row:SetScript("OnDoubleClick", function(self) if BHS.EquipSet then BHS.EquipSet(self.setName) end end)
        Tooltip(row, "", "Click to select. Equip switches to this set now.")
        rows[i] = row
        return row
    end

    function sets.Refresh()
        local names = {}
        for k in pairs(BearsHotSwapDB.sets or {}) do table.insert(names, k) end
        table.sort(names)
        local sel = sets.selected
        for i, name in ipairs(names) do
            local row = sets.GetRow(i)
            row.setName = name
            local iconTex = BHS.ClassIcon or BEAR
            if BearsHotSwapDB and BearsHotSwapDB.triggers then
                for _, t in ipairs(BearsHotSwapDB.triggers) do
                    if t.setName and t.setName:lower() == name:lower() then
                        iconTex = t.auraIcon or iconTex
                        local tex = GetSpellTexture and GetSpellTexture(t.auraName or t.spellId)
                        if tex then iconTex = tex; break end
                        break
                    end
                end
            end
            row.icon:SetTexture(iconTex)
            row.name:SetText(name)
            row.status:SetText(BHS.currentTarget == name and "|cff40ff40Wearing|r" or "")
            row:Show()
        end
        for i = #names + 1, #rows do rows[i]:Hide() end
        child:SetHeight(math.max(10, #names * 32))
        sets.empty:SetShown(#names == 0)
        if not sel and names[1] then sets.selected = names[1] end
    end

    local saveBar = Boxed(p, 560, 34)
    saveBar:SetPoint("BOTTOMLEFT", 10, 10)
    local saveTitle = Header(saveBar, "Save current gear", {"LEFT", 8, -7})
    Tooltip(saveBar, "Save current gear", "Saves everything you're wearing right now as a new set.")
    local saveBox = Edit(saveBar, 260, 20); saveBox:SetPoint("LEFT", saveTitle, "RIGHT", 6, 0)
    local saveBtn = Button(saveBar, "Save", 60, 22, function()
        local n = saveBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
        if n ~= "" and BHS.SaveSet then BHS.SaveSet(n); saveBox:SetText(""); Refresh() end
    end)
    saveBtn:SetPoint("LEFT", saveBox, "RIGHT", 4, 0)
    sets.saveBox = saveBox
end

-- ---------------------------------------------------------------- triggers page
local function TriggersPage(p)
    local box = Boxed(p, 560, 360)
    box:SetPoint("TOPLEFT", 10, -70)

    local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -26, 6)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(520, 10)
    sf:SetScrollChild(child)
    triggers.child = child
    triggers.rows = {}

    function triggers.Refresh()
        for _, c in ipairs(triggers.rows) do c:Hide() end
        wipe(triggers.rows)
        local y = -10
        for i, t in ipairs(BearsHotSwapDB.triggers or {}) do
            local row = CreateFrame("Frame", nil, child)
            row:SetSize(520, 30)
            row:SetPoint("TOPLEFT", 0, y)
            table.insert(triggers.rows, row)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24); icon:SetPoint("LEFT", 4, -3)
            icon:SetTexture(t.auraIcon or (GetSpellTexture and GetSpellTexture(t.auraName or t.spellId)) or QMARK)

            local auraLbl = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            auraLbl:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            auraLbl:SetText(t.auraName or tostring(t.spellId))

            local arrow = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            arrow:SetPoint("LEFT", auraLbl, "RIGHT", 6, 0)
            arrow:SetText("->")

            local function NextSetName(cur)
                local names = {}
                for k in pairs(BearsHotSwapDB.sets or {}) do table.insert(names, k) end
                table.sort(names)
                if #names == 0 then return cur end
                for j, n in ipairs(names) do
                    if n == cur then return names[j % #names + 1] end
                end
                return names[1]
            end
            local setBtn = Button(row, t.setName or "(none)", 120, 20, function()
                BearsHotSwapDB.triggers[i].setName = NextSetName(BearsHotSwapDB.triggers[i].setName)
                Refresh()
            end)
            setBtn:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
            Tooltip(setBtn, "Target set", "Click to cycle through saved sets.")

            local del = Button(row, "X", 20, 20, function()
                table.remove(BearsHotSwapDB.triggers, i)
                Refresh()
            end)
            del:SetPoint("RIGHT", -4, 0)
            Tooltip(del, "Remove trigger", "Removes this trigger.")
            y = y - 32
        end
        child:SetHeight(math.max(10, #BearsHotSwapDB.triggers * 32 + 20))
    end

    local addBar = Boxed(p, 560, 34)
    addBar:SetPoint("BOTTOMLEFT", 10, 10)
    local auraBox = Edit(addBar, 180, 20); auraBox:SetPoint("LEFT", 8, -7)
    local setPick = Button(addBar, "(set)", 120, 22, function()
        local names = {}
        for k in pairs(BearsHotSwapDB.sets or {}) do table.insert(names, k) end
        table.sort(names)
        if #names == 0 then return end
        local cur = addBar._setName
        local next = names[1]
        for j, n in ipairs(names) do
            if n == cur then next = names[j % #names + 1] end
        end
        addBar._setName = next
        setPick:SetText(next)
    end)
    setPick:SetPoint("LEFT", auraBox, "RIGHT", 6, 0)
    addBar._setName = nil
    local addBtn = Button(addBar, "Add", 60, 22, function()
        local aura = auraBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
        local sn = addBar._setName
        if not sn then
            local names = {}
            for k in pairs(BearsHotSwapDB.sets or {}) do table.insert(names, k) end
            table.sort(names)
            sn = names[1]
        end
        if aura ~= "" and sn then
            table.insert(BearsHotSwapDB.triggers, { auraName = aura, spellId = tonumber(aura), setName = sn })
            auraBox:SetText("")
            addBar._setName = nil
            setPick:SetText("(set)")
            Refresh()
        end
    end)
    addBtn:SetPoint("LEFT", setPick, "RIGHT", 6, 0)
    local discoverBtn = Button(addBar, "Discover", 90, 22, function()
        if BHS.DiscoverForms then BHS.DiscoverForms() end
        Refresh()
    end)
    discoverBtn:SetPoint("RIGHT", -8, -7)

    -- default set picker
    local defLabel = child:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    defLabel:SetPoint("TOPLEFT", 0, -10 - (#(BearsHotSwapDB.triggers or {}) * 34) - 10)
    defLabel:SetText("Default set (no form): " .. tostring(BearsHotSwapDB.defaultSet))
    local defBtn = Button(child, "Cycle", 60, 18, function()
        local names = {}
        for k in pairs(BearsHotSwapDB.sets or {}) do table.insert(names, k) end
        table.sort(names)
        if #names == 0 then return end
        local cur = BearsHotSwapDB.defaultSet
        local next = names[1]
        for j, n in ipairs(names) do
            if n == cur then next = names[j % #names + 1] end
        end
        BearsHotSwapDB.defaultSet = next
        Refresh()
    end)
    defBtn:SetPoint("LEFT", defLabel, "RIGHT", 6, 0)
end

-- ---------------------------------------------------------------- debug page
local function DebugPage(p)
    local box = Boxed(p, 560, 360)
    box:SetPoint("TOPLEFT", 10, -70)

    local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -26, 40)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(520, 10)
    sf:SetScrollChild(child)
    debugs = { child = child }

    local text = CreateFrame("EditBox", nil, child)
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(500)
    text:SetMultiLine(true)
    text:SetAutoFocus(false)
    text:SetFontObject("GameFontNormalSmall")
    text:EnableMouse(true)
    text:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    child.text = text
    debugs.text = text

    local measure = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    measure:SetPoint("TOPLEFT", 0, 0)
    measure:SetJustifyH("LEFT")
    measure:SetWidth(500)
    measure:Hide()
    debugs.measure = measure

    function debugs.Refresh()
        local lines = {}
        table.insert(lines, "=== Bears Hot Swap Debug ===")
        table.insert(lines, "Aura API: " .. (type(UnitBuff) == "function" and "UnitBuff" or type(UnitAura) == "function" and "UnitAura" or (type(C_UnitAuras) == "table" and "C_UnitAuras") or "NONE"))
        table.insert(lines, "Current target set: " .. tostring(BHS.currentTarget))
        table.insert(lines, "Scheduled set: " .. tostring(BHS.scheduledSet or "none"))
        table.insert(lines, "Pending combat set: " .. tostring(BHS.pendingCombatSet or "none"))
        table.insert(lines, "")
        table.insert(lines, "Current auras:")
        if BHS.GetBuffInfo then
            for i = 1, 40 do
                local name, sid = BHS.GetBuffInfo("player", i)
                if not name then break end
                table.insert(lines, "  " .. name .. " (" .. tostring(sid) .. ")")
            end
        end
        table.insert(lines, "")
        table.insert(lines, "Triggers:")
        if BearsHotSwapDB and BearsHotSwapDB.triggers then
            for _, t in ipairs(BearsHotSwapDB.triggers) do
                table.insert(lines, "  " .. (t.auraName or tostring(t.spellId)) .. " -> " .. t.setName)
            end
        end
        table.insert(lines, "")
        table.insert(lines, "Saved sets:")
        if BearsHotSwapDB and BearsHotSwapDB.sets then
            for k, _ in pairs(BearsHotSwapDB.sets) do table.insert(lines, "  " .. k) end
        end
        table.insert(lines, "")
        table.insert(lines, "Debug log:")
        for _, m in ipairs(BHS.DebugLog or {}) do table.insert(lines, "  " .. m) end
        local out = table.concat(lines, "\n")
        debugs.text:SetText(out)
        debugs.measure:SetText(out)
        child:SetHeight(debugs.measure:GetStringHeight() + 10)
    end

    local refresh = Button(box, "Refresh", 80, 22, function() if debugs.Refresh then debugs.Refresh() end end)
    refresh:SetPoint("BOTTOM", -50, 10)
    local clear = Button(box, "Clear Log", 80, 22, function()
        wipe(BHS.DebugLog)
        if debugs.Refresh then debugs.Refresh() end
    end)
    clear:SetPoint("BOTTOM", 50, 10)
end

local function CreateUI()
    if frame then return frame end
    frame = CreateFrame("Frame", "BHS_MainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 440)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:EnableKeyboard(true)
    local function KeyboardOn()
        if InCombatLockdown and InCombatLockdown() then
            frame:EnableKeyboard(false)
        else
            frame:EnableKeyboard(true)
            if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(true) end
        end
    end
    frame:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown and InCombatLockdown() then return end
        if key == "ESCAPE" then
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
            self:Hide()
        elseif self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(true)
        end
    end)
    frame:HookScript("OnShow", KeyboardOn)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then self:EnableKeyboard(false)
        elseif self:IsShown() then KeyboardOn() end
    end)
    frame:HookScript("OnShow", Refresh)
    frame:SetScript("OnShow", function() KeyboardOn(); Refresh() end)
    frame:Hide()
    local title = frame.TitleText
    if not title then
        title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
    end
    local ver = (GetAddOnMetadata and GetAddOnMetadata("Bears-Hot-Swap", "Version")) or "1.0.0"
    title:SetText("Bears Hot Swap " .. TEAL .. "|r  |cff888888v" .. ver .. "|r")
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(18, 18)
    icon:SetPoint("RIGHT", title, "LEFT", -6, 0)
    icon:SetTexture(BHS.ClassIcon or BEAR)
    Tooltip(frame, "Bears Hot Swap", "Automatically swaps gear when triggers change. Left-click the minimap button to open here; right-click for debug.")

    pages = {
        sets = CreateFrame("Frame", nil, frame),
        triggers = CreateFrame("Frame", nil, frame),
        debug = CreateFrame("Frame", nil, frame),
    }
    for k, p in pairs(pages) do p:SetPoint("TOPLEFT", 0, 0); p:SetPoint("BOTTOMRIGHT", -16, 12); p:Hide() end
    sets = { selected = nil }
    triggers = { rows = {} }
    debugs = {}
    SetsPage(pages.sets)
    TriggersPage(pages.triggers)
    DebugPage(pages.debug)

    tabs = {}
    local t1 = Button(frame, "Sets", 90, 20, function() SelectPage("sets") end)
    t1:SetPoint("TOPLEFT", 12, -40)
    tabs.sets = t1
    local t2 = Button(frame, "Triggers", 90, 20, function() SelectPage("triggers") end)
    t2:SetPoint("LEFT", t1, "RIGHT", 3, 0)
    tabs.triggers = t2
    local t3 = Button(frame, "Debug", 90, 20, function() SelectPage("debug") end)
    t3:SetPoint("LEFT", t2, "RIGHT", 3, 0)
    tabs.debug = t3
    SelectPage("sets")
    return frame
end

local function ToggleUI()
    if BHS.InitDB then BHS.InitDB() end
    CreateUI()
    if frame:IsShown() then frame:Hide() else frame:Show(); Refresh() end
end

local function ToggleDebug()
    if BHS.InitDB then BHS.InitDB() end
    CreateUI()
    if not frame:IsShown() then frame:Show() end
    SelectPage("debug")
    Refresh()
end

BHS.ToggleUI = ToggleUI
BHS.ToggleDebug = ToggleDebug
BHS.RefreshUI = Refresh