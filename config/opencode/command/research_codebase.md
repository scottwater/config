---
description: Research codebase comprehensively with parallel sub-agents
---

# Research Codebase

When this command is invoked, use the `researching-codebase` skill to conduct comprehensive research across the codebase.

**User's research query:** $ARGUMENTS

## Usage

Simply invoke the skill:
```
/researching-codebase
```

The skill will:
- Conduct comprehensive research by spawning parallel sub-agents
- Synthesize findings from multiple sources
- Document the current state of the codebase (not suggest improvements)
- Generate structured research documents with proper metadata
- Handle follow-up questions iteratively

## When to Use

Use this command when you need to:
- Investigate how features work
- Understand component relationships
- Document the current state of the system
- Answer architectural questions
- Map out existing patterns and conventions

## Important Notes

- The skill is a documentarian, not a critic
- It describes what exists, not what should be improved
- All findings are backed by concrete file references
- Research is stored in `thoughts/shared/research/` with proper metadata
