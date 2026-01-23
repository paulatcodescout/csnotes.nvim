.PHONY: test format lint clean

# Run tests using plenary
test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Format Lua files using stylua (if installed)
format:
	@if command -v stylua >/dev/null 2>&1; then \
		stylua lua/ plugin/ tests/; \
	else \
		echo "stylua not found. Install it with: cargo install stylua"; \
	fi

# Lint Lua files using luacheck (if installed)
lint:
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck lua/ plugin/; \
	else \
		echo "luacheck not found. Install it with: luarocks install luacheck"; \
	fi

# Clean temporary files
clean:
	find . -type f -name "*.swp" -delete
	find . -type f -name "*.swo" -delete
	find . -type f -name "*~" -delete

# Install development dependencies
dev-deps:
	@echo "Installing development dependencies..."
	@if ! command -v luacheck >/dev/null 2>&1; then \
		echo "Installing luacheck..."; \
		luarocks install luacheck; \
	fi
	@if ! command -v stylua >/dev/null 2>&1; then \
		echo "Installing stylua..."; \
		echo "Run: cargo install stylua"; \
	fi

# Help command
help:
	@echo "Available targets:"
	@echo "  test      - Run tests with plenary"
	@echo "  format    - Format Lua files with stylua"
	@echo "  lint      - Lint Lua files with luacheck"
	@echo "  clean     - Remove temporary files"
	@echo "  dev-deps  - Install development dependencies"
	@echo "  help      - Show this help message"
