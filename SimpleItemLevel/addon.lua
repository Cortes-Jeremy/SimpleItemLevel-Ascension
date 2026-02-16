local myname, ns = ...
local myfullname = C_AddOns.GetAddOnMetadata(myname, "Title")
local db
ns.DEBUG = C_AddOns.GetAddOnMetadata(myname, "Version") == "@".."project-version@"

_G.SimpleItemLevel = {}

local SLOT_MAINHAND = GetInventorySlotInfo("MainHandSlot")
local SLOT_OFFHAND = GetInventorySlotInfo("SecondaryHandSlot")

function ns.Print(...) print("|cFF33FF99".. myfullname.. "|r:", ...) end

-- events
local hooks = {}
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) if ns[event] then return ns[event](ns, event, ...) end end)
function ns:RegisterEvent(...) for i=1,select("#", ...) do f:RegisterEvent((select(i, ...))) end end
function ns:UnregisterEvent(...) for i=1,select("#", ...) do f:UnregisterEvent((select(i, ...))) end end
function ns:RegisterAddonHook(addon, callback)
    if C_AddOns.IsAddOnLoaded(addon) then
        xpcall(callback, geterrorhandler())
    else
        hooks[addon] = callback
    end
end

local LAI = LibStub("LibAppropriateItems-1.0")

ns.soulboundAtlas = "Soulbind-32x32" -- "AzeriteReady" -- UF-SoulShard-Icon-2x
ns.upgradeAtlas = "poi-door-arrow-up" -- MiniMap-PositionArrowUp?
ns.upgradeString = CreateAtlasMarkup(ns.upgradeAtlas, 1.5, 1, 0)
ns.gemString = CreateAtlasMarkup("jailerstower-score-gem-tooltipicon", 1.4, 0, -2) -- worldquest-icon-jewelcrafting
ns.enchantString = RED_FONT_COLOR:WrapTextInColorCode("E")

ns.Fonts = {
    HighlightSmall = GameFontHighlightSmall,
    Normal = GameFontNormalOutline,
    Large = GameFontNormalLargeOutline,
    Huge = GameFontNormalHugeOutline,
    NumberNormal = NumberFontNormal,
    NumberNormalSmall = NumberFontNormalSmall,
}

ns.PositionOffsets = {
    TOPLEFT = {2, -2},
    TOPRIGHT = {-2, -2},
    BOTTOMLEFT = {2, 2},
    BOTTOMRIGHT = {-2, 2},
    BOTTOM = {0, 2},
    TOP = {0, -2},
    LEFT = {2, 0},
    RIGHT = {-2, 0},
    CENTER = {0, 0},
}

-- A lot of space on the character sheet freed up here

-- Ilvl

local IlvlPosRight = {"TOPLEFT", "TOPRIGHT", 8, 0}
local IlvlPosLeft = {"TOPRIGHT", "TOPLEFT", -8, 0}

ns.CharacterButtonInsetPositions = {
    AscensionCharacterMainHandSlot = {"BOTTOM", "TOP", 0, 6},
    AscensionInspectMainHandSlot = {"BOTTOM", "TOP", 0, 6},
    AscensionCharacterSecondaryHandSlot = {"BOTTOM", "TOP", 0, 6},
    AscensionInspectSecondaryHandSlot = {"BOTTOM", "TOP", 0, 6},
    AscensionCharacterRangedSlot = {"BOTTOM", "TOP", 0, 6},
    AscensionInspectRangedSlot = {"BOTTOM", "TOP", 0, 6},
}
for _, slot in ipairs({"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist"}) do
    ns.CharacterButtonInsetPositions["AscensionCharacter"..slot.."Slot"] = IlvlPosRight
    ns.CharacterButtonInsetPositions["AscensionInspect"..slot.."Slot"] = IlvlPosRight
end
for _, slot in ipairs({"Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1"}) do
    ns.CharacterButtonInsetPositions["AscensionCharacter"..slot.."Slot"] = IlvlPosLeft
    ns.CharacterButtonInsetPositions["AscensionInspect"..slot.."Slot"] = IlvlPosLeft
end

-- Enchant

local EnchPosRight = {"LEFT", "RIGHT", 8, 0}
local EnchPosLeft = {"RIGHT", "LEFT", -8, 0}

ns.CharacterButtonInsetPositionsEnchant = {
    AscensionCharacterMainHandSlot = {"BOTTOMRIGHT", "TOPRIGHT", -1, 20},
    AscensionInspectMainHandSlot = {"BOTTOMRIGHT", "TOPRIGHT", -1, 20},
    AscensionCharacterSecondaryHandSlot = {"BOTTOMLEFT", "TOPLEFT", 1, 20},
    AscensionInspectSecondaryHandSlot = {"BOTTOMLEFT", "TOPLEFT", 1, 20},
    AscensionCharacterRangedSlot = {"TOPLEFT", "TOPRIGHT", 8, 0},
    AscensionInspectRangedSlot = {"TOPLEFT", "TOPRIGHT", 8, 0},
}
for _, slot in ipairs({"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist"}) do
    ns.CharacterButtonInsetPositionsEnchant["AscensionCharacter"..slot.."Slot"] = EnchPosRight
    ns.CharacterButtonInsetPositionsEnchant["AscensionInspect"..slot.."Slot"] = EnchPosRight
end
for _, slot in ipairs({"Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1"}) do
    ns.CharacterButtonInsetPositionsEnchant["AscensionCharacter"..slot.."Slot"] = EnchPosLeft
    ns.CharacterButtonInsetPositionsEnchant["AscensionInspect"..slot.."Slot"] = EnchPosLeft
end


