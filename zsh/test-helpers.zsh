#!/usr/bin/env zsh

# =============================================================================
# TEST HELPER FUNCTIONS
# =============================================================================
# A collection of functions to make testing more efficient in Rails/RSpec projects.
# All functions automatically detect whether you're using RSpec or Rails test framework.

# -----------------------------------------------------------------------------
# PRIVATE HELPER FUNCTIONS
# -----------------------------------------------------------------------------

# Global associative array to store test configuration profiles
declare -gA _TEST_CONFIG

# Parses .t configuration file and populates _TEST_CONFIG associative array
# File format: profile_name: arguments
# Example:
#   default: --tag ~type:system --tag ~speed:slow
#   slow: --tag type:system --tag speed:slow
#   doc: --format documentation
_parse_test_config() {
  # Clear any existing config
  _TEST_CONFIG=()

  # Check if .t file exists
  if [[ ! -f ".t" ]]; then
    return 0
  fi

    # Parse the .t file
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ '^[[:space:]]*#' ]] && continue

        # Split on first colon manually
    if [[ "$line" == *":"* ]]; then
      local profile="${line%%:*}"    # Everything before first colon
      local args="${line#*:}"        # Everything after first colon

      # Clean up profile name (remove leading/trailing spaces)
      profile="${profile#"${profile%%[![:space:]]*}"}"   # Remove leading spaces
      profile="${profile%"${profile##*[![:space:]]}"}"   # Remove trailing spaces

      # Clean up args (remove leading spaces only)
      args="${args#"${args%%[![:space:]]*}"}"   # Remove leading spaces only

      # Store in config array
      if [[ -n "$profile" ]]; then
        _TEST_CONFIG[$profile]="$args"
      fi
    fi
  done < ".t"
}

# Resolves test arguments by processing profile flags and merging with user args
# Args: all arguments passed to test function
# Returns: final arguments array with profile args included
_resolve_test_args() {
  local user_args=("$@")
  local profile_args=()
  local final_args=()
  local use_profile=true
  local specified_profile=""
  local show_help=false
  local i=1

  # Parse .t config file
  _parse_test_config

  # Process user arguments to extract profile-related flags
  while [[ $i -le ${#user_args[@]} ]]; do
    case "${user_args[$i]}" in
      --profile)
        if [[ $i -lt ${#user_args[@]} ]]; then
          specified_profile="${user_args[$i+1]}"
          i=$((i + 1))  # Skip the next argument as it's the profile name
        else
          echo "Error: --profile requires a profile name" >&2
          return 1
        fi
        ;;
      --profile=*)
        specified_profile="${user_args[$i]#*=}"
        ;;
      --no-profile)
        use_profile=false
        ;;
      --help|-h)
        show_help=true
        ;;
      *)
        final_args+=("${user_args[$i]}")
        ;;
    esac
    i=$((i + 1))
  done

  # Handle help display
  if [[ $show_help == true ]]; then
    _show_profile_help >&2
    return 42  # Special return code to indicate help was shown
  fi

  # Determine which profile to use
  if [[ $use_profile == true ]]; then
    local target_profile="${specified_profile:-default}"

    if [[ -n "${_TEST_CONFIG[$target_profile]:-}" ]]; then
      # Split profile args safely without eval to avoid ~ expansion issues
      local profile_arg_string="${_TEST_CONFIG[$target_profile]}"
      profile_args=(${=profile_arg_string})
    elif [[ -n "$specified_profile" ]]; then
      echo "Error: Profile '$specified_profile' not found in .t file" >&2
      if [[ ${#_TEST_CONFIG[@]} -gt 0 ]]; then
        echo "Available profiles: ${(k)_TEST_CONFIG[*]}" >&2
      fi
      return 1
    fi
  fi

  # Combine profile args with user args (profile args first, so user args can override)
  echo "${profile_args[@]} ${final_args[@]}"
}

# Shows help information including available profiles from .t file
_show_profile_help() {
  echo ""
  if [[ ${#_TEST_CONFIG[@]} -gt 0 ]]; then
    echo ""
    echo "Available test profiles from .t file:"
    for profile in "${(@k)_TEST_CONFIG}"; do
      printf "  %-12s %s\n" "$profile:" "${_TEST_CONFIG[$profile]}"
    done
    echo ""
    echo "Usage:"
    echo "  t                      # Use 'default' profile if available"
    echo "  t --profile <name>     # Use specific profile"
    echo "  t --no-profile         # Don't use any profile"
    echo ""
  else
    echo "No .t configuration file found in current directory."
    echo ""
    echo "Usage:"
    echo "  t [options]            # Run tests"
    echo "  t --help               # Show this help"
    echo ""
    echo "All options are passed to the test runner (RSpec/Rails test)."
    echo ""
  fi
}

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
#   t                           # Run all tests (with default profile if .t exists)
#   t --profile slow            # Run with 'slow' profile from .t file
#   t --no-profile              # Run without any profile
#   t --format documentation    # Run with specific RSpec format
#   t --verbose                 # Run Rails tests with verbose output
function t() {
  local framework=$(_detect_test_framework)
  local resolved_args

  # Resolve arguments with profile support
  resolved_args=$(_resolve_test_args "$@")
  local resolve_status=$?

  # If _resolve_test_args failed or handled help, return
  if [[ $resolve_status -ne 0 ]]; then
    # Return 0 for help (status 42), preserve other error codes
    [[ $resolve_status -eq 42 ]] && return 0 || return $resolve_status
  fi

  # Convert resolved args back to array and run tests
  local args=(${=resolved_args})
  _run_tests "$framework" "" "${args[@]}"
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
#   tff                         # Run with fail-fast and random seed (with default profile if .t exists)
#   tff --profile slow          # Run with 'slow' profile from .t file
#   tff --no-profile            # Run without any profile
#   tff --seed=12345           # Run with specific seed
#   echo $SEED                 # Check persisted seed after failure
function tff() {
  local framework=$(_detect_test_framework)
  local resolved_args

  # First resolve profile arguments
  resolved_args=$(_resolve_test_args "$@")
  local resolve_status=$?

  # If _resolve_test_args failed or handled help, return
  if [[ $resolve_status -ne 0 ]]; then
    # Return 0 for help (status 42), preserve other error codes
    [[ $resolve_status -eq 42 ]] && return 0 || return $resolve_status
  fi

  # Convert back to array for seed handling
  local profile_processed_args=(${=resolved_args})

  # Handle seed logic with the profile-processed arguments
  local final_args=($(_handle_test_seed "${profile_processed_args[@]}"))

  # Run tests with fail-fast
  _run_tests "$framework" "" --fail-fast "${final_args[@]}"
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