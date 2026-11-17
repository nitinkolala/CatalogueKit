# AI usage notes

This file records how AI tools were used on this submission. It is a draft: items marked **[fill in]** need the author's own account before submission.

## 1. Tools and models

| Tool | Used for | Model |
| --- | --- | --- |
| Claude Code (CLI and desktop app) | Planning, reading the brief, generating and editing backend and iOS code, writing these documents | Claude Haiku 5.5 (`claude-haiku-5-5`) for this session. [fill in any other sessions and models] |
| [fill in any other tools, e.g. Xcode, Cursor, Copilot] | [fill in] | [fill in] |

No paid service or account is needed to run the solution. The AI tools were used only at development time, not in the product.

## 2. Agent instruction files

Committed to the repo:

- **`CLAUDE.md`** at the repo root. It sets the stack (Swift and Swift Concurrency on iOS, Node.js only if a backend is added), the MVVM and Clean architecture rules, SOLID guidance, caching and environment rules, the no-hardcoding rule, the validator rules (strict email, exactly 10 digits for mobile), the testing expectations, and repo hygiene (no `xcuserdata/`, `DerivedData/` or signing values committed).

The file was committed in three steps: `1172863` (initial architecture and rules), `04a11cc` (restored the init sections and added project rules) and `322e21d` (added the order flow testing rule). Those commits show the file evolving with the project.

No `AGENTS.md` or `.cursor/rules` file is in the repo.

## 3. Plan and spec

- **The brief** is the source of truth for acceptance criteria. Its gaps are recorded as assumptions in [DECISIONS.md](DECISIONS.md), section 3.
- **The plan** was kept as a task list during the session, not as a separate committed spec. The architecture decisions were written into `DECISIONS.md` section 2 and are reflected in `CLAUDE.md`.
- [fill in: if you wrote a separate plan or spec file, link it here]

## 4. Key prompts and moments that shaped the solution

These are candidates inferred from the commit history and the code, not verified prompt logs. [fill in: replace or confirm each one against your own prompts, and add the exact wording where you want to share it.]

1. **Setting the architecture rules first.** The project began with `CLAUDE.md` before any code. That made the agent follow MVVM + Clean, protocol boundaries and the no-hardcoding rule from the first file onward, instead of retrofitting them.
2. **Asking for a replaceable data source.** The brief says the product data source will change. Asking for a `ProductSource` interface on the backend, with the Fake Store mapping in one adapter, shaped the `domain/` and `data/` split.
3. **Requesting the backend as the only route to Fake Store.** The brief forbids direct client calls. Keeping `FakeStoreClient` behind `ProductService` and the HTTP layer enforces that rule in code.
4. **Asking for tests with each layer.** The backend has tests for ranking, the client mapping, the service, and the HTTP routes. The iOS side has tests for the repository, use case, view model and DTO mapping. [fill in: the prompt you used]
5. **[fill in: a moment you changed direction, e.g. dropping the disk cache on the backend, or choosing iOS over web.]**

## 5. Where the AI got something wrong, and how I caught it

I have not yet recorded a verified case in this submission. [fill in with real examples. Good candidates to check:]

- **Staged files that should not be committed.** `git status` shows `.DS_Store` files staged, and `CLAUDE.md` says not to commit that kind of file. This needs a fix before the PR. Fix: `git rm --cached .DS_Store Documents/.DS_Store`, then add a `.DS_Store` rule to `.gitignore` if one is missing.
- **Duplicated configuration.** The featured count (5) and cache TTL (300 s) appear in both `backend/src/config/config.ts` and `ios/.../Core/Constants.swift`. This breaks `CLAUDE.md`'s no-hardcoding rule and could drift. Caught on review.
- **[fill in: a bug the tests or a run caught, and what the AI had written.]**

## 6. How I reviewed AI output

- Read each generated file before committing, and checked it against `CLAUDE.md`.
- Ran the iOS unit tests with `xcodebuild test -scheme CatalogueKit -only-testing:CatalogueKitTests` on the iPhone 17 Pro Simulator: 16 passed, 0 failed, on the first run with no changes needed.
- Backend: `npm run typecheck` is clean and `npm test` passes 24 of 24 across 5 files, on Node 22.23.5, on the first run with no changes needed. Node was installed to `~/.local/node` from the official tarball, with its SHA-256 checked against Node's published SHASUMS file.
- Built and ran the iOS app in the Simulator. [fill in: result]
- Checked the acceptance criteria one by one against what the app does. [fill in: which ones are verified]

## 7. Time spent

See the time table in [DECISIONS.md](DECISIONS.md), section 7. [fill in the same totals here.]
