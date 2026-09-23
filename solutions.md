# Assessment solutions

## RES-101 — Search shows results for the wrong query

**Reproduction:** Typing `sushi` letter by letter caused shorter-query results
to replace the results for the full keyword.

**Root cause:** Search requests completed out of order, and every response
could overwrite the results and loading state without checking whether its
query was still current. The simulated backend gives shorter queries longer
delays, making this race easy to trigger.

**Fix:** Increment a version immediately on every query change. Only the
current version may update results, report errors, or clear loading. A 300 ms
debouncer reduces requests while typing; the version checks prevent stale
responses from affecting the current search.

**Alternative considered:** During review, considered debouncing alone. It
reduces requests but cannot prevent an already-running request from returning
outdated results, so version checks are also needed.

**Edge cases and limits:** Clearing input, including whitespace-only input,
resets the state and cancels the debounce. Closing the controller cancels the
timer and invalidates pending work. Older responses are ignored even during
the next debounce interval. In-flight API calls finish rather than being
cancelled. Current-query errors retain the existing console logging.

**Verification:** Focused Dart analysis of the search controller and debounce
utility passed.

## AI usage log

- **Codex — preparation:** Explained the assessment requirements, project
  architecture, and data flow from the local brief and source code.
- **Codex — RES-101:** Suggested the reproduction procedure, reviewed the
  existing implementation, ran
  focused Dart analysis, and helped document the diagnosis and decisions.

**Incorrect or misleading suggestions:** No actual incidents recorded yet.

## Design questions

### Q1 — GetX controller lifecycle versus widget State lifecycle

Pending: explain the distinction and identify a relevant Part A bug.

### Q2 — Scoping Obx reactivity

Pending: explain when a large reactive subtree hurts performance and how to
choose the appropriate scope.

### Q3 — Automated coverage for RES-106

Pending: describe a test that would catch the pickup-time bug and any code
changes needed to make it testable.

## Time spent and next steps

- **RES-101:** About 15 minutes elapsed on 2026-09-23;
- **Remaining work:** RES-102 through RES-107, features, and design answers are not yet
  documented as completed.
- **With one more day:** Pending; decide based on the completed work.
