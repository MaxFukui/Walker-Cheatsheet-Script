return {
    hotkey = { modifiers = { "alt", "ctrl", "shift" }, key = "K" },
    chooser = { width = 55, rows = 14 },
    terminal = "Ghostty",
    editor = "nvim",
    newWindow = { retryInterval = 0.1, timeout = 3.0 },
    typeOrder = {
        command = 1, note = 2, prompt = 3, link = 4, app = 5,
        bwhash = 6, editsheets = 6, utility = 6, diagnostic = 0,
    },
    icons = {
        command = "NSActionTemplate", note = "NSInfo", prompt = "NSBookmarksTemplate",
        link = "NSShareTemplate", app = "NSApplicationIcon", utility = "NSAdvanced",
        diagnostic = "NSCaution",
    },
}
