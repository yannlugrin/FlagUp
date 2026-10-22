std = "lua51"
max_line_length = false
codes = true
exclude_files = { "Libs/", ".release/", ".vscode/" }

ignore = {
    "212/self", -- unused self argument
}

globals = {
    "UISpecialFrames",
}

read_globals = {
    "LibStub", "CreateFrame", "UIParent", "C_AddOns", "EllesmereUI",
    "CreateScrollBoxListLinearView", "ScrollUtil", "CreateDataProvider", "ScrollBoxConstants",
    "NORMAL_FONT_COLOR", "HIGHLIGHT_FONT_COLOR", "GRAY_FONT_COLOR", "Enum", "ColorManager",
    "GameFontNormal", "ButtonFrameTemplate_HidePortrait",
}
