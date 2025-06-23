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
alias bd="bin/dev"
alias be="bundle exec"
alias br="bin/rails"
alias g="git"
alias s="g status -s"
alias vs="code"
alias ws="windsurf"
alias c="cursor"
alias popo="bin/rubocop -f github"
alias prime="bin/rails dev:prime"
alias dots="cursor ~/projects/config"
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

# https://github.com/kevinSuttle/dotfiles/blob/9458141f40094d96952adc7c423cbdddeb909a81/functions
searchAndDestroy() {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
  echo "Port" $1 "found and killed."
}


function t() {
  if [ -d "spec" ]; then
    bundle exec rspec "$@"
  elif [ -d "test" ]; then
    bin/rails test "$@"
  else
    echo "No spec or test directory found."
  fi
}

function tg() {
  # Get all changed, staged, and untracked files
  local changed_files=$(git diff --name-only 2>/dev/null)
  local staged_files=$(git diff --cached --name-only 2>/dev/null)
  local untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)

  # Combine all files and remove duplicates
  local all_files=$(echo "$changed_files\n$staged_files\n$untracked_files" | sort -u | grep -v '^$')

  if [ -d "spec" ]; then
    # Filter for RSpec files
    local spec_files=$(echo "$all_files" | grep '_spec\.rb$')

    if [ -n "$spec_files" ]; then
      echo "Running RSpec on modified files:"
      echo "$spec_files" | sed 's/^/  /'
      echo ""
      bundle exec rspec $(echo "$spec_files" | tr '\n' ' ') "$@"
    else
      echo "No modified _spec.rb files found."
    fi
  elif [ -d "test" ]; then
    # Filter for test files
    local test_files=$(echo "$all_files" | grep '_test\.rb$')

    if [ -n "$test_files" ]; then
      echo "Running tests on modified files:"
      echo "$test_files" | sed 's/^/  /'
      echo ""
      bin/rails test $(echo "$test_files" | tr '\n' ' ') "$@"
    else
      echo "No modified _test.rb files found."
    fi
  else
    echo "No spec or test directory found."
  fi
}

function tgff() {
  local args=("$@")
  local seed_param=""
  local has_seed=false
  local i=1

  # Check if --seed parameter exists in arguments
  while [[ $i -le ${#args[@]} ]]; do
    if [[ ${args[$i]} == --seed=* ]]; then
      has_seed=true
      export SEED="${args[$i]#*=}"
      break
    elif [[ ${args[$i]} == "--seed" && -n ${args[$i+1]} ]]; then
      has_seed=true
      export SEED="${args[$i+1]}"
      break
    fi
    ((i++))
  done

  # If no seed parameter and no SEED env var, create one
  if [[ $has_seed == false && -z $SEED ]]; then
    export SEED=$RANDOM
  fi

  # Add seed to arguments if not already present
  if [[ $has_seed == false ]]; then
    args+=("--seed=$SEED")
  fi

  # Call the tg function with fail-fast and all arguments
  tg --fail-fast "${args[@]}"
  local test_status=$?

  # Clear SEED if tests passed (exit status 0)
  if [[ $test_status -eq 0 ]]; then
    unset SEED
  fi

  return $test_status
}

alias tgf="tg --only-failures"

alias tf="t --only-failures"
function tff() {
  local args=("$@")
  local seed_param=""
  local has_seed=false
  local i=1

  # Check if --seed parameter exists in arguments
  while [[ $i -le ${#args[@]} ]]; do
    if [[ ${args[$i]} == --seed=* ]]; then
      has_seed=true
      export SEED="${args[$i]#*=}"
      break
    elif [[ ${args[$i]} == "--seed" && -n ${args[$i+1]} ]]; then
      has_seed=true
      export SEED="${args[$i+1]}"
      break
    fi
    ((i++))
  done

  # If no seed parameter and no SEED env var, create one
  if [[ $has_seed == false && -z $SEED ]]; then
    export SEED=$RANDOM
  fi

  # Add seed to arguments if not already present
  if [[ $has_seed == false ]]; then
    args+=("--seed=$SEED")
  fi

  # Call the test function with fail-fast and all arguments
  t --fail-fast "${args[@]}"
  local test_status=$?

  # Clear SEED if tests passed (exit status 0)
  if [[ $test_status -eq 0 ]]; then
    unset SEED
  fi

  return $test_status
}

alias aic="tg && popo"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Added by Windsurf
export PATH="/Users/Scott.Watermasysk/.codeium/windsurf/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"