# Bajinka Workbench redesign

## Product direction
This GitHub Flutter app is moving from a course-first academy to a practical personal workbench: **Build → Document → Showcase → Learn when needed**. The Base44 learning product is separate.

## Target navigation
Dashboard; Python Studio; Cybersecurity Lab; Projects; Notebook; Portfolio; My Files; Career Hub; Reference Library; Settings.

## First implementation slice in this branch
- Workbench dashboard and navigation.
- Python Studio entry point reusing the existing Pyodide runner.
- Project creation, editing, deletion, category, objective, status, technology and repository/demo URL fields. Project records use the existing signed-in workspace record.
- Defensive fictional lab checklists for network design, SOC investigation, email triage, firewall policy, incident response and security audit, with saved case notes.
- Portfolio view of completed projects.
- Career Hub feature roadmap.

## Important technical boundaries
Pyodide is a browser Python runtime, not a Linux shell. Package support must be compatible with the Pyodide runtime. General desktop Python requires a separate isolated execution service. Cybersecurity labs are local defensive simulations only. Existing account data is not deleted.

## Not yet complete
- Independent technical notebook with tags, project links, snippets and search.
- General project file/asset library.
- Persistent checklist state and exportable investigation reports.
- Private Supabase Storage bucket, owner-scoped RLS and certificate/evidence upload metadata.
- Evidence-based professional achievements.
- Functional CV, cover-letter, apprenticeship and interview tools.
- Migration/archive of course-specific screens and safe migration of useful legacy code/notes.
- Automated tests, flutter analyze, widget tests and production build verification.
