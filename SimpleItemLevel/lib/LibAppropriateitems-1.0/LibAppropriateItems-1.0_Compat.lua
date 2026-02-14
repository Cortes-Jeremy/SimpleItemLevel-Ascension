-- WoW 3.3.5 Enum shim
if not Enum then Enum = {} end

-- --------------------------------------------------------------------
-- ItemClass (classID retourné par GetItemInfoInstant)
-- --------------------------------------------------------------------
Enum.ItemClass = {
    Consumable = 0,
    Container  = 1,
    Weapon     = 2,
    Gem        = 3,
    Armor      = 4,
    Reagent    = 5,
    Projectile = 6,
    Tradegoods = 7,
    Generic    = 8,
    Recipe     = 9,
    Money      = 10,
    Quiver     = 11,
    Quest      = 12,
    Key        = 13,
    Permanent  = 14,
    Miscellaneous = 15,
    Glyph      = 16, -- existe déjà en 3.3.5
}

-- --------------------------------------------------------------------
-- Weapon subclasses (subclassID)
-- --------------------------------------------------------------------
Enum.ItemWeaponSubclass = {
    Axe1H      = 0,
    Axe2H      = 1,
    Bows       = 2,
    Guns       = 3,
    Mace1H     = 4,
    Mace2H     = 5,
    Polearm    = 6,
    Sword1H    = 7,
    Sword2H    = 8,
    Warglaive  = 9,
    Staff      = 10,
    Bearclaw   = 11,
    Catclaw    = 12,
    Unarmed    = 13,
    Generic    = 14,
    Dagger     = 15,
    Thrown     = 16,
    Spear      = 17,
    Crossbow   = 18,
    Wand       = 19,
    Fishingpole = 20,
}

-- --------------------------------------------------------------------
-- Armor subclasses
-- --------------------------------------------------------------------
Enum.ItemArmorSubclass = {
    Generic   = 0, -- bijoux, trinkets, offhands
    Cloth     = 1,
    Leather   = 2,
    Mail      = 3,
    Plate     = 4,
    Shield    = 6,
    Libram    = 7,
    Idol      = 8,
    Totem     = 9,
    Sigil     = 10,

    -- Alias modernes
    Cosmetic = 0,
}
