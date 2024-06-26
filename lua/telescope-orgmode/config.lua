local M = {}

M.opts = {
  max_depth = nil,
}

function M.setup(ext_opts)
  M.opts = vim.tbl_extend('force', M.opts, ext_opts or {})
end

function M.init_opts(opts, prompt_titles)
  opts = vim.tbl_extend('force', M.opts, opts or {})
  opts.prompt_titles = prompt_titles
  opts.states = {}
  for state, _ in pairs(prompt_titles) do
    table.insert(opts.states, state)
  end
  return opts
end

return M
