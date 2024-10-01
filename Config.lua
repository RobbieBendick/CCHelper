
local CCHelper = _G.LibStub("AceAddon-3.0"):NewAddon("CCHelper", "AceConsole-3.0", "AceEvent-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local CCHelperConfig;

CCHelper.castedCCForClass = {
    ["MAGE"] = {spellID = 118, dr = "Incapacitate"}, -- polymorph
    ["EVOKER"] = {spellID = 360806, dr = "Disorient"}, -- sleep walk
    ["DRUID"] = {spellID = 33786, dr = "Disorient"}, -- cyclone
    ["WARLOCK"] = {spellID = 5782, dr = "Disorient"}, -- fear
    ["SHAMAN"] = {spellID = 11641, dr = "Incapacitate"}, -- hex
}

CCHelper.lightBlue = {0, 0.75, 1};
CCHelper.severityColor = {
    [0] = CCHelper.lightBlue,  -- light blue for no DR
    [1] = {0, 1, 0},           -- green for mild DR
    [2] = {1, 1, 0},           -- yellow for moderate DR
    [3] = {1, 0, 0},           -- red for full DR
}

function CCHelper:CreateMenu()
    CCHelperConfig = CreateFrame("Frame", "CCHelperConfig", UIParent);
    CCHelperConfig.name = "CCHelper";

    local version = C_AddOns.GetAddOnMetadata(CCHelperConfig.name, "Version") or "Unknown";
    local author = C_AddOns.GetAddOnMetadata(CCHelperConfig.name, "Author") or "Mageiden";

    local options = {
        name = CCHelperConfig.name,
        type = "group",
        args = {
            info = {
                order = 1,
                type = "description",
                name = "|cffffd700Version|r " .. version .. "\n|cffffd700 Author|r " .. author,
            },
            CCBar = {
                order = 2,
                type = "group",
                name = "CC Bar Settings",
                inline = true,
                args = {
                    xPos = {
                        order = 1,
                        type = "range",
                        name = "X Position",
                        desc = "Set the X position of the CC Bar",
                        min = 0,
                        max = 2000,
                        step = 1,
                        get = function() return self.db.profile.ccBarPosition.x end,
                        set = function(_, value)
                            self.db.profile.ccBarPosition.x = value;
                            self:UpdateCCBarPosition();
                        end,
                    },
                    yPos = {
                        order = 2,
                        type = "range",
                        name = "Y Position",
                        desc = "Set the Y position of the CC Bar",
                        min = 0,
                        max = 1200,
                        step = 1,
                        get = function() return self.db.profile.ccBarPosition.y end,
                        set = function(_, value)
                            self.db.profile.ccBarPosition.y = value;
                            self:UpdateCCBarPosition();
                        end,
                    },
                    ccBarWidth = {
                        order = 3,
                        type = "range",
                        name = "CC Bar Width",
                        desc = "Set the width of the CC Bar",
                        min = 100,
                        max = 1000,
                        step = 1,
                        get = function() return self.db.profile.ccBarWidth end,
                        set = function(_, value)
                            self.db.profile.ccBarWidth = value;
                            self:UpdateCCBarSize();
                        end,
                    },
                    ccBarHeight = {
                        order = 4,
                        type = "range",
                        name = "CC Bar Height",
                        desc = "Set the height of the CC Bar",
                        min = 10,
                        max = 100,
                        step = 1,
                        get = function() return self.db.profile.ccBarHeight end,
                        set = function(_, value)
                            self.db.profile.ccBarHeight = value;
                            self:UpdateCCBarSize();
                        end,
                    },
                    gracePeriod = {
                        order = 5,
                        type = "range",
                        name = "Grace Period",
                        desc = "End the status bar x seconds earlier to give yourself some room. (Doesn't apply for Cyclone, so your CC doesn't get immuned.)",
                        min = 0,
                        max = 1,
                        step = 0.01,
                        get = function() return self.db.profile.gracePeriod end,
                        set = function(_, value)
                            self.db.profile.gracePeriod = value;
                            self:UpdateGracePeriod();
                        end,
                    },
                    spacer = {
                        order = 6,
                        type = "description",
                        name = "",
                        width = 0.1,
                    },
                    showIcon = {
                        order = 7,
                        type = "toggle",
                        name = "Show CC Icon",
                        desc = "Toggle the display of the icon showing what the enemy healer is CC'd with.",
                        get = function() return self.db.profile.showIcon end,
                        set = function(_, value)
                            self.db.profile.showIcon = value;
                            self:UpdateIconVisibility();
                        end,
                        width = 0.72,
                    },
                    showDuration = {
                        order = 8,
                        type = "toggle",
                        name = "Show duration",
                        desc = "Show the amount of seconds of before you need to cast.",
                        get = function() return self.db.profile.showDuration end,
                        set = function(_, value)
                            self.db.profile.showDuration = value;
                            self:UpdateDurationVisibility();
                        end,
                        width = 0.75,
                    },
                    drColors = {
                        order = 9,
                        type = "toggle",
                        name = "Show DR colors",
                        desc = "Set the bar's color to reflect the healer's DR status for your casted CC.",
                        get = function() return self.db.profile.drColors end,
                        set = function(_, value)
                            self.db.profile.drColors = value;
                            self:UpdateDRColors();
                        end,
                        width = 0.75,
                    },
                    testModeButton = {
                        order = 10,
                        type = "execute",
                        name = "Toggle Test Mode",
                        desc = "Click to toggle test mode on and off. You can drag to move the bar in test mode.",
                        func = function() 
                            self.db.profile.testMode = not self.db.profile.testMode;
                            self:ToggleTestMode();
                        end,
                        width = "full",
                    },
            
                },
            },
        }
    };

    AceConfig:RegisterOptionsTable(CCHelperConfig.name, options);
    AceConfigDialog:AddToBlizOptions(CCHelperConfig.name, CCHelperConfig.name);

    return CCHelperConfig;
end

function CCHelper:UpdateCCBarSize()
    self.CCBar:SetSize(self.db.profile.ccBarWidth, self.db.profile.ccBarHeight);
end

function CCHelper:UpdateCCBarPosition()
    self.CCBar:SetPoint("CENTER", UIParent, "CENTER", self.db.profile.ccBarPosition.x, self.db.profile.ccBarPosition.y);
end

function CCHelper:ToggleTestMode()
    if self.db.profile.testMode then
        self:EnableDragging();
        self:SimulateCC();
    else
        self:DisableDragging();
        self.CCBar.testText:Hide();
    end
end

function CCHelper:UpdateIconVisibility()
    if self.db.profile.showIcon then
        self.CCBar.icon:Show();
    else
        self.CCBar.icon:Hide();
    end
end

function CCHelper:UpdateDurationVisibility()
    if self.db.profile.showDuration then
        self.CCBar.duration:Show();
    else
        self.CCBar.duration:Hide();
    end
end

function CCHelper:UpdateDRColors()
    if self.db.profile.drColors then
        local _, class = UnitClass("player");
        local drCategory = self.castedCCForClass[class].dr;
        if drCategory then
            local severity = self:GetDRSeverity(drCategory);
            self.CCBar:SetStatusBarColor(unpack(self.severityColor[severity]));
        end
    else
        self.CCBar:SetStatusBarColor(unpack(self.lightBlue));
    end
end

function CCHelper:SimulateCC()
    local fakeCCSpellID = 118;
    local fakeCCDuration = 30;
    local fakeIconTexture = 136071;

    local currentTime = GetTime();  
    local fakeExpirationTime = currentTime + fakeCCDuration;

    self.CCBar:SetMinMaxValues(0, fakeCCDuration);
    self.CCBar:SetValue(fakeCCDuration);
    self.CCBar:Show();

    self.CCBar.icon:SetTexture(fakeIconTexture);

    self:UpdateDurationVisibility();
    self.CCBar.testText:Show();

    self.CCBar:SetScript("OnUpdate", function(_, elapsed)
        local remainingTime = fakeExpirationTime - GetTime();
        if remainingTime > 0 then
            self.CCBar:SetValue(remainingTime);
            self.CCBar.duration:SetFormattedText("%.1f", remainingTime);
        else
            self.CCBar:SetScript("OnUpdate", nil);
        end
    end);
end

function CCHelper:EnableDragging()
    self.CCBar:Show();
    self.CCBar:EnableMouse(true);
    self.CCBar:SetMovable(true);
    self.CCBar:RegisterForDrag("LeftButton");
    self.CCBar:SetScript("OnDragStart", function(frame)
        frame:StartMoving();
    end)
    self.CCBar:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing();
        local point, _, relativePoint, x, y = frame:GetPoint();

        self.db.profile.ccBarPosition.point = point;
        self.db.profile.ccBarPosition.relativePoint = relativePoint;
        self.db.profile.ccBarPosition.x = x;
        self.db.profile.ccBarPosition.y = y;
    end);
