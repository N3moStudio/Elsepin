# Elsepin UI polish notes

Read this before applying new design skills or continuing the video-inspired
polish. Current implementation and device evidence are in [CURRENT-WORK](CURRENT-WORK.md).

## Product constraints

Keep the established Elsepin identity, eight themes, thirteen icons, Bloom/Solid
defaults and compact rounded presentation, including accessibility text sizes.
Keep the larger Settings identity card, swipe-revealed search, native navigation,
explicit movement confirmation, cancellation, backup compatibility and honest
provider status. Design advice is not permission to change these decisions.

Use Axiom for native implementation. The installed `unslop` skill supplements
visual review; its web-specific font, grayscale, 32–36px navigation, animation
and logo rules do not replace our native controls, touch targets, chosen colors,
icon artwork or Reduce Motion behavior. Preserve its upstream manual unchanged.
Do not remove options just to satisfy a choice-count rule.

## Sources reviewed — 30 October 2026

Three user-provided MP4s were inspected through sampled frames and local audio
transcription (automatic transcripts can contain recognition errors):

- Cecilia Kim's Nessie motion example, 54.9 seconds: changing numbers, major
  success feedback, loading placeholders, optional shader backgrounds and
  Reduce Motion/Low Power considerations.
- Design transformation roundup, 35.9 seconds: Damir Sokolovsky's dashboard
  example and his forthcoming-at-recording `unslop` skill.
- Motion UI Interface UX examples, 100.9 seconds: discoverable scrolling,
  modal focus, contextual notices, less typing, connected steps and fewer
  simultaneous choices. Its exact percentages and study claims were not
  independently verified and are not universal product requirements.

Installed [unslop by Damir Sokolovsky](https://github.com/heydamir/unslop),
CC BY 4.0, from commit `4652254daff586ff4739849395a127b56f7f8cc7` using the skill
installer. The installed directory is `C:/Users/naith/.codex/skills/unslop`.
Existing skills remain intact. Optional upstream snapshot/story scripts were
inspected, not executed. No image service, paid provider or plugin hook added.

## Direction

Product: an iPhone location tool with deliberate manual movement controls.
Character: calm, tactile, precise. World: maps and wayfinding. Visual emphasis:
the selected destination and the next useful action. Signature: connected steps
where a task actually has a sequence. Use the existing theme and component system.

## First local pass

| Before | After | Why |
| --- | --- | --- |
| Pairing instructions mention the Island before opening Settings; four dense paragraphs | Three numbered, connected steps in task order, with short headings | Makes the next action easier to locate without changing the native protocol |
| Pairing sheet paints a system background over the theme canvas | Existing themed screen background shows through | Matches the selected theme |
| Always-visible troubleshooting card | Removed; no Pairing help disclosure | User requested removal after reviewing the connected-steps preview |
| Separate plain capsule pairing actions | Existing `ShiftActionStyle` | Reuses theme shape, press feedback and Reduce Motion behavior |
| Route mode chips scroll horizontally without an indicator | Adaptive grid; a flexible single column at accessibility sizes | Keeps all five choices visible inside the existing Mode & speed disclosure |

Owners: `Locus/Features/Settings/PairOnDeviceView.swift` and
`Locus/Features/Routes/RoutePlannerSheet.swift`. No pairing/session engine,
Live Activity code, stored values, permission requests or imports changed.
The step numbers are instructions, not a fabricated progress/completion meter.

## Ideas deliberately held back

- No always-running shader, looping decoration or artificial loading delay.
- Keep native progress indicators where the result shape is unknown; skeletons
  are not automatically better for pairing or routing.
- Do not animate PINs, coordinates or continuously changing countdowns. Reserve
  number transitions for occasional user-triggered changes if a preview proves useful.
- Existing native dialogs already supply focus/dimming. Existing search,
  saved places and advanced disclosures already reduce typing and choices.

## Validation and next device check

### Build 63 activity follow-up

| Before | After | What this changes |
| --- | --- | --- |
| Large status headline, explanatory line, journey state, progress, distance, route name and repeated age | Route/name and distance/ETA lead; short update-status row; bounded timer and one-line labels | Reduces the stacked height visible in the user's clipped Island screenshot |
| Optional provider status can add multiple multiline blocks | Compact provider rows retain separate status and report age | Keeps Find My/Life360 evidence without implying an update command verified another app |
| Normal text hierarchy can crowd at accessibility sizes | Omit the optional route-name line at accessibility sizes; keep status and route progress | Gives the essential information space without globally reducing accessibility text |

This is source-level layout work; native/physical-device screenshots are still
needed for all variants. Pairing code, system Island background, privacy and
stale-state behavior are preserved. No decorative activity animation was added.

57 focused Swift tests passed: pairing activity, route planning, appearance and
backup compatibility. Both changed SwiftUI files passed Swift syntax parsing
on WSL. This does not type-check Apple SDK calls or validate native layout.
The conversational comparison passed browser checks at 320/390/736px and its
action/reset interactions; it is an illustrative mockup, not iPhone evidence.
Local evidence: `.build/video-review/` (ignored, not part of the app).

The subsequently authorized build 62 passed native compilation and all 551 CI
tests on run 41126221099; the exact Downloads IPA passed integrity/package checks.
Three pre-existing warnings remain, with no new UI diagnostics. Still check on
iPhone: all themes, small widths, accessibility sizes,
VoiceOver step order, pairing cancel/retry/background PIN delivery, and each
route mode's existing behavior. The delivered build 61 predates this pass.
No IPA, push, deployment or release was made during the initial polish pass.
The user subsequently requested build 62 in Downloads; its native evidence
is recorded in CURRENT-WORK and BUILD-HISTORY. Publication remains excluded.
