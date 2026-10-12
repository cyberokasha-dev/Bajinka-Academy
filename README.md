# Bajinka Academy

Responsive Flutter learner website and Android app. Learner interface only; course content has been cleared.

## Learner features
- Expandable chapters with topics and breadcrumbs; 43 retained topic slots and embedded Python terminals.
- Saved guest notes, code, input, attempts, revision queue and progress on the current device.
- Large Python workspace with fixed controls, independent desktop panes, mobile Code/Terminal tabs and full-screen mode.
- Persistent Python shell with multiline blocks, expression output, saved command history and interactive top-level input(). Input inside synchronous functions and scripts uses the supplied input box.
- Fresh workers for scripts/homework checks, traceback, stop/time/output limits, function harnesses and exact/normalized/numeric output comparisons.
- Homework workspaces bind a unique activity ID to their own source, input values, expected output and comparison configuration. No questions have been added.
- Empty lesson, classwork, homework, challenge, project and assessment areas.
- Downloadable progress PDFs; new study records are locked while requirements are empty.
- JSON backup and validated restore, Python-file import/download, saved workspace output.
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
Teaching text, examples, questions, assignments, hints, solutions, challenges and projects have been removed. Chapter/topic IDs, navigation, visual layout, notes and code tools are retained. Existing personal device records are preserved. The separate admin application has been removed. Login and cloud sync remain deferred.