ns.defaults = {
    -- places
    character = true,
    character_inset = false,
    inspect = true,
    inspect_inset = false,
    bags = true,
    merchants = true,
    auctions = true,
    loot = true,
    flyout = true,
    tooltip = true,
    characteravg = false,
    inspectavg = false,
    -- equipmentonly = true,
    equipment = true,
    battlepets = true,
    reagents = false,
    misc = false,
    -- data points
    itemlevel = true,
    upgrades = true,
    missinggems = true,
    missingenchants = true,
    missingcharacter = false, -- missing on character-frame only
    bound = true,
    -- display
    color = true,
    -- Retail has Uncommon, BCC/Classic has Good
    quality = Enum.ItemQuality.Common or Enum.ItemQuality.Standard,
    -- appearance config
    font = "NumberNormal",
    position = "TOPRIGHT",
    positionup = "TOPLEFT",
    positionmissing = "LEFT",
    positionbound = "BOTTOMLEFT",
    scaleup = 1,
    scalebound = 1,
}

function ns:ADDON_LOADED(event, addon)
    if hooks[addon] then
        xpcall(hooks[addon], geterrorhandler())
        hooks[addon] = nil
    end
    if addon == myname then
        _G[myname.."DB"] = setmetatable(_G[myname.."DB"] or {}, {
            __index = ns.defaults,
        })
        db = _G[myname.."DB"]
        ns.db = db

        ns:SetupConfig()

        -- So our upgrade arrows can work reliably when opening inventories
        ns.CacheEquippedItems()
    end
end
ns:RegisterEvent("ADDON_LOADED")

ns.frames = {} -- TODO: should I make this a FramePool now?
local function PrepareItemButton(button, variant)
    if not button.simpleilvl then
        local overlayFrame = CreateFrame("FRAME", nil, button)
        overlayFrame:SetAllPoints()
        overlayFrame:SetFrameLevel(button:GetFrameLevel() + 1)
        button.simpleilvloverlay = overlayFrame

        button.simpleilvl = overlayFrame:CreateFontString(nil, "OVERLAY")
        button.simpleilvl:Hide()

        button.simpleilvlup = overlayFrame:CreateTexture(nil, "OVERLAY")
        button.simpleilvlup.baseSize = 10
        button.simpleilvlup:SetSize(button.simpleilvlup.baseSize, button.simpleilvlup.baseSize)
        button.simpleilvlup:SetAtlas(ns.upgradeAtlas, Const.TextureKit.IgnoreAtlasSize)
        button.simpleilvlup:Hide()

        button.simpleilvlmissing = overlayFrame:CreateFontString(nil, "OVERLAY")
        button.simpleilvlmissing:Hide()

        button.simpleilvlenchant = overlayFrame:CreateFontString(nil, "OVERLAY")
        button.simpleilvlenchant:SetFontObject(GameFontGreen)
        local font, size, flags = button.simpleilvlenchant:GetFont()
        button.simpleilvlenchant:SetFont(font, size * 0.8, flags)
        button.simpleilvlenchant:Hide()

        button.simpleilvlbound = overlayFrame:CreateTexture(nil, "OVERLAY")
        button.simpleilvlbound.baseSize = 6 -- 10
        button.simpleilvlbound:SetSize(button.simpleilvlbound.baseSize, button.simpleilvlbound.baseSize)
        button.simpleilvlbound:SetAtlas(ns.soulboundAtlas, Const.TextureKit.IgnoreAtlasSize) -- Soulbind-32x32
        button.simpleilvlbound:Hide()

        ns.frames[button] = overlayFrame
    end
    button.simpleilvloverlay.variant = variant or button.simpleilvloverlay.variant
    variant = button.simpleilvloverlay.variant

    button.simpleilvloverlay:SetFrameLevel(button:GetFrameLevel() + 1)

    -- Apply appearance config:
    button.simpleilvl:ClearAllPoints()
    local position, positionOffsets = db.position, ns.PositionOffsets[db.position]
    if ((variant == "character" and db.character_inset) or (variant == "inspect" and db.inspect_inset)) and ns.CharacterButtonInsetPositions[button:GetName()] and not button.demo then
        local point, relativePoint, x, y = unpack(ns.CharacterButtonInsetPositions[button:GetName()])
        button.simpleilvl:SetPoint(point, button.simpleilvloverlay, relativePoint, x, y)
    else
        button.simpleilvl:SetPoint(db.position, unpack(ns.PositionOffsets[db.position]))
    end
    button.simpleilvl:SetFontObject(ns.Fonts[db.font] or NumberFontNormal)
    -- button.simpleilvl:SetJustifyH('RIGHT')

    button.simpleilvlup:ClearAllPoints()
    button.simpleilvlup:SetPoint(db.positionup, unpack(ns.PositionOffsets[db.positionup]))
    if button.simpleilvlup.SetScale then
        button.simpleilvlup:SetScale(db.scaleup or 1)
    else
        local s = db.scaleup or 1
        button.simpleilvlup:SetSize( button.simpleilvlup.baseSize * s, button.simpleilvlup.baseSize * s)
    end

    button.simpleilvlmissing:ClearAllPoints()
    button.simpleilvlmissing:SetPoint(db.positionmissing, unpack(ns.PositionOffsets[db.positionmissing]))
    button.simpleilvlmissing:SetFont([[Fonts\ARIALN.TTF]], 11, "OUTLINE,MONOCHROME")

    button.simpleilvlenchant:ClearAllPoints()
    if ((variant == "character" and db.character_inset) or (variant == "inspect" and db.inspect_inset)) and ns.CharacterButtonInsetPositions[button:GetName()] and not button.demo then
        local point, relativePoint, x, y = unpack(ns.CharacterButtonInsetPositionsEnchant[button:GetName()])
        button.simpleilvlenchant:SetPoint(point, button.simpleilvloverlay, relativePoint, x, y)
    else
        button.simpleilvlenchant:Hide()
    end

    button.simpleilvlbound:ClearAllPoints()
    button.simpleilvlbound:SetPoint(db.positionbound, unpack(ns.PositionOffsets[db.positionbound]))
    if button.simpleilvlbound.SetScale then
        button.simpleilvlbound:SetScale(db.scalebound or 1)
    else
        local s = db.scalebound or 1
        button.simpleilvlbound:SetSize( button.simpleilvlbound.baseSize * s, button.simpleilvlbound.baseSize * s)
    end
end
ns.PrepareItemButton = PrepareItemButton

local blank = {}
local function CleanButton(button, suppress)
    suppress = suppress or blank
    if button.simpleilvl and not suppress.level then button.simpleilvl:Hide() end
    if button.simpleilvlup and not suppress.upgrade then button.simpleilvlup:Hide() end
    if button.simpleilvlmissing and not suppress.missing then button.simpleilvlmissing:Hide() end
    if button.simpleilvlbound and not suppress.bound then button.simpleilvlbound:Hide() end
    if button.simpleilvlenchant and not suppress.enchant then button.simpleilvlenchant:Hide() end
end
ns.CleanButton = CleanButton

function ns.RefreshOverlayFrames()
    for button in pairs(ns.frames) do
        PrepareItemButton(button)
    end
end

local function AddLevelToButton(button, item)
    if not (db.itemlevel and item) then
        return button.simpleilvl and button.simpleilvl:Hide()
    end

    local quality = item:GetItemQuality()
    local r, g, b = GetItemQualityColor(db.color and quality or 1)
    local ilvl

    if quality == 7 and item.equipmentUnit ~= nil then
        ilvl = GetHeirloomEffectiveIlvl(item.equipmentUnit)
    else
        ilvl = item:GetCurrentItemLevel() or "?"
    end

    button.simpleilvl:SetText(ilvl)
    button.simpleilvl:SetTextColor(r, g, b)
    button.simpleilvl:Show()
end

local function AddUpgradeToButton(button, item, equipLoc, minLevel)
    if not (db.upgrades and LAI:IsAppropriate(item:GetItemID())) then
        return button.simpleilvlup and button.simpleilvlup:Hide()
    end

    if item:GetItemLocation() and item:GetItemLocation():IsEquipmentSlot() and button.unit == "player" then
        -- This is meant to catch the character frame, to avoid rings/trinkets
        -- you've already got equipped showing as an upgrade since they're
        -- higher ilevel than your other ring/trinket
        return
    end

    ns.ForEquippedItems(equipLoc, function(equippedItem, slot)
        if not equippedItem then
            return
        end

        if equippedItem:IsItemEmpty() and slot == SLOT_OFFHAND then
            local mainhand = GetInventoryItemID("player", SLOT_MAINHAND)
            if mainhand then
                local itemInfos = GetItemInfoInstant(mainhand)
                local invtype = INVTYPE_TO_STRING[itemInfos.inventoryType]

                if invtype == "INVTYPE_2HWEAPON" then
                    return
                end
            end
        end

        -- Player Item
        local equippedItemLevel
        if equippedItem:GetItemQuality() == 7 and equippedItem.equipmentUnit ~= nil then
            equippedItemLevel = GetHeirloomEffectiveIlvl(equippedItem.equipmentUnit)
        else
            equippedItemLevel = equippedItem:GetCurrentItemLevel() or 0
        end

        -- Inspect Item
        local itemLevel
        if item:GetItemQuality() == 7 and item.equipmentUnit ~= nil then
            itemLevel = GetHeirloomEffectiveIlvl(item.equipmentUnit)
        else
            itemLevel = item:GetCurrentItemLevel() or 0
        end

        -- Compare
        if equippedItem:IsItemEmpty() or equippedItemLevel < itemLevel then
            button.simpleilvlup:Show()
            if minLevel and minLevel > UnitLevel("player") then
                button.simpleilvlup:SetVertexColor(1, 0, 0)
            else
                button.simpleilvlup:SetVertexColor(1, 1, 1)
            end
        end

    end)
end

local function AddMissingToButton(button, itemLink)
    if not itemLink then
        return button.simpleilvlmissing and button.simpleilvlmissing:Hide()
    end
    local missingGems     = db.missinggems     and ns.ItemHasEmptySlots(itemLink)
    local missingEnchants = db.missingenchants and ns.ItemIsMissingEnchants(itemLink)
    -- print(itemLink, missingEnchants, missingGems)
    button.simpleilvlmissing:SetFormattedText("%s%s", missingGems and ns.gemString or "", missingEnchants and ns.enchantString or "")
    button.simpleilvlmissing:Show()
end

local function AddEnchantToButton(button, link, variant)
    if not button.simpleilvlenchant then return end
    --[[ if not db.showEnchants then
        return button.simpleilvlenchant and button.simpleilvlenchant:Hide()
    end ]]

    if not ((variant == "character" and db.character_inset) or (variant == "inspect" and db.inspect_inset))then
        button.simpleilvlenchant:Hide()
        return
    end

    local enchantName = ns.GetEnchantNameFromLink(link)

    if enchantName then
        local maxLen = 999
        if #enchantName > maxLen then
            button.simpleilvlenchant:SetText(string.sub(enchantName, 1, maxLen) .. "...")
        else
            button.simpleilvlenchant:SetText(enchantName)
        end
        button.simpleilvlenchant:Show()
    else
        button.simpleilvlenchant:Hide()
    end
end

local function AddBoundToButton(button, item)
    if not db.bound then
        return button.simpleilvlbound and button.simpleilvlbound:Hide()
    end

    if item:GetItemLocation() and item:GetItemLocation():IsEquipmentSlot() then
        -- This is meant to catch the character frame
        return
    end

    if item and item:IsItemInPlayersControl() then
        local itemLocation = item:GetItemLocation()

        if item:IsBloodforged() or itemLocation and C_Item.IsBound(itemLocation) then
            button.simpleilvlbound:Show()

            if item:IsBloodforged() then
                button.simpleilvlbound:SetVertexColor(1,.1,.1)
            else
                button.simpleilvlbound:SetVertexColor(1,1,1)
            end
        end
    end
