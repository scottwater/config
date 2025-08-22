#!/usr/bin/env zsh

# =============================================================================
# RUBY HELPER FUNCTIONS
# =============================================================================
# A collection of functions to make Ruby development more efficient.

# Gets all git-modified files (changed, staged, or untracked) matching a pattern
# Args: $1 - regex pattern to match against filenames
# Returns: newline-separated list of matching files
_get_git_modified_ruby_files() {
  local pattern="$1"

  # Get all changed, staged, and untracked files
  local changed_files=$(git diff --name-only 2>/dev/null)
  local staged_files=$(git diff --cached --name-only 2>/dev/null)
  local untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)

  # Combine all files, remove duplicates, and filter by pattern
  echo "$changed_files\n$staged_files\n$untracked_files" | sort -u | grep -v '^$' | grep "$pattern"
}

# Run rubocop on git-modified .rb files (specs and non-specs)
# Uses the same flags as the 'popo' alias: -f github, plus -A for auto-correct
# Usage: rg [additional options]
# Examples:
#   rg                          # Run rubocop on all modified .rb files with auto-correct
#   rg --display-only-failed   # Run with additional options
function rg() {
  local ruby_files=$(_get_git_modified_ruby_files "\.rb$")

  if [ -n "$ruby_files" ]; then
    echo "Running rubocop with auto-correct on modified .rb files:"
    echo "$ruby_files" | sed 's/^/  /'
    echo ""
    bin/rubocop -f github -A $(echo "$ruby_files" | tr '\n' ' ') "$@"
  else
    echo "No modified .rb files found."
  fi
}

# Run rubocop on specified files, filtering for .rb files only
# Designed for use with Claude PostToolUse Hook
# Args: list of files (can be space-separated or provided as separate arguments)
# Usage: rgh file1.rb file2.js file3.rb [additional options]
# Examples:
#   rgh app/models/user.rb config/routes.rb  # Run rubocop on these .rb files
#   rgh $(echo "file1.rb file2.js file3.rb") # Run rubocop on .rb files from list
function rgh() {
  local all_files=("$@")
  local ruby_files=()
  local additional_opts=()
  local processing_files=true
  
  # Separate files from additional rubocop options
  for arg in "${all_files[@]}"; do
    if [[ "$processing_files" == true && "$arg" == *.rb && -f "$arg" ]]; then
      ruby_files+=("$arg")
    elif [[ "$arg" == -* ]]; then
      # Found an option flag, everything from here on is additional options
      processing_files=false
      additional_opts+=("$arg")
    elif [[ "$processing_files" == false ]]; then
      additional_opts+=("$arg")
    fi
  done
  
  if [[ ${#ruby_files[@]} -gt 0 ]]; then
    echo "Running rubocop with auto-correct on specified .rb files:"
    printf "  %s\n" "${ruby_files[@]}"
    echo ""
    bin/rubocop -f github -A "${ruby_files[@]}" "${additional_opts[@]}"
  else
    echo "No .rb files found in the provided list."
  fi
}