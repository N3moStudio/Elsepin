# Product workstreams and next decisions

Updated 26 October 2026. Planning record, not implemented entitlement changes.

## Recommended organization

Use two ongoing chats/projects: Elsepin (full public-facing app and website) and Veypax (all paid editions). Keep one Veypax source repository with Basic, Pro and Ultimate build configurations and a central feature entitlement table. Avoid three divergent copies. Read this handoff, the Product Atlas and Change Ledger instead of replaying the whole chat. Record source commits when porting shared fixes; review branding and entitlements before merging.

## Required paid-app reminder

- [ ] Require **Pro or Ultimate** for changing app icons and choosing multiple UI/theme designs. Basic uses a fixed icon and appearance. This latest request supersedes the earlier Basic-themes proposal; confirm final customer-facing wording before shipping.
- [ ] Keep unavailable features discoverable with a clear upgrade explanation, and enforce restrictions in action handlers as well as the UI, including widgets, imports and deep links.
- [ ] Preserve manual confirmation before widget-triggered movement for every tier.
- [ ] Keep driving, Dynamic Island/provider checks and cloud features Ultimate-only according to prior decisions. Pro allows walking/cycling routes.
- [ ] Verify the final paid entitlement matrix before building; this record does not change current app behavior.

Do not apply paid restrictions to Elsepin. Do not automatically copy private commercial configuration into public documentation. Separate chats are workspaces for discussion, not a reliable shared requirements database; shared versioned files are the handoff.
