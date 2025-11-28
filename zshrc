eval "$(atuin init zsh)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

source $HOME/zsh/zsh-z.plugin.zsh
autoload -U compinit; compinit
zstyle ':completion:*' menu select

export EDITOR=nvim
set -o emacs



# Aliases
alias bb="brew bundle"
alias la="ls -A -l -G"
alias pl="cd ~/play"
alias wo="cd ~/work"
alias p="cd ~/projects"
alias src="cd ~/src"
alias rake='noglob rake'
alias bundle='nocorrect bundle'
alias rspec='nocorrect rspec'
alias reload="source ~/.zshrc"
alias tpd="tail -f ~/Library/Logs/puma-dev.log"
alias rc="bundle exec rails console"
alias bd="bin/dev"
alias be="bundle exec"
alias br="bin/rails"
alias g="git"
alias lg="lazygit"
alias s="g status -s"


alias popo="bin/rubocop -f github"
alias prime="bin/rails dev:prime"
alias dots="zed ~/projects/config"
alias yc="claude --dangerously-skip-permissions"
function hs(){
  heroku  "$@" --remote staging
}

function hp(){
  heroku  "$@" --remote production
}

function hd(){
  heroku "$@" --remote demo
}

function kill_console(){
  ps -ef | grep 'heroku run' | grep -v grep | awk '{print $2}' | xargs kill -9
}

function find_routes() {
  bin/rails routes -g "$1"
}

alias hp="nocorrect hp"
alias hs="nocorrect hs"
alias mwt='eval "$(bin/wt --select)"'
alias zw='bin/wt --select --open zed'
alias tg='t -g'
alias tf='t -f'
alias tff='t --ff'
# https://github.com/kevinSuttle/dotfiles/blob/9458141f40094d96952adc7c423cbdddeb909a81/functions
searchAndDestroy() {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
  echo "Port" $1 "found and killed."
}

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Added by CodeRabbit CLI installer
export PATH="$HOME/.local/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"

# Add repo's bin folder to PATH (resolves symlink to find actual location)
export PATH="${0:A:h}/bin:$PATH"
