.DEFAULT_GOAL := test

NVIM_HEADLESS:=nvim --headless --noplugin -u tests/min_init.lua
CYBU_TEST_DIR:=cybu-nvim-test
export CYBU_TEST_DIR

.PHONY: clean
clean: 
	rm -rf /tmp/$(CYBU_TEST_DIR)

.PHONY: test
test:
	$(NVIM_HEADLESS) -c "lua run_tests()"

.PHONY: clean_test
clean_test: clean test
