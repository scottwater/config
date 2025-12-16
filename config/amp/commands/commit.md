---
description: Create git commits following story-driven guidelines using conversation context
---

# Commit Changes with Guidelines

You are tasked with creating git commits that follow story-driven commit guidelines.

## Context Awareness

Before planning commits:
1. Review the conversation history to understand what was accomplished during this session
2. Check the current branch name and look for related context in `/thoughts` and `/workflow` directories that might inform commit decisions
3. Use this context to write commits that accurately reflect the work's purpose and decisions

## Process

### 1. Understand What Changed

Run these commands in parallel to gather information:
- `git status` - See all modified, untracked, and staged files
- `git diff` - View unstaged changes in detail
- `git diff --staged` - View already-staged changes
- `git log --oneline -n 5` - Review recent commit style

Analyze the changes to understand:
- What features or fixes were implemented
- Which files naturally group together
- Whether this should be one commit or multiple logical commits
- What architectural or product decisions were made

### 2. Plan Your Commits

Based on the changes and conversation history, plan your commit(s) following these principles:

**Commit Structure:**
- **Summary:** Action verb (Add/Update/Remove) + product-focused description
- **Body (optional):** Bulleted list of architectural decisions, trade-offs, or product implications
- **NO AI attribution:** Never include "Generated with Claude" or co-author lines

**Grouping Strategy:**
For related changes, create a logical sequence:
1. Schema/infrastructure changes first
2. Core model or business logic second
3. Controllers or services third
4. UI components last

**Atomic Commits:**
- Each commit should represent one logical change
- Include related tests with the code they test
- Ensure each commit could theoretically stand alone

### 3. Present Your Plan

Show the user:
1. The number of commits you plan to create
2. For each commit:
   - The proposed commit message (summary + body if needed)
   - The files to be included
   - Brief explanation of the grouping rationale

Format:
```
I plan to create [N] commit(s):

Commit 1: [Summary line]
Files: file1.rb, file2.rb, spec/file1_spec.rb
[Body bullets if needed]

Commit 2: [Summary line]
Files: file3.rb, file4.rb
[Body bullets if needed]

Does this commit plan look good?
```

### 4. Execute Upon Confirmation

Once the user confirms, create the commits:

1. Stage files explicitly (never use `git add -A` or `git add .`):
   ```bash
   git add file1.rb file2.rb spec/file1_spec.rb
   ```

2. Create commit with the planned message:
   ```bash
   git commit -m "Summary line

   - First bullet point
   - Second bullet point"
   ```

3. Repeat for each commit

4. Show results:
   ```bash
   git log --oneline -n [number_of_commits]
   ```

## Important Rules

**NEVER include:**
- AI attribution or "Generated with Claude" messages
- Co-authored-by lines for AI tools
- References to AI assistance

**DO include:**
- Present tense verbs (Add, Update, Remove)
- Product-focused descriptions
- Architectural decisions and trade-offs (in body)
- Clear reasoning for changes

**Commit authorship:**
- Commits should be authored solely by the user
- You are helping draft messages, but they represent the user's decisions
- The user is responsible for understanding and maintaining this code

## Leveraging Context

Before finalizing commits:
1. Check `/thoughts` directory for files matching the current branch name
2. Look for related context files that explain the feature or architectural decisions
3. Use this context to ensure commits accurately reflect the broader goals and decisions
4. Incorporate relevant architectural reasoning from thoughts into commit bodies

## Review Before Creating

Ask yourself:
- Does each commit tell one part of the story?
- Are the messages focused on product/architecture decisions, not tasks?
- Would a reviewer understand the "why" from these messages?
- Is the sequence logical (foundation → implementation → UI)?
- Have I included all related changes (code + tests) in each commit?

---

Now begin by running the git commands to understand the current state of changes.
