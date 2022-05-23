vim.cmd("packadd packer.nvim")

local function pjoin(...)
  return table.concat({ ... }, "/")
end

local temp_dir = vim.loop.os_getenv("TEMP") or "/tmp"
local package_root = pjoin(temp_dir, vim.env.CYBU_TEST_DIR, "site", "pack")
local install_path = pjoin(package_root, "packer", "start", "packer.nvim")
local compile_path = pjoin(install_path, "plugin", "packer_compiled.lua")

local function load_plugins()
  require("packer").startup({
    {
      "wbthomason/packer.nvim",
      "nvim-lua/plenary.nvim",
      "ghillb/cybu.nvim",
      "kyazdani42/nvim-web-devicons",
    },
    config = {
      package_root = package_root,
      compile_path = compile_path,
    },
  })
  require("packer").sync()
end

local function load_config()
  require("cybu").setup()
end

function _G.run_tests()
  require("plenary.test_harness").test_directory("./tests", {
    minimal_init = vim.fn.getcwd() .. "/tests/min_init.lua",
  })
end

load_plugins()
load_config()
