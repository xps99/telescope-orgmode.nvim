local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')

local utils = require('telescope-orgmode.utils')

local api = require('orgmode.api')

local M = {}

M.refile = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)

  -- Refile to the file by default
  local destination = entry.value.file

  -- Refile to a specific heading if is set
  if entry.value.headline then
    destination = entry.value.headline
  end

  return api.refile({
    source = M.closest_headline,
    destination = destination,
  })
end

M.gen_depth_toggle = function(opts, prompt_bufnr)
  local status = state.get_status(prompt_bufnr)
  status._ot_current_depth = opts.max_depth
  status._ot_next_depth = nil
  if status._ot_current_depth ~= 0 then
    status._ot_next_depth = 0
  end

  return function()
    local current_picker = action_state.get_current_picker(prompt_bufnr)

    local aux = status._ot_current_depth
    status._ot_current_depth = status._ot_next_depth
    status._ot_next_depth = aux

    opts.max_depth = status._ot_current_depth
    local new_finder = finders.new_table({
      results = utils.get_entries(opts),
      entry_maker = opts.entry_maker or utils.make_entry(opts),
    })

    current_picker:refresh(new_finder, opts)
  end
end

M.closest_headline = nil

return function(opts)
  opts = opts or {}

  M.closest_headline = api.current():get_closest_headline()

  pickers
    .new(opts, {
      -- TODO: alter prompt title when depth is 0: Refile under file, Refile
      -- under Headline
      prompt_title = 'Refile Destination',
      finder = finders.new_table({
        results = utils.get_entries(opts),
        entry_maker = opts.entry_maker or utils.make_entry(opts),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        action_set.select:replace(M.refile)
        map('i', '<c-space>', M.gen_depth_toggle(opts, prompt_bufnr))
        return true
      end,
    })
    :find()
end