end

local function ShouldShowOnItem(item)

    local quality = item:GetItemQuality() or -1
    if quality < db.quality then
        return false
    end

    local itemID = item:GetItemID()
    local itemInfos = GetItemInfoInstant(itemID)
    local itemClass = itemInfos.classID

    if (itemClass == Enum.ItemClass.Weapon or itemClass == Enum.ItemClass.Armor ) then
        return db.equipment
    end

    if itemClass == 5 then
        return db.reagents
    end

    return db.misc
end

local function ApplyItemQualityVisual(button, quality)
    if not button then return end

    local icon = button.icon or button.Icon or button.IconTexture or _G[button:GetName().."IconTexture"]
    if not icon then return end

    if quality and quality > 1 then
        -- Uncommon / Rare / Epic
        SetItemButtonQuality(button, quality)
        SetItemButtonDesaturated(button, false)
        SetItemButtonTextureVertexColor(button, 1, 1, 1)
        SetItemButtonNormalTextureVertexColor(button, 1, 1, 1)

    elseif quality == 1 then
        -- Common (blanc) → reset total
        SetItemButtonQuality(button, nil)
        SetItemButtonDesaturated(button, false)
        SetItemButtonTextureVertexColor(button, 1, 1, 1)
        SetItemButtonNormalTextureVertexColor(button, 1, 1, 1)

    elseif quality == 0 then
        -- Poor (gris)
        SetItemButtonQuality(button, nil)
        SetItemButtonDesaturated(button, true, 0.5, 0.5, 0.5)
        SetItemButtonNormalTextureVertexColor(button, 0.7, 0.7, 0.7)

    else
        -- fallback sécurité
        SetItemButtonQuality(button, nil)
        SetItemButtonDesaturated(button, false)
        SetItemButtonTextureVertexColor(button, 1, 1, 1)
        SetItemButtonNormalTextureVertexColor(button, 1, 1, 1)
    end
end


local blank = {}
local function UpdateButtonFromItem(button, item, variant, suppress)
    if not item then return end
    ExtendItem(item) -- Ascension
    if item:IsItemEmpty() then return end

    suppress = suppress or blank
    item:ContinueOnItemLoad(function()

        -- TEMP
        local itemInfos = GetItemInfoInstant(item:GetItemID())
        ApplyItemQualityVisual(button, itemInfos.quality)
        -- //

        if not ShouldShowOnItem(item) then return end
        PrepareItemButton(button, variant)
        local itemID = item:GetItemID()
        local link = item:GetInstanceItemLink(item.equipmentUnit)
        local itemInfos = GetItemInfoInstant(itemID)
        local equipLoc = INVTYPE_TO_STRING[itemInfos.inventoryType]
        local minLevel = link and select(5, GetItemInfo(link or itemID))

        if not suppress.level then AddLevelToButton(button, item) end
        if not suppress.upgrade then AddUpgradeToButton(button, item, equipLoc, minLevel) end
        if not suppress.bound then AddBoundToButton(button, item) end
        if (variant == "character" or variant == "inspect" or not db.missingcharacter) then
            if not suppress.missing then AddMissingToButton(button, link) end
        end
        AddEnchantToButton(button, link, variant)

    end)
end
ns.UpdateButtonFromItem = UpdateButtonFromItem

local continuableContainer
local function AddAverageLevelToFontString(unit, fontstring)
    if not continuableContainer then
        continuableContainer = ContinuableContainer:Create()
    end

    fontstring:Hide()

    local key = unit == "player" and "character" or "inspect"
    if not db[key .. "avg"] then
        return
    end

    local mainhandEquipLoc, offhandEquipLoc
    local items = {}

    for slotID = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        -- shirt and tabard don't count
        if slotID ~= INVSLOT_BODY and slotID ~= INVSLOT_TABARD then
            local itemID = GetInventoryItemID(unit, slotID) -- GetInventoryItemTrueID
            local itemLink = GetInventoryItemLink(unit, slotID)
            if itemLink or itemID then
                local item = itemLink and Item:CreateFromItemLink(itemLink) or Item:CreateFromItemID(itemID)
                continuableContainer:AddContinuable(item)
                table.insert(items, item)
                -- slot bookkeeping
                local itemInfos = GetItemInfoInstant(itemLink and GetItemInfoFromHyperlink(itemLink) or itemID)
                local equipLoc = INVTYPE_TO_STRING[itemInfos.inventoryType]
                if slotID == INVSLOT_MAINHAND then mainhandEquipLoc = equipLoc end
                if slotID == INVSLOT_OFFHAND then offhandEquipLoc = equipLoc end
            end
        end
    end

    local numSlots
    if mainhandEquipLoc and offhandEquipLoc then
        numSlots = 16
    else
        local isFuryWarrior = select(2, UnitClass(unit)) == "WARRIOR"
        if unit == "player" then
            isFuryWarrior = isFuryWarrior and IsSpellKnown(1146917) -- knows titan's grip
        else
            isFuryWarrior = isFuryWarrior and _G.GetInspectSpecialization and GetInspectSpecialization(unit) == 72
        end
        -- unit is holding a one-handed weapon, a main-handed weapon, or a 2h weapon while Fury: 16 slots
        -- otherwise 15 slots
        local equippedLocation = mainhandEquipLoc or offhandEquipLoc
        numSlots = (
            equippedLocation == "INVTYPE_WEAPON" or
            equippedLocation == "INVTYPE_WEAPONMAINHAND" or
            (equippedLocation == "INVTYPE_2HWEAPON" and isFuryWarrior)
        ) and 16 or 15
    end
    if pcall(GetInventorySlotInfo, "RANGEDSLOT") then
         -- ranged slot exists until Pandaria
         -- C_PaperDollInfo.IsRangedSlotShown(), but that doesn't actually exist in classic...
        numSlots = numSlots + 1
    end
    continuableContainer:ContinueOnLoad(function()
        local totalLevel = 0
        for slotID, item in ipairs(items) do
            totalLevel = totalLevel + item:GetCurrentItemLevel()
        end
        fontstring:SetFormattedText(ITEM_LEVEL, totalLevel / numSlots)
        fontstring:Show()
    end)
