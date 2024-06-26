local finders = require('telescope-orgmode.finders')
local org = require('telescope-orgmode.org')

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')

local M = {}

function M.toggle_headlines_orgfiles(opts)
  return function(prompt_bufnr)
    local status = state.get_status(prompt_bufnr)

    -- _ot_ is used as our plugin-specific namespace in the action status
    -- (ot - orgmode telescope)
    --
    -- FIXME: the state get's sometimes nil when the initalization has already been run
    -- In this case, a toggle is "dropped" (keypress does not change the state).
    -- Can we avoid that by initializing the state in the higher order function?
    -- Idea: We can try to do it as before, but pass the prompt_bufnr with the opts.
    if status._ot_state == nil then
      -- uninitialized state - initialize with orgfiles
      -- Because when this function is called the first time, it is triggered
      -- by the users and we search over headlines by default, we set the state
      -- for the first toggle already here.
      status._ot_state = { current = opts.states[2], next = opts.states[1] }
    else
      status._ot_state.current, status._ot_state.next = status._ot_state.next, status._ot_state.current
    end

    if status._ot_state.current == 'headlines' then
      M._find_headlines(opts, prompt_bufnr)
    elseif status._ot_state.current == 'orgfiles' then
      M._find_orgfiles(opts, prompt_bufnr)
    else
      -- this should not happen
      error(string.format('Invalid state %s', status._ot_state.current))
    end
  end
end

function M.search_headlines(opts)
  return function(prompt_bufnr)
    M._find_headlines(opts, prompt_bufnr)
  end
end

function M.search_orgfiles(opts)
  return function(prompt_bufnr)
    M._find_orgfiles(opts, prompt_bufnr)
  end
end

function M.refile(closest_headline)
  return function(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    -- Refile to the file by default
    local destination = entry.value.file

    -- Refile to a specific heading if is set
    if entry.value.headline then
      destination = entry.value.headline
    end

    return org.refile({
      source = closest_headline,
      destination = destination,
    })
  end
end

function M.insert(_)
  return function(prompt_bufnr)
    actions.close(prompt_bufnr)

    ---@type MatchEntry
    local entry = action_state.get_selected_entry()

    -- Link to the filename by default
    local destination = entry.value.file.filename

    -- Link to a specific heading if is set
    if entry.value.headline then
      destination = 'file:' .. entry.value.file.filename .. '::*' .. entry.value.headline.title
    end

    org.insert_link(destination)
    return true
  end
end

function M._find_headlines(opts, prompt_bufnr)
  local headlines = finders.headlines(opts)
  M._update_picker(headlines, opts.prompt_titles.headlines, prompt_bufnr)
end

function M._find_orgfiles(opts, prompt_bufnr)
  local orgfiles = finders.orgfiles(opts)
  M._update_picker(orgfiles, opts.prompt_titles.orgfiles, prompt_bufnr)
end

function M._update_picker(results, title, prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)

  current_picker.layout.prompt.border:change_title(title)
  current_picker:refresh(results)
end

return M
