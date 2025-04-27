-- src/rendering/styles.lua
-- Centralized text style definitions for the game UI.

local Card = require('src.game.card') -- Required for PORT_COLORS keys

local StyleGuide = {
    -- Font names correspond to keys in Renderer.fonts table
    CARD_TITLE =      { fontName = 'worldStandard',      color = {0, 0, 0, 1} },       -- Black (Original - maybe for hand view?)
    CARD_TITLE_NW =   { fontName = 'worldTitleSemiBold', color = {0, 0, 0, 1} },       -- Black, SemiBold for Network
    CARD_COST =       { fontName = 'worldSmall',         color = {0.2, 0.2, 0.2, 1} }, -- Dark Gray, Uses standard worldSmall
    CARD_EFFECT =     { fontName = 'worldSmall',         color = {0.1, 0.1, 0.1, 1} }, -- Dark Gray, Uses standard worldSmall
    CARD_ART_LABEL =  { fontName = 'worldStandard',      color = {0, 0, 0, 1} },       -- Black (For the 'ART' placeholder)

    -- NEW: Style for Convergence text using the white BMFont
    CARD_EFFECT_CONVERGENCE = { fontName = 'worldConvergence', color = {1, 1, 1, 1} }, -- White

    UI_LABEL =        { fontName = 'uiStandard',    color = {1, 1, 1, 1} },       -- White
    UI_HAND_LABEL =   { fontName = 'uiStandard',    color = {1, 1, 1, 1} },       -- White
    UI_STATUS_MSG =   { fontName = 'uiStandard',    color = {1, 1, 1, 1} },       -- White (Was yellow)
    UI_HELP_TEXT =    { fontName = 'uiStandard',    color = {1, 1, 1, 1} },       -- White

    BUTTON_TEXT =     { fontName = 'uiStandard',    color = {0, 0, 0, 1} },       -- Black
    BUTTON_TEXT_DIS = { fontName = 'uiStandard',    color = {0.3, 0.3, 0.3, 1} }, -- Dark Gray (Disabled)

    -- Preview Styles (use preview fonts, copy CARD colors)
    PREVIEW_TITLE_NW = { fontName = 'previewTitleSemiBold', color = {0, 0, 0, 1} },       -- Black, SemiBold
    PREVIEW_COST =     { fontName = 'previewSmall',         color = {0.2, 0.2, 0.2, 1} }, -- Dark Gray
    PREVIEW_EFFECT =   { fontName = 'previewSmall',         color = {0.1, 0.1, 0.1, 1} }, -- Dark Gray
    PREVIEW_ART_LABEL ={ fontName = 'previewStandard',      color = {0, 0, 0, 1} },       -- Black
    HELP_BOX_BACKGROUND_COLOR = {0.1, 0.1, 0.15, 0.85}, -- Gray with 50% opacity
    HELP_BOX_BORDER_COLOR = {0.8, 0.8, 0.8, 0.9},
    HELP_BOX_TEXT_COLOR = {1, 1, 1, 1}, -- White

    -- NEW: Port Colors moved from renderer.lua
    PORT_COLORS = {
        [Card.Type.TECHNOLOGY] = { 0.2, 1, 0.2, 1 }, -- Electric Green
        [Card.Type.CULTURE]    = { 1, 0.8, 0, 1 },   -- Warm Yellow/Orange
        [Card.Type.RESOURCE]   = { 0.6, 0.4, 0.2, 1 }, -- Earthy Brown/Bronze
        [Card.Type.KNOWLEDGE]  = { 0.6, 0.2, 1, 1 },   -- Deep Purple/Indigo
    },
    ABSENT_PORT_COLOR = { 0.3, 0.3, 0.3, 1 }, -- Dim Gray (For ports that are not defined)
    PORT_BORDER_COLOR = { 0, 0, 0, 1 }, -- Black
}

-- You could add baseSize here too if needed for complex calculations,
-- but for now, font objects handle size.

return StyleGuide 
