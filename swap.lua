-- swap.lua: equipment saving/equipping helpers for Bears Hot Swap

local ADDON = BHS.ADDON
local SLOTS = BHS.SLOTS

local function InitDB()
    BearsHotSwapDB = BearsHotSwapDB or {}
    BearsHotSwapDB.sets = BearsHotSwapDB.sets or {}
    BHS.DB = BearsHotSwapDB
end

local function ItemID(link)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function SaveSet(name)
    InitDB()
    local set = { ignored = {} }
    for _, slot in ipairs(SLOTS) do
        set[slot] = GetInventoryItemLink("player", slot)
    end
    BHS.Debug("SaveSet: " .. name .. " slot16=" .. tostring(set[16]) .. " slot17=" .. tostring(set[17]))
    BearsHotSwapDB.sets[name] = set
    BHS.Debug("SaveSet: " .. name .. " (SaveEquipmentSet=" .. tostring(type(SaveEquipmentSet)) .. ")")
    -- Also create/update a Blizzard Equipment Manager set with the same name so
    -- bag addons (e.g. BetterBags) categorize these items as "Gear: <name>".
    BHS.Debug("SaveEquipmentSet type=" .. tostring(type(SaveEquipmentSet)) .. " C_EquipmentSet=" .. tostring(type(C_EquipmentSet)))
    if type(C_EquipmentSet) == "table" then
        local keys = {}
        for k, v in pairs(C_EquipmentSet) do table.insert(keys, k .. "=" .. type(v)) end
        BHS.Debug("C_EquipmentSet keys: " .. table.concat(keys, ", "))
    if type(SaveEquipmentSet) == "function" then
        local icon = BHS.ClassIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
        -- If a trigger targets this set, use the aura's spell icon.
        if BearsHotSwapDB and BearsHotSwapDB.triggers then
            for _, t in ipairs(BearsHotSwapDB.triggers) do
                if t.setName and t.setName:lower() == name:lower() then
                    local tex = t.auraIcon
                    if not tex and type(GetSpellTexture) == "function" then
                        if t.spellId then tex = GetSpellTexture(t.spellId) end
                        if not tex then tex = GetSpellTexture(t.auraName) end
                    end
                    BHS.Debug("  trigger tex for " .. tostring(t.auraName) .. " (id " .. tostring(t.spellId) .. ") = " .. tostring(tex) .. " auraIcon=" .. tostring(t.auraIcon))
                    if tex then icon = tex; break end
                end
            end
        end
        BHS.Debug("SaveEquipmentSet icon=" .. tostring(icon))
        local fileID = nil
        if type(GetFileIDFromPath) == "function" then
            fileID = GetFileIDFromPath(icon)
            BHS.Debug("GetFileIDFromPath=" .. tostring(fileID))
        end
        local blizName = name:gsub("^%l", string.upper)
        local ok, err = pcall(SaveEquipmentSet, blizName, icon)
        if not ok then
            BHS.Debug("SaveEquipmentSet failed: " .. tostring(err))
        else
            BHS.Debug("SaveEquipmentSet returned OK for '" .. blizName .. "'.")
        end
        -- Try to update icon via C_EquipmentSet if available.
        if type(C_EquipmentSet) == "table" then
            local id = nil
            if type(C_EquipmentSet.GetEquipmentSetID) == "function" then
                local ok2, res = pcall(C_EquipmentSet.GetEquipmentSetID, blizName)
                if ok2 then id = res end
            end
            BHS.Debug("C_EquipmentSet.GetEquipmentSetID=" .. tostring(id))
            if id and type(C_EquipmentSet.ModifyEquipmentSet) == "function" then
                local useIcon = fileID or icon
                local ok2, err2 = pcall(C_EquipmentSet.ModifyEquipmentSet, id, blizName, useIcon)
                if not ok2 then
                    BHS.Debug("ModifyEquipmentSet failed: " .. tostring(err2))
                else
                    BHS.Debug("ModifyEquipmentSet returned OK.")
                end
            end
        end
    end
    if type(C_EquipmentSet) == "table" and type(C_EquipmentSet.CreateEquipmentSet) == "function" then
        local icon = BHS.ClassIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
        if BearsHotSwapDB and BearsHotSwapDB.triggers then
            for _, t in ipairs(BearsHotSwapDB.triggers) do
                if t.setName and t.setName:lower() == name:lower() then
                    local tex = t.auraIcon
                    if not tex and type(GetSpellTexture) == "function" then
                        if t.spellId then tex = GetSpellTexture(t.spellId) end
                        if not tex then tex = GetSpellTexture(t.auraName) end
                    end
                    BHS.Debug("  trigger tex for " .. tostring(t.auraName) .. " (id " .. tostring(t.spellId) .. ") = " .. tostring(tex) .. " auraIcon=" .. tostring(t.auraIcon))
                    if tex then icon = tex; break end
                end
            end
        end
        local fileID = nil
        if type(GetFileIDFromPath) == "function" and type(icon) == "string" then
            fileID = GetFileIDFromPath(icon)
        end
        if fileID then icon = fileID else icon = 134400 end
        BHS.Debug("CreateEquipmentSet icon=" .. tostring(icon))
        local blizName = name:gsub("^%l", string.upper)
        local ok, err = pcall(C_EquipmentSet.CreateEquipmentSet, blizName, icon)
        if not ok then
            BHS.Debug("CreateEquipmentSet failed: " .. tostring(err))
        else
            BHS.Debug("CreateEquipmentSet returned OK for '" .. blizName .. "'.")
        end
        -- Get set ID and save current gear into it.
        -- Find the set ID by listing all sets.
        local id = nil
        -- Try GetEquipmentSetIDs as method (with self)
        if type(C_EquipmentSet.GetEquipmentSetIDs) == "function" then
            local ok2, sets = pcall(C_EquipmentSet.GetEquipmentSetIDs, C_EquipmentSet)
            if not ok2 or type(sets) ~= "table" then
                ok2, sets = pcall(C_EquipmentSet.GetEquipmentSetIDs)
            end
            BHS.Debug("GetEquipmentSetIDs=" .. tostring(sets and (type(sets) == "table" and #sets or sets) or "nil") .. " ok=" .. tostring(ok2))
            if ok2 and type(sets) == "table" then
                for _, sid in ipairs(sets) do
                    local ok3, sname = pcall(C_EquipmentSet.GetEquipmentSetInfo, sid)
                    BHS.Debug("  set " .. tostring(sid) .. " = " .. tostring(sname))
                    if ok3 and sname and tostring(sname):lower() == blizName:lower() then
                        id = sid
                        break
                    end
                end
            end
        end
        -- Fallback: iterate IDs 1-50
        if not id then
            for sid = 1, 50 do
                local ok3, sname = pcall(C_EquipmentSet.GetEquipmentSetInfo, sid)
                if ok3 and sname and tostring(sname):lower() == blizName:lower() then
                    id = sid
                    BHS.Debug("Found set by iteration: " .. sid .. " = " .. tostring(sname))
                    break
                end
            end
        end
        if not id and type(C_EquipmentSet.GetEquipmentSetID) == "function" then
            local ok2, res = pcall(C_EquipmentSet.GetEquipmentSetID, C_EquipmentSet, blizName)
            if not ok2 then ok2, res = pcall(C_EquipmentSet.GetEquipmentSetID, blizName) end
            if ok2 then id = res end
            BHS.Debug("GetEquipmentSetID=" .. tostring(id))
        end
        if id ~= nil then
            if type(C_EquipmentSet.ModifyEquipmentSet) == "function" then
                local ok2, err2 = pcall(C_EquipmentSet.ModifyEquipmentSet, id, blizName, icon)
                if not ok2 then BHS.Debug("ModifyEquipmentSet failed: " .. tostring(err2))
                else BHS.Debug("ModifyEquipmentSet returned OK.") end
            end
            if type(C_EquipmentSet.SaveEquipmentSet) == "function" then
                local ok3, err3 = pcall(C_EquipmentSet.SaveEquipmentSet, id)
                if not ok3 then BHS.Debug("SaveEquipmentSet failed: " .. tostring(err3))
                else BHS.Debug("SaveEquipmentSet returned OK.") end
            end
        end
    end
    if type(SaveEquipmentSet) ~= "function" and not (type(C_EquipmentSet) == "table" and type(C_EquipmentSet.CreateEquipmentSet) == "function") then
        BHS.Debug("No equipment set API found.")
    end
    BHS.Debug("saved set '" .. name .. "'")
end

local function GetContainerNumSlotsCompat(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    elseif type(GetContainerNumSlots) == "function" then
        return GetContainerNumSlots(bag)
    end
    return 0
end

local function GetContainerItemLinkCompat(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    elseif type(GetContainerItemLink) == "function" then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

local function PickupContainerItemCompat(bag, slot)
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    elseif type(PickupContainerItem) == "function" then
        PickupContainerItem(bag, slot)
    end
end

local function FindInBags(targetLink)
    local targetID = ItemID(targetLink)
    if not targetID then return nil, nil end
    for bag = 0, 4 do
        local num = GetContainerNumSlotsCompat(bag)
        if num and num > 0 then
            for slot = 1, num do
                local link = GetContainerItemLinkCompat(bag, slot)
                if link and ItemID(link) == targetID then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

local function EquipSet(name)
    InitDB()
    BHS.Debug("EquipSet: " .. tostring(name))
    if InCombatLockdown and InCombatLockdown() then
        BHS.pendingCombatSet = name
        print("|cff33ff99" .. ADDON .. ":|r in combat - '" .. name .. "' set queued.")
        return
    end
    local resolved = name
    if BHS.FindSetKey then resolved = BHS.FindSetKey(name) or name end
    local set = BearsHotSwapDB.sets and BearsHotSwapDB.sets[resolved]
    if not set then
        print("|cff33ff99" .. ADDON .. ":|r no saved set named '" .. name .. "'. Use /bhs save " .. name .. ".")
        return
    end
    name = resolved
    for _, slot in ipairs(SLOTS) do
        if set.ignored and set.ignored[slot] then
            -- ignored slot: never change
        else
        local target = set[slot]
        local current = GetInventoryItemLink("player", slot)
        local targetID = ItemID(target)
        local currentID = ItemID(current)
        if slot == 16 or slot == 17 then
            BHS.Debug("  slot " .. slot .. " target=" .. tostring(target) .. " current=" .. tostring(current))
            BHS.Debug("  slot " .. slot .. " targetID=" .. tostring(targetID) .. " currentID=" .. tostring(currentID))
        end
        if targetID and targetID ~= currentID then
            local ok, bag, bslot = pcall(FindInBags, target)
            if not ok then
                BHS.Debug("  FindInBags error: " .. tostring(bag))
                bag, bslot = nil, nil
            end
            BHS.Debug("  slot " .. slot .. ": FindInBags=" .. tostring(bag) .. "," .. tostring(bslot))
            if bag then
                BHS.Debug("  slot " .. slot .. ": equipping " .. tostring(targetID) .. " from bag " .. bag .. " slot " .. bslot)
                local ok, err = pcall(PickupContainerItemCompat, bag, bslot)
                if not ok then BHS.Debug("  PickupContainerItem error: " .. tostring(err)) end
                ok, err = pcall(EquipCursorItem, slot)
                if not ok then BHS.Debug("  EquipCursorItem error: " .. tostring(err)) end
                if CursorHasItem and CursorHasItem() then
                    ClearCursor()
                end
            else
                BHS.Debug("  slot " .. slot .. ": item " .. tostring(targetID) .. " not in bags")
            end
        elseif targetID then
            BHS.Debug("  slot " .. slot .. ": already equipped")
        end
        end
    end
end

BHS.SaveSet = SaveSet
BHS.EquipSet = EquipSet

-- hook: refresh UI after equip
local origEquip = EquipSet
BHS.EquipSet = function(name)
    origEquip(name)
    if BHS.RefreshUI then BHS.RefreshUI() end
end