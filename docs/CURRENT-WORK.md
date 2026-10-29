# Elsepin current handoff

Updated 28 October 2026. Verify Git status and source before acting.

- Source repository: private Elsepin. Public downloads/help: Elsepin-Releases.
- Source project version is 2.6.0; public release was published in the prior workstream. Recheck GitHub before making live-release claims.
- Website: https://elsepin.onrender.com (not reverified by this documentation task).
- This task adds repository instructions and chat/delegation guidance only. No app changes, IPA build, release or website deployment authorized by this setup.
- Veypax is separate at the sibling `Veypax (Basic - Ultimate)` directory. Its new pending appearance request has not been applied to Elsepin; do not infer cross-product changes.
- Use [BUILDING.md](BUILDING.md), [APP-MAP.md](APP-MAP.md), [CHAT-WORKFLOW.md](CHAT-WORKFLOW.md) and the ledger as needed. The older WORKSTREAM-HANDOFF.md is historical planning; current Veypax policy is in that repository's docs/PRO-PLAN.md.

## Chat intake — 28 October 2026

- Objective: establish this chat as the full public-facing Elsepin workstream; preserve existing local work. No implementation request yet.
- Read AGENTS.md, this handoff, CHAT-WORKFLOW.md, APP-MAP.md, BRAND-MAP.md and relevant ledger/build references.
- Local branch `main`, HEAD `c9c3203`; live `git ls-remote` confirmed remote main at the same full commit on intake.
- Existing local work preserved: modified `docs/WORKSTREAM-HANDOFF.md`; untracked `AGENTS.md`, `docs/CHAT-WORKFLOW.md`, and this file. This intake only appends to this handoff.
- Verified public GitHub latest release: `v2.6.0`, published 27 October 2026, neither draft nor prerelease; asset `Elsepin-2.6.0.ipa`, 18,199,999 bytes. Asset contents/hash were not revalidated. Source app/extension version is 2.6.0 (59).
- Website HEAD request returned HTTP 200; rendered content and deployed source revision were not checked.
- Outstanding: physical-device/provider, accessibility/gesture and measured battery acceptance. Older APP-MAP.md/BUILDING.md and ledger passages retain historical Shift/unreleased wording; reconcile when documentation maintenance is requested. No new app implementation is assigned.
- Product boundary: Elsepin remains the full app. Veypax paid restrictions and its latest Bloom/compact/rounded changes must not be copied into Elsepin implicitly; the user's current clarification supersedes the older pending-appearance wording above.
- Validation this turn: read-only source/status/remote checks; no tests, IPA build, push, publication or deployment. GitHub CLI was unavailable on PATH, so release metadata was checked through the public GitHub API.
