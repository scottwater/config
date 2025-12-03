# AGENTS.md

Personal macOS dotfiles and development environment configuration repository.

## Commands

- **Install/Setup**: `ruby install.rb` - Creates symlinks for dotfiles and installs Homebrew deps
- **Update packages**: `brew bundle` (alias: `bb`) - Updates from Brewfile

## Structure

- `install.rb` - Ruby setup script that symlinks dotfiles to `~` and `~/.config`
- `Brewfile` - Homebrew packages, casks, and taps
- `zshrc`, `zprofile` - Zsh shell configuration with aliases
- `gitconfig`, `gitignore_global` - Git configuration
- `config/` - App configs (nvim, kitty, ghostty, atuin, starship, zed, lazygit, delta)
- `zsh/` - Zsh functions including `test-helpers.zsh` for Rails/RSpec workflows
- `bin/` - Custom executable scripts

## Code Style

- Ruby: Use `system!` helper for commands that must succeed; guard with existence checks
- Shell: Define aliases and functions in `zshrc`; source additional files from `zsh/`
- Symlinks: Use `link_if_needed` pattern - check existence before creating

