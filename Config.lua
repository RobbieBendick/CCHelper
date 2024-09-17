
local CCHelper = _G.LibStub("AceAddon-3.0"):NewAddon("CCHelper", "AceConsole-3.0", "AceEvent-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local CCHelperConfig;

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
            position = {
                order = 2,
                type = "group",
                name = "CC Bar Position",
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
                },
            },
        }
    };

    AceConfig:RegisterOptionsTable(CCHelperConfig.name, options);
    AceConfigDialog:AddToBlizOptions(CCHelperConfig.name, CCHelperConfig.name);
end

function CCHelper:UpdateCCBarPosition()
    self.CCBar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.db.profile.ccBarPosition.x, self.db.profile.ccBarPosition.y);
end

local defaults = {
    profile = {
        ccBarPosition = { x = 500, y = 300 },
        ccBarLocked = false,
        testMode = false,
    }
};

function CCHelper:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CCHelperDB", defaults, true);

    self.healerUnitID = nil;

    self:CreateMenu();
    self:CreateCCBar();
    
    self:RegisterEvent("UNIT_AURA", "HandleUnitAura");
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "HandleCombatLog");
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "SetEnemyArenaHealerID");
    self:RegisterEvent("ARENA_OPPONENT_UPDATE", "SetEnemyArenaHealerID");

end