# Bajinka Academy

Responsive Flutter learner website and Android app. Login and the admin build are deferred.

## Learner features
- Expandable chapters with topics and breadcrumbs; eight original starter lessons and later draft outlines.
- Saved guest notes, code, input, attempts, revision queue and progress on the current device.
- Python worker runner with input, traceback, stop/time/output limits and behavioural output tests.
- 19 starter activities, progressive hints, classwork, homework, challenges and a project.
- Opening assessment, honest eligibility gates and downloadable progress PDFs.
- JSON backup and validated restore, resources, separate acknowledgements and data/privacy information.
- Responsive layout, dark mode, text size and optional device reminders.

Code and objective checks are local self-study evidence. Written explanations and design requirements need review. Full-course certificates remain locked while later lessons are drafts. No verified qualification or university endorsement is claimed.

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

## Admin and backend
`apps/admin` remains a local planning preview, not a secured production admin. `docs/PRODUCT_MAP.md` and `shared/course-map.json` describe the planned product. Supabase configuration is retained separately; the guest learner currently runs without cloud sync or login. Do not connect local draft editing to production without authentication, server-enforced roles and publishing controls.

Private Base44 course records have not been copied into this public learner. Only independently authored starter material and outlines are included.
