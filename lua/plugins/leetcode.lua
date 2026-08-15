-- LeetCode 刷题专属会话
-- 启动方式：nvim leetcode.nvim
local leet_arg = "leetcode.nvim"

local function is_leet_session()
  return vim.fn.argv(0, -1) == leet_arg
end

local function repo_root()
  return vim.fs.normalize("~/Space/Study/LeetCode")
end

local function leetcode_gdb_adapter()
  return {
    type = "executable",
    command = "gdb",
    args = { "--interpreter=dap", "-x", repo_root() .. "/debug/leetcode.gdb" },
  }
end

local function gen_checks(q)
  local ok, fn = pcall(dofile, repo_root() .. "/scripts/gen_checks.lua")
  if not ok then
    vim.notify("加载 gen_checks.lua 失败: " .. fn, vim.log.levels.WARN, { title = "leetcode" })
    return
  end
  fn(q)
end

return {
  {
    "kawre/leetcode.nvim",
    enabled = vim.fn.has("wsl") == 1,
    lazy = not is_leet_session(),
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      arg = leet_arg,
      lang = "cpp",
      cn = { enabled = true },
      storage = {
        home = repo_root() .. "/solutions",
      },
      picker = { provider = "snacks-picker" },
      editor = {
        reset_previous_code = false,
        fold_imports = true,
      },
      injector = {
        cpp = {
          imports = function()
            return {
              "// Created: " .. os.date("%Y-%m-%d %H:%M:%S"),
              "",
              '#include "../utils.h"',
              "",
              "using namespace std;",
            }
          end,
          after = {
            "int main() {",
            "  // @TESTAUTOGEN",
            "  return 0;",
            "}",
          },
        },
      },
      hooks = {
        ["question_enter"] = { gen_checks },
      },
    },
    config = function(_, opts)
      require("leetcode").setup(opts)

      require("which-key").add({ { "<leader>k", group = "LeetCode" } })
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
      end

      map("<leader>kk", "<cmd>Leet menu<cr>", "主面板")
      map("<leader>kc", "<cmd>Leet console<cr>", "测试用例控制台")
      map("<leader>ki", "<cmd>Leet info<cr>", "题目信息")
      map("<leader>kt", "<cmd>Leet tabs<cr>", "已开题目")
      map("<leader>ky", "<cmd>Leet yank<cr>", "复制提交区")
      map("<leader>kL", "<cmd>Leet lang<cr>", "切换语言")
      map("<leader>kr", "<cmd>Leet run<cr>", "远程样例测试")
      map("<leader>ks", "<cmd>Leet submit<cr>", "提交")
      map("<leader>kR", "<cmd>Leet random<cr>", "随机一题")
      map("<leader>kl", "<cmd>Leet list<cr>", "题单")
      map("<leader>kD", "<cmd>Leet daily<cr>", "每日一题")
      map("<leader>ko", "<cmd>Leet open<cr>", "浏览器打开")
      map("<leader>kS", "<cmd>Leet last_submit<cr>", "恢复上次提交代码")
      map("<leader>ke", "<cmd>Leet reset<cr>", "重置代码部分")
      map("<leader>kI", "<cmd>Leet inject<cr>", "重新注入")
      map("<leader>kd", "<cmd>Leet desc toggle<cr>", "题面开关")

      map("<leader>kC", function()
        local q = require("leetcode.utils").curr_question()
        if q then
          gen_checks(q)
        end
      end, "重新生成样例 CHECK")

      -- 本地编译运行
      local function current_solution()
        local file = vim.api.nvim_buf_get_name(0)
        if vim.bo.buftype ~= "" or not file:match("%.cpp$") then
          vim.notify("当前不是题解 buffer", vim.log.levels.WARN, { title = "leetcode" })
          return nil
        end
        vim.cmd.write()
        return file
      end

      map("<leader>kb", function()
        local file = current_solution()
        if not file then
          return
        end
        local cmd = { "just", "run", file }
        local term_opts = {
          cwd = repo_root(),
          interactive = false,
          win = { position = "bottom", height = 0.35, enter = false },
        }
        -- get 只在新建终端时启动进程：先销毁旧终端（含 buffer），
        -- 否则第二次按键只会展示上次的旧输出而不重新编译
        local existing = Snacks.terminal.get(cmd, vim.tbl_extend("force", term_opts, { create = false }))
        if existing then
          existing:close({ buf = true })
        end
        Snacks.terminal.get(cmd, term_opts)
      end, "本地编译运行")

      -- 编译 debug 版并启动 DAP（gdb adapter 见 debug.lua）
      map("<leader>kg", function()
        local file = current_solution()
        if not file then
          return
        end
        local res = vim.system({ "just", "debug", file }, { cwd = repo_root(), text = true }):wait()
        if res.code ~= 0 then
          vim.notify(res.stderr or "编译失败", vim.log.levels.ERROR, { title = "leetcode" })
          return
        end
        local lines = vim.split(res.stdout or "", "\n", { trimempty = true })
        local dap = require("dap")
        dap.adapters.leetcode_gdb = leetcode_gdb_adapter()
        dap.run({
          name = "LeetCode",
          type = "leetcode_gdb",
          request = "launch",
          program = lines[#lines],
          cwd = repo_root(),
        })
      end, "编译并调试")

      -- 笔记
      map("<leader>kn", function()
        local file = current_solution()
        if not file then
          return
        end
        local res = vim.system({ "just", "note", file }, { cwd = repo_root(), text = true }):wait()
        if res.code ~= 0 then
          vim.notify(res.stderr or "创建笔记失败", vim.log.levels.ERROR, { title = "leetcode" })
          return
        end
        local note_path = vim.trim(res.stdout)
        local in_zellij = vim.env.ZELLIJ ~= nil
        if in_zellij then
          local cmd = {
            "zellij",
            "action",
            "new-pane",
            "--stacked",
            "--name",
            "note",
            "--",
            "nvim",
            note_path,
          }
          vim.fn.jobstart(cmd, { detach = true })
          vim.notify("已在 Zellij 新 pane 打开笔记", vim.log.levels.INFO, { title = "leetcode" })
        end
      end, "笔记")
    end,
  },
  {
    "zbirenbaum/copilot.lua",
    cond = function()
      return not is_leet_session()
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    optional = true,
    cond = function()
      return not is_leet_session()
    end,
  },
  {
    "fang2hou/blink-copilot",
    optional = true,
    cond = function()
      return not is_leet_session()
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      if not is_leet_session() then
        return
      end
      local default = vim.tbl_get(opts, "sources", "default")
      if type(default) == "table" then
        opts.sources.default = vim.tbl_filter(function(s)
          return s ~= "copilot"
        end, default)
      end
      if vim.tbl_get(opts, "sources", "providers", "copilot") then
        opts.sources.providers.copilot = nil
      end
    end,
  },
}
