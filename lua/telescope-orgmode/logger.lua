local config = require('telescope-orgmode.config').options

local logger = {}

--- Plugin-specific notify. Only shows messages if the specified level is at or above the configured log_level.
--- @param msg string The message to display.
--- @param level number The log level (e.g. vim.log.levels.DEBUG, INFO, WARN, ERROR).
function logger.notify(msg, level)
  level = level or vim.log.levels.INFO
  if level >= config.log_level then
    vim.notify(msg, level)
  end
end

return logger
