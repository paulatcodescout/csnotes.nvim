# Contributing to CSNotes.nvim

Thank you for your interest in contributing to CSNotes.nvim! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive in all interactions. We aim to maintain a welcoming and inclusive community.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/paulatcodescout/csnotes.nvim/issues)
2. If not, create a new issue with:
   - A clear, descriptive title
   - Steps to reproduce the bug
   - Expected behavior
   - Actual behavior
   - Neovim version (`nvim --version`)
   - Plugin configuration
   - Any error messages

### Suggesting Features

1. Check if the feature has already been suggested
2. Create a new issue with:
   - A clear description of the feature
   - Use cases and benefits
   - Possible implementation approach (optional)

### Pull Requests

1. Fork the repository
2. Create a new branch for your feature/fix:
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. Make your changes
4. Run tests and linting:
   ```bash
   make test
   make lint
   ```
5. Format your code:
   ```bash
   make format
   ```
6. Commit your changes with clear commit messages
7. Push to your fork
8. Create a pull request with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots (if applicable)

## Development Setup

### Prerequisites

- Neovim >= 0.8.0
- Git
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for tests)

### Optional Tools

- [luacheck](https://github.com/lunarmodules/luacheck) for linting
- [stylua](https://github.com/JohnnyMorganz/StyLua) for formatting

Install development dependencies:
```bash
make dev-deps
```

### Project Structure

```
csnotes.nvim/
├── lua/
│   ├── csnotes/
│   │   ├── init.lua          # Main module
│   │   ├── config.lua        # Configuration
│   │   ├── daily.lua         # Daily notes functionality
│   │   ├── list.lua          # Notes listing and search
│   │   ├── tags.lua          # Tagging system
│   │   ├── archive.lua       # Archiving functionality
│   │   └── utils.lua         # Utility functions
│   └── telescope/
│       └── _extensions/
│           └── csnotes.lua   # Telescope integration
├── plugin/
│   └── csnotes.lua           # Plugin entry point
├── doc/
│   └── csnotes.txt           # Vim help documentation
├── tests/
│   ├── minimal_init.lua      # Test initialization
│   ├── utils_spec.lua        # Utility tests
│   └── config_spec.lua       # Configuration tests
└── README.md
```

### Running Tests

Run all tests:
```bash
make test
```

Run specific test file:
```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/utils_spec.lua"
```

### Code Style

- Use 2 spaces for indentation
- Follow existing code style
- Add comments for complex logic
- Use type annotations where helpful
- Keep functions focused and small

Example:
```lua
--- Description of function
---@param arg1 string Description
---@param arg2 table|nil Optional parameter
---@return boolean success
---@return string|nil error
function M.my_function(arg1, arg2)
  -- Implementation
end
```

### Documentation

- Update README.md for user-facing changes
- Update doc/csnotes.txt for new commands/API
- Add comments to complex code
- Include examples in documentation

### Testing Guidelines

- Write tests for new features
- Ensure existing tests pass
- Test edge cases
- Use descriptive test names

Example:
```lua
describe("my_function", function()
  it("should handle normal input", function()
    assert.equals(expected, result)
  end)
  
  it("should handle edge case", function()
    assert.equals(expected, result)
  end)
end)
```

## Commit Message Guidelines

Use clear, descriptive commit messages:

- `feat: add new feature X`
- `fix: resolve issue with Y`
- `docs: update README with Z`
- `test: add tests for W`
- `refactor: improve code structure of V`
- `chore: update dependencies`

## Areas for Contribution

### High Priority

- [ ] Export functionality (PDF, HTML)
- [ ] Note linking and backlinks
- [ ] Additional tests
- [ ] Performance improvements

### Medium Priority

- [ ] Calendar integration
- [ ] Cloud sync support
- [ ] Reminder system
- [ ] Statistics and insights

### Low Priority

- [ ] Email/messaging integration
- [ ] Note encryption
- [ ] Templates per weekday

## Questions?

If you have questions about contributing:
1. Check existing issues and discussions
2. Create a new issue with the "question" label
3. Join discussions in pull requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
