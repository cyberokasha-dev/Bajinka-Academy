# Bajinka Academy

Phase 1: responsive learner interface and admin planning workspace. All curriculum content remains draft. No real grades, certificates, login or publishing are claimed.

## Repository
- `apps/learner`: Flutter learner shell for web and Android.
- `apps/admin`: dependency-free admin planning website, ready for Vercel static hosting.
- `shared/course-map.json`: versioned course catalogue and supported question/marking types.
- `docs/PRODUCT_MAP.md`: full product, data and permissions map.

## Run learner
Install Flutter stable, then inside `apps/learner` run:
```sh
flutter create --platforms=android,web --org=com.bajinka --project-name=bajinka_academy .
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
The platform generation command supplies standard Android/web wrappers; preserve the committed lib and test files. APK signing and release packaging are later phases.

## Run admin
```sh
python3 -m http.server 8080 --directory apps/admin
```
Vercel project root: `apps/admin`; framework: Other; no build command; output directory: `.`. This is a local planning preview, not a secured production admin. No backend credentials are included.

## Next phase
Supabase authentication, server-enforced roles, schema, ownership policies and versioned publishing. Supabase project: `zesvwdewewylotohcsgn`. Do not connect the preview's local draft editing to production without these controls.
