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

vim.api.nvim_create_user_command("CybuLastusedPrev", function()
  require("cybu").cycle("prev", "last_used")
end, { nargs = 0 })

vim.api.nvim_create_user_command("CybuLastusedNext", function()
  require("cybu").cycle("next", "last_used")
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
  "<plug>(CybuLastusedPrev)",
  ":lua require('cybu').cycle('prev', 'last_used')<cr>",
  { silent = true, noremap = true }
)
vim.keymap.set(
  "n",
  "<plug>(CybuLastusedNext)",
  ":lua require('cybu').cycle('next', 'last_used')<cr>",
  { silent = true, noremap = true }
)

-- set default highlight groups
vim.api.nvim_set_hl(0, "CybuFocus", {
  fg = vim.api.nvim_get_hl_by_name("Normal", true).foreground,
  bg = vim.api.nvim_get_hl_by_name("Visual", true).background,
})
vim.api.nvim_set_hl(0, "CybuAdjacent", { link = "Comment" })
vim.api.nvim_set_hl(0, "CybuBackground", { link = "Normal" })
vim.api.nvim_set_hl(0, "CybuInfobar", { link = "StatusLine" })
