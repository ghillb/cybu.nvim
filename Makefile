.DEFAULT_GOAL := tests

NVIM_HEADLESS:=nvim --headless --noplugin -u tests/min_init.lua
CYBU_TEST_DIR:=cybu-nvim-test
PACK_PATH:=~/.local/share/nvim/site/pack/packer/start
export CYBU_TEST_DIR

.PHONY: dependencies
dependencies:
	@echo "\033[0;33m>>> Installing dependencies...\033[0m"
	git clone --depth 1 https://github.com/wbthomason/packer.nvim \
		$(PACK_PATH)/packer.nvim
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
		$(PACK_PATH)/plenary.nvim
	git clone --depth 1 https://github.com/ghillb/cybu.nvim \
		$(PACK_PATH)/cybu.nvim
	git clone --depth 1 https://github.com/kyazdani42/nvim-web-devicons \
		$(PACK_PATH)/nvim-web-devicons

.PHONY: clean
clean:
	@echo "\033[0;33m>>> Cleaning...\033[0m"
	rm -rf /tmp/$(CYBU_TEST_DIR)
	rm $(PACK_PATH)/* -rf

.PHONY: tests
tests:
	@echo "\033[0;33m>>> Executing tests...\033[0m"
	$(NVIM_HEADLESS) -c "lua run_tests()"

.PHONY: ci_tests
ci_tests: dependencies tests

.PHONY: clean_tests
clean_tests: clean dependencies tests
