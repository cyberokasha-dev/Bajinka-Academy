# Verification status

The repository contains the Flutter learner app only. There is no separate admin application, admin route, admin build workflow, or admin backend in the current source tree. Role names inside Python examples are teaching data, not app permissions.

Executed locally for the Chapters 0–3 content update:
- 22 lesson examples and 258 answer cases through the actual Python runner wrapper.
- Incorrect answer rejection.
- Runner comparison rules.
- Worker input, harness, error reporting, output limits and filesystem checks.
- Persistent shell state, blocks, input and traceback checks.
- Workspace save, marking and explicit-only download checks.
- Activity ID uniqueness and all five activity sections for each of 22 authored topics.

Not executed locally:
- Flutter analysis, widget tests, web or APK build: Flutter SDK unavailable.
- Live browser layout and interaction testing.

GitHub learner workflows run Flutter analysis, tests and builds. Consult their actual run results before treating those checks as passed. Full-course certification remains locked while later course requirements are incomplete.
