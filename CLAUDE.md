# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup Commands

- **Install dependencies**: `ruby install.rb` - Sets up symlinks for dotfiles and installs Homebrew dependencies
- **Update Homebrew packages**: `brew bundle` (alias: `bb`) - Updates packages from Brewfile

## Repository Structure

This is a personal macOS configuration repository containing dotfiles and development environment setup scripts. The main components are:

### Core Setup
- `install.rb` - Ruby script that creates symlinks for dotfiles and handles initial setup
- `Brewfile` - Homebrew bundle file defining all packages, tools, and casks to install

### Configuration Files
- **Shell**: `zshrc`, `zprofile` - Zsh configuration with aliases and custom functions
- **Git**: `gitconfig`, `gitignore_global` - Git configuration and global ignore rules
- **Applications**: `config/` directory contains app-specific configurations:
  - `nvim/` - Neovim with LazyVim configuration
  - `kitty/` - Kitty terminal configuration
  - `atuin/` - Shell history configuration
  - `ghostty/` - Terminal configuration
  - `starship.toml` - Shell prompt configuration

### Test Helpers
The `zsh/test-helpers.zsh` file provides comprehensive Rails/RSpec testing functions:
- `t` - Run all tests with profile support from `.t` config file
- `tg` - Run tests on git-modified files only
- `tf` - Run tests showing only failures
- `tff` - Run tests with fail-fast and seed persistence
- Profile system: Use `--profile <name>` to apply predefined test configurations

### Key Aliases and Functions
- `bb` - `brew bundle`
- `dots` - Open this config repository in Cursor
- `c` - Open Cursor editor
- `g` - Git shorthand
- `s` - Git status short format
- `rc` - Bundle exec rails console
- `bd` - `bin/dev`
- `be` - Bundle exec
- Heroku helpers: `hs`, `hp`, `hd` for staging, production, demo environments

## Development Environment

This setup assumes:
- macOS with Homebrew
- Ruby for the install script
- Zsh as the shell
- Development tools: Neovim, Git, various CLI utilities
- Terminal applications: Kitty, Ghostty
- Code editors: Cursor, VS Code

The configuration is designed for Rails development with comprehensive testing workflows and shell productivity enhancements.