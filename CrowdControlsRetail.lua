local CCHelper = LibStub("AceAddon-3.0"):GetAddon("CCHelper");

CCHelper.CCsToLookFor = {
    -- mage
    [118]    = true, -- polymorph
    [113724] = true, -- ring of frost

    -- rogue
    [1833]   = true, -- cheap shot
    [408]    = true, -- kidney shot
    [6770]   = true, -- sap
    [1776]   = true, -- gouge
    [8122]   = true, -- psychic scream

    -- hunter
    [187650] = true, -- freezing trap
    [19577]  = true, -- intimidation

    -- paladin
    [853]    = true, -- hammer of justice
    [115750] = true, -- blinding light

    -- warrior
    [107570] = true, -- storm bolt
    [132168] = true, -- shockwave
    [5246]   = true, -- intimidating shout

    -- monk
    [115078] = true, -- paralysis
    [119381] = true, -- leg sweep

    -- shaman
    [211015] = true, -- hex

    -- warlock
    [5782]   = true, -- fear
    [5484]   = true, -- howl of terror
    [30283]  = true, -- shadowfury

    -- demon hunter
    [211881] = true, -- fel eruption
    [179057] = true, -- chaos nova
    [217832] = true, -- imprison

    -- death knight
    [108194] = true, -- asphyxiate

    -- druid
    [33786]  = true, -- cyclone
    [5211]   = true, -- mighty bash
    [22570]  = true, -- maim

    -- dragon
    [360806] = true, -- sleep walk
}