local MiniTest = require "mini.test"
MiniTest.setup()

local child = MiniTest.new_child_neovim()

local start_seek = function(opts)
  child.lua_func(function(opts)
    vim.schedule(function()
      M.seek(opts)
    end)
  end, opts or {})
end

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
    return ("Expected cursor to be at %s, %s, was at %s, %s"):format(
      row_1i,
      col_0i,
      cursor[1],
      cursor[2]
    )
  end
)

local T = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua" }
      child.bo.readonly = false
      child.o.lines = 20
      child.o.columns = 75
      child.lua_func(function()
        M = require "seek"
      end)
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
  start_seek {}
  child.type_keys "<Esc>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())

  start_seek {}
  child.type_keys { "c", "<Esc>" }
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["cancel select with <C-c>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "<C-c>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())

  start_seek {}
  child.type_keys { "c", "<C-c>" }
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["seek"]["same line"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "chj"
  expect_cursor(2, 35, "char)")
end
T["seek"]["separate line"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "chd"
  expect_cursor(3, 42, "char = nil, } end")
end
T["seek"]["single match"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "no"
  expect_cursor(3, 5, "not ok then return { type = 'Error', char = nil, } end")
end
T["seek"]["multibyte input"] = function()
  child.api.nvim_buf_set_lines(0, 0, -1, true, { "prefix éø target" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  start_seek {}
  child.type_keys "éø"
  expect_cursor(1, 7, "éø target")
end
T["seek"]["case_type=smart"] = MiniTest.new_set()
T["seek"]["case_type=smart"]["lower case input"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "erf"
  expect_cursor(3, 34, "Error', char = nil, } end")
end
T["seek"]["case_type=smart"]["upper case input"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "Er"
  expect_cursor(3, 34, "Error', char = nil, } end")
end
T["seek"]["case_type=sensitive"] = MiniTest.new_set()
T["seek"]["case_type=sensitive"]["lower case input"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek { case_type = "sensitive" }
  child.type_keys "er"
  expect_cursor(5, 42, "error', char = nil, } end")
end
T["seek"]["case_type=sensitive"]["upper case input"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek { case_type = "sensitive" }
  child.type_keys "Er"
  expect_cursor(3, 34, "Error', char = nil, } end")
end
T["seek"]["case_type=insensitive"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek { case_type = "insensitive" }
  child.type_keys "erf"
  expect_cursor(3, 34, "Error', char = nil, } end")
end

T["seek"]["no matches"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "zz"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["invalid label selected"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "chz"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["cancel label with <Esc>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
  child.type_keys "ch"
  child.type_keys "<Esc>"
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end
T["seek"]["cancel label with <C-c>"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek {}
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
  start_seek { direction = "backwards" }
  child.type_keys "chf"
  expect_cursor(6, 29, "char = vim.fn.nr2char(char), }")
end
T["seek"]["backwards"]["separate line"] = function()
  expect_cursor(6, 58, "}")
  start_seek { direction = "backwards" }
  child.type_keys "chk"
  expect_cursor(5, 5, "char == escape then return { type = 'error', char = nil, } end")
end
T["seek"]["backwards"]["single match"] = function()
  expect_cursor(6, 58, "}")
  start_seek { direction = "backwards" }
  child.type_keys "pc"
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
end

T["seek"]["forwards"] = MiniTest.new_set()
T["seek"]["forwards"]["same line"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek { direction = "forwards" }
  child.type_keys "chf"
  expect_cursor(2, 35, "char)")
end
T["seek"]["forwards"]["separate line"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek { direction = "forwards" }
  child.type_keys "chj"
  expect_cursor(3, 42, "char = nil, } end")
end
T["seek"]["forwards"]["single match"] = function()
  expect_cursor(2, 19, "pcall(vim.fn.getchar)")
  start_seek { direction = "forwards" }
  child.type_keys "lo"
  expect_cursor(4, 2, "local escape = 27")
end

T["visible-range boundaries"] = MiniTest.new_set()
T["visible-range boundaries"]["default search excludes matches below the window"] = function()
  child.cmd "resize 8"
  child.api.nvim_buf_set_lines(0, 0, -1, true, {
    "start",
    "plain",
    "zz inside",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "zz outside",
  })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  start_seek {}
  child.type_keys "zz"
  expect_cursor(3, 0, "zz inside")
end
T["visible-range boundaries"]["forward search excludes matches below the window"] = function()
  child.cmd "resize 8"
  child.api.nvim_buf_set_lines(0, 0, -1, true, {
    "start",
    "plain",
    "zz inside",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "zz outside",
  })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  start_seek { direction = "forwards" }
  child.type_keys "zz"
  expect_cursor(3, 0, "zz inside")
end
T["visible-range boundaries"]["backward search excludes matches below the window"] = function()
  child.cmd "resize 8"
  child.api.nvim_buf_set_lines(0, 0, -1, true, {
    "start",
    "zz inside",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "plain",
    "zz outside",
  })
  child.api.nvim_win_set_cursor(0, { 4, 0 })
  start_seek { direction = "backwards" }
  child.type_keys "zz"
  expect_cursor(2, 0, "zz inside")
end

T["closed folds"] = MiniTest.new_set()
T["closed folds"]["ignores folded matches and selects a visible match"] = function()
  child.api.nvim_buf_set_lines(0, 0, -1, true, {
    "start",
    "zz folded",
    "inside fold",
    "zz visible",
  })
  child.cmd "setlocal foldmethod=manual"
  child.cmd "2,3fold"
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  start_seek {}
  child.type_keys "zz"
  expect_cursor(4, 0, "zz visible")
end

T["closed folds"]["forward search from a later row skips folded matches"] = function()
  child.api.nvim_buf_set_lines(0, 0, -1, true, {
    "start",
    "cursor",
    "plain",
    "plain",
    "zz folded",
    "inside fold",
    "plain",
    "zz visible",
  })
  child.cmd "setlocal foldmethod=manual"
  child.cmd "5,6fold"
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  start_seek { direction = "forwards" }
  child.type_keys "zz"
  expect_cursor(8, 0, "zz visible")
end
T["closed folds"]["backward search from a later row skips folded matches"] = function()
  child.api.nvim_buf_set_lines(0, 0, -1, true, {
    "plain",
    "zz visible",
    "zz folded",
    "inside fold",
    "plain",
    "plain",
    "plain",
    "cursor",
  })
  child.cmd "setlocal foldmethod=manual"
  child.cmd "3,4fold"
  child.api.nvim_win_set_cursor(0, { 8, 0 })
  start_seek { direction = "backwards" }
  child.type_keys "zz"
  expect_cursor(2, 0, "zz visible")
end
T["closed folds"]["default search from a scrolled view skips folded matches"] = function()
  local lines = {}
  for row = 1, 30 do
    lines[row] = "plain"
  end
  lines[22] = "zz folded"
  lines[23] = "inside fold"
  lines[25] = "zz visible"
  child.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  child.cmd "setlocal foldmethod=manual"
  child.cmd "22,23fold"
  child.api.nvim_win_set_cursor(0, { 20, 0 })
  child.cmd "normal! zt"
  start_seek {}
  child.type_keys "zz"
  expect_cursor(25, 0, "zz visible")
end

T["match limit"] = MiniTest.new_set()
T["match limit"]["warns without creating labels beyond capacity"] = function()
  child.api.nvim_buf_set_lines(0, 0, -1, true, { string.rep("zz ", 56) })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.lua_func(function()
    _G.seek_notifications = {}
    _G.seek_getchar_calls = 0
    rawset(vim, "notify", function(message, level)
      table.insert(_G.seek_notifications, { message = message, level = level })
    end)
    rawset(vim.fn, "getchar", function()
      _G.seek_getchar_calls = _G.seek_getchar_calls + 1
      return string.byte "z"
    end)
  end)
  child.lua [[M.seek()]]
  MiniTest.expect.equality(child.lua_get "_G.seek_notifications", {
    { message = "[seek.nvim]: Listening ...", level = 2 },
    { message = "[seek.nvim]: Too many matches (maximum 54)", level = 3 },
  })
  MiniTest.expect.equality(child.lua_get "_G.seek_getchar_calls", 2)
  MiniTest.expect.equality(child.api.nvim_win_get_cursor(0), { 1, 0 })
  MiniTest.expect.equality(
    child.lua_get [[vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().Seek, 0, -1, {})]],
    {}
  )
end

T["setup"] = MiniTest.new_set()
T["setup"]["sets the label highlight and is idempotent across reloads"] = function()
  child.lua [[package.loaded.seek = nil]]
  child.lua [[M = require "seek"]]
  child.api.nvim_set_hl(0, "SeekLabel", {})
  child.lua [[M.setup()]]
  MiniTest.expect.equality(child.api.nvim_get_hl(0, { name = "SeekLabel", link = true }), {
    link = "Search",
  })

  child.api.nvim_set_hl(0, "SeekLabel", { link = "WarningMsg" })
  child.lua [[M.setup()]]
  MiniTest.expect.equality(child.api.nvim_get_hl(0, { name = "SeekLabel", link = true }), {
    link = "WarningMsg",
  })

  child.api.nvim_set_hl(0, "SeekLabel", {})
  child.lua [[package.loaded.seek = nil]]
  child.lua [[M = require "seek"]]
  child.lua [[M.setup()]]
  MiniTest.expect.equality(child.api.nvim_get_hl(0, { name = "SeekLabel", link = true }), {
    link = "Search",
  })
end

return T