end

-- Character frame:

local function UpdateItemSlotButton(button, unit)
    CleanButton(button)

    local key = unit == "player" and "character" or "inspect"
    if not db[key] then
        return
    end
    local slotID = button:GetID()

    if (slotID >= INVSLOT_FIRST_EQUIPPED and slotID <= INVSLOT_LAST_EQUIPPED) then
        local item = Item:CreateFromEquipmentSlot(unit, slotID)
        UpdateButtonFromItem(button, item, key)
    end
end

do
    local levelUpdater = CreateFrame("Frame")
    levelUpdater:SetScript("OnUpdate", function(self)
        if not self.avglevel then
            self.avglevel = AscensionPaperDollPanelModel:CreateFontString(nil, "OVERLAY")
            self.avglevel:SetPoint("TOP", 0, -8)
            self.avglevel:SetFontObject(NumberFontNormal) -- GameFontHighlightSmall isn't bad
        end
        AddAverageLevelToFontString("player", self.avglevel)
        self:Hide()
    end)
    levelUpdater:Hide()

    for _, slot in pairs({AscensionPaperDollPanel.ItemsFrame:GetChildren()}) do
        if slot.Update then
            hooksecurefunc(slot, "Update", function(button)
                UpdateItemSlotButton(button, "player")
                levelUpdater:Show()
            end)
        end
    end
end

-- Inspect frame

ns:RegisterAddonHook("Ascension_InspectUI", function()

    local avglevel
    hooksecurefunc(InspectPaperDollPanel, "SetUnit", function(self, unit)
        if not avglevel then
            avglevel = InspectPaperDollPanelModel:CreateFontString(nil, "OVERLAY")
            avglevel:SetFontObject(NumberFontNormal)
            avglevel:SetPoint("TOP", 0, -8)
        end
        AddAverageLevelToFontString(self.unit or "target", avglevel)
    end)

    for _, slot in pairs({InspectPaperDollPanel.ItemsFrame:GetChildren()}) do
        if slot.Update then
            hooksecurefunc(slot, "Update", function(button)
                CleanButton(button)
                UpdateItemSlotButton(button, InspectFrame.unit or "target")
            end)
        end
    end

end)

-- Equipment flyout in character frame

local function ItemFromEquipmentFlyoutDisplayButton(button)
    local location = button.location
    if not location then return end

    if location >= EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION then
        return
    end

    local player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(location)

    -- Bag item
    if bags and bag and slot then
        local item = Item:CreateFromBagAndSlot(bag, slot)
        if item then
            item:SetBagAndSlot(bag, slot)
            return item
        end

    -- Equipped item (player or bank)
    elseif (player or bank) and slot then
        local item = Item:CreateFromEquipmentSlot("player", slot)
        if item then
            item:SetEquipmentSlot("player", slot)
            return item
        end
    end

    -- Fallback
    local itemID = EquipmentManager_GetItemInfoByLocation(location)
    if itemID then
        return Item:CreateFromItemID(itemID)
    end

end

hooksecurefunc(EquipmentFlyoutFrame, "RefreshItems", function(self)
    if not db.character then return end
    if not self.ButtonPool then return end

    for button in self.ButtonPool:EnumerateActive() do
        CleanButton(button)

        local item = ItemFromEquipmentFlyoutDisplayButton(button)
        if item then
            UpdateButtonFromItem(button, item, "character")
        end
    end
end)

-- Bags:

local function UpdateContainerButton(button, bag, slot)
    CleanButton(button)
    if not db.bags then
        return
    end
    slot = slot or button:GetID()
    if not (bag and slot) then
        return
    end
    local item = Item:CreateFromBagAndSlot(bag, slot or button:GetID())
    UpdateButtonFromItem(button, item, "bags")
end

hooksecurefunc("ContainerFrame_Update", function(container)
    local bag = container:GetID()
    local name = container:GetName()
    for i = 1, container.size, 1 do
        local button = _G[name .. "Item" .. i]
        UpdateContainerButton(button, bag)
    end
end)

hooksecurefunc("BankFrameItemButton_Update", function(button)
    if button.isBag then return end
    local slotID = button:GetID()
    local bagID = BANK_CONTAINER
    UpdateContainerButton(button, bagID, slotID)
end)

-- Loot

hooksecurefunc("LootFrame_UpdateButton", function(index)
    local button = _G["LootButton"..index]
    if not button then return end
    CleanButton(button)
    if not db.loot then return end
    -- ns.Debug("LootFrame_UpdateButton", button:IsEnabled(), button.slot, button.slot and GetLootSlotLink(button.slot))
    if button:IsEnabled() and button.slot then
        local link = GetLootSlotLink(button.slot)
        if link then
            UpdateButtonFromItem(button, Item:CreateFromItemLink(link), "loot", { missing = true })
        end
    end
end)

-- Tooltip

local OnTooltipSetItem = function(self)
    if not db.tooltip then return end
    local _, itemLink = self:GetItem()
    if not itemLink then return end
    local item = Item:CreateFromItemLink(itemLink)
    if item:IsItemEmpty() then return end
    item:ContinueOnItemLoad(function()
        self:AddLine(ITEM_LEVEL:format(item:GetCurrentItemLevel()))
    end)
end
if _G.TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
else
    GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    -- This is mostly world quest rewards:
    if GameTooltip.ItemTooltip then
        GameTooltip.ItemTooltip.Tooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    end
