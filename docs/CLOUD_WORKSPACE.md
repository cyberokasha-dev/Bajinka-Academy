# Cloud workspace

The production learner requires Supabase email/password authentication. Create your account in the app, confirm the email if requested, then sign in. The SDK keeps its session only in memory. No learner data is automatically stored in browser local storage or Android preferences.

An account owns one JSON workspace in `academy_workspaces`, containing notes, source, inputs, run output, shell transcript/history, preferences, progress, attempts, reviews and issued study records. RLS restricts SELECT, INSERT and UPDATE to the authenticated owner. The app checks the current user before every operation. Anonymous access is revoked.

The `academy_save_workspace` RPC uses an expected revision. Stale writes raise WORKSPACE_CONFLICT rather than overwrite newer work. Saves are serialized and later edits coalesced. Network errors leave the current workspace open with Unsaved changes. Retry explicitly; no local fallback exists. A conflict offers export and a confirmed reload of the cloud copy.

Live Python variables and temporary runtime files last only for the active shell worker. Saved history is never automatically executed. Scripts and homework tests run in fresh workers. No full-course examination or qualification is published.

Database verification used a rolled-back transaction with assertions for create, update, stale revision rejection, other-user isolation and anonymous denial. No test accounts or records were retained.
