--- @generic T
--- @param val T | nil
--- @param default_val T
--- @return T
local default = function(val, default_val)
  if val == nil then
    return default_val
  end
  return val
end

--- @param tbl table
--- @param ... any
local tbl_get = function(tbl, ...)
  if tbl == nil then return nil end
  return vim.tbl_get(tbl, ...)
end

local get_key = function()
  local ok, char = pcall(vim.fn.getchar)
  if not ok then return { type = "error", char = nil, } end
  local escape = 27
  if char == escape then return { type = "error", char = nil, } end
  return { type = "success", char = vim.fn.nr2char(char), }
end

--- @param tbl table
local tbl_reverse = function(tbl)
  local reversed = {}
  for idx = #tbl, 1, -1 do
    table.insert(reversed, tbl[idx])
  end
  return reversed
end

--- @param level vim.log.levels
--- @param msg string
--- @param ... any
local notify = function(level, msg, ...)
  msg = "[marks.nvim]: " .. msg
  vim.notify(msg:format(...), level)
end

local ns_id = vim.api.nvim_create_namespace "seek"
local lower_case = ("abcdefghijklmnopqrstuvwxyz")
local labels = vim.split(lower_case .. lower_case:upper(), "")

-- TODO
-- opts for case (in)sensitive
-- handle when the first key is the last char in the line - what's the second key
-- search on the current line?

local M = {}

--- @class SeekOpts
--- @field direction "before"|"after"
--- @param opts SeekOpts
M.seek = function(opts)
  local first_key = get_key()
  if first_key.type == "error" then
    notify(vim.log.levels.INFO, "Exiting after key 1")
    return
  end

  local second_key = get_key()
  if second_key.type == "error" then
    notify(vim.log.levels.INFO, "Exiting after key 2")
    return
  end

  local keys = first_key.char .. second_key.char

  --- @class Match
  --- @field row_0i number
  --- @field char_col_0i number
  --- @field label_col_0i number
  --- @field label string

  --- @type Match[]
  local matches = {}

  local curr_line_0i = vim.fn.line "." - 1
  local bottom_line_0i = vim.fn.line "w$" - 1
  local top_line_0i = vim.fn.line "w0" - 1

  local lines = (function()
    if opts.direction == "after" then
      local next_line_0i = curr_line_0i
      return vim.api.nvim_buf_get_lines(0, next_line_0i, bottom_line_0i + 1, false)
    end

    local prev_line_0i = curr_line_0i
    return tbl_reverse(vim.api.nvim_buf_get_lines(0, top_line_0i, prev_line_0i + 1, false))
  end)()

  for line_idx_1i, line in ipairs(lines) do
    local plain = true

    local idx_1i = 1
    while true do
      local start_col_1i, end_col_1i = line:find(keys, idx_1i, plain)
      if not start_col_1i then break end

      local row_0i = line_idx_1i - 1
      row_0i = (function()
        if opts.direction == "before" then
          return curr_line_0i - row_0i
        end
        return curr_line_0i + row_0i
      end)()

      local char_col_0i = start_col_1i - 1

      local label_col_1i = start_col_1i + 2
      local label_col_0i = label_col_1i - 1
      local label = labels[#matches + 1]

      table.insert(matches,
        {
          line = line,
          row_0i = row_0i,
          char_col_0i = char_col_0i,
          label_col_0i = label_col_0i,
          label = label,
        })

      idx_1i = end_col_1i + 1
    end
  end

  if #matches == 0 then
    notify(vim.log.levels.WARN, "No matches")
    return
  end

  if #matches == 1 then
    local match = matches[1]
    local row_1i = match.row_0i + 1
    vim.api.nvim_win_set_cursor(0, { row_1i, match.char_col_0i, })
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    return
  end

  for _, match in ipairs(matches) do
    vim.api.nvim_buf_set_extmark(0, ns_id, match.row_0i, match.label_col_0i, {
      virt_text = { { match.label, "CurSearch", }, },
      virt_text_pos = "overlay",
    })
  end

  vim.schedule(function()
    local label_key = get_key()
    if label_key.type == "error" then
      notify(vim.log.levels.WARN, "No label selected")
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      return
    end

    for _, match in ipairs(matches) do
      if label_key.char == match.label then
        local row_1i = match.row_0i + 1
        vim.api.nvim_win_set_cursor(0, { row_1i, match.char_col_0i, })
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
        return
      end
    end

    notify(vim.log.levels.WARN, "Invalid label selected")
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end)
end

return M