end

-- Void Storage

ns:RegisterAddonHook("Blizzard_VoidStorageUI", function()
    local VOID_STORAGE_MAX = 80
    hooksecurefunc("VoidStorage_ItemsUpdate", function(doStorage, doContents)
        if not doContents then return end
        for i = 1, VOID_STORAGE_MAX do
            local itemID, textureName, locked, recentDeposit, isFiltered, quality = GetVoidItemInfo(VoidStorageFrame.page, i)
            local button = _G["VoidStorageStorageButton"..i]
            CleanButton(button)
            if itemID and db.bags then
                local link = GetVoidItemHyperlinkString(((VoidStorageFrame.page - 1) * VOID_STORAGE_MAX) + i)
                if link then
                    local item = Item:CreateFromItemLink(link)
                    UpdateButtonFromItem(button, item, "bags")
                end
            end
        end
    end)
end)

-- Auction House

ns:RegisterAddonHook("Blizzard_AuctionUI", function()

    -- Browse tab
    hooksecurefunc("AuctionFrameBrowse_Update", function()
        if not db.auctions then return end

        local numItems = GetNumAuctionItems("list")
        for i = 1, NUM_BROWSE_TO_DISPLAY do
            local button = _G["BrowseButton"..i.."Item"]
            if button then
                CleanButton(button)

                local index = i + FauxScrollFrame_GetOffset(BrowseScrollFrame)
                if index <= numItems then
                    local link = GetAuctionItemLink("list", index)
                    if link then
                        local item = Item:CreateFromItemLink(link)
                        UpdateButtonFromItem(button, item, "Auction", { missing = true })
                    end
                end
            end
        end
    end)

    -- Bid tab
    hooksecurefunc("AuctionFrameBid_Update", function()
        if not db.auctions then return end

        local numItems = GetNumAuctionItems("bidder")
        for i = 1, NUM_BIDS_TO_DISPLAY do
            local button = _G["BidButton"..i.."Item"]
            if button then
                CleanButton(button)

                local index = i + FauxScrollFrame_GetOffset(BidScrollFrame)
                if index <= numItems then
                    local link = GetAuctionItemLink("bidder", index)
                    if link then
                        local item = Item:CreateFromItemLink(link)
                        UpdateButtonFromItem(button, item, "Auction", { missing = true })
                    end
                end
            end
        end
    end)

    -- Auctions tab
    hooksecurefunc("AuctionFrameAuctions_Update", function()
        if not db.auctions then return end

        local numItems = GetNumAuctionItems("owner")
        for i = 1, NUM_AUCTIONS_TO_DISPLAY do
            local button = _G["AuctionsButton"..i.."Item"]
            if button then
                CleanButton(button)

                local index = i + FauxScrollFrame_GetOffset(AuctionsScrollFrame)
                if index <= numItems then
                    local link = GetAuctionItemLink("owner", index)
                    if link then
                        local item = Item:CreateFromItemLink(link)
                        UpdateButtonFromItem(button, item, "Auction", { missing = true })
                    end
                end
            end
        end
    end)

end)

-- Group Loot Roll

local function UpdateGroupLootButton(frame)
    if not db.loot then return end
    local IconFrame = _G[frame:GetName().."IconFrame"]
    if not frame or not IconFrame then return end

    CleanButton(IconFrame)

    if frame.rollID then
        local link = GetLootRollItemLink(frame.rollID)
        if link then
            local item = Item:CreateFromItemLink(link)
            UpdateButtonFromItem(IconFrame, item, "loot", { missing = true })
        end
    end
end

hooksecurefunc("GroupLootFrame_OpenNewFrame", function(rollID)
    C_Timer.After(0.05, function()
        for i = 1, NUM_GROUP_LOOT_FRAMES do
            local frame = _G["GroupLootFrame"..i]
            if frame and frame.rollID == rollID then
                UpdateGroupLootButton(frame)
                break
            end
        end
    end)
end)

-- Merchant Frame

local function UpdateMerchantButton(button)
    if not db.merchants then return end
    if not button or not button:IsShown() then return end

    local index = button:GetID()
    local _, _, _, _, numAvailable, isUsable = GetMerchantItemInfo(index)

    CleanButton(button)

    local itemLink = GetMerchantItemLink(index)
    if not itemLink then return end

    local item = Item:CreateFromItemLink(itemLink)
    if not item then return end

    UpdateButtonFromItem(button, item, "merchant", { missing = true })

    if numAvailable == 0 then
        if not isUsable then
            SetItemButtonTextureVertexColor(button, 0.5, 0, 0)
            SetItemButtonNormalTextureVertexColor(button, 0.5, 0, 0)
        else
            SetItemButtonTextureVertexColor(button, 0.5, 0.5, 0.5)
            SetItemButtonNormalTextureVertexColor(button, 0.5, 0.5, 0.5)
        end
    elseif not isUsable then
        SetItemButtonTextureVertexColor(button, 0.9, 0, 0)
        SetItemButtonNormalTextureVertexColor(button, 0.9, 0, 0)
    end
end

local function UpdateAllMerchantButtons()
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local button = _G["MerchantItem"..i.."ItemButton"]
        if button then
            UpdateMerchantButton(button)
        end
    end
end

hooksecurefunc("MerchantFrame_OnShow", UpdateAllMerchantButtons)
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", UpdateAllMerchantButtons)

