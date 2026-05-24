# Batch Dispatch Template

## Usage

Dispatch multiple independent tasks to different agents running in parallel.

```bash
# Via dispatch CLI
./scripts/dispatch.sh batch \
  "codex:Implement the REST API endpoints" \
  "claude:Security review of the API design" \
  "gemini:Design the onboarding UI components"

# Via task-coordinator library
source scripts/task-coordinator.sh
dispatch_parallel \
  "codex:Implement feature X" \
  "claude:Review architecture" \
  "gemini:Design the UI"
```

## When to Use Batch Dispatch

- Tasks are **independent** (no shared state or sequential dependencies)
- Different agents are **best suited** for each task
- You want **parallel execution** to save time

## Format

Each task uses `agent:task description` format:

```
"codex:Implement the email notification system"
"claude:Review auth module for OWASP Top 10 vulnerabilities"
"gemini:Create responsive checkout form component"
```

## Coordination

1. All tasks start simultaneously (respecting parallelism limit, default 3)
2. Each agent works in an isolated session
3. Results collected as each agent completes
4. Aggregated summary displayed after all finish

## Result Format

```
===== Multi-Agent Dispatch Results =====

Summary:
  Total tasks: 3
  Completed: 3
  Failed: 0
  Duration: 245s (parallel)

--- codex (batch-1711800000-0) [completed] ---
[Agent output here]
--- end codex ---

--- claude (batch-1711800000-1) [completed] ---
[Agent output here]
--- end claude ---

--- gemini (batch-1711800000-2) [completed] ---
[Agent output here]
--- end gemini ---

===== End Results =====
```

## Cross-Model Review Pattern

A powerful batch pattern - pair implementation with adversarial review:

```bash
# Step 1: Implement + Review in parallel
./scripts/dispatch.sh batch \
  "codex:Implement the checkout flow as specified in docs/checkout-spec.md" \
  "claude:Review docs/checkout-spec.md for security gaps and suggest improvements"

# Step 2: Fix based on review (sequential)
./scripts/dispatch.sh single codex "Fix these security issues found by Claude: [paste findings]"
```
