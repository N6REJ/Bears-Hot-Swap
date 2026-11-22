-- Bears Hot Swap
-- Generalized: swaps a saved equipment set when tracked form/aura spells change.
-- Built for WoW:Forever (3.3.5a).

BearsHotSwapDB = BearsHotSwapDB or {}

local ADDON = "BearsHotSwap"

BHS = BHS or {}
BHS.DB = BearsHotSwapDB
BHS.ADDON = ADDON
BHS.DebugLog = BHS.DebugLog or {}
BHS.Debug = function(msg)
    local line = date("%H:%M:%S") .. " " .. tostring(msg)
    table.insert(BHS.DebugLog, line)
    if #BHS.DebugLog > 200 then table.remove(BHS.DebugLog, 1) end
end
BHS.SLOTS = BHS.SLOTS or {}
if #BHS.SLOTS == 0 then for i = 1, 19 do BHS.SLOTS[i] = i end end

local frame = CreateFrame("Frame")

local function InitDB()
    BearsHotSwapDB = BearsHotSwapDB or {}
    BearsHotSwapDB.sets = BearsHotSwapDB.sets or {}
    if not BearsHotSwapDB.triggers then
        BearsHotSwapDB.triggers = {
            { auraName = "Bear Form",      spellId = 5487, auraIcon = "Interface\\Icons\\Ability_Racial_BearForm", setName = "bear" },
            { auraName = "Dire Bear Form", spellId = 9634, auraIcon = "Interface\\Icons\\Ability_Racial_BearForm", setName = "bear" },
        }
    end
    -- Migrate older triggers that only stored a spellId.
    local knownNames = { [5487]="Bear Form", [9634]="Dire Bear Form", [768]="Cat Form", [783]="Travel Form", [1066]="Aquatic Form", [33943]="Flight Form", [40120]="Swift Flight Form", [24858]="Moonkin Form", [33891]="Tree of Life" }
    local knownIcons = { [5487]="Interface\\Icons\\Ability_Racial_BearForm", [9634]="Interface\\Icons\\Ability_Racial_BearForm", [768]="Interface\\Icons\\Ability_Druid_CatForm", [783]="Interface\\Icons\\Ability_Druid_TravelForm", [1066]="Interface\\Icons\\Ability_Druid_AquaticForm", [33943]="Interface\\Icons\\Ability_Druid_FlightForm", [40120]="Interface\\Icons\\Ability_Druid_FlightForm", [24858]="Interface\\Icons\\Spell_Nature_ForceOfNature", [33891]="Interface\\Icons\\Ability_Druid_TreeofLife" }
    for _, t in ipairs(BearsHotSwapDB.triggers) do
        if not t.auraName and t.spellId and knownNames[t.spellId] then
            t.auraName = knownNames[t.spellId]
        end
        if not t.auraIcon and t.spellId and knownIcons[t.spellId] then
            t.auraIcon = knownIcons[t.spellId]
        end
        if not t.auraName and t.spellId and type(GetSpellLink) == "function" then
            local link = GetSpellLink(t.spellId)
            if link then t.auraName = link:match("%[(.-)%]") end
        end
    end
    if BearsHotSwapDB.defaultSet == nil then
        BearsHotSwapDB.defaultSet = "normal"
    end
    -- If the configured default set doesn't exist, pick a saved set that isn't
    -- used by any trigger (so leaving a form swaps to a real non-form set).
    do
        local found = false
        for k in pairs(BearsHotSwapDB.sets or {}) do
            if k:lower() == tostring(BearsHotSwapDB.defaultSet):lower() then found = true; break end
        end
        if not found then
            local targets = {}
            for _, t in ipairs(BearsHotSwapDB.triggers or {}) do
                if t.setName then targets[t.setName:lower()] = true end
            end
            local names = {}
            for k in pairs(BearsHotSwapDB.sets or {}) do table.insert(names, k) end
            table.sort(names)
            local cand
            for _, k in ipairs(names) do
                if not targets[k:lower()] then cand = k; break end
            end
            if not cand then cand = names[1] end
            if cand then BearsHotSwapDB.defaultSet = cand end
        end
    end
    BHS.DB = BearsHotSwapDB