-- Adibags
ns:RegisterAddonHook("AdiBags", function()
    local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags")
    local searchModule = AdiBags:GetModule("SearchHighlight", true)

    local function IsItemSearchFiltered(button)
        if not (searchModule and searchModule:IsEnabled() and searchModule.widget) then
            return false
        end

        local searchText = searchModule.widget:GetText()
        if not searchText or searchText:trim() == "" then
            return false
        end

        local itemName = GetItemInfo(button.itemId)
        return itemName and not itemName:lower():match(searchText:lower():trim())
    end

    local function ApplySearchFilter(button)
        SetItemButtonDesaturated(button, false)
        button.IconTexture:SetVertexColor(0.2, 0.2, 0.2)
        button.IconBorder:Hide()
        button.IconQuestTexture:Hide()
        button.Count:Hide()
        button.Stock:Hide()
    end

    local function ReapplyPoorQuality(button)
        if button.__itemQuality == 0 then
            SetItemButtonDesaturated(button, true, 0.5, 0.5, 0.5)
            SetItemButtonNormalTextureVertexColor(button, 0.7, 0.7, 0.7)
            button.IconTexture:SetVertexColor(0.5, 0.5, 0.5)
        end
    end

    AdiBags.RegisterMessage(ns, "AdiBags_UpdateButton", function(event, button)
        if not (db.bags and button.hasItem) then
            CleanButton(button)
            return
        end

        CleanButton(button)

        local item = Item:CreateFromBagAndSlot(button.bag, button.slot)
        if not item then return end

        local isSearchFiltered = IsItemSearchFiltered(button)
        local itemInfos = GetItemInfoInstant(item:GetItemID())

        if itemInfos and itemInfos.quality ~= nil then
            button.__itemQuality = itemInfos.quality

            if not isSearchFiltered then
                ApplyItemQualityVisual(button, itemInfos.quality)
                UpdateButtonFromItem(button, item, "bags")
            end
        end

        if isSearchFiltered then
            ApplySearchFilter(button)
        end
    end)

    AdiBags.RegisterMessage(ns, "AdiBags_UpdateLock", function(event, button)
        if db.bags and button.hasItem and not AdiBags.globalLock then
            ReapplyPoorQuality(button)
        end
    end)

    AdiBags.RegisterMessage(ns, "AdiBags_UpdateBorder", function(event, button)
        if db.bags and button.hasItem then
            ReapplyPoorQuality(button)
        end
    end)
end)

-- Inventorian
ns:RegisterAddonHook("Inventorian", function()
    local inv = LibStub("AceAddon-3.0", true):GetAddon("Inventorian", true)
    local function ToIndex(bag, slot) -- copied from inside Inventorian
        return (bag < 0 and bag * 100 - slot) or (bag * 100 + slot)
    end
    local function invContainerUpdateSlot(self, bag, slot)
        local button = self.items[ToIndex(bag, slot)]
        if not button then return end
        if button:IsCached() then
            local item
            local icon, count, locked, quality, readable, lootable, link, noValue, itemID, isBound = button:GetInfo()
            if link then
                item = Item:CreateFromItemLink(link)
            elseif itemID then
                item = Item:CreateFromItemID(itemID)
            end
            UpdateButtonFromItem(button, item, "bags")
        else
            UpdateContainerButton(button, bag, slot)
        end
    end
    local function hookInventorian()
        hooksecurefunc(inv.bag.itemContainer, "UpdateSlot", invContainerUpdateSlot)
        hooksecurefunc(inv.bank.itemContainer, "UpdateSlot", invContainerUpdateSlot)
    end
    if inv.bag then
        hookInventorian()
    else
        hooksecurefunc(inv, "OnEnable", function()
            hookInventorian()
        end)
    end
end)

-- Baggins:
ns:RegisterAddonHook("Baggins", function()
    hooksecurefunc(Baggins, "UpdateItemButton", function(baggins, bagframe, button, bag, slot)
        UpdateContainerButton(button, bag)
    end)
end)

-- Bagnon:
do
    local function bagbrother_button(button)
        CleanButton(button)
        if not db.bags then
            return
        end
        local bag = button:GetBag()
        if type(bag) ~= "number" then
            -- try to fall back on item links, mostly for void storage which would be "vault" here
            local itemLink = button:GetItem()
            if itemLink then
                local item = Item:CreateFromItemLink(itemLink)
                UpdateButtonFromItem(button, item, "bags")
            end
            return
        end
        UpdateContainerButton(button, bag)
    end
    ns:RegisterAddonHook("Bagnon", function()
        hooksecurefunc(Bagnon.Item, "Update", bagbrother_button)
    end)

    --Combuctor (exactly same internals as Bagnon):
    ns:RegisterAddonHook("Combuctor", function()
        hooksecurefunc(Combuctor.Item, "Update", bagbrother_button)
    end)
end

-- LiteBag:
ns:RegisterAddonHook("LiteBag", function()
    _G.LiteBag_RegisterHook('LiteBagItemButton_Update', function(frame)
        local bag = frame:GetParent():GetID()
        UpdateContainerButton(frame, bag)
    end)
end)

-- Baganator
ns:RegisterAddonHook("Baganator", function()
    local suppress = {}
    local function check_baginator_config(value)
        return Baganator.Config.Get("icon_top_left_corner") == value or
            Baganator.Config.Get("icon_top_right_corner") == value or
            Baganator.Config.Get("icon_bottom_left_corner") == value or
            Baganator.Config.Get("icon_bottom_right_corner") == value
    end
    local function baganator_setitemdetails(button, details)
        CleanButton(button)
        if not db.bags then return end
        local item
        -- If we have a container-item, we should use that because it's needed for soulbound detection
        local bag = button.GetBagID and button:GetBagID() or button:GetParent():GetID()
        local slot = button:GetID()
        -- print("SetItemDetails", details.itemLink, bag, slot)
        if bag and slot and slot ~= 0 then
            item = Item:CreateFromBagAndSlot(bag, slot)
        elseif details.itemLink then
            item = Item:CreateFromItemLink(details.itemLink)
        end
        if not item then return end
        suppress.level = check_baginator_config("item_level")
        UpdateButtonFromItem(button, item, "bags", suppress)
    end
    local function baganator_rebuildlayout(frame)
        for _, button in ipairs(frame.buttons) do
            if not button.____SimpleItemLevelHooked then
                button.____SimpleItemLevelHooked = true
                hooksecurefunc(button, "SetItemDetails", baganator_setitemdetails)
            end
        end
    end
    local function baganator_hookmain()
        hooksecurefunc(Baganator_MainViewFrame.BagLive, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.ReagentBagLive, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.BankLive, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.ReagentBankLive, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.BagCached, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.ReagentBagCached, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.BankCached, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_MainViewFrame.ReagentBankCached, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_BankOnlyViewFrame.BankLive, "RebuildLayout", baganator_rebuildlayout)
        hooksecurefunc(Baganator_BankOnlyViewFrame.ReagentBankLive, "RebuildLayout", baganator_rebuildlayout)
    end
    -- Depending on whether we were loaded before or after Baganator, this might or might not have already been created...
    if Baganator_MainViewFrame then
        baganator_hookmain()
    elseif Baganator and Baganator.UnifiedBags.Initialize then
        hooksecurefunc(Baganator.UnifiedBags, "Initialize", baganator_hookmain)
    end
end)

