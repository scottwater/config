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
  local specified_profiles=()
  local show_help=false
  local i=1

  # Parse .t config file
  _parse_test_config

  # Process user arguments to extract profile-related flags
  while [[ $i -le ${#user_args[@]} ]]; do
    case "${user_args[$i]}" in
      --profile)
        if [[ $i -lt ${#user_args[@]} ]]; then
          local profile_list="${user_args[$i+1]}"
          # Handle comma-separated profiles
          if [[ "$profile_list" == *","* ]]; then
            IFS=',' read -A profile_array <<< "$profile_list"
            specified_profiles+=("${profile_array[@]}")
          else
            specified_profiles+=("$profile_list")
          fi
          i=$((i + 1))  # Skip the next argument as it's the profile name
        else
          echo "Error: --profile requires a profile name" >&2
          return 1
        fi
        ;;
      --profile=*)
        local profile_list="${user_args[$i]#*=}"
        # Handle comma-separated profiles
        if [[ "$profile_list" == *","* ]]; then
          IFS=',' read -A profile_array <<< "$profile_list"
          specified_profiles+=("${profile_array[@]}")
        else
          specified_profiles+=("$profile_list")
        fi
        ;;
      --no-profile)
        use_profile=false
        ;;
      --help|-h)
        show_help=true
        ;;
      *)
        # Check if this flag matches a profile name (e.g., --fast, --slow)
        if [[ "${user_args[$i]}" == --* ]]; then
          local potential_profile="${user_args[$i]#--}"
          if [[ -n "${_TEST_CONFIG[$potential_profile]:-}" ]]; then
            # This is a profile shortcut
            specified_profiles+=("$potential_profile")
          else
            # Regular flag, pass it through
            final_args+=("${user_args[$i]}")
          fi
        else
          final_args+=("${user_args[$i]}")
        fi
        ;;
    esac
    i=$((i + 1))
  done

  # Handle help display
  if [[ $show_help == true ]]; then
    _show_profile_help >&2
    return 42  # Special return code to indicate help was shown
  fi

  # Determine which profiles to use
  if [[ $use_profile == true ]]; then
    local profiles_to_use=()

    # If no profiles specified, use default
    if [[ ${#specified_profiles[@]} -eq 0 ]]; then
      profiles_to_use=("default")
    else
      profiles_to_use=("${specified_profiles[@]}")
    fi

    # Process each profile and collect arguments
    for target_profile in "${profiles_to_use[@]}"; do
      # Skip empty profile names
      [[ -z "$target_profile" ]] && continue

      if [[ -n "${_TEST_CONFIG[$target_profile]:-}" ]]; then
        # Resolve profile (handles references like --fast)
        local resolved_profile_args
        resolved_profile_args=$(_resolve_profile_reference "$target_profile")
        local resolve_status=$?

        if [[ $resolve_status -ne 0 ]]; then
          return $resolve_status
        fi

        # Split profile args safely without eval to avoid ~ expansion issues
        local single_profile_args=(${=resolved_profile_args})
        profile_args+=("${single_profile_args[@]}")
      elif [[ "$target_profile" != "default" || ${#specified_profiles[@]} -gt 0 ]]; then
        # Only show error if it's not the default profile or if profiles were explicitly specified
        echo "Error: Profile '$target_profile' not found in .t file" >&2
        if [[ ${#_TEST_CONFIG[@]} -gt 0 ]]; then
          echo "Available profiles: ${(k)_TEST_CONFIG[*]}" >&2
        fi
        return 1
      fi
    done
  fi

  # Combine profile args with user args (profile args first, so user args can override)
  echo "${profile_args[@]} ${final_args[@]}"
}

# Resolves profile references recursively (when profile value starts with --)
# Args: $1 - profile name to resolve
# Returns: the final profile arguments, or error if circular reference detected
_resolve_profile_reference() {
  local profile_name="$1"
  local visited_profiles=("${@:2}")  # Get all previously visited profiles
  local profile_value="${_TEST_CONFIG[$profile_name]:-}"

  # Check if profile exists
  if [[ -z "$profile_value" ]]; then
    return 1
  fi

  # Check for circular reference
  for visited in "${visited_profiles[@]}"; do
    if [[ "$visited" == "$profile_name" ]]; then
      echo "Error: Circular profile reference detected: ${visited_profiles[*]} -> $profile_name" >&2
      return 1
    fi
  done

  # Check if this profile references another profile (starts with --)
  if [[ "$profile_value" =~ ^--([a-zA-Z0-9_-]+)$ ]]; then
    local referenced_profile="${profile_value#--}"
    # Recursively resolve the referenced profile
    _resolve_profile_reference "$referenced_profile" "${visited_profiles[@]}" "$profile_name"
  else
    # This is a regular profile, return its args
    echo "$profile_value"
  fi
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
    echo "  t --<profile>          # Use profile shortcut (e.g., --fast, --slow)"
    echo "  t --profile <name>     # Use specific profile"
    echo "  t --profile <n1,n2>    # Use multiple profiles (comma-separated)"
    echo "  t --profile <n1> --profile <n2>  # Use multiple profiles (multiple flags)"
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

# Generates a default .t configuration file with fast and slow profiles
# Based on the detected test framework (RSpec or Rails)
_generate_test_config() {
  # Check if .t file already exists
  if [[ -f ".t" ]]; then
    echo "Error: .t file already exists. Delete it first if you want to generate a new one." >&2
    return 1
  fi

  local framework=$(_detect_test_framework)

  if [[ "$framework" == "none" ]]; then
    echo "Error: No test framework detected (no spec/ or test/ directory found)." >&2
    return 1
  fi

  echo "Generating .t configuration file for $framework framework..."

  case $framework in
    "rspec")
      cat > .t << 'EOF'
# Test configuration profiles
# Usage: t --profile <profile_name>

default: --fast
fast: --tag ~type:system --tag ~speed:slow
slow: --tag type:system --tag speed:slow
EOF
      ;;
    "rails")
      cat > .t << 'EOF'
# Test configuration profiles
# Usage: t --profile <profile_name>

default: --fast
fast: test/models test/controllers test/helpers test/mailers test/jobs
slow: test/system
EOF
      ;;
  esac

  echo ".t file generated successfully!"
  echo "You can customize the profiles by editing the .t file."
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
#   t --generate                # Generate a .t configuration file with fast/slow profiles
#   t --fast                    # Run with 'fast' profile (shortcut for --profile fast)
#   t --slow                    # Run with 'slow' profile (shortcut for --profile slow)
#   t --profile slow            # Run with 'slow' profile from .t file
#   t --profile slow,doc        # Run with multiple profiles (comma-separated)
#   t --profile slow --profile doc  # Run with multiple profiles (multiple flags)
#   t --no-profile              # Run without any profile
#   t --format documentation    # Run with specific RSpec format
#   t --verbose                 # Run Rails tests with verbose output
function t() {
  # Check for --generate flag first
  for arg in "$@"; do
    if [[ "$arg" == "--generate" ]]; then
      _generate_test_config
      return $?
    fi
  done

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

# Find the corresponding spec file for a given source file
# Converts paths like app/models/user.rb to spec/models/user_spec.rb
# Args: $1 - source file path
# Returns: spec file path if it exists, empty string otherwise
_find_related_spec() {
  local source_file="$1"
  local spec_file=""

  # Skip if already a spec or test file
  if [[ "$source_file" =~ _spec\.rb$ ]] || [[ "$source_file" =~ _test\.rb$ ]]; then
    return
  fi

  # Only process Ruby files
  if [[ ! "$source_file" =~ \.rb$ ]]; then
    return
  fi

  # Convert source path to spec path using string manipulation
  local base_name="${source_file%.rb}"  # Remove .rb extension

  # Handle app/ prefix
  if [[ "$source_file" == app/* ]]; then
    # Remove 'app/' prefix and add to spec/
    local path_without_app="${base_name#app/}"
    spec_file="spec/${path_without_app}_spec.rb"
  # Handle lib/ prefix
  elif [[ "$source_file" == lib/* ]]; then
    # Keep lib/ in the spec path
    spec_file="spec/${base_name}_spec.rb"
  else
    # For other files, try direct mapping to spec/
    spec_file="spec/${base_name}_spec.rb"
  fi

  # Check if the spec file exists
  if [[ -f "$spec_file" ]]; then
    echo "$spec_file"
  fi
}

# Run tests only on git-modified files (changed, staged, or untracked)
# Automatically detects _spec.rb files for RSpec or _test.rb files for Rails tests
# Also finds and includes related spec files for modified source files
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

  # Get modified test files
  local test_files=$(_get_git_modified_files "$pattern")

  # Get ALL modified files to find related specs
  local all_modified_files=$(git diff --name-only 2>/dev/null)
  all_modified_files="$all_modified_files"$'\n'$(git diff --cached --name-only 2>/dev/null)
  all_modified_files="$all_modified_files"$'\n'$(git ls-files --others --exclude-standard 2>/dev/null)

  # Find related spec files for non-test files
  local related_specs=""
  local debug_mode="${TG_DEBUG:-}"

  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      if [[ -n "$debug_mode" ]]; then
        echo "DEBUG: Checking file: $file" >&2
      fi
      local spec_file=$(_find_related_spec "$file")
      if [[ -n "$spec_file" ]]; then
        if [[ -n "$debug_mode" ]]; then
          echo "DEBUG: Found spec: $spec_file" >&2
        fi
        related_specs="$related_specs"$'\n'"$spec_file"
      elif [[ -n "$debug_mode" ]] && [[ "$file" =~ \.rb$ ]] && [[ ! "$file" =~ _spec\.rb$ ]]; then
        # Debug: show what spec file we looked for but didn't find
        local expected_spec=""
        if [[ "$file" == app/* ]]; then
          expected_spec="spec/${file#app/}"
          expected_spec="${expected_spec%.rb}_spec.rb"
          echo "DEBUG: No spec found at: $expected_spec" >&2
        fi
      fi
    fi
  done <<< "$all_modified_files"

  # Combine test files and related specs, remove duplicates and empty lines
  local all_test_files=""
  if [[ -n "$test_files" ]]; then
    all_test_files="$test_files"
  fi
  if [[ -n "$related_specs" ]]; then
    if [[ -n "$all_test_files" ]]; then
      all_test_files="$all_test_files"$'\n'"$related_specs"
    else
      all_test_files="$related_specs"
    fi
  fi

  # Remove duplicates and empty lines
  all_test_files=$(echo "$all_test_files" | sort -u | grep -v '^$')

  if [ -n "$all_test_files" ]; then
    echo "Running tests on modified files and their related specs:"
    echo "$all_test_files" | sed 's/^/  /'
    echo ""
    _run_tests "$framework" "$all_test_files" "$@"
  else
    echo "No modified test files or related specs found."
  fi
}

# Run all tests, but only show failures (skip passing tests in output)
# Does NOT use test profiles - runs tests directly with arguments
# Usage: tf [options]
# Examples:
#   tf                          # Run all tests, only show failures
#   tf spec/models              # Run tests in spec/models, only show failures
function tf() {
  local framework=$(_detect_test_framework)

  if [ "$framework" = "none" ]; then
    echo "No spec or test directory found."
    return 1
  fi

  # Run tests directly without profile resolution
  _run_tests "$framework" "" --only-failures "$@"
}

# Run git-modified tests, but only show failures
# Does NOT use test profiles - runs tests directly with arguments
# Usage: tgf [options]
# Examples:
#   tgf                         # Run modified tests, only show failures
function tgf() {
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

  # Get modified test files
  local test_files=$(_get_git_modified_files "$pattern")

  # Get ALL modified files to find related specs
  local all_modified_files=$(git diff --name-only 2>/dev/null)
  all_modified_files="$all_modified_files"$'\n'$(git diff --cached --name-only 2>/dev/null)
  all_modified_files="$all_modified_files"$'\n'$(git ls-files --others --exclude-standard 2>/dev/null)

  # Find related spec files for non-test files
  local related_specs=""
  local debug_mode="${TG_DEBUG:-}"

  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      if [[ -n "$debug_mode" ]]; then
        echo "DEBUG: Checking file: $file" >&2
      fi
      local spec_file=$(_find_related_spec "$file")
      if [[ -n "$spec_file" ]]; then
        if [[ -n "$debug_mode" ]]; then
          echo "DEBUG: Found spec: $spec_file" >&2
        fi
        related_specs="$related_specs"$'\n'"$spec_file"
      elif [[ -n "$debug_mode" ]] && [[ "$file" =~ \.rb$ ]] && [[ ! "$file" =~ _spec\.rb$ ]]; then
        # Debug: show what spec file we looked for but didn't find
        local expected_spec=""
        if [[ "$file" == app/* ]]; then
          expected_spec="spec/${file#app/}"
          expected_spec="${expected_spec%.rb}_spec.rb"
          echo "DEBUG: No spec found at: $expected_spec" >&2
        fi
      fi
    fi
  done <<< "$all_modified_files"

  # Combine test files and related specs, remove duplicates and empty lines
  local all_test_files=""
  if [[ -n "$test_files" ]]; then
    all_test_files="$test_files"
  fi
  if [[ -n "$related_specs" ]]; then
    if [[ -n "$all_test_files" ]]; then
      all_test_files="$all_test_files"$'\n'"$related_specs"
    else
      all_test_files="$related_specs"
    fi
  fi

  # Remove duplicates and empty lines
  all_test_files=$(echo "$all_test_files" | sort -u | grep -v '^$')

  if [ -n "$all_test_files" ]; then
    echo "Running tests on modified files and their related specs (failures only):"
    echo "$all_test_files" | sed 's/^/  /'
    echo ""
    # Run tests directly without profile resolution
    _run_tests "$framework" "$all_test_files" --only-failures "$@"
  else
    echo "No modified test files or related specs found."
  fi
}

# Run all tests with fail-fast and automatic seed management
# Generates a random seed if none provided. If tests fail, the seed persists
# in the SEED environment variable so you can re-run the same failing test.
# If tests pass, the seed is cleared.
# Usage: tff [options]
# Examples:
#   tff                         # Run with fail-fast and random seed (with default profile if .t exists)
#   tff --profile slow          # Run with 'slow' profile from .t file
#   tff --profile slow,doc      # Run with multiple profiles (comma-separated)
#   tff --profile slow --profile doc  # Run with multiple profiles (multiple flags)
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