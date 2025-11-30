# Scripts

Utility scripts for the researching-codebase skill.

## spec_metadata

Collects metadata for research documents.

**Purpose**: Gathers all necessary metadata (date/time, git info, researcher name) before creating research documents to avoid placeholder values.

**Usage**:
```bash
spec_metadata
```

**Note**: The `spec_metadata` script is available in your PATH (from your dotfiles bin/ directory).

**Output includes**:
- Current date/time with timezone (ISO format)
- Git commit hash
- Current branch name
- Repository name

**Why this exists**: Research documents require consistent metadata in YAML frontmatter. Running this script before writing ensures all values are real and accurate, never placeholders.

## Guidelines

- Scripts should solve problems, not punt to Claude
- Include error handling
- Document why constants have specific values
- Use forward slashes for paths (cross-platform)
