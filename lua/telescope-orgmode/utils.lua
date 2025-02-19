local entry_display = require('telescope.pickers.entry_display')
local orgmode = require('orgmode.api')

local utils = {}

-- Modified get_entries function with additional debug messages.
utils.get_entries = function(opts)
  vim.notify('utils.get_entries called with opts: ' .. vim.inspect(opts or {}), vim.log.levels.DEBUG)

  local file_results = {}
  if opts.current_file then
    local current_filename = vim.api.nvim_buf_get_name(0)
    local abs_path = vim.fn.fnamemodify(current_filename, ':p')
    file_results[1] = { file = orgmode.load(abs_path), filename = abs_path }
    vim.notify('Loading current file: ' .. abs_path, vim.log.levels.DEBUG)
  else
    file_results = vim.tbl_map(function(file)
      return { file = file, filename = file.filename }
    end, orgmode.load())
    vim.notify('Loaded ' .. tostring(#file_results) .. ' files', vim.log.levels.DEBUG)

    if not opts.archived then
      file_results = vim.tbl_filter(function(entry)
        return not entry.file.is_archive_file
      end, file_results)
      vim.notify('Filtered archived files, remaining count: ' .. tostring(#file_results), vim.log.levels.DEBUG)
    end
  end

  local results = {}
  if opts.parent_headline then
    vim.notify(
      'Applying drill-down filter with parent_headline: ' .. vim.inspect(opts.parent_headline),
      vim.log.levels.DEBUG
    )
    local parent_level = opts.parent_headline.level
    local max_allowed_level = parent_level + (opts.max_depth or math.huge)
    for _, file_entry in ipairs(file_results) do
      vim.notify('Searching headlines in file: ' .. file_entry.filename, vim.log.levels.DEBUG)
      for _, headline in ipairs(file_entry.file.headlines) do
        if headline.level > parent_level and headline.level <= max_allowed_level then
          local entry = {
            file = file_entry.file,
            filename = file_entry.filename,
            headline = headline,
          }
          table.insert(results, entry)
          vim.notify(
            'Adding headline: ' .. headline.title .. ' (level: ' .. headline.level .. ')',
            vim.log.levels.DEBUG
          )
        end
      end
    end
  else
    vim.notify(
      'No parent_headline provided; returning all headlines up to max_depth: ' .. vim.inspect(opts.max_depth),
      vim.log.levels.DEBUG
    )
    for _, file_entry in ipairs(file_results) do
      for _, headline in ipairs(file_entry.file.headlines) do
        local allowed_depth = opts.max_depth == nil or headline.level <= opts.max_depth
        local allowed_archive = opts.archived or not headline.is_archived
        if allowed_depth and allowed_archive then
          local entry = {
            file = file_entry.file,
            filename = file_entry.filename,
            headline = headline,
          }
          table.insert(results, entry)
        end
      end
    end
  end

  vim.notify('Final results count in get_entries: ' .. tostring(#results), vim.log.levels.DEBUG)
  return results
end

utils.make_entry = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = vim.F.if_nil(opts.location_width, 20) },
      { remaining = true },
    },
  })

  local function make_display(entry)
    return displayer({ entry.location, entry.line })
  end

  return function(entry)
    local headline = entry.headline
    local lnum = nil
    local location = vim.fn.fnamemodify(entry.filename, ':t')
    local line = ''
    if headline then
      lnum = headline.position.start_line
      location = string.format('%s:%i', location, lnum)
      line = string.format('%s %s', string.rep('*', headline.level), headline.title)
    end

    return {
      value = entry,
      ordinal = location .. ' ' .. line,
      filename = entry.filename,
      lnum = lnum,
      display = make_display,
      location = location,
      line = line,
    }
  end
end

return utils