-- helper

do
    local EquipLocToSlot1 = {
        INVTYPE_HEAD = 1,
        INVTYPE_NECK = 2,
        INVTYPE_SHOULDER = 3,
        INVTYPE_BODY = 4,
        INVTYPE_CHEST = 5,
        INVTYPE_ROBE = 5,
        INVTYPE_WAIST = 6,
        INVTYPE_LEGS = 7,
        INVTYPE_FEET = 8,
        INVTYPE_WRIST = 9,
        INVTYPE_HAND = 10,
        INVTYPE_FINGER = 11,
        INVTYPE_TRINKET = 13,
        INVTYPE_CLOAK = 15,

        INVTYPE_WEAPON = 16,
        INVTYPE_2HWEAPON = 16,
        INVTYPE_WEAPONMAINHAND = 16,

        INVTYPE_WEAPONOFFHAND = 17,
        INVTYPE_SHIELD = 17,
        INVTYPE_HOLDABLE = 17,

        INVTYPE_RANGED = 18,
        INVTYPE_RANGEDRIGHT = 18,
        INVTYPE_THROWN = 18,
        INVTYPE_RELIC = 18,

        INVTYPE_TABARD = 19,
    }
    local EquipLocToSlot2 = {
        INVTYPE_FINGER = 12,
        INVTYPE_TRINKET = 14,
        INVTYPE_WEAPON = 17,
    }
    local ForEquippedItem = function(slot, callback)
        if not slot then
            return
        end
        local item = Item:CreateFromEquipmentSlot("player", slot)
        if not item then
            return callback(nil, slot)
        end
        if item:IsItemEmpty() then
            return callback(item, slot)
        end
        item:ContinueOnItemLoad(function() callback(item, slot) end)
    end
    ns.ForEquippedItems = function(equipLoc, callback)
        ForEquippedItem(EquipLocToSlot1[equipLoc], callback)
        ForEquippedItem(EquipLocToSlot2[equipLoc], callback)
    end
end

ns.CacheEquippedItems = function()
    for slotID = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            local item = Item:CreateFromItemLink(itemLink)
            if item and not item:IsCached() then
                item:Query()
            end
        end
    end
end

do
    -- could arguably also do TooltipDataProcessor.AddLinePostCall(Enum.TooltipDataLineType.GemSocket, ...)
    local t = {}
    function ns.ItemHasEmptySlots(itemLink)
        if not itemLink then return false end

        wipe(t)
        local stats = GetItemStats(itemLink, t)
        if not stats then return false end

        local totalSockets = 0
        for label, value in pairs(stats) do
            if label:sub(1, 13) == "EMPTY_SOCKET_" then
                totalSockets = totalSockets + value
            end
        end

        if totalSockets == 0 then return false end

        local _, _, _, gem1, gem2, gem3 = strsplit(":", itemLink)
        local gems = 0
        if gem1 ~= "0" then gems = gems + 1 end
        if gem2 ~= "0" then gems = gems + 1 end
        if gem3 ~= "0" then gems = gems + 1 end

        return totalSockets > gems
    end

    local enchantable = {
        INVTYPE_HEAD = true,
        INVTYPE_SHOULDER = true,
        INVTYPE_CHEST = true,
        INVTYPE_ROBE = true,
        INVTYPE_LEGS = true,
        INVTYPE_FEET = true,
        INVTYPE_WRIST = true,
        INVTYPE_HAND = true,
        -- INVTYPE_FINGER = true, -- only enchanter can
        INVTYPE_CLOAK = true,
        INVTYPE_WEAPON = true,
        INVTYPE_SHIELD = true,
        INVTYPE_2HWEAPON = true,
        INVTYPE_WEAPONMAINHAND = true,
        INVTYPE_RANGED = true,
        INVTYPE_RANGEDRIGHT = true,
        INVTYPE_WEAPONOFFHAND = true,
        INVTYPE_HOLDABLE = true,

        INVTYPE_WAIST = true -- added
    }

    function ns.ItemIsMissingEnchants(itemLink)
        if not itemLink then return false end

        local itemString = itemLink:match("item:[^|]+")
        if not itemString then return false end

        local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemLink)
        if not equipSlot or not enchantable[equipSlot] then
            return false
        end

        local enchantID = select(3, strsplit(":", itemString))
        enchantID = tonumber(enchantID) or 0

        return enchantID == 0
    end

    function ns.GetEnchantNameFromLink(itemLink)
        if not itemLink then return end

        local enchantID = itemLink:match("item:%d+:(%d+):")
        enchantID = tonumber(enchantID)

        if enchantID and enchantID > 0 then
            local enchantName = ENCHANT_ID_TO_DATA[enchantID] -- 57080 bugid
            if not enchantName then return end

            return enchantName
        end
    end


end
