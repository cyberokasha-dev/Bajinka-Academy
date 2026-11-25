# Bajinka Workbench redesign

## Product direction
This GitHub Flutter app is a practical personal workbench: **Build → Document → Showcase → Learn when needed**. The separate Base44 learning product is not part of this repository.

## Current navigation
Dashboard; Python Studio; Cybersecurity Lab; Projects; Notebook; Portfolio; My Files; Career Hub; Reference Library; Settings; Sources & Acknowledgements; Privacy Policy.

## Implemented in this branch
- Workbench dashboard and practical-tool navigation. Course and assessment items are not part of the visible navigation.
- Python Studio reuses the Pyodide runner. On desktop, the editor and terminal/output are side-by-side; on narrow screens they switch to Code and Terminal tabs. The shell keeps Python variables for the session. Its general workspace ID is supported by filename generation, My Files and backup validation. Web and Android/iOS WebView are supported; the Linux desktop fallback is informational only.
- Project creation, editing, deletion, category, objective, status, technologies and repository/demo URL fields. Project records are saved in the signed-in workbench record.
- Defensive fictional cybersecurity checklists for network design, SOC investigation, email review, firewall policy, incident response and security audit. Case notes and checklist selections save separately.
- My Files lists saved Python/text versions independently of old course-topic groupings.
- Portfolio lists projects marked Completed.
- Career Hub is a clearly labelled feature roadmap, not a completed CV or job-application tool.
- Widget and storage regression tests cover the current workbench navigation, project creation, Python workspace routing, cybersecurity checklist persistence and generic workbench backup/file round trips.

## Runtime and data boundaries
Pyodide is a browser Python runtime, not a Linux shell. Only packages compatible with the Pyodide runtime can run. General desktop Python requires a separate isolated execution service. Cybersecurity labs are local fictional defensive simulations; they do not contact external systems or use real credentials. Signed-in workspace data is stored through the existing Supabase account workspace. Guest sessions are temporary. Existing records are not automatically deleted.

## Still incomplete
- A full notebook with multiple entries, tags, project links, snippets and search; the current Notebook provides a general notes space.
- A general project asset library for folders and arbitrary attachments; My Files currently handles saved Python/text versions.
- Private Supabase Storage uploads for certificates and evidence, issuer/date metadata and verification links.
- Evidence-based achievements and external portfolio publishing.
- Functional CV, cover-letter, apprenticeship-tracking and interview-preparation tools.
- A dedicated Linux/container Python runtime, multi-file project editor, syntax-aware IDE features and package-management workflow. The current editor is a plain text editor; the Python shell is not an operating-system terminal.
- Full removal of dormant course-specific implementation and migration of any useful legacy notes/files. The old course data model remains as a compatibility layer; it is not exposed in the new navigation.
- A complete functional and privacy review before public release.

## CI acceptance
The pull request workflow must pass Flutter analysis, all Dart/widget tests, the repository's runner and content checks, the web build and the Android debug APK build. Do not merge while any required job is failing or incomplete.
