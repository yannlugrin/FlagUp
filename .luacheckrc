std = "lua51"
max_line_length = false
codes = true
exclude_files = { "Libs/", ".release/", ".vscode/" }

ignore = {
    "212/self", -- unused self argument
}

globals = {
    "UISpecialFrames", "SlashCmdList", "SLASH_FLAGUP1", "StaticPopupDialogs",
}

read_globals = {
    "LibStub", "CreateFrame", "UIParent", "C_AddOns", "EllesmereUI",
    "CreateScrollBoxListLinearView", "ScrollUtil", "CreateDataProvider", "ScrollBoxConstants",
    "NORMAL_FONT_COLOR", "HIGHLIGHT_FONT_COLOR", "GRAY_FONT_COLOR", "Enum", "ColorManager",
    "GameFontNormal", "ButtonFrameTemplate_HidePortrait", "FILTER", "CANCEL",
    "Settings", "CreateSettingsListSectionHeaderInitializer", "MenuUtil",
    "MailFrame", "GetMoneyString", "ATTACHMENTS_MAX_SEND", "GameTooltip", "GameTooltip_Hide",
    "GREEN_FONT_COLOR", "RED_FONT_COLOR",
    "C_GameRules", "UnitFullName", "UnitFactionGroup", "UnitGUID",
    "C_Item", "Item", "RETRIEVING_ITEM_INFO", "WHITE_FONT_COLOR", "GetCursorInfo", "ClearCursor", "C_EventUtils",
    "ChatFrameUtil", "ChatEdit_InsertLink", "hooksecurefunc", "tContains",
    "CopyTable", "StaticPopup_Show", "OKAY", "strtrim",
    "C_Container", "BACKPACK_CONTAINER", "NUM_BAG_SLOTS", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "ClearSendMail", "ClickSendMailItemButton", "SendMail",
    "CursorHasItem", "C_Timer", "BACK",
}
