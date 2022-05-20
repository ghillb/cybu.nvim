# Cybu.nvim

**_Cy_**[cle]**_bu_**[ffer]**_.nvim_** is essentially a wrapper around `:bnext` & `:bprevious`. It adds a customizable notification window, that shows the buffer in focus and its neighbors, to provide context when cycling the buffer list with the provided plugin commands / key bindings.

See [:help cybu.nvim](https://github.com/ghillb/cybu.nvim/blob/main/doc/cybu.nvim.txt) for the docs.

<p align="center">
  <img src="https://user-images.githubusercontent.com/35503959/169406683-6fb0c4dd-2083-4b9b-87b2-3928da81d472.gif" alt="demo1.gif"/>
</p>

<details>
  <summary>More previews</summary>

<p align="center">
  <img src="https://user-images.githubusercontent.com/35503959/169406698-6d5e5eab-88a0-4804-a9a0-4add54d7a368.gif" alt="demo2.gif"/>
</p>

<p align="center">
  <img src="https://user-images.githubusercontent.com/35503959/169406701-aabebcb5-fbcb-4f4e-b43c-ce605d77a8d7.gif" alt="demo3.gif"/>
</p>

</details>

## Requirements

- Neovim >= 0.7.0

## Installation

### Quickstart with [packer](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "ghillb/cybu.nvim",
  branch = "v1.x", -- won't receive breaking changes
  -- branch = "main", -- timely updates
  requires = { "kyazdani42/nvim-web-devicons" }, --optional
  config = function()
    local ok, cybu = pcall(require, "cybu")
    if not ok then
      return
    end
    cybu.setup()
    vim.keymap.set("n", "K", "<Plug>(CybuPrev)")
    vim.keymap.set("n", "J", "<Plug>(CybuNext)")
  end,
})
```

After installing, run the `:CybuNext` or `:CybuPrev` command to cycle buffers and display the context window or use the exemplary key bindings defined above.

### Setup with other plugin managers

If you use another plugin manager, install `"ghillb/cybu.nvim"` and optionally `"kyazdani42/nvim-web-devicons"` with it, like you would with any other plugin.

Setup up **_Cybu_** by calling its setup function and placing the respective key bindings, which load the previous/next buffer, somewhere into your `init.lua`.

```lua
require("cybu").setup()
vim.keymap.set("n", "[b", "<Plug>(CybuPrev)")
vim.keymap.set("n", "]b", "<Plug>(CybuNext)")
```

## Configuration

If you want to customize the appearance and behaviour of **_Cybu_**, you can do it by adapting the configuration table.

```lua
require("cybu").setup({
  position = {
    relative_to = "win",          -- win, editor, cursor
    anchor = "topcenter",         -- topleft, topcenter, topright,
                                    -- centerleft, center, centerright,
                                    -- bottomleft, bottomcenter, bottomright
    vertical_offset = 10,         -- vertical offset from anchor in lines
    horizontal_offset = 0,        -- vertical offset from anchor in columns
    max_win_height = 5,           -- height of cybu window in lines
    max_win_width = 0.5,          -- integer for absolute in columns
                                    -- float for relative to win/editor width
  },
  style = {
    path = "relative",            -- absolute, relative, tail (filename only)
    border = "rounded",           -- single, double, rounded, none
    separator = " ",              -- string used as separator
    prefix = "…",                 -- string used as prefix for truncated paths
    padding = 1,                  -- left & right padding in number of spaces
    devicons = {
      enabled = true,             -- enable or disable web dev icons
      colored = true,             -- enable color for web dev icons
    },
    highlights = {                -- see highlights via :highlight
      current_buffer = "Visual",    -- used for the current buffer
      adjacent_buffers = "Comment", -- used for buffers not in focus
      background = "Normal",        -- used for the window background
    },
  },
  display_time = 750,             -- time the cybu window is displayed
  exclude = {                     -- filetypes, cybu will not be active
    "neo-tree",
    "fugitive",
    "qf",
  },
  fallback = function() end,      -- arbitrary fallback function
                                    -- used in excluded filetypes
})
```

## Features

- Adaptive size of the **_Cybu_** window
- Various styling & positioning options
- Exclude filetypes and define fallback
- Autocmd events `CybuOpen` & `CybuClose`

## Breaking changes

If breaking changes (will be kept to a minimum) are of no concern to you, use the `main` branch. Otherwise you can use the version pinned branches, e.g. `v1.x`. These branches will only receive bug fixes and other non-breaking changes.

## Roadmap

- Improve tests, tooling and add CI
- Add possibility to further customize the entry layout

## Testing via [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

Run tests with

```bash
nvim --headless -c "PlenaryBustedDirectory tests/"
```
