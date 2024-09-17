local CCHelper = LibStub("AceAddon-3.0"):GetAddon("CCHelper");
local GetSpellInfo = C_Spell.GetSpellInfo;
local Details = Details;
local HealerSpecs = {
    [105]  = true,  -- druid resto
    [270]  = true,  -- monk mw
    [65]   = true,  -- paladin holy
    [256]  = true,  -- priest disc
    [257]  = true,  -- priest holy
    [264]  = true,  -- shaman resto
    [1468] = true,  -- preservation evoker  
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

-- track cc breaks including dispels & PvP trinket use
function CCHelper:HandleCombatLog()
    local _, eventType, _, _, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo();

    if not (eventType == "SPELL_AURA_BROKEN" or eventType == "SPELL_AURA_BROKEN_SPELL" or eventType == "SPELL_DISPEL" or eventType == "SPELL_AURA_REMOVED") then
        return;
    end
    if not self.healerUnitID then
        return;
    end
    if destGUID ~= UnitGUID(self.healerUnitID) or not self.CCsToLookFor[spellID] then
        return;
    end

    self.CCBar:Hide();
    self.CCBar:SetScript("OnUpdate", nil);
end

function CCHelper:CreateCCBar()
    self.CCBar = CreateFrame("StatusBar", nil, UIParent);
    self.CCBar:SetSize(200, 20);
    self.CCBar:SetPoint("CENTER", UIParent, "CENTER", 0, -200);
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
    
    self.CCBar:Hide();
end


function CCHelper:HandleUnitAura(event, unit)
    local _, instanceType = IsInInstance();
    if not self.healerUnitID or not UnitIsUnit(unit, self.healerUnitID) then return end
    if instanceType ~= "arena" then return end
    self:FindLongestCCAndUpdateStatusBar(unit);
end

function CCHelper:FindLongestCCAndUpdateStatusBar(unit)
    local longestDuration = 0;
    local longestExpirationTime = 0;
    local longestDurationSpellID;
    local longestIconTexture;

    --[[ 
        -- debugging
        unit = "target";
    ]]--
    
    AuraUtil.ForEachAura(unit, "HARMFUL", nil, function(name, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID)
        if self.CCsToLookFor[spellID] then
            local remainingTime = expirationTime - GetTime();
            if duration > longestDuration then
                longestDuration = duration;
                longestExpirationTime = expirationTime;
                longestDurationSpellID = spellID;
                longestIconTexture = icon;
            end
        end
        return true;
    end);
    if longestDuration > 0 then
        local gracePeriod = 0.15;
        local progressBarDuration = longestDuration - gracePeriod;
        local remainingTime = longestExpirationTime - GetTime();
        local castTime = C_Spell.GetSpellInfo(longestDurationSpellID).castTime / 1000;

        self.CCBar:SetMinMaxValues(0, progressBarDuration - castTime);
        self.CCBar:SetValue(progressBarDuration);
        self.CCBar:Show();

        self.CCBar.icon:SetTexture(longestIconTexture);

        self.CCBar:SetScript("OnUpdate", function(_, elapsed)
            remainingTime = longestExpirationTime - GetTime();
            local adjustedValue = remainingTime - castTime - gracePeriod;

            if adjustedValue > 0 then
                adjustedValue = math.max(0, adjustedValue);
                self.CCBar:SetValue(adjustedValue);
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
