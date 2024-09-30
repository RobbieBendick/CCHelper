local CCHelper = LibStub("AceAddon-3.0"):GetAddon("CCHelper");
local GetSpellInfo = C_Spell.GetSpellInfo;
local HealerSpecs = {
    [105]  = true,  -- druid resto
    [270]  = true,  -- monk mw
    [65]   = true,  -- paladin holy
    [256]  = true,  -- priest disc
    [257]  = true,  -- priest holy
    [264]  = true,  -- shaman resto
    [1468] = true,  -- preservation evoker  
}
local CastedCCForClass = {
    ["MAGE"] = {spellID = 118, dr = "Incapacitate"}, -- polymorph
    ["EVOKER"] = {spellID = 360806, dr = "Disorient"}, -- sleep walk
    ["DRUID"] = {spellID = 33786, dr = "Disorient"}, -- cyclone
    ["WARLOCK"] = {spellID = 5782, dr = "Disorient"}, -- fear
    ["SHAMAN"] = {spellID = 11641, dr = "Incapacitate"}, -- hex
}

local severityColor = {
    [1] = { 0, 1, 0, 1},
    [2] = { 1, 1, 0, 1},
    [3] = { 1, 0, 0, 1},
}

function CCHelper:SetEnemyArenaHealerID()
    for i=1, 3 do
        local specID = GetArenaOpponentSpec(i);
        if specID and specID > 0 and HealerSpecs[specID] then
            self.healerUnitID = "arena"..i;
            break;
        end
    end
end


function CCHelper:CreateCCBar()
    self.CCBar = CreateFrame("StatusBar", nil, UIParent);
    self.CCBar:SetSize(self.db.profile.ccBarWidth, self.db.profile.ccBarHeight);
    self.CCBar:SetPoint(self.db.profile.ccBarPosition.point or "CENTER", UIParent, self.db.profile.ccBarPosition.relativePoint or "CENTER", self.db.profile.ccBarPosition.x or 0, self.db.profile.ccBarPosition.y or -300);
    self.CCBar:SetMinMaxValues(0, 1);
    self.CCBar:SetValue(1);
    self.CCBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar");
    self.CCBar:SetStatusBarColor(0, 0.75, 1);

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
    local _, eventType, _, _, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if not self.healerUnitID then return end
    if destGUID ~= UnitGUID(self.healerUnitID) or not self.CCsToLookFor[spellID] then return end

    local _, class = UnitClass("player")
    if not CastedCCForClass[class] then return end

    local drCategory = CastedCCForClass[class].dr;

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
            self.CCBar:SetStatusBarColor(unpack(severityColor[severity]));
        end
        
        self:FindLongestCCAndUpdateStatusBar();
    end
end


function CCHelper:FindLongestCCAndUpdateStatusBar()
    local _, class = UnitClass("player");
    if not CastedCCForClass[class] then return end

    local longestDuration = 0;
    local longestExpirationTime = 0;
    local longestDurationSpellID;
    local longestIconTexture;

    for i=1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(self.healerUnitID, i, "HARMFUL");
        if not aura then break end
        if self.CCsToLookFor[aura.spellId] then
            local remainingTime = aura.expirationTime - GetTime();
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
        local castTime = C_Spell.GetSpellInfo(CastedCCForClass[class].spellID).castTime / 1000;

        self.CCBar:SetMinMaxValues(0, progressBarDuration - castTime);
        self.CCBar:SetValue(progressBarDuration);
        self.CCBar:Show();

        self.CCBar.icon:SetTexture(longestIconTexture);

        self:UpdateIconVisibility();
        self:UpdateDurationVisibility();

        self.CCBar:SetScript("OnUpdate", function(_, elapsed)
            local drCategory = CastedCCForClass[class].dr;

            -- adjust for haste each iteration.
            castTime = C_Spell.GetSpellInfo(CastedCCForClass[class].spellID).castTime / 1000;

            remainingTime = longestExpirationTime - GetTime();

            local adjustedValue = remainingTime - castTime - gracePeriod;
            local cycloneSpellID = 33786;

            -- if the CC is cylcone, we don't want a gracePeriod cuz it'll be immuned.
            if cycloneSpellID == longestDurationSpellID then
                adjustedValue = remainingTime - castTime;
            end
            
            if adjustedValue > 0 then
                adjustedValue = math.max(0, adjustedValue);
                self.CCBar:SetValue(adjustedValue);
                self.CCBar.duration:SetFormattedText("%.1f", adjustedValue);

                if self.db.profile.drColors then
                    local severity = self:GetDRSeverity(drCategory);
                    self.CCBar:SetStatusBarColor(unpack(severityColor[severity]));
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
