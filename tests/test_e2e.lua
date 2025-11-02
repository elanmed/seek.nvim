require "mini.test".setup()

local child = MiniTest.new_child_neovim()

local expect_cursor = MiniTest.new_expectation(
  "cursor set",
  --- @param row_1i number
  --- @param col_0i number
  --- @param content string
  function(row_1i, col_0i, content)
    local row_0i = row_1i - 1
    local col_1i = col_0i + 1
    local subbed_line = child.api.nvim_buf_get_lines(0, row_0i, row_0i + 1, false)[1]:sub(col_1i)
    local cursor = child.api.nvim_win_get_cursor(0)
    return cursor[1] == row_1i and cursor[2] == col_0i and subbed_line == content
  end,
  --- @param row_1i number
  --- @param col_0i number
  function(row_1i, col_0i)
    local cursor = child.api.nvim_win_get_cursor(child.api.nvim_get_current_win())
    return ("Expected cursor to be at %s, %s, was at %s, %s with content '%s'"):format(
      row_1i, col_0i, cursor[1], cursor[2]
    )
  end
)

local T = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua", }
      child.bo.readonly = false
      child.o.lines = 20
      child.o.columns = 75
      child.lua [[M = require('seek')]]
      child.api.nvim_buf_set_lines(0, 0, -1, true, {
        "local get_key = function()",
        "  local ok, char = pcall(vim.fn.getchar)",
        "  if not ok then return { type = 'Error', char = nil, } end",
        "  local escape = 27",
        "  if char == escape then return { type = 'error', char = nil, } end",
        "  return { type = 'Success', char = vim.fn.nr2char(char), }",
        "end",
      })
      child.type_keys "gg0"
      child.type_keys "jfp"
    end,
    post_once = child.stop,
  },
}

T["seek"] = MiniTest.new_set()
T["seek"]["cancel select with <Esc>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "<Esc>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())

  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys { "c", "<Esc>", }
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["cancel select with <C-c>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "<C-c>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())

  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys { "c", "<C-c>", }
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["same line"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "cha"
  expect_cursor(2, 35, "char)")
end
T["seek"]["separate line"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "chs"
  expect_cursor(3, 42, "char = nil, } end")
end
T["seek"]["single match"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "lo"
  expect_cursor(4, 2, "local escape = 27")
end
T["seek"]["case sensitive"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards", case_sensitive = true } end)]]
  child.type_keys "er"
  expect_cursor(5, 42, "error', char = nil, } end")
end
T["seek"]["no matches"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards", case_sensitive = true } end)]]
  child.type_keys "zz"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["invalid label selected"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "chz"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["cancel label with <Esc>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "ch"
  child.type_keys "<Esc>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["cancel label with <C-c>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  child.lua [[vim.schedule(function() M.seek { direction = "forwards" } end)]]
  child.type_keys "ch"
  child.type_keys "<C-c>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["seek"]["backwards"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.type_keys "G0"
      child.type_keys "k$"
    end,
  },
}
T["seek"]["backwards"]["same line"] = function()
  expect_cursor(6, 58, "}")
  child.lua [[vim.schedule(function() M.seek { direction = "backwards" } end)]]
  child.type_keys "cha"
  expect_cursor(6, 29, "char = vim.fn.nr2char(char), }")
end
T["seek"]["backwards"]["separate line"] = function()
  expect_cursor(6, 58, "}")
  child.lua [[vim.schedule(function() M.seek { direction = "backwards" } end)]]
  child.type_keys "chf"
  expect_cursor(5, 5, "char == escape then return { type = 'error', char = nil, } end")
end
T["seek"]["backwards"]["single match"] = function()
  expect_cursor(6, 58, "}")
  child.lua [[vim.schedule(function() M.seek { direction = "backwards" } end)]]
  child.type_keys "pc"
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
end

return T
