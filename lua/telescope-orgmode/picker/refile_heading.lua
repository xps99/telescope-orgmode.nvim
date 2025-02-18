local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')

local config = require('telescope-orgmode.config')
local finders = require('telescope-orgmode.finders')
local actions = require('telescope-orgmode.actions')
local action_state = require('telescope.actions.state')
local org = require('telescope-orgmode.org')
local mappings = require('telescope-orgmode.mappings')
local state = require('telescope.state')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Refile to headline',
    orgfiles = 'Refile to orgfile',
  }, 'headlines')

  local closest_headline = org.get_closest_headline()

  -- local function increase_depth(prompt_bufnr)
  --   local current_picker = action_state.get_current_picker(prompt_bufnr)
  --   local status = state.get_status(prompt_bufnr)
  --   status._ot_current_depth = status._ot_current_depth or opts.max_depth or 1
  --   status._ot_current_depth = status._ot_current_depth + 1
  --   opts.max_depth = status._ot_current_depth
  --
  --   local new_finder = finders.from_options(opts)
  --   current_picker:refresh(new_finder, opts)
  -- end
  --
  -- local function decrease_depth(prompt_bufnr)
  --   local current_picker = action_state.get_current_picker(prompt_bufnr)
  --   local status = state.get_status(prompt_bufnr)
  --   status._ot_current_depth = status._ot_current_depth or opts.max_depth or 1
  --   status._ot_current_depth = math.max(1, status._ot_current_depth - 1)
  --   opts.max_depth = status._ot_current_depth
  --
  --   local new_finder = finders.from_options(opts)
  --   current_picker:refresh(new_finder, opts)
  -- end

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
      finder = finders.from_options(opts),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(_, map)
        action_set.select:replace(actions.refile(closest_headline))

        local status = state.get_status(prompt_bufnr)
        status.current_depth = opts.max_depth or 0

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
        -- Add keybindings for increasing and decreasing depth
        map('i', '<C-k>', increase_depth)
        map('i', '<C-j>', decrease_depth)

        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
