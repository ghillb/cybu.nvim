local version = "nvim-0.7.0"
if 1 ~= vim.fn.has(version) then
  vim.api.nvim_err_writeln(string.format("Cybu.nvim requires at least %s.", version))
  return
end
if vim.g.loaded_cybu then
  return
end

vim.g.loaded_cybu = true

vim.api.nvim_create_user_command("CybuPrev", function()
  require("cybu").cycle("prev")
end, { nargs = 0 })

vim.api.nvim_create_user_command("CybuNext", function()
  require("cybu").cycle("next")
end, { nargs = 0 })

vim.api.nvim_create_user_command("CybuHistoryPrev", function()
  require("cybu").cycle("prev", "history")
end, { nargs = 0 })

vim.api.nvim_create_user_command("CybuHistoryNext", function()
  require("cybu").cycle("next", "history")
end, { nargs = 0 })

vim.api.nvim_create_user_command("Cybu", function(args)
  require("cybu").cycle(args.fargs[1])
end, {
  nargs = 1,
  complete = function()
    return { "next", "prev" }
  end,
})

-- define <Plug> mappings
vim.keymap.set("n", "<plug>(CybuPrev)", ":lua require('cybu').cycle('prev')<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<plug>(CybuNext)", ":lua require('cybu').cycle('next')<cr>", { silent = true, noremap = true })
vim.keymap.set(
  "n",
  "<plug>(CybuHistoryPrev)",
  ":lua require('cybu').cycle('prev', 'history')<cr>",
  { silent = true, noremap = true }
)
vim.keymap.set(
  "n",
  "<plug>(CybuHistoryNext)",
  ":lua require('cybu').cycle('next', 'history')<cr>",
  { silent = true, noremap = true }
)
