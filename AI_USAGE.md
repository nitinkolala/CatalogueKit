# AI usage notes

How AI tools were used on this submission, and how the output was checked. Items marked **[fill in]** need the author's own account before submission.

## 1. Tools and models

| Tool | Used for | Model |
| --- | --- | --- |
| Claude Code (CLI and desktop app) | Reading the brief, planning, generating and editing backend and iOS code, tests, and these documents | Claude Haiku 5.5 (`claude-haiku-5-5`) for the session that did the final audit. [fill in: any other sessions and their models] |
| Xcode and the iOS Simulator | Building, running the app, and checking screens | Not AI. Used to verify the AI's output. |
| [fill in: any other tools, e.g. Cursor or Copilot] | [fill in] | [fill in] |

No paid service or account is needed to run the solution. AI tools were used only while building it, not inside the product.

## 2. Agent instruction files

Committed to the repo:

- **`CLAUDE.md`** at the repo root. It sets the stack, the MVVM and Clean architecture rules, the SOLID guidance, the caching and environment rules, the no-hardcoding rule, the validator rules (strict email, exactly 10 digits for mobile), the testing expectations, and repo hygiene (no `xcuserdata/`, `DerivedData/` or signing values committed). Its "Current state" section now lists the real commands.

The file was committed in three steps: `1172863` (architecture and rules), `04a11cc` (restored the init sections and added project rules) and `322e21d` (added the testing rule). The history shows the file changing as the project did.

No `AGENTS.md` or `.cursor/rules` file is in the repo.

## 3. Plan and spec

- **The brief** (`Documents/Code Challenge - AI-Native Engineer 1.pdf`) and **the acceptance criteria** (`Documents/User Acceptance Criteria.md`) are the source of truth. The gaps in them are recorded as assumptions in [DECISIONS.md](DECISIONS.md), section 3.
- **The plan** was kept as a task list during the session, not as a separate committed spec. The architecture decisions are in `DECISIONS.md` section 2 and in `CLAUDE.md`.
- [fill in: if you wrote a separate plan or spec file, link it here]

## 4. Key prompts and moments that shaped the solution

1. **Rules before code.** `CLAUDE.md` was written before any feature. That kept MVVM and Clean, protocol boundaries, and the no-hardcoding rule in place from the first file, rather than added afterwards.
2. **A replaceable data source.** The brief says the product data source will change. A `ProductSource` interface on the backend, with the Fake Store mapping in one adapter, shaped the layers.
3. **The backend as the only route to Fake Store.** The brief forbids direct client calls. `FakeStoreClient` sits behind `ProductService` and the HTTP layer, so the rule holds in code.
4. **Build each feature, then test it in the Simulator, then fix.** Each feature (Home, categories, search, product page, enquiry) was run in the Simulator and fixed in a loop until it matched the acceptance criteria, rather than tested once at the end.
5. **A criteria audit before submitting.** The request was to check every requirement in the brief, the criteria and `CLAUDE.md`, test each scenario, and fix what failed. It found the gaps listed in section 5.

[fill in: replace or confirm each item against your own prompts, and add the exact wording you want to share.]

## 5. Where the AI got something wrong, and how I caught it

Each of these was written by the AI, and caught by a test, a screen check, or a review against the criteria:

- **Oversized enquiry body returned 500, not 413.** The error handler did not map the body parser's "too large" error. Caught by sending a 20 KB body to `POST /enquiries`. Fixed in `backend/src/http/app.ts`, with a test.
- **Required fields lost their "required" status for VoiceOver.** When the visible labels dropped "(required)", the spoken labels lost it too. Caught by checking criterion 30 in the audit. Fixed: each field now reads "required" or "optional".
- **The featured count was in two places.** The iOS app capped Home at a hard-coded 5 as well as the backend's `FEATURED_COUNT`. Caught by the `CLAUDE.md` no-hardcoding rule. Fixed: the backend caps the list, and the app shows what it receives.
- **A failed categories request hid the section silently.** Caught on the Simulator with the backend stopped. Fixed: the section shows a message and a retry. A stale-featured notice was added at the same time, using a flag that the repository now returns.
- **The Message editor drew a black box in dark mode.** Caught on a dark-mode screenshot. Fixed by hiding the editor's own background.
- **`.DS_Store` files were staged in an early commit.** Caught in `git status`. Fixed by unstaging them and excluding them from later commits.
- **Stale documents.** The earlier notes in this file and in `DECISIONS.md` gave test counts and claims that no longer matched the code (for example, "phone required" and an SMTP catcher that was never built). Caught in the audit. Both documents were rewritten against the current code.
- **Home reloaded on every return.** `load()` on Home ran each time the view appeared, so coming back from a product page or a category page reloaded the data when it was not needed. Caught by [fill in: how you noticed it]. Fixed in [fill in: file and change].

## 6. How I reviewed AI output

- Read each generated file before committing, and checked it against `CLAUDE.md` and the acceptance criteria.
- Backend: `npm test` runs 61 tests across 8 files, and `npm run typecheck` is clean. The enquiry and search endpoints were also run as a scenario matrix with curl: invalid and boundary inputs, malformed JSON, unknown products, oversized bodies, and encoded symbols.
- iOS: `xcodebuild test` runs 106 unit tests on the iPhone 17 Pro Simulator, all passing.
- Simulator checks: Home with live data; Home with the backend stopped (saved products with a notice, and a categories retry); recovery after the backend restarted; search failure with the typed text kept and a retry; the enquiry form with validation, the keyboard open and Submit working, and the thank-you screen; dark mode on the enquiry form.
- Not verified: landscape, VoiceOver and larger text sizes on a device. The product page in dark mode was not checked on the Simulator.

## 7. Time spent

See the time table in [DECISIONS.md](DECISIONS.md), section 7. [fill in the same totals here.]
