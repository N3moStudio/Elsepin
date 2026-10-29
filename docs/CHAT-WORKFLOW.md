# Working efficiently across chats

Read this when starting a new workstream, delegating supporting work, or handing off.
Use two product workstreams: Elsepin and Veypax. All Veypax editions stay in one
repository with one feature policy; do not fork three independent code copies.
Chats do not automatically share their context. Repository files are the handoff.

## Starting and finishing

Read AGENTS.md and CURRENT-WORK.md, then verify the branch, working-tree changes
and relevant source before acting. Read linked specialist docs when the task needs
them. Preserve unfinished changes; never interpret a handoff as new permission to
push, build an IPA, publish or delete. The latest human instruction wins.

At a meaningful stopping point update CURRENT-WORK.md with the date, objective,
completed work, pending work, changed paths, test evidence and limitations. Record
commit IDs when syncing shared code between products. Keep long historical evidence
in the existing change ledger, not in the startup handoff. Do not copy secrets or
entire conversations into it. Every claim of success needs actual evidence.

Use local search/scripts for deterministic lookups. Reuse unchanged evidence and
saved logs; expand investigation and tests whenever correctness requires it. Do
not impose reading limits, lower reasoning quality or suppress necessary checks.

## Optional external supporting analysis on this Windows workstation

Before use, read `C:/Users/naith/.codex/delegation/README.md` and run
`python C:/Users/naith/.codex/delegation/delegate.py status`. These local paths are
optional workstation tooling, not repository build dependencies. If absent, continue
normally. No API keys belong in the repository or handoff.

The user authorizes bounded supporting analysis through the already configured
Groq/Gemini workers. Use Groq for focused code analysis/test suggestions, Gemini for
simple extraction/summaries. Prefer one useful worker over duplicate reviews. Send
only relevant selected non-sensitive material, never credentials or whole chats.
Create job JSON under ignored `.build/`, run `check` before `run`, and inspect saved
usage/completion evidence. Existing runner caching avoids identical repeat jobs.
Quota errors stop; no automatic retries, paid fallback, provider switching or billing
changes. Account free-tier status cannot be guaranteed by a model name or key.

Workers cannot edit or inspect the repository themselves. The lead agent owns
architecture, security, changes, verification and final review. Reject unsupported
findings. Native subagents still consume Codex usage. Do not promise percentage
savings without measuring representative tasks including review overhead.