end

BHS.InitDB = InitDB

-- Discover shapeshift/stance forms available to this character and add any
-- missing triggers (setName defaults to the lowercased form name).
local function DiscoverForms()
    InitDB()
    local num = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
    local added = 0
    for i = 1, num do
        local r1, r2, r3, r4, r5, r6 = GetShapeshiftFormInfo(i)
        local name = nil
        local icon = nil
        for _, v in ipairs({r1, r2, r3, r4, r5, r6}) do
            if type(v) == "string" and v ~= "" then
                if v:find("Interface") or v:find("Icons") then
                    if not icon then icon = v end
                else
                    if not name then name = v end
                end
            end
        end
        -- fallback: first string is icon in some versions
        if not icon then icon = r1 end
        if not name then
            for _, v in ipairs({r1, r2, r3, r4, r5, r6}) do
                if type(v) == "string" and v ~= "" and v ~= icon then name = v; break end
            end
        end
        if name and name ~= "" then
            local found = false
            for _, t in ipairs(BearsHotSwapDB.triggers) do
                if t.auraName == name then
                    if not t.auraIcon and icon then t.auraIcon = icon end
                    found = true; break
                end
            end
            if not found then
                local setName = name:lower():gsub("%s+", "")
                table.insert(BearsHotSwapDB.triggers, { auraName = name, spellId = nil, auraIcon = icon, setName = setName })
                added = added + 1
            end
        end
    end
    return added, num
end

BHS.DiscoverForms = DiscoverForms

BHS.GetBuffInfo = nil
local function GetBuffInfo(unit, index)
    if type(UnitBuff) == "function" then
        local ok, name, _, _, _, _, _, _, _, _, spellId = pcall(UnitBuff, unit, index)
        if ok then return name, spellId end
    elseif type(UnitAura) == "function" then
        local ok, name, _, _, _, _, _, _, _, spellId = pcall(UnitAura, unit, index, "HELPFUL")
        if ok then return name, spellId end
    elseif type(C_UnitAuras) == "table" and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HELPFUL")
        if not ok or not aura then ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index) end
        if not ok or not aura then ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, 1) end
        if ok and aura then
            local n = aura.name or aura.label or aura.spellName or aura.auraName
            local sid = aura.spellId or aura.spellID or aura.id
            return n, sid
        end
    end
    return nil, nil
end

BHS.GetBuffInfo = GetBuffInfo

local function HasSpellAura(trigger)
    for i = 1, 40 do
        local name, sid = GetBuffInfo("player", i)
        if not name then break end
        if trigger.auraName and name == trigger.auraName then return true end
        if trigger.spellId and sid and sid == trigger.spellId then return true end
    end
    return false
end

local function FindSetKey(name)
    if not name or not BearsHotSwapDB.sets then return nil end
    if BearsHotSwapDB.sets[name] then return name end
    for k in pairs(BearsHotSwapDB.sets) do
        if k:lower() == name:lower() then return k end
    end
    return nil
end

BHS.FindSetKey = FindSetKey

local function DefaultCandidate()
    if not BearsHotSwapDB or not BearsHotSwapDB.sets then return BearsHotSwapDB and BearsHotSwapDB.defaultSet end
    local targets = {}
    for _, t in ipairs(BearsHotSwapDB.triggers or {}) do
        if t.setName then targets[t.setName:lower()] = true end
    end
    local names = {}
    for k in pairs(BearsHotSwapDB.sets) do table.insert(names, k) end
    table.sort(names)
    for _, k in ipairs(names) do
        if not targets[k:lower()] then return k end
    end
    return names[1]
end

local function ActiveSetName()
    for _, t in ipairs(BearsHotSwapDB.triggers or {}) do
        if HasSpellAura(t) then
            return FindSetKey(t.setName) or t.setName
        end
    end
    -- fallback: if defaultSet missing, prefer a set not used by any trigger
    local fk = FindSetKey(BearsHotSwapDB.defaultSet)
    if fk then return fk end
    local cand = DefaultCandidate()
    if cand then return cand end
    for k in pairs(BearsHotSwapDB.sets or {}) do return k end
    return BearsHotSwapDB.defaultSet
end

local currentTarget = nil
local scheduledSet = nil
local scheduleTimer = 0
local checkTimer = 0

local function CheckForm()
    if InCombatLockdown and InCombatLockdown() then
        BHS.Debug("CheckForm: in combat lockdown, skipping (auras may be secret)")
        return
    end
    local auras = {}
    for i = 1, 40 do
        local name, sid = GetBuffInfo("player", i)
        if not name then break end
        table.insert(auras, name .. "(" .. tostring(sid) .. ")")
    end
    BHS.Debug("CheckForm: auras=" .. table.concat(auras, ", "))
    BHS.Debug("CheckForm: defaultSet=" .. tostring(BearsHotSwapDB.defaultSet))
    for _, t in ipairs(BearsHotSwapDB.triggers or {}) do
        BHS.Debug("  trigger: '" .. tostring(t.auraName) .. "' -> '" .. tostring(t.setName) .. "'")
    end
    local nowTarget = ActiveSetName()
    BHS.Debug("CheckForm: active=" .. tostring(nowTarget) .. " current=" .. tostring(currentTarget))
    if nowTarget ~= currentTarget then
        BHS.Debug("form changed: " .. tostring(currentTarget) .. " -> " .. tostring(nowTarget))
    end
    if nowTarget == currentTarget then return end
    currentTarget = nowTarget
    BHS.currentTarget = currentTarget
    if nowTarget and BearsHotSwapDB.sets and BearsHotSwapDB.sets[nowTarget] then
        scheduledSet = nowTarget
        BHS.scheduledSet = scheduledSet
        scheduleTimer = 0
        BHS.Debug("scheduled set '" .. nowTarget .. "'")
    else
        BHS.Debug("no saved set for '" .. tostring(nowTarget) .. "'")
    end
end

BHS.CheckForm = CheckForm

frame:SetScript("OnUpdate", function(self, elapsed)
    checkTimer = (checkTimer or 0) + elapsed
    if checkTimer >= 0.5 then
        checkTimer = 0
        if BHS.CheckForm then BHS.CheckForm() end
    end
    if scheduledSet then
        scheduleTimer = scheduleTimer + elapsed
        if scheduleTimer >= 0.4 then
            scheduleTimer = 0
            local s = scheduledSet
            scheduledSet = nil
            BHS.scheduledSet = nil
            if BHS.EquipSet then BHS.EquipSet(s) end
        end
    end
    local inCombat = (InCombatLockdown and InCombatLockdown())
    local casting = (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player"))
    if BHS.pendingCombatSet and not inCombat and not casting then
        local s = BHS.pendingCombatSet
        BHS.pendingCombatSet = nil
        if BHS.EquipSet then BHS.EquipSet(s) end
    end
end)

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        InitDB()
        print("BHS aura API:", type(UnitBuff) == "function" and "UnitBuff" or type(UnitAura) == "function" and "UnitAura" or (type(C_UnitAuras) == "table" and "C_UnitAuras") or "NONE")
        DiscoverForms()
        print("BHS defaultSet:", tostring(BearsHotSwapDB.defaultSet))
        local _, classToken = UnitClass("player")
        BHS.ClassIcon = "Interface\\Icons\\ClassIcon_" .. (classToken or "Druid")
        currentTarget = ActiveSetName()
        BHS.currentTarget = currentTarget
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            BHS.Debug("UNIT_AURA fired")
            CheckForm()
        end
    else
        CheckForm()
    end
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

SLASH_BHS1 = "/bhs"
SlashCmdList["BHS"] = function(msg)
    InitDB()
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" or msg == "ui" or msg == "window" then
        if BHS.ToggleUI then BHS.ToggleUI() end
        return
    end
    -- trigger management
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if cmd == "trigger" then
        local sub, args = rest:match("^(%S+)%s*(.*)$")
        if sub == "list" then
            print("|cff33ff99" .. ADDON .. ":|r triggers:")
            for _, t in ipairs(BearsHotSwapDB.triggers) do
                local label = t.auraName or tostring(t.spellId)
                print("  " .. label .. " -> set '" .. t.setName .. "'")
            end
            print("  default set: " .. tostring(BearsHotSwapDB.defaultSet))
            return
        elseif sub == "add" then
            local sid, sname = args:match("^(%d+)%s+(%S+)$")
            if sid and sname then
                local id = tonumber(sid)
                local auraName = nil
                if type(GetSpellLink) == "function" then
                    local link = GetSpellLink(id)
                    if link then auraName = link:match("%[(.-)%]") end
                end
                table.insert(BearsHotSwapDB.triggers, { auraName = auraName, spellId = id, setName = sname })
                print("|cff33ff99" .. ADDON .. ":|r added trigger " .. (auraName or sid) .. " -> '" .. sname .. "'.")
            else
                print("|cff33ff99" .. ADDON .. ":|r usage: /bhs trigger add <spellId> <setName>")
            end
            return
        elseif sub == "remove" then
            local sid = tonumber(args)
            if sid then
                for i = #BearsHotSwapDB.triggers, 1, -1 do
                    if BearsHotSwapDB.triggers[i].spellId == sid then
                        table.remove(BearsHotSwapDB.triggers, i)
                    end
                end
                print("|cff33ff99" .. ADDON .. ":|r removed triggers for spell " .. sid .. ".")
            else
                print("|cff33ff99" .. ADDON .. ":|r usage: /bhs trigger remove <spellId>")
            end
            return
        elseif sub == "set" then
            local key, newSet = args:match("^(%S+)%s+(%S+)$")
            if key and newSet then
                local id = tonumber(key)
                local found = false
                for _, t in ipairs(BearsHotSwapDB.triggers) do
                    if (id and t.spellId == id) or (t.auraName and t.auraName:lower() == key:lower()) then
                        t.setName = newSet
                        found = true
                    end
                end
                if found then
                    print("|cff33ff99" .. ADDON .. ":|r updated trigger target -> '" .. newSet .. "'.")
                else
                    print("|cff33ff99" .. ADDON .. ":|r trigger not found: " .. key)
                end
            else
                print("|cff33ff99" .. ADDON .. ":|r usage: /bhs trigger set <spellId|auraName> <setName>")
            end
            return
        end
    elseif cmd == "discover" then
        local added, num = DiscoverForms()
        print("|cff33ff99" .. ADDON .. ":|r scanned " .. num .. " shapeshift/stance forms, added " .. added .. " new triggers.")
        print("|cff33ff99" .. ADDON .. ":|r use /bhs trigger list to review; save sets with matching names.")
        return
    elseif cmd == "debug" then
        if BHS.ToggleDebug then BHS.ToggleDebug() end
        return
    elseif cmd == "default" then
        if rest ~= "" then
            BearsHotSwapDB.defaultSet = rest
            print("|cff33ff99" .. ADDON .. ":|r default set set to '" .. rest .. "'.")
        else
            print("|cff33ff99" .. ADDON .. ":|r usage: /bhs default <setName>")
        end
        return
    end

    if msg == "save normal" or msg == "save caster" or msg == "save out" then
        if BHS.SaveSet then BHS.SaveSet("normal") end
    elseif msg == "save bear" then
        if BHS.SaveSet then BHS.SaveSet("bear") end
    elseif msg == "normal" or msg == "caster" or msg == "out" then
        if BHS.EquipSet then BHS.EquipSet("normal") end
    elseif msg == "bear" then
        if BHS.EquipSet then BHS.EquipSet("bear") end
    elseif msg == "status" then
        print("|cff33ff99" .. ADDON .. ":|r sets:")
        for k, _ in pairs(BearsHotSwapDB.sets) do print("  " .. k) end
    else
        print("|cff33ff99" .. ADDON .. ":|r commands: (ui) save <name>, <name>, status, trigger list/add/remove, default <name>")
    end
end