return {
  {
    "nvim-mini/mini.surround",
    opts = {
      custom_surroundings = {
        ["（"] = { input = { "（().-()）" }, output = { left = "（", right = "）" } },
        ["）"] = { input = { "（().-()）" }, output = { left = "（", right = "）" } },
        ["【"] = { input = { "【().-()】" }, output = { left = "【", right = "】" } },
        ["】"] = { input = { "【().-()】" }, output = { left = "【", right = "】" } },
        ["《"] = { input = { "《().-()》" }, output = { left = "《", right = "》" } },
        ["》"] = { input = { "《().-()》" }, output = { left = "《", right = "》" } },
        ["‘"] = { input = { "「().-()」" }, output = { left = "「", right = "」" } },
        ["’"] = { input = { "「().-()」" }, output = { left = "「", right = "」" } },
        ["“"] = { input = { "『().-()』" }, output = { left = "『", right = "』" } },
        ["”"] = { input = { "『().-()』" }, output = { left = "『", right = "』" } },
        ["「"] = { input = { "「().-()」" }, output = { left = "「", right = "」" } },
        ["」"] = { input = { "「().-()」" }, output = { left = "「", right = "」" } },
        ["『"] = { input = { "『().-()』" }, output = { left = "『", right = "』" } },
        ["』"] = { input = { "『().-()』" }, output = { left = "『", right = "』" } },
      },
      mappings = {
        add = "Sa",
        delete = "Sd",
        find = "Sf",
        find_left = "SF",
        highlight = "Sh",
        replace = "Sr",
        update_n_lines = "Sn",
      },
    },
  },
}
