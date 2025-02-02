eval "$(atuin init zsh)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

source $HOME/zsh/zsh-z.plugin.zsh
autoload -U compinit; compinit
zstyle ':completion:*' menu select

export EDITOR=nvim




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
alias rs="bin/dev"
alias be="bundle exec"
alias g="git"
alias s="g status -s"
alias vs="code"
alias c="cursor"
alias dots="cursor ~/projects/config"
function hs(){
  heroku  "$@" --remote staging
}

function hp(){
  heroku  "$@" --remote production
}

function kill_console(){
  ps -ef | grep 'heroku run' | grep -v grep | awk '{print $2}' | xargs kill -9
}

alias hp="nocorrect hp"
alias hs="nocorrect hs"

# https://github.com/kevinSuttle/dotfiles/blob/9458141f40094d96952adc7c423cbdddeb909a81/functions
searchAndDestroy() {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
  echo "Port" $1 "found and killed."
}

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Added by Windsurf
export PATH="/Users/Scott.Watermasysk/.codeium/windsurf/bin:$PATH"
