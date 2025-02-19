local pickers = require('telescope.pickers')
local finders = require('telescope-orgmode.finders')
local conf = require('telescope.config').values
local config = require('telescope-orgmode.config')
local mappings = require('telescope-orgmode.mappings')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')
local logger = require('telescope-orgmode.logger')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Search headlines',
    orgfiles = 'Search org files',
  }, 'headlines')

  logger.notify('search_headings picker starting with opts: ' .. vim.inspect(opts or {}), vim.log.levels.DEBUG)

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
          logger.notify('Increasing depth to: ' .. tostring(opts.max_depth), vim.log.levels.DEBUG)
          local new_finder = finders.from_options(opts)
          action_state.get_current_picker(prompt_bufnr):refresh(new_finder, opts)
        end

        local function decrease_depth()
          if status.current_depth and status.current_depth > 1 then
            status.current_depth = status.current_depth - 1
            opts.max_depth = status.current_depth
            logger.notify('Decreasing depth to: ' .. tostring(opts.max_depth), vim.log.levels.DEBUG)
            local new_finder = finders.from_options(opts)
            action_state.get_current_picker(prompt_bufnr):refresh(new_finder, opts)
          else
            logger.notify('Minimum depth reached', vim.log.levels.DEBUG)
          end
        end

        map('i', '<C-k>', increase_depth)
        map('i', '<C-j>', decrease_depth)

        local function drill_down()
          local entry = action_state.get_selected_entry()
          if not entry or not entry.value.headline then
            logger.notify('Drill-down aborted: No entry or headline found', vim.log.levels.WARN)
            return
          end
          logger.notify('Drill-down triggered on headline: ' .. vim.inspect(entry.value.headline), vim.log.levels.DEBUG)
          if not opts.parent_stack then
            opts.parent_stack = {}
          end
          if opts.parent_headline then
            table.insert(opts.parent_stack, { headline = opts.parent_headline, filename = opts.parent_headline_file })
          end
          opts.parent_headline = entry.value.headline
          opts.parent_headline_file = entry.value.filename
          local new_finder = finders.from_options(opts)
          local picker = action_state.get_current_picker(prompt_bufnr)
          picker:refresh(new_finder, opts)
          vim.schedule(function()
            picker:set_selection(1)
            logger.notify('Selection reset to first entry after drill-down', vim.log.levels.DEBUG)
          end)
        end

        local function drill_up()
          if opts.parent_stack and #opts.parent_stack > 0 then
            local parent = table.remove(opts.parent_stack)
            opts.parent_headline = parent.headline
            opts.parent_headline_file = parent.filename
            logger.notify(
              'Drill-up: returned to parent headline: ' .. vim.inspect(parent.headline),
              vim.log.levels.DEBUG
            )
          else
            opts.parent_headline = nil
            opts.parent_headline_file = nil
            logger.notify('Drill-up: cleared drilldown, returned to top-level', vim.log.levels.DEBUG)
          end
          local new_finder = finders.from_options(opts)
          local picker = action_state.get_current_picker(prompt_bufnr)
          picker:refresh(new_finder, opts)
          vim.schedule(function()
            picker:set_selection(1)
            logger.notify('Selection reset to first entry after drill-up', vim.log.levels.DEBUG)
          end)
        end

        map('i', '<C-y>', drill_down)
        map('i', '<C-h>', drill_up)
        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
