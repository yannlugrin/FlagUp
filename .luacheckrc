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
    "NORMAL_FONT_COLOR", "LIGHTBLUE_FONT_COLOR",
}
