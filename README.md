# `seek.nvim`

My take on a minimal [`vim-easymotion`](https://github.com/easymotion/vim-easymotion)

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
