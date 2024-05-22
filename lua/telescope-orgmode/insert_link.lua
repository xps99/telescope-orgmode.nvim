local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

---@type OrgApi
local OrgApi = require('orgmode.api')

local utils = require('telescope-orgmode.utils')

---@class MatchEntry
---@field value OrgEntry
---@field ordinal string
---@field filename string
---@field lnum number
---@field display function
---@field location string,
---@field line string,

local function insert(prompt_bufnr)
  actions.close(prompt_bufnr)

  ---@type MatchEntry
  local entry = action_state.get_selected_entry()

  -- Link to the filename by default
  local destination = entry.value.file.filename

  -- Link to a specific heading if is set
  if entry.value.headline then
    destination = 'file:' .. entry.value.file.filename .. '::*' .. entry.value.headline.title
  end

  --print(vim.inspect(destination))
  OrgApi.insert_link(destination)
  return true
end

return function(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = 'Link Target',
      finder = finders.new_table({
        results = utils.get_entries(opts),
        entry_maker = opts.entry_maker or utils.make_entry(opts),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        action_set.select:replace(insert)
        map('i', '<c-space>', utils.gen_depth_toggle(opts, prompt_bufnr))
        return true
      end,
    })
    :find()
end
