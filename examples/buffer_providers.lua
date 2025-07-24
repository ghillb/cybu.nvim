-- Buffer provider functions for cybu.nvim experimental integration

local function grapple_buffer_provider()
  local ok, grapple = pcall(require, "grapple")
  if not ok then
    return {}
  end

  local items = {}

  local setup_ok = pcall(grapple.setup)
  if not setup_ok then
    return items
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 then
      local success, is_tagged = pcall(grapple.exists, { buffer = bufnr })
      if success and is_tagged then
        table.insert(items, {
          bufnr = bufnr,
          filename = vim.api.nvim_buf_get_name(bufnr),
        })
      end
    end
  end

  return items
end

local function harpoon_buffer_provider()
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then
    return {}
  end

  local items = {}

  local setup_ok = pcall(harpoon.setup, {})
  if not setup_ok then
    return items
  end

  local list_ok, list = pcall(harpoon.list, harpoon)
  if list_ok and list and list.items then
    for _, item in ipairs(list.items) do
      local file_path = item.value
      if file_path and file_path ~= "" then
        local bufnr = vim.fn.bufnr(file_path)
        if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
          table.insert(items, {
            bufnr = bufnr,
            filename = file_path,
          })
        end
      end
    end
  end

  return items
end

return {
  grapple = grapple_buffer_provider,
  harpoon = harpoon_buffer_provider,
}
