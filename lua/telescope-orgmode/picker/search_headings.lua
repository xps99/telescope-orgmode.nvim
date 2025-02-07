local pickers = require('telescope.pickers')
local finders = require('telescope-orgmode.finders')
local conf = require('telescope.config').values

local config = require('telescope-orgmode.config')
local mappings = require('telescope-orgmode.mappings')

local action_set = require('telescope.actions.set') -- <--- ADD THIS
local actions = require('telescope.actions') -- <--- AND THIS

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
      attach_mappings = function(_, map)
        -- Override the default select action to add fold reordering
        action_set.select:enhance({
          post = function()
            -- Run zx after jumping to the selected entry
            vim.schedule(function()
              vim.cmd('normal! zx')
            end)
          end,
        })

        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
