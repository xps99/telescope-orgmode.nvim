local finders = require('telescope-orgmode.finders')
local org = require('telescope-orgmode.org')

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

function M.toggle_headlines_orgfiles(opts)
  return function(prompt_bufnr)
    opts.state.current, opts.state.next = opts.state.next, opts.state.current

    if opts.state.current == 'headlines' then
      M._find_headlines(opts, prompt_bufnr)
    elseif opts.state.current == 'orgfiles' then
      M._find_orgfiles(opts, prompt_bufnr)
    else
      -- this should not happen
      error(string.format('Invalid state %s', opts.state.current))
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

    destination = org.refile({ source = closest_headline, destination = destination })

    -- Warte auf die Promise-Auflösung mit :next()
    return destination:next(function(resolved_value)
      -- Dieser Block wird erst nach der Auflösung ausgeführt
      if entry.value.headline then
        local filename = entry.value.headline.file.filename
        local line = entry.value.headline.position.end_line
        vim.cmd('edit ' .. filename)
        vim.api.nvim_win_set_cursor(0, { line + 1, 0 })
      else
        local filename = entry.filename
        vim.cmd('edit ' .. filename)
      end
      vim.cmd('normal! zx')
      -- vim.cmd('normal! ]]')
      -- vim.cmd('normal! zx')

      -- Gib den Wert für weiteres Chaining zurück
      return resolved_value
    end)
  end
end

function M.insert(_)
  return function(prompt_bufnr)
    actions.close(prompt_bufnr)

    ---@type MatchEntry
    local entry = action_state.get_selected_entry()

    local destination = (function()
      if entry.value.headline then
        -- Link to a specific heading if is set
        return entry.value.headline:get_link()
      else
        return entry.value.file:get_link()
      end
    end)()

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

function M._update_picker(finder, title, prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)

  -- current_picker.layout.prompt.border:change_title(title)
  current_picker:refresh(finder)
end

return M
