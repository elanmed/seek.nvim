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
  msg = "[seek.nvim]: " .. msg
  vim.notify(msg:format(...), level)
end

local ns_id = vim.api.nvim_create_namespace "Seek"
local lower_case = ("asdfjklghqweruioptyzxcvnmb")
local labels = vim.split(lower_case .. lower_case:upper(), "")

local M = {}

--- @class SeekOpts
--- @field direction "backwards"|"forwards"
--- @field case_sensitive? boolean
--- @param opts SeekOpts
M.seek = function(opts)
  if opts == nil then
    return notify(vim.log.levels.ERROR, "seek.opts is a required param")
  end
  if opts.direction ~= "backwards" and opts.direction ~= "forwards" then
    return notify(vim.log.levels.ERROR, "seek.opts.direction must be 'backwards' or 'forwards'")
  end
  local case_sensitive = (function()
    if vim.tbl_get(opts, "case_sensitive") == nil then return false end
    return opts.case_sensitive
  end)()

  local first_key = get_key()
  if first_key.type == "error" then
    notify(vim.log.levels.INFO, "Exiting")
    return
  end

  local second_key = get_key()
  if second_key.type == "error" then
    notify(vim.log.levels.INFO, "Exiting")
    return
  end

  local keys = first_key.char .. second_key.char
  if not case_sensitive then
    keys = keys:lower()
  end

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
  local _, cursor_col_0i = unpack(vim.api.nvim_win_get_cursor(0))
  local cursor_col_1i = cursor_col_0i + 1

  local lines = (function()
    if opts.direction == "forwards" then
      return vim.api.nvim_buf_get_lines(0, curr_line_0i, bottom_line_0i + 1, false)
    end

    return tbl_reverse(vim.api.nvim_buf_get_lines(0, top_line_0i, curr_line_0i + 1, false))
  end)()

  for line_idx_1i, line in ipairs(lines) do
    if not case_sensitive then
      line = line:lower()
    end

    local col_idx_1i = 1
    while true do
      local row_0i
      local char_col_0i
      local label_col_1i
      local label_col_0i
      local label

      local plain = true
      local match_start_col_1i, match_end_col_1i = line:find(keys, col_idx_1i, plain)
      if not match_start_col_1i then break end

      if line_idx_1i == 1 then
        if match_start_col_1i == cursor_col_1i then goto continue end
        if opts.direction == "backwards" and match_start_col_1i > cursor_col_1i then goto continue end
        if opts.direction == "forwards" and match_start_col_1i < cursor_col_1i then goto continue end
      end

      row_0i = line_idx_1i - 1
      row_0i = (function()
        if opts.direction == "backwards" then
          return curr_line_0i - row_0i
        end
        return curr_line_0i + row_0i
      end)()

      label_col_1i = match_start_col_1i + 2
      label_col_0i = label_col_1i - 1
      label = labels[#matches + 1]

      table.insert(matches,
        {
          row_0i = row_0i,
          char_col_0i = match_start_col_1i - 1,
          label_col_0i = label_col_0i,
          label = label,
        })

      ::continue::
      col_idx_1i = match_end_col_1i + 1
    end
  end

  if #matches == 0 then
    notify(vim.log.levels.WARN, "No matches")
    return
  end

  if #matches == 1 then
    local match = matches[1]
    local row_1i = match.row_0i + 1
    vim.cmd.normal { [[m']], bang = true, }
    vim.api.nvim_win_set_cursor(0, { row_1i, match.char_col_0i, })
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    return
  end

  for _, match in ipairs(matches) do
    vim.api.nvim_buf_set_extmark(0, ns_id, match.row_0i, match.label_col_0i, {
      virt_text = { { match.label, "SeekLabel", }, },
      virt_text_pos = "overlay",
    })
  end

  vim.schedule(function()
    local label_key = get_key()
    if label_key.type == "error" then
      notify(vim.log.levels.WARN, "Exiting")
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      return
    end

    for _, match in ipairs(matches) do
      if label_key.char == match.label then
        local row_1i = match.row_0i + 1
        vim.cmd.normal { [[m']], bang = true, }
        vim.api.nvim_win_set_cursor(0, { row_1i, match.char_col_0i, })
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
        return
      end
    end

    notify(vim.log.levels.WARN, "Invalid label selected")
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end)
end

vim.g.seek_setup_called = false
M.setup = function()
  if vim.g.seek_setup_called then return end
  vim.g.seek_setup_called = true

  vim.api.nvim_set_hl(0, "SeekLabel", { link = "Search", })
end

return M
