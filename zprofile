eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/share/mise/shims:$PATH"

if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  eval "$(mise activate zsh --shims)"
elif; then
  eval "$(mise activate zsh)"
fi
