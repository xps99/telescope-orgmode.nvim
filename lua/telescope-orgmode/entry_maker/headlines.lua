local org = require('telescope-orgmode.org')
local entry_display = require('telescope.pickers.entry_display')
local logger = require('telescope-orgmode.logger')

-- Updated index_headlines method that uses debug messages and robust parent matching.
local function index_headlines(file_results, opts)
  local results = {}
  if opts.parent_headline then
    local parent = opts.parent_headline
    local parent_level = parent.level
    local parent_filename = opts.parent_headline_file or ''
    logger.notify(
      'index_headlines: Drill-down active. Parent: '
        .. parent.title
        .. ' (level '
        .. parent_level
        .. '), file: '
        .. parent_filename,
      vim.log.levels.DEBUG
    )

    for _, file_entry in ipairs(file_results) do
      if file_entry.filename == parent_filename then
        local headlines = file_entry.file.headlines
        local found_parent = false
        for i, headline in ipairs(headlines) do
          if not found_parent then
            -- Use start_line and title to find the parent entry.
            if
              headline.position
              and parent.position
              and headline.position.start_line == parent.position.start_line
              and headline.title == parent.title
            then
              found_parent = true
              logger.notify('index_headlines: Found parent headline at index ' .. i, vim.log.levels.DEBUG)
            end
          else
            -- Once the parent is found, add subsequent headlines until a headline
            -- with level less than or equal to the parent's level is encountered.
            if headline.level <= parent_level then
              logger.notify(
                "index_headlines: Stopped at headline '" .. headline.title .. "' (level " .. headline.level .. ')',
                vim.log.levels.DEBUG
              )
              break
            end
            if opts.max_depth then
              if headline.level <= parent_level + opts.max_depth then
                table.insert(results, { file = file_entry.file, filename = file_entry.filename, headline = headline })
                logger.notify(
                  "index_headlines: Adding headline '" .. headline.title .. "' (level " .. headline.level .. ')',
                  vim.log.levels.DEBUG
                )
              else
                logger.notify(
                  "index_headlines: Skipping headline '"
                    .. headline.title
                    .. "' (level "
                    .. headline.level
                    .. ') > allowed max level ('
                    .. parent_level + opts.max_depth
                    .. ')',
                  vim.log.levels.DEBUG
                )
              end
            else
              table.insert(results, { file = file_entry.file, filename = file_entry.filename, headline = headline })
              logger.notify(
                "index_headlines: Adding headline '" .. headline.title .. "' (level " .. headline.level .. ')',
                vim.log.levels.DEBUG
              )
            end
          end
        end

        if not found_parent then
          logger.notify('index_headlines: Parent headline not found in file ' .. parent_filename, vim.log.levels.WARN)
        end
      end
    end

    if #results == 0 then
      logger.notify(
        "index_headlines: No child headlines found under parent '" .. parent.title .. "'",
        vim.log.levels.DEBUG
      )
    end
  else
    logger.notify(
      'index_headlines: No parent_headline provided; indexing all headlines up to max_depth: '
        .. tostring(opts.max_depth),
      vim.log.levels.DEBUG
    )
    for _, file_entry in ipairs(file_results) do
      for _, headline in ipairs(file_entry.file.headlines) do
        local allowed_depth = opts.max_depth == nil or headline.level <= opts.max_depth
        local allowed_archive = opts.archived or not headline.is_archived
        if allowed_depth and allowed_archive then
          table.insert(results, { file = file_entry.file, filename = file_entry.filename, headline = headline })
        end
      end
    end
  end
  logger.notify('index_headlines: Final results count: ' .. tostring(#results), vim.log.levels.DEBUG)
  return results
end

local M = {}

M.get_entries = function(opts)
  local file_results = org.load_files(opts)
  logger.notify('headlines.get_entries: Loaded ' .. tostring(#file_results) .. ' file(s)', vim.log.levels.DEBUG)
  return index_headlines(file_results, opts)
end

M.make_entry = function(opts)
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

return M
