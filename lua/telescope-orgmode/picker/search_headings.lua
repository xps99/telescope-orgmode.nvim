local pickers = require('telescope.pickers')
local finders = require('telescope-orgmode.finders')
local conf = require('telescope.config').values
local config = require('telescope-orgmode.config')
local mappings = require('telescope-orgmode.mappings')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Search headlines',
    orgfiles = 'Search org files',
  }, 'headlines')

  vim.notify('search_headings picker starting with opts: ' .. vim.inspect(opts or {}), vim.log.levels.DEBUG)

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
      finder = finders.from_options(opts),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        local status = state.get_status(prompt_bufnr)
        status.current_depth = opts.max_depth or nil

        local function increase_depth()
          status.current_depth = (status.current_depth or 0) + 1
          opts.max_depth = status.current_depth
          vim.notify('Increasing depth to: ' .. tostring(opts.max_depth), vim.log.levels.DEBUG)
          local new_finder = finders.from_options(opts)
          action_state.get_current_picker(prompt_bufnr):refresh(new_finder, opts)
        end

        local function decrease_depth()
          if status.current_depth and status.current_depth > 1 then
            status.current_depth = status.current_depth - 1
            opts.max_depth = status.current_depth
            vim.notify('Decreasing depth to: ' .. tostring(opts.max_depth), vim.log.levels.DEBUG)
            local new_finder = finders.from_options(opts)
            action_state.get_current_picker(prompt_bufnr):refresh(new_finder, opts)
          else
            vim.notify('Minimum depth reached', vim.log.levels.DEBUG)
          end
        end

        map('i', '<C-k>', increase_depth)
        map('i', '<C-j>', decrease_depth)

        local function drill_down()
          local entry = action_state.get_selected_entry()
          if not entry or not entry.value.headline then
            vim.notify('Drill-down aborted: No entry or headline found', vim.log.levels.WARN)
            return
          end
          vim.notify('Drill-down triggered on headline: ' .. vim.inspect(entry.value.headline), vim.log.levels.DEBUG)
          opts.parent_headline = entry.value.headline
          opts.parent_headline_file = entry.value.filename
          local new_finder = finders.from_options(opts)
          local picker = action_state.get_current_picker(prompt_bufnr)
          picker:refresh(new_finder, opts)
          vim.schedule(function()
            picker:set_selection(1)
            vim.notify('Selection reset to first entry after drill-down', vim.log.levels.DEBUG)
          end)
        end

        map('i', '<C-y>', drill_down)
        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
