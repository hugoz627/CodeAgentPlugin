# Example 2: Parallel Batch Dispatch

Run multiple agents simultaneously on independent tasks.

## Scenario

Building a user onboarding feature. Three independent workstreams:
1. Backend API (Codex - fast implementation)
2. Security review (Claude - deep analysis)
3. Frontend UI (Gemini - strong at UI/UX)

## Command

```bash
./scripts/dispatch.sh batch \
  "codex:Implement REST API endpoints for user onboarding: POST /register, POST /verify-email, POST /complete-setup. Use Express with input validation and proper error responses." \
  "claude:Review the proposed onboarding API design in docs/onboarding-spec.md for security vulnerabilities, auth weaknesses, and data privacy issues." \
  "gemini:Create responsive onboarding UI components: RegistrationForm, EmailVerification, SetupWizard. Use React + Tailwind CSS, ensure WCAG 2.1 AA accessibility."
```

## What Happens

```
[INFO] Starting parallel dispatch of 3 tasks (parallelism=3)
[INFO] [1/3] Dispatching to codex: Implement REST API endpoints...
[INFO] [2/3] Dispatching to claude: Review the proposed onboarding API...
[INFO] [3/3] Dispatching to gemini: Create responsive onboarding UI...
[INFO] Waiting for all tasks to complete...
[OK] Agent codex completed: batch-1711800000-0
[OK] Agent claude completed: batch-1711800000-1
[OK] Agent gemini completed: batch-1711800000-2

===== Multi-Agent Dispatch Results =====

Summary:
  Total tasks: 3
  Completed: 3
  Failed: 0
  Duration: 267s (parallel)

--- codex (batch-1711800000-0) [completed] ---
Implemented 3 endpoints:
- POST /register - User registration with email/password validation
- POST /verify-email - Token-based email verification
- POST /complete-setup - Profile completion with optional fields

Files created:
- src/api/onboarding.ts (142 lines)
- src/api/onboarding.test.ts (89 lines)
- src/middleware/validate.ts (34 lines)

All 12 tests passing.
--- end codex ---

--- claude (batch-1711800000-1) [completed] ---
Security Review of Onboarding API:

Critical:
- Password stored as SHA-256 (use bcrypt with salt instead)

High:
- No rate limiting on /register endpoint
- Email verification token is predictable (use crypto.randomUUID)

Medium:
- Missing CORS configuration
- No input length limits on profile fields

Recommendation: Address Critical and High before deployment.
--- end claude ---

--- gemini (batch-1711800000-2) [completed] ---
Created 3 React components:
- RegistrationForm.tsx - Email/password with real-time validation
- EmailVerification.tsx - OTP input with resend timer
- SetupWizard.tsx - 3-step wizard with progress indicator

Features:
- Mobile-responsive (tested at 320px, 768px, 1024px)
- WCAG 2.1 AA: proper labels, focus management, contrast
- Loading states and error handling included

Files: src/ui/onboarding/*.tsx (3 files, ~400 lines total)
--- end gemini ---

===== End Results =====
```

## Time Saved

| Execution | Duration |
|-----------|----------|
| Sequential (one after another) | ~4m 30s + ~4m + ~3m = **11m 30s** |
| Parallel (all at once) | **4m 27s** |
| **Time saved** | **7m 3s (61%)** |

## Cross-Model Review Follow-Up

After the batch, use Claude's findings to fix Codex's implementation:

```bash
./scripts/dispatch.sh single codex \
  "Fix these security issues in src/api/onboarding.ts:
   1. Replace SHA-256 password hashing with bcrypt (npm install bcrypt)
   2. Add rate limiting to POST /register (5 req/min per IP)
   3. Use crypto.randomUUID() for email verification tokens
   4. Add input length limits (email: 254 chars, name: 100 chars)"
```

This is the **cross-model adversarial review** pattern: implementation by one model, review by another.
