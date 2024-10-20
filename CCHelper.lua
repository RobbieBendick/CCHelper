local CCHelper = LibStub("AceAddon-3.0"):GetAddon("CCHelper");
local TEMP_WOW_CATA_CLASSIC_ID = 14;
local isCata = WOW_PROJECT_ID == TEMP_WOW_CATA_CLASSIC_ID;
local GetSpellInfo;
if isCata then
    GetSpellInfo = _G.GetSpellInfo;
else
    GetSpellInfo = C_Spell.GetSpellInfo;
end

function CCHelper:CreateCCBar()
    self.CCBar = CreateFrame("StatusBar", nil, UIParent);
    self.CCBar:SetSize(self.db.profile.ccBarWidth, self.db.profile.ccBarHeight);
    self.CCBar:SetPoint(self.db.profile.ccBarPosition.point or "CENTER", UIParent, self.db.profile.ccBarPosition.relativePoint or "CENTER", self.db.profile.ccBarPosition.x or 0, self.db.profile.ccBarPosition.y or -300);
    self.CCBar:SetMinMaxValues(0, 1);
    self.CCBar:SetValue(1);
    self.CCBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar");
    self.CCBar:SetStatusBarColor(unpack(self.lightBlue));

    self.CCBar.bg = self.CCBar:CreateTexture(nil, "BACKGROUND");
    self.CCBar.bg:SetAllPoints(true);
    self.CCBar.bg:SetColorTexture(0, 0, 0, 0.5);
    
    self.CCBar.icon = self.CCBar:CreateTexture(nil, "OVERLAY");
    self.CCBar.icon:SetSize(20, 20);
    self.CCBar.icon:SetPoint("RIGHT", self.CCBar, "LEFT", -5, 0);
    self.CCBar.icon:SetTexture(136071); -- polymorph icon id for placeholder

    self.CCBar.testText = self.CCBar:CreateFontString(nil, "OVERLAY");
    self.CCBar.testText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE");
    self.CCBar.testText:SetText("Drag To Move");
    self.CCBar.testText:SetPoint("CENTER", self.CCBar, "CENTER");
    self.CCBar.testText:Hide();

    self.CCBar.duration = self.CCBar:CreateFontString(nil, "OVERLAY");
    self.CCBar.duration:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE");
    self.CCBar.duration:SetPoint("LEFT", self.CCBar, "LEFT", 5, 0);

    self:UpdateIconVisibility();
    self:UpdateDurationVisibility();

    self.CCBar:Hide();
end

function CCHelper:HandleCombatLog()
    local _, eventType, _, _, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo();
    local inInstance, instanceType = IsInInstance();

    if instanceType ~= "arena" then return end
    -- self.healerUnitID = 'target'; -- for debugging
    
    if not self.healerUnitID then return end
    if destGUID ~= UnitGUID(self.healerUnitID) or not self.drList[spellID] then return end

    local _, class = UnitClass("player")
    if not self.castedCCForClass[class] then return end

    local drCategory = self.castedCCForClass[class].dr;

    if eventType == "SPELL_AURA_BROKEN" or eventType == "SPELL_AURA_BROKEN_SPELL" or eventType == "SPELL_DISPEL" or eventType == "SPELL_AURA_REMOVED" then
        self.CCBar:Hide();
        self.CCBar:SetScript("OnUpdate", nil);

        if self.drList[spellID] == drCategory then
            self:ResetDRTimer(drCategory);
        end
    elseif eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        if self.db.profile.drColors and self.drList[spellID] == drCategory then
            self:ApplyDR(drCategory);
            local severity = self:GetDRSeverity(drCategory);
            self.CCBar:SetStatusBarColor(unpack(self.severityColor[severity]));
        end
        self:FindLongestCCAndUpdateStatusBar();
    end
end

function CCHelper:FindLongestCCAndUpdateStatusBar()
    local _, class = UnitClass("player");
    if not self.castedCCForClass[class] then return end

    local longestDuration = 0;
    local longestExpirationTime = 0;
    local longestDurationSpellID;
    local longestIconTexture;

    for i=1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(self.healerUnitID, i, "HARMFUL");
        if not aura then break end
        if self.drList[aura.spellId] then
            if aura.duration > longestDuration then
                longestDuration = aura.duration;
                longestExpirationTime = aura.expirationTime;
                longestDurationSpellID = aura.spellId;
                longestIconTexture = aura.icon;
            end
        end
    end

    if longestDuration > 0 then
        local gracePeriod = self.db.profile.gracePeriod;
        local progressBarDuration = longestDuration - gracePeriod;
        local remainingTime = longestExpirationTime - GetTime();
        local cast;

        -- cata has a different GetSpellInfo function which returns in a different way
        if isCata then
            local name, rank, icon, cataCastTime, minRange, maxRange = GetSpellInfo(self.castedCCForClass[class].spellID);
            cast = cataCastTime;
        end

        local castTime = cast and cast / 1000 or GetSpellInfo(self.castedCCForClass[class].spellID).castTime / 1000;

        self.CCBar:SetMinMaxValues(0, progressBarDuration - castTime);
        self.CCBar:SetValue(progressBarDuration);
        self.CCBar:Show();

        self.CCBar.icon:SetTexture(longestIconTexture);

        self:UpdateIconVisibility();
        self:UpdateDurationVisibility();

        self.CCBar:SetScript("OnUpdate", function(_, elapsed)
            local drCategory = self.castedCCForClass[class].dr;
            local cycloneSpellID = 33786;

            -- need to always be checking cast time cuz haste procs
            local castTime = cast and cast / 1000 or GetSpellInfo(self.castedCCForClass[class].spellID).castTime / 1000;

            remainingTime = longestExpirationTime - GetTime();
            local adjustedValue = remainingTime - castTime - gracePeriod;

            -- if the CC is cylcone, we don't want a grace period cuz it'll be immuned.
            if cycloneSpellID == longestDurationSpellID then
                adjustedValue = remainingTime - castTime;
            end
            
            if adjustedValue > 0 then
                adjustedValue = math.max(0, adjustedValue);
                self.CCBar:SetValue(adjustedValue);
                self.CCBar.duration:SetFormattedText("%.1f", adjustedValue);

                if self.db.profile.drColors then
                    local severity = self:GetDRSeverity(drCategory);
                    self.CCBar:SetStatusBarColor(unpack(self.severityColor[severity]));
                end
                
            else
                self.CCBar:Hide();
                self.CCBar:SetScript("OnUpdate", nil);
            end
        end);
    else
        self.CCBar:Hide();
        self.CCBar:SetScript("OnUpdate", nil);
    end
end

function CCHelper:SetEnemyArenaHealerID()
    local healerSpecs = {
        [105]  = true,  -- druid resto
        [270]  = true,  -- monk mw
        [65]   = true,  -- paladin holy
        [256]  = true,  -- priest disc
        [257]  = true,  -- priest holy
        [264]  = true,  -- shaman resto
        [1468] = true,  -- preservation evoker  
    };

    for i=1, 3 do
        local specID = GetArenaOpponentSpec(i);
        if specID and specID > 0 and healerSpecs[specID] then
            self.healerUnitID = "arena"..i;
            break;
        end
    end
end

function CCHelper:CataclysmIdentifyHealer()

    local IsInInstance, instanceType = IsInInstance();

    if instanceType ~= "arena" then return end

    local healerUnitID;
    
    for i = 1, 5 do
        local unitID = "arena"..i;
        if UnitExists(unitID) then
            local _, class = UnitClass(unitID);
            local maxMana = UnitPowerMax(unitID);
            
            -- healer capable classes
            if class == "PRIEST" or class == "PALADIN" or class == "DRUID" or class == "SHAMAN" then

                -- check if its a hpal
                if class == "PALADIN" and maxMana > 60000 then
                    self.healerUnitID = unitID;
                    return;
                end

                -- further check by buffs
                local healingSpellDetected = self:TrackHealingSpells(unitID);
                
                if healingSpellDetected then
                    self.healerUnitID = unitID;
                    return;
                end
            end
        end
    end
end

function CCHelper:TrackHealingSpells(unitID)
    local healingSpells = {
        [974]    = true,            -- Earth Shield
        [61295]  = true,            -- Riptide
        [51886]  = true,            -- Cleanse Spirit
        [16190]  = true,            -- Mana Tide Totem
        [53390]  = true,            -- Tidal Waves
        [31616]  = true,            -- Nature's Guardian
        [16236]  = true,            -- Ancestral Fortitude (buff)
        [16188]  = true,            -- Nature's Swiftness
        [98008]  = true,            -- Soul Link Totem
        [51564]  = true,            -- Tidal Waves
        [51562]  = true,            -- Tidal Waves
        [51563]  = true,            -- Tidal Waves
        [105284] = true,            -- Ancestral Vigor
        [51945]  = true,            -- Earthliving
        [52752]  = true,            -- Ancestral Awakening (SPELL_HEAL)
        [77613]  = true,            -- Grace
        [59889]  = true,            -- Borrowed Time
        [59888]  = true,            -- Borrowed Time
        [59887]  = true,            -- Borrowed Time
        [10060]  = true,            -- Power Infusion
        [33206]  = true,            -- Pain Suppression
        [45242]  = true,            -- Focused Will
        [45241]  = true,            -- Focused Will
        [34861]  = true,            -- Circle of Healing
        [724]    = true,            -- Lightwell
        [7001]   = true,            -- Lightwell Heal
        [33143]  = true,            -- Blessed Resilience
        [65081]  = true,            -- Body and Soul
        [64128]  = true,            -- Body and Soul
        [63735]  = true,            -- Serendipity
        [63731]  = true,            -- Serendipity
        [47788]  = true,            -- Guardian Spirit
        [27827]  = true,            -- Spirit of Redemption
        [14751]  = true,            -- Chakra
        [81206]  = true,            -- Chakra: Sanctuary
        [81209]  = true,            -- Chakra: Chastise
        [81208]  = true,            -- Chakra: Serenity
        [89912]  = true,            -- Chakra: Flow
        [88625]  = true,            -- Chastise (cast)
        [53563]  = true,            -- Beacon of Light
        [31842]  = true,            -- Divine Favor
        [54149]  = true,            -- Infusion of Light
        [85222]  = true,            -- Light of Dawn
        [31821]  = true,            -- Aura Mastery
        [85497]  = true,            -- Speed of Light
        [88819]  = true,            -- Daybreak
    };
    
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unitID, i, "HELPFUL");
        if not aura then break end
        
        if healingSpells[aura.spellId] and aura.sourceUnit == unitID then
            print("Healing spell detected on", UnitName(unitID), "Spell:", aura.spellId);
            return true;
        end
    end

    return false;
end

function CCHelper:CataclysmHandleZoneChanged()
    local IsInInstance, instanceType = IsInInstance();

    if instanceType ~= "arena" then
        self.healerUnitID = nil;
    end
end



