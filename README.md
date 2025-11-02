# `seek.nvim`

My take on a minimal [`vim-easymotion`](https://github.com/easymotion/vim-easymotion)

### Overview
- ~200 LOC, 1 source file, 1 test file
- When calling `seek()`, the next two chars are recorded and used to search for substring matches
    - If there's one match, the cursor is set to the location corresponding to the first typed char and the jumplist is updated
    - Else, an extmark label is set on the character following the match
    - The next char is recorded:
        - If a label is typed, the cursor is to the location corresponding to the first typed char and the jumplist is updated
- At any point, the function can be aborted with `<Esc>` or `<C-c>`

### API
```lua
--- @class SeekOpts
--- @field direction "backwards"|"forwards"
--- @field case_sensitive? boolean defaults to false

--- @param opts SeekOpts
local seek = function(opts)
```

### Similar plugins
- [`flash`](https://github.com/folke/flash.nvim)
- [`leap`](https://github.com/ggandor/leap.nvim)
- [`hop`](https://github.com/smoka7/hop.nvim)
