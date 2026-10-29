# Elsepin current handoff

Updated 28 October 2026. Read AGENTS.md, inspect status and preserve newer work.

## Current state
Private Elsepin source on main; public downloads/help in Elsepin-Releases. Development version 2.6.1 (60); published version remains 2.6.0. User authorized an unpublished release draft only. No IPA builds or publication without a new request.

## Completed appearance changes
Bloom is fresh/reset default; Abyss maps to Bloom for stored choices and old backups. Eight selectable themes, all thirteen icons retained. Rounded/compact shared presentation retains accessibility categories. Only surface override remains (Theme default by default, Solid, Liquid Glass); color mode follows theme. Old typography/color backup fields decode but do not affect presentation. Library data, identities, keys and full Elsepin capabilities remain intact. No Veypax gates.

## Evidence and remaining checks
410 Swift tests passed using Swift 6.4 in WSL, including backup migration/round trips. 14 Python script tests passed; appearance, app identity and helper archive checks passed. Website catalog generation passed (eight themes, thirteen icons); not deployed. Logs: .build/appearance-swift.log and .build/appearance-python-final.log.
These edits have NOT been compiled with the iOS SDK. The current GitHub workflow always packages an IPA and was deliberately not triggered. Next authorized native build must regenerate from project.yml and validate both targets, followed by iPhone import/appearance acceptance. Do not describe this source as natively build-verified or publish the older IPA as 2.6.1.
Last native success 40460137350 applies to the prior 2.6.0 baseline, not these changes. Physical-device/provider/accessibility/battery acceptance remains separate.

## Navigation and continuity
APP-MAP.md identifies feature ownership and appearance migration paths. BACKUPS.md describes import rules. CHANGE-LEDGER.md records evidence; docs/releases/2.6.1-DRAFT.md is the release text. CHAT-WORKFLOW.md covers sparse optional delegation.
The deleted arena branch remains deleted. Its saved bundle .build/elsepin-arena-3430259.bundle is recovery history only; reviewed appearance work has now been explicitly reapplied and corrected under the user's new authorization. Veypax is a separate repository with its own verified handoff.
