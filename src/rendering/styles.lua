-- src/rendering/styles.lua
-- Centralized text style definitions for the game UI.

local StyleGuide = {
    -- Font names correspond to keys in Renderer.fonts table
    CARD_TITLE =      { fontName = 'worldStandard',      color = {0, 0, 0, 1} },       -- Black (Original - maybe for hand view?)
    CARD_TITLE_NW =   { fontName = 'worldTitleSemiBold', color = {0, 0, 0, 1} },       -- Black, SemiBold for Network
    CARD_COST =       { fontName = 'worldSmall',         color = {0.2, 0.2, 0.2, 1} }, -- Dark Gray, Uses standard worldSmall
    CARD_EFFECT =     { fontName = 'worldSmall',         color = {0.1, 0.1, 0.1, 1} }, -- Dark Gray, Uses standard worldSmall
    CARD_ART_LABEL =  { fontName = 'worldStandard',      color = {0, 0, 0, 1} },       -- Black (For the 'ART' placeholder)

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
}

-- You could add baseSize here too if needed for complex calculations,
-- but for now, font objects handle size.

return StyleGuide 
