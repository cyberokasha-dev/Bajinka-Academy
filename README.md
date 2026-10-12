# Bajinka Academy

Responsive Flutter learner website and Android app. Learner interface only; course content has been cleared.

## Learner features
- Expandable chapters with topics and breadcrumbs; 43 retained topic slots; the first 14 have lessons and activity workspaces.
- My Files stores manually saved versions grouped by chapter, topic and activity. Save in app and Download are separate; Run never downloads a file.
- Supabase account login and cloud-only storage for notes, code, input, terminal history/transcripts, attempts, preferences, revision and progress. Login sessions are not persisted; sign in again after reopening.
- Large Python workspace with fixed controls, independent desktop panes, mobile Code/Terminal tabs and full-screen mode.
- Persistent Python shell with multiline blocks, expression output, saved command history and interactive top-level input(). Input inside synchronous functions and scripts uses the supplied input box.
- Fresh workers for scripts/homework checks, traceback, stop/time/output limits, function harnesses and exact/normalized/numeric output comparisons.
- Homework workspaces bind a unique activity ID to their own source, input values, expected output and comparison configuration. No questions have been added.
- Functions and Variables plus Conditionals: 14 lessons, 112 activities, 43 code activities with independent test cases, brief hints and question-specific automatic answer checks.
- Downloadable progress PDFs; new study records are locked while requirements are empty.
- JSON backup and validated restore, Python-file import/download, saved workspace output and line numbers with cursor position and automatic indentation.
- Issued opening study records retain their ID, date and learner details on re-download.
- Resources, separate acknowledgements and data/privacy information.
- Responsive layout, dark mode, text size and optional device reminders.

Code and objective checks are local self-study evidence. Written explanations and design requirements need review. Full-course certificates remain locked until full-course assessment and review requirements are published. No verified qualification or university endorsement is claimed.

## Run the learner
Install the Flutter version pinned in the workflows. In `apps/learner`:
```sh
flutter create --platforms=android,web --org=com.bajinka --project-name=bajinka_academy .
python ../../scripts/configure_learner_android.py
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
The platform generator supplies standard Android/web wrappers. The configuration script adds Android internet and optional notification permissions and desugaring. Preserve the committed library, assets and tests.

## Delivery
`.github/workflows/learner-pages.yml` validates and publishes the learner website on GitHub Pages. `learner-build.yml` validates the same code and builds web and a debug APK for device testing. Store signing/release packaging is still pending. Python requires internet on first use to download the pinned Pyodide runtime from jsDelivr.

## Content reset
Functions and Variables adapts the owner’s supplied material with corrections and app-specific execution instructions. The supplied files contained no Conditionals content; that chapter was independently authored within the existing outline. Later chapters remain empty. Chapter/topic IDs, navigation, visual layout, notes and code tools are retained. Old personal device records are not automatically read or uploaded. The separate admin application has been removed. Supabase Auth gates the production learner and RLS limits each account to its own cloud workspace.