end

function CCHelper:DisableDragging()
    self.CCBar:Hide();
    self.CCBar:EnableMouse(false);
    self.CCBar:SetMovable(false);
    self.CCBar:SetScript("OnDragStart", nil);
    self.CCBar:SetScript("OnDragStop", nil);
end

local defaults = {
    profile = {
        ccBarPosition = { x = 0, y = -300 },
        ccBarWidth = 200,
        ccBarHeight = 20,
        ccBarLocked = false,
        testMode = false,
        showIcon = true,
        gracePeriod = 0.15,
        showDuration = false,
        drColors = true,
    }
};

function CCHelper:ResetSettings()
    self.db.profile.ccBarPosition = defaults.profile.ccBarPosition;
    self.db.profile.ccBarWidth = defaults.profile.ccBarWidth;
    self.db.profile.ccBarHeight = defaults.profile.ccBarHeight;
    self.db.profile.showIcon = defaults.profile.showIcon;
    self.db.profile.showDuration = defaults.profile.showDuration;
    self.db.profile.gracePeriod = defaults.profile.gracePeriod;
    self.db.profile.drColors = defaults.profile.drColors;
end

function CCHelper:HandleSlashCommand(input)
    if input == "test" then
        self.db.profile.testMode = not self.db.profile.testMode;
        self:ToggleTestMode();
        self:Print("Test Mode " .. (self.db.profile.testMode and "enabled" or "disabled"));
    elseif input == "reset" then
        self:ResetSettings();
        self:UpdateCCBarPosition();
        self:UpdateCCBarSize();

        print("CCHelper: Settings reset to default");
    elseif input == "" then
        Settings.OpenToCategory("CCHelper");
    else
        self:Print("Commands:");
        print("/cc test - Toggle test mode on and off");
        print("/cc reset - Reset the CC Bar settings to default");
        print("/cc - Open the addon options panel");
    end
end

function CCHelper:Reload(input)
    if input == "" then
        ReloadUI();
    end
end

function CCHelper:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CCHelperDB", defaults, true);

    self.healerUnitID = nil;

    self:CreateMenu();
    self:CreateCCBar();
    self:ToggleTestMode();

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "HandleCombatLog");
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "SetEnemyArenaHealerID");
    self:RegisterEvent("ARENA_OPPONENT_UPDATE", "SetEnemyArenaHealerID");

    self:RegisterChatCommand("cc", "HandleSlashCommand");
    self:RegisterChatCommand("rl", "Reload");
end