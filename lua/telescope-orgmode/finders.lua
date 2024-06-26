local headlines = require('telescope-orgmode.entry_maker.headlines')
local orgfiles = require('telescope-orgmode.entry_maker.orgfiles')

local finders = require('telescope.finders')

local M = {}

function M.headlines(opts)
  return finders.new_table({
    results = headlines.get_entries(opts),
    entry_maker = opts.entry_maker or headlines.make_entry(opts),
  })
end

function M.orgfiles(opts)
  return finders.new_table({
    results = orgfiles.get_entries(opts),
    entry_maker = opts.entry_maker or orgfiles.make_entry(),
  })
end

return M
