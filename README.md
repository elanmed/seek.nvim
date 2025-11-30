# `seek.nvim`

My take on a minimal [`vim-easymotion`](https://github.com/easymotion/vim-easymotion)

![demo](https://elanmed.dev/nvim-plugins/seek.png)

### Overview

- ~200 LOC, 1 source file, 1 test file
- When calling `seek()`, the function records the next two keys and searches for substring matches of those characters in the file
  - If there's only one match, the cursor is set to the match
  - Otherwise, an extmark label is set on the character _following_ the match
  - The next key is recorded:
    - If a label is typed, the cursor is set to the location corresponding to the first typed char (i.e. not the location of the label)
- At any point, `seek()` can be aborted with `<Esc>` or `<C-c>`

### API

```lua
--- @class SeekOpts
--- @field direction? "backwards"|"forwards" if no direction is passed, the all visible lines are searched
--- @field case_type? "sensitive"|"insensitive"|"smart" defaults to "smart"

--- @param opts? SeekOpts
local seek = function(opts)
```

### Similar plugins

- [`vim-easymotion`](https://github.com/easymotion/vim-easymotion)
- [`flash.nvim`](https://github.com/folke/flash.nvim)
- [`leap.nvim`](https://github.com/ggandor/leap.nvim)
- [`hop.nvim`](https://github.com/smoka7/hop.nvim)
