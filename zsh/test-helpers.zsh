#!/usr/bin/env zsh

# =============================================================================
# TEST HELPER FUNCTIONS
# =============================================================================
# A collection of functions to make testing more efficient in Rails/RSpec projects.
# All functions automatically detect whether you're using RSpec or Rails test framework.

# -----------------------------------------------------------------------------
# PRIVATE HELPER FUNCTIONS
# -----------------------------------------------------------------------------

# Detects which test framework is being used in the current project
# Returns: "rspec", "rails", or "none"
_detect_test_framework() {
  if [ -d "spec" ]; then
    echo "rspec"
  elif [ -d "test" ]; then
    echo "rails"
  else
    echo "none"
  fi
}

# Gets all git-modified files (changed, staged, or untracked) matching a pattern
# Args: $1 - regex pattern to match against filenames
# Returns: newline-separated list of matching files
_get_git_modified_files() {
  local pattern="$1"

  # Get all changed, staged, and untracked files
  local changed_files=$(git diff --name-only 2>/dev/null)
  local staged_files=$(git diff --cached --name-only 2>/dev/null)
  local untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)

  # Combine all files, remove duplicates, and filter by pattern
  echo "$changed_files\n$staged_files\n$untracked_files" | sort -u | grep -v '^$' | grep "$pattern"
}

# Handles seed logic for test functions that support fail-fast with seed persistence
# If no seed is provided, generates a random one and adds it to arguments
# If tests fail, the SEED environment variable persists for re-running
# Args: all arguments passed to the test function
# Returns: modified arguments array with seed included
_handle_test_seed() {
  local args=("$@")
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
    args+=("--seed=$SEED")
  fi

  echo "${args[@]}"
}

# Executes tests using the appropriate command for the detected framework
# Args: $1 - framework ("rspec" or "rails")
#       $2 - space/newline-separated list of test files (empty string for all tests)
#       $@ - additional arguments to pass to the test runner
_run_tests() {
  local framework="$1"
  shift
  local files="$1"
  shift
  local args=("$@")

  case $framework in
    "rspec")
      if [ -n "$files" ]; then
        bundle exec rspec $(echo "$files" | tr '\n' ' ') "${args[@]}"
      else
        bundle exec rspec "${args[@]}"
      fi
      ;;
    "rails")
      if [ -n "$files" ]; then
        bin/rails test $(echo "$files" | tr '\n' ' ') "${args[@]}"
      else
        bin/rails test "${args[@]}"
      fi
      ;;
    *)
      echo "No spec or test directory found."
      return 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# MAIN TEST FUNCTIONS
# -----------------------------------------------------------------------------

# Run all tests in the project
# Usage: t [options]
# Examples:
#   t                           # Run all tests
#   t --format documentation    # Run with specific RSpec format
#   t --verbose                 # Run Rails tests with verbose output
function t() {
  local framework=$(_detect_test_framework)
  _run_tests "$framework" "" "$@"
}

# Run tests only on git-modified files (changed, staged, or untracked)
# Automatically detects _spec.rb files for RSpec or _test.rb files for Rails tests
# Usage: tg [options]
# Examples:
#   tg                          # Run tests on all modified test files
#   tg --format progress        # Run modified tests with progress format
function tg() {
  local framework=$(_detect_test_framework)

  if [ "$framework" = "none" ]; then
    echo "No spec or test directory found."
    return 1
  fi

  local pattern
  if [ "$framework" = "rspec" ]; then
    pattern="_spec\.rb$"
  else
    pattern="_test\.rb$"
  fi

  local test_files=$(_get_git_modified_files "$pattern")

  if [ -n "$test_files" ]; then
    echo "Running tests on modified files:"
    echo "$test_files" | sed 's/^/  /'
    echo ""
    _run_tests "$framework" "$test_files" "$@"
  else
    echo "No modified test files found."
  fi
}

# Run all tests, but only show failures (skip passing tests in output)
# Usage: tf [options]
# Examples:
#   tf                          # Run all tests, only show failures
function tf() {
  t --only-failures "$@"
}

# Run git-modified tests, but only show failures
# Usage: tgf [options]
# Examples:
#   tgf                         # Run modified tests, only show failures
function tgf() {
  tg --only-failures "$@"
}

# Run all tests with fail-fast and automatic seed management
# Generates a random seed if none provided. If tests fail, the seed persists
# in the SEED environment variable so you can re-run the same failing test.
# If tests pass, the seed is cleared.
# Usage: tff [options]
# Examples:
#   tff                         # Run with fail-fast and random seed
#   tff --seed=12345           # Run with specific seed
#   echo $SEED                 # Check persisted seed after failure
function tff() {
  local args=($(_handle_test_seed "$@"))
  t --fail-fast "${args[@]}"
  local test_status=$?

  # Clear SEED if tests passed
  if [[ $test_status -eq 0 ]]; then
    unset SEED
  fi

  return $test_status
}

# Run git-modified tests with fail-fast and automatic seed management
# Combines the benefits of tg (only modified files) with tff (seed persistence)
# Usage: tgff [options]
# Examples:
#   tgff                        # Run modified tests with fail-fast and random seed
#   tgff --seed=67890          # Run modified tests with specific seed
function tgff() {
  local args=($(_handle_test_seed "$@"))
  tg --fail-fast "${args[@]}"
  local test_status=$?

  # Clear SEED if tests passed
  if [[ $test_status -eq 0 ]]; then
    unset SEED
  fi

  return $test_status
}