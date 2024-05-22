# telescope-orgmode.nvim

Integration for [orgmode](https://github.com/nvim-orgmode/orgmode) with
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

## Demo

Jump to to any heading in `org_agenda_files` with `:Telescope orgmode search_headings`

[![asciicast](https://asciinema.org/a/Oko0GT32HS6JCpzuSznUG0D1D.svg)](https://asciinema.org/a/Oko0GT32HS6JCpzuSznUG0D1D)

Refile heading from capture or current file under destination with `:Telescope orgmode refile_heading`

[![asciicast](https://asciinema.org/a/1X4oG6s5jQZrJJI3DfEzJU3wN.svg)](https://asciinema.org/a/1X4oG6s5jQZrJJI3DfEzJU3wN)

## Installation
### With lazyvim

```lua 
  {
    "lyz-code/telescope-orgmode.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("orgmode")

      vim.keymap.set("n", "<leader>r", require("telescope").extensions.orgmode.refile_heading)
      vim.keymap.set("n", "<leader>fh", require("telescope").extensions.orgmode.search_headings)
      vim.keymap.set("n", "<leader>li", require("telescope").extensions.orgmode.insert_link)
    end,
  }
```

### Without lazyvim

You can setup the extension by doing:

```lua
require('telescope').load_extension('orgmode')
```

To replace the default refile prompt:

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  group = vim.api.nvim_create_augroup('orgmode_telescope_nvim', { clear = true }),
  callback = function()
    vim.keymap.set('n', '<leader>or', require('telescope').extensions.orgmode.refile_heading)
  end,
})
```

## Available commands

```viml
:Telescope orgmode search_headings
:Telescope orgmode refile_heading
:Telescope orgmode insert_link
```

## Available functions

```lua
require('telescope').extensions.orgmode.search_headings
require('telescope').extensions.orgmode.refile_heading
require('telescope').extensions.orgmode.insert_link
```
