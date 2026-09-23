# Assessment solutions

Working notes maintained during the assessment. Incomplete sections are marked
as pending and will be reviewed before submission.

## Current status

- Assessment email, README, full brief, and relevant starter code inspected with Codex.
- Project architecture, dependency registration, navigation, and data flow reviewed with Codex.
- No bug ticket or feature work recorded yet.
- No application runs, bug reproductions, tests, or performance measurements recorded yet.

## Time notes

Times will use Asia/Yangon (UTC+06:30). Active work estimates will account for
reported breaks; elapsed time alone will not be treated as active work.

| Date | Activity | Time spent |
| --- | --- | --- |
| 2026-09-23 | Assessment review and explanation of the documentation requirements with Codex | Not timed; retrospective estimate pending |
| 2026-09-23 | Project onboarding with Codex: architecture, data flow, and assessment boundaries | Assistant source inspection began at 11:25:13; applicant active time not measured, estimate pending |

Ticket timing has not started.

## Ticket and feature notes

No tickets or features attempted yet.

<!-- For each ticket or feature, record:
- Ticket ID and title
- Start, pause/resume, and finish times as reported
- Approximate active time spent
- Reproduction steps and observed behavior (for bugs)
- Root cause, distinguishing hypotheses from verified findings
- Implementation and why it addresses the cause
- At least one alternative considered and rejected, with reasons
- Verification actually performed and its results
- Edge cases considered, deliberately unhandled cases, and remaining limitations
- Related AI log entries and commit(s)
-->

## AI usage log

### AI-001 — Assessment review and workflow preparation

- **Date:** 2026-09-23
- **Tool:** Codex
- **Purpose:** Understand the assessment and how to record the work.
- **Assistance:** Read the local assessment email, `README.md`, `PROBLEM.md`,
  and relevant starter code; summarized the bug tickets, features, constraints,
  grading criteria, and deliverables; explained how to keep time notes and an
  AI usage log alongside normal fix/test/commit work; created this draft log.
- **Evidence and limits:** The summary was checked against the local brief and
  source files. Code observations came from static inspection; no runtime
  behavior or proposed fix has been verified yet.
- **Decision:** Keep these notes as work proceeds. Begin timing the first
  ticket when the applicant explicitly starts it.

### AI-002 — Project onboarding

- **Date:** 2026-09-23
- **Tool:** Codex
- **Purpose:** Understand how the existing app is organized before starting a ticket.
- **Assistance:** Traced startup in `main.dart`, route bindings and dependency
  injection, the search request/response path, shared cart state, checkout,
  analytics, model parsing, and the simulated API. Mapped responsibilities to
  source folders and clarified the assessment's protected files and pinned
  toolchain. Prepared a static diagram and a suggested reading order.
- **Evidence and limits:** Based on local source inspection and the assessment
  brief. The business API is simulated in memory, while deal images and map
  tiles use external URLs. No runtime behavior, tests, or performance claims
  were verified during this onboarding.
- **Boundaries:** `lib/service/fake_api_service.dart` and `assets/data/` are
  readable but must not be edited. Other services, models, repositories,
  controllers, widgets, and tests are available for task-related changes.
- **Outcome:** Onboarding notes prepared; no ticket started or application
  code changed by Codex.

### Incorrect or misleading AI suggestions

No actual incidents recorded yet. The assessment requires at least two concrete
examples across the submission. For each real incident, record the suggestion,
the evidence that exposed its problem, and what was done instead.

The search-debounce example used while explaining the log was hypothetical;
it is not an actual incident and does not count toward this requirement.

## Design questions

### Q1 — GetX controller lifecycle versus widget State lifecycle

Pending: explain the distinction and identify a relevant Part A bug.

### Q2 — Scoping Obx reactivity

Pending: explain when a large reactive subtree hurts performance and how to
choose the appropriate scope.

### Q3 — Automated coverage for RES-106

Pending: describe a test that would catch the pickup-time bug and any code
changes needed to make it testable.

## Total time and one more day

- **Approximate total active time:** Pending.
- **What remains unfinished:** All bug tickets, features, and design answers.
- **What I would do with one more day:** Pending; decide based on the completed work.
