# `seek.nvim`

My take on a minimal [`vim-easymotion`](https://github.com/easymotion/vim-easymotion)

### Overview
- ~200 LOC, 1 source file, 1 test file (TODO)
- When invoking `seek()`, the next two chars are recorded:
    - If either is `<Esc>` or `<C-c>`, the function is aborted
    - Else, `seek()` searches for substring matches of the recorded chars and creates an extmark label immediately after the match
    - The next char is recorded:
        - If a label is typed, the cursor is to the location of the first typed char (not the label) and the jumplist is updated
        - Else, the function is aborted

### API
```lua
--- @class SeekOpts
--- @field direction "before"|"after"
--- @field case_sensitive? boolean defaults to false

--- @param opts SeekOpts
local seek = function(opts)
```

### Similar plugins
- [`flash`](https://github.com/folke/flash.nvim)
- [`leap`](https://github.com/ggandor/leap.nvim)
- [`hop`](https://github.com/smoka7/hop.nvim)
