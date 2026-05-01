# Agent Dispatch Prompt Template

Use this template when dispatching a task to an external agent via `./scripts/dispatch.sh`.

## Template

```
./scripts/dispatch.sh --approve-all --timeout [seconds] single [agent] "[prompt below]"
```

### Prompt Structure

```
You are working as a [agent-name] specialist being delegated a focused task.

## Task

[FULL TASK DESCRIPTION - be specific and complete]

## Context

Project: [project name]
Working directory: [cwd]
Key files: [list the most relevant files]
Upstream: [any tasks that were completed before this one]

## Constraints

- Work only in: [specified directory/files]
- Do NOT modify: [files to avoid]
- Approval mode: [approve-all / approve-reads]
- Timeout seconds: [600 / 1800 / 3600 / custom]

## Expected Output

When done, provide:
1. What you implemented/found
2. Files changed (with paths)
3. Test results (if applicable)
4. Issues or concerns
5. Recommended next steps

## Important

- If anything is unclear, state your assumptions
- Test your work before reporting completion
- Provide actionable, specific output
```

## Examples

### Implementation Task (Codex)

```bash
./scripts/dispatch.sh --approve-all --timeout 1800 single codex \
  "Implement email notification service in src/services/email.ts. Requirements:
   - Async send method with retry logic (max 3 retries, exponential backoff)
   - Support HTML and plain text templates
   - Error logging to console
   - Write tests in src/services/email.test.ts
   Constraints: Do NOT modify any existing files. Only create new files."
```

### Security Review (Claude)

```bash
./scripts/dispatch.sh --approve-reads --timeout 600 single claude \
  "Security review of src/auth/ directory. Check for:
   - OWASP Top 10 vulnerabilities
   - Input validation gaps
   - Authentication/authorization issues
   - Secrets or credentials in code
   Report format: List each finding with severity (critical/high/medium/low), file:line, and fix recommendation."
```

### UI Design (Gemini)

```bash
./scripts/dispatch.sh --approve-all --timeout 1800 single gemini \
  "Create a responsive checkout form component in src/ui/CheckoutForm.tsx. Requirements:
   - Form fields: name, email, card number, expiry, CVV
   - Client-side validation
   - Mobile-responsive with Tailwind CSS
   - Accessible (WCAG 2.1 AA)
   - Loading state and error state handling"
```

## Timeout Recommendations

- `600`: read-only review, architecture discussion, narrow analysis
- `1800`: normal coding, refactors, medium-sized feature work
- `3600`: dependency installation, large test/build loops, major repairs
