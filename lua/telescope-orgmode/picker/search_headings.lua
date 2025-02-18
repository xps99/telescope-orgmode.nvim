local pickers = require('telescope.pickers')
local finders = require('telescope-orgmode.finders')
local conf = require('telescope.config').values

local config = require('telescope-orgmode.config')
local mappings = require('telescope-orgmode.mappings')

local action_set = require('telescope.actions.set')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Search headlines',
    orgfiles = 'Search org files',
  }, 'headlines')

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
      finder = finders.from_options(opts),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        local status = state.get_status(prompt_bufnr)
        status.current_depth = opts.max_depth or nil

        -- Function to increase heading depth
        local function increase_depth()
          status.current_depth = (status.current_depth or 0) + 1
          opts.max_depth = status.current_depth
          local new_finder = finders.from_options(opts)
          action_state.get_current_picker(prompt_bufnr):refresh(new_finder, opts)
        end

        -- Function to decrease heading depth (minimum 1)
        local function decrease_depth()
          if status.current_depth and status.current_depth > 1 then
            status.current_depth = status.current_depth - 1
            opts.max_depth = status.current_depth
            local new_finder = finders.from_options(opts)
            action_state.get_current_picker(prompt_bufnr):refresh(new_finder, opts)
          end
        end

        -- Override default select action for fold reordering
        action_set.select:enhance({
          post = function()
            vim.schedule(function()
              vim.cmd('normal! zx')
            end)
          end,
        })

        -- Map Ctrl-+ and Ctrl-- to depth adjustment functions
        map('i', '<C-k>', increase_depth)
        map('i', '<C-j>', decrease_depth)

        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
