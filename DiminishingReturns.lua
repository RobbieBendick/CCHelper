local CCHelper = LibStub("AceAddon-3.0"):GetAddon("CCHelper");

CCHelper.drCategories = {
    "Stun",
    "Incapacitate",
    "Disorient",
    "Silence",
    "Root",
    "Knock",
    "Disarm",
};
local drCategories = CCHelper.drCategories;
local drTime = 18.5;
local GetTime = GetTime;

function CCHelper:ApplyDR(drCategory)
    if not self.DRTimers then
        self.DRTimers = {};
    end

    if not self.DRTimers[self.healerUnitID] then
        self.DRTimers[self.healerUnitID] = {};
    end

    if not self.DRTimers[self.healerUnitID][drCategory] then
        self.DRTimers[self.healerUnitID][drCategory] = {expires = GetTime() + drTime, severity = 1};
    else
        local currentDR = self.DRTimers[self.healerUnitID][drCategory];
        
        -- current dr has expired
        if GetTime() >= currentDR.expires then
            currentDR.severity = 1;
            currentDR.expires = GetTime() + drTime;
        else
            currentDR.expires = GetTime() + drTime;
            currentDR.severity = math.min(currentDR.severity + 1, 4);
        end
    end
end

function CCHelper:GetDRSeverity(drCategory)
    if self.DRTimers and self.DRTimers[self.healerUnitID] and self.DRTimers[self.healerUnitID][drCategory] then
        local drData = self.DRTimers[self.healerUnitID][drCategory];
        if GetTime() < drData.expires then
            return drData.severity;
        else
            -- dr expired
            self.DRTimers[self.healerUnitID][drCategory] = nil;
        end
    end
    return 0;
end

function CCHelper:ResetDRTimer(drCategory)
    if self.DRTimers and self.DRTimers[self.healerUnitID] and self.DRTimers[self.healerUnitID][drCategory] then
        local currentDR = self.DRTimers[self.healerUnitID][drCategory];
        currentDR.expires = GetTime() + drTime;
    end
end

CCHelper.drList = {
    [207167]  = "Disorient",       -- Blinding Sleet
    [207685]  = "Disorient",       -- Sigil of Misery
    [33786]   = "Disorient",       -- Cyclone
    [209753]  = "Disorient",       -- Cyclone (Honor talent)
    [31661]   = "Disorient",       -- Dragon's Breath
    [198909]  = "Disorient",       -- Song of Chi-ji
    [202274]  = "Disorient",       -- Incendiary Brew
    [105421]  = "Disorient",       -- Blinding Light
    [605]     = "Disorient",       -- Mind Control
    [8122]    = "Disorient",       -- Psychic Scream
    [226943]  = "Disorient",       -- Mind Bomb
    [2094]    = "Disorient",       -- Blind
    [118699]  = "Disorient",       -- Fear
    [130616]  = "Disorient",       -- Fear (Warlock Horrify talent)
    [5484]  = "Disorient",       -- Howl of Terror
    [6358]    = "Disorient",       -- Seduction (Succubus)
    [115268]  = "Disorient",       -- Mesmerize (Shivarra)
    [5246]    = "Disorient",       -- Intimidating Shout
	[316593]  = "Disorient",       -- Intimidating Shout (Menace Main Target)
	[316595]  = "Disorient",       -- Intimidating Shout (Menace Other Targets)
    [1513]    = "Disorient",       -- Scare Beast
    [10326]   = "Disorient",       -- Turn Evil
    [331866]   = "Disorient",      -- Agent of Chaos
    [324263]   = "Disorient",      -- Sulfuric Emission
    [360806]   = "Disorient",      -- Sleep Walk

    [217832]  = "Incapacitate",    -- Imprison
    [221527]  = "Incapacitate",    -- Imprison (Honor talent)
    [99]      = "Incapacitate",    -- Incapacitating Roar
    [3355]    = "Incapacitate",    -- Freezing Trap
    [203337]  = "Incapacitate",    -- Freezing Trap (Honor talent)
    [212365]  = "Incapacitate",    -- Freezing Trap (TODO: incorrect?)
    [213691]  = "Incapacitate",    -- Scatter Shot
    [118]     = "Incapacitate",    -- Polymorph
    [28271]   = "Incapacitate",    -- Polymorph (Turtle)
    [28272]   = "Incapacitate",    -- Polymorph (Pig)
    [61025]   = "Incapacitate",    -- Polymorph (Snake)
    [61305]   = "Incapacitate",    -- Polymorph (Black Cat)
    [61780]   = "Incapacitate",    -- Polymorph (Turkey)
    [61721]   = "Incapacitate",    -- Polymorph (Rabbit)
    [126819]  = "Incapacitate",    -- Polymorph (Porcupine)
    [161353]  = "Incapacitate",    -- Polymorph (Polar Bear Cub)
    [161354]  = "Incapacitate",    -- Polymorph (Monkey)
    [161355]  = "Incapacitate",    -- Polymorph (Penguin)
    [161372]  = "Incapacitate",    -- Polymorph (Peacock)
    [277787]  = "Incapacitate",    -- Polymorph (Baby Direhorn)
    [277792]  = "Incapacitate",    -- Polymorph (Bumblebee)
	[391622]  = "Incapacitate",    -- Polymorph (Duck)
	[383121]  = "Incapacitate",    -- Mass Polymorph
    [82691]   = "Incapacitate",    -- Ring of Frost
    [115078]  = "Incapacitate",    -- Paralysis
    [20066]   = "Incapacitate",    -- Repentance
    [9484]    = "Incapacitate",    -- Shackle Undead
    [200196]  = "Incapacitate",    -- Holy Word: Chastise
    [1776]    = "Incapacitate",    -- Gouge
    [6770]    = "Incapacitate",    -- Sap
    [51514]   = "Incapacitate",    -- Hex
    [196942]  = "Incapacitate",    -- Hex (Voodoo Totem)
    [210873]  = "Incapacitate",    -- Hex (Raptor)
    [211004]  = "Incapacitate",    -- Hex (Spider)
    [211010]  = "Incapacitate",    -- Hex (Snake)
    [211015]  = "Incapacitate",    -- Hex (Cockroach)
    [269352]  = "Incapacitate",    -- Hex (Skeletal Hatchling)
    [277778]  = "Incapacitate",    -- Hex (Zandalari Tendonripper)
    [277784]  = "Incapacitate",    -- Hex (Wicker Mongrel)
	[309328]  = "Incapacitate",    -- Hex (Living Honey)
    [197214]  = "Incapacitate",    -- Sundering
    [710]     = "Incapacitate",    -- Banish
    [6789]    = "Incapacitate",    -- Mortal Coil
    [107079]  = "Incapacitate",    -- Quaking Palm (Pandaren)
    [2637]    = "Incapacitate",       -- Hibernate

    [47476]   = "Silence",         -- Strangulate
    [204490]  = "Silence",         -- Sigil of Silence
--  [78675]   = "Silence",         -- Solar Beam
    [202933]  = "Silence",         -- Spider Sting
    [356727]  = "Silence",         -- Spider Venom
    [217824]  = "Silence",         -- Shield of Virtue
    [15487]   = "Silence",         -- Silence
    [1330]    = "Silence",         -- Garrote
    [43523]   = "Silence",         -- Unstable Affliction Silence Effect (TODO: incorrect?)
    [196364]  = "Silence",         -- Unstable Affliction Silence Effect 2

    [210141]  = "Stun",            -- Zombie Explosion
    [108194]  = "Stun",            -- Asphyxiate (Unholy)
    [221562]  = "Stun",            -- Asphyxiate (Blood)
    [377048]  = "Stun",            -- Absolute Zero (Frost)
    [91800]   = "Stun",            -- Gnaw (Ghoul)
    [91797]   = "Stun",            -- Monstrous Blow (Mutated Ghoul)
    [287254]  = "Stun",            -- Dead of Winter
    [179057]  = "Stun",            -- Chaos Nova
    [205630]  = "Stun",            -- Illidan's Grasp (Primary effect)
    [208618]  = "Stun",            -- Illidan's Grasp (Secondary effect)
    [211881]  = "Stun",            -- Fel Eruption
    [203123]  = "Stun",            -- Maim
    [163505]  = "Stun",            -- Rake (Prowl)
    [5211]    = "Stun",            -- Mighty Bash
    [202244]  = "Stun",            -- Overrun (Also a knockback)
    [24394]   = "Stun",            -- Intimidation
	[117526]  = "Stun",            -- Binding Shot
	[357021]  = "Stun",            -- Consecutive Concussion
    [119381]  = "Stun",            -- Leg Sweep
    [202346]  = "Stun",            -- Double Barrel
    [853]     = "Stun",            -- Hammer of Justice
    [64044]   = "Stun",            -- Psychic Horror
    [200200]  = "Stun",            -- Holy Word: Chastise Censure
    [1833]    = "Stun",            -- Cheap Shot
    [408]     = "Stun",            -- Kidney Shot
    [118905]  = "Stun",            -- Static Charge (Capacitor Totem)
    [118345]  = "Stun",            -- Pulverize (Primal Earth Elemental)
    [305485]  = "Stun",            -- Lightning Lasso
    [89766]   = "Stun",            -- Axe Toss
    [171017]  = "Stun",            -- Meteor Strike (Infernal)
    [171018]  = "Stun",            -- Meteor Strike (Abyssal)
--  [22703]   = "Stun",            -- Infernal Awakening (doesn't seem to DR)
    [30283]   = "Stun",            -- Shadowfury
    [46968]   = "Stun",            -- Shockwave
    [132168]  = "Stun",            -- Shockwave (Protection)
    [132169]  = "Stun",            -- Storm Bolt
    [199085]  = "Stun",            -- Warpath
    [20549]   = "Stun",            -- War Stomp (Tauren)
    [255723]  = "Stun",            -- Bull Rush (Highmountain Tauren)
    [287712]  = "Stun",            -- Haymaker (Kul Tiran)
    [372245]  = "Stun",            -- Terror of the Skies
	[389831]  = "Stun",            -- Snowdrift
}
