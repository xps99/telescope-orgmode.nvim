local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')

local utils = require('telescope-orgmode.utils')

local api = require('orgmode.api')

-- MYHACK
local jump_to_destination = function(entry)
  local filename, row, col
  if entry.path or entry.filename then
    filename = entry.path or entry.filename

    -- TODO: Check for off-by-one
    row = entry.row or entry.lnum
    col = entry.col
  elseif not entry.bufnr then
    -- TODO: Might want to remove this and force people
    -- to put stuff into `filename`
    local value = entry.value
    if not value then
      utils.notify('actions.set.edit', {
        msg = 'Could not do anything with blank line...',
        level = 'WARN',
      })
      return
    end

    if type(value) == 'table' then
      value = entry.display
    end

    local sections = vim.split(value, ':')

    filename = sections[1]
    row = tonumber(sections[2])
    col = tonumber(sections[3])
  end

  -- local destination = entry.value.file
  -- local filename = destination.file.filename
  pcall(vim.cmd, string.format('%s %s', 'edit', vim.fn.fnameescape(filename)))

  -- HACK: fixes folding: https://github.com/nvim-telescope/telescope.nvim/issues/699
  if vim.wo.foldmethod == 'expr' then
    vim.schedule(function()
      vim.opt.foldmethod = 'expr'
    end)
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  if col == nil then
    if row == pos[1] then
      col = pos[2] + 1
    elseif row == nil then
      row, col = pos[1], pos[2] + 1
    else
      col = 1
    end
  end

  if row and col then
    local ok, err_msg = pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
    if not ok then
      log.debug('Failed to move to cursor:', err_msg, row, col)
    end
  end
end

return function(opts)
  opts = opts or {}

  local closest_headline = api.current():get_closest_headline()

  local function refile(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    -- Refile to the file by default
    local destination = entry.value.file

    -- Refile to a specific heading if is set
    if entry.value.headline then
      destination = entry.value.headline
    end

    --- MYHACK
    local ok = api.refile({
      source = closest_headline,
      destination = destination,
    })

    jump_to_destination(entry)
    return ok
  end

  local function gen_depth_toggle(opts, prompt_bufnr)
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
        action_set.select:replace(refile)
        map('i', '<c-space>', gen_depth_toggle(opts, prompt_bufnr))
        return true
      end,
    })
    :find()
end
