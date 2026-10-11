# Phase 1 product map

## Architecture
Flutter web and Android learner clients and a separate Vercel admin share one Supabase backend. This phase is a navigable interface and specification. Authentication, cross-device persistence, execution, notifications, publishing and certificate generation follow in later phases.

## Learner navigation
Home: continue learning, genuine progress, review queue, notifications.
Courses → course overview → chapters → topics → lesson workspace.
Lesson workspace: targets; detailed explanation; examples; resources; private notes; classwork; homework; unfamiliar challenge; reflection; completion evidence.
Practice: A–D choices, written answers, tracing, debugging and code; question-specific hints; explicit solution reveal; attempt history.
Projects: files, written explanation, requirements, tests, rubric, evidence and versions.
Notebook: lesson-linked notes, general notes, search, export, recoverable drafts.
Assessments: chapter and final exams, fresh attempts, latest/best results, review status.
Progress: completed versus mastered, weak topics, points ledger, journey history.
Certificates: locked reasons, eligible journey, confirmed name/dates, preview, PDF download and permanent history.
Resources: PDFs, links, videos; reading position and topic links.
Settings: theme, accessibility, reminders, account, privacy, export and deletion requests.
Footer and Settings: Sources & Acknowledgements, Privacy Policy, Terms, Accessibility.
Phone: compact drawer, stacked reading/work areas, full-screen code editor. Laptop: persistent sidebar, wide reading space and split workspace where appropriate. Keyboard and screen-reader navigation required.

## Admin navigation
Overview: real content counts, draft status, review queue and system health.
Courses: create, reorder, archive, requirements, version and publication state.
Curriculum: chapter/topic tree, targets, lesson bodies, examples and output, resources, prerequisites and revision guidance.
Question bank: stable ID, topic, activity category, question type, prompt, marks, requirement, options A–D where appropriate, correct option IDs, accepted answers, tolerance, case sensitivity, code fixtures/tests, rubric, progressive hints, worked solution, source and version.
Every topic needs classwork, homework and an unfamiliar challenge before full publication. Questions are supplied by the author; the app never invents them.
Assessments: authored question selection, threshold, required reviews, hint policy, retakes, version and publication checks.
Projects: cumulative requirements, files, rubric, test plan and review criteria.
Learners/reviews: authorised evidence access, feedback and appeals. Private notebook contents remain learner-owned; no general admin browsing of private notes.
Certificates: per-course templates, requirements, review basis, issue/revoke history, original branding.
Sources: exact source URLs, author/institution, licence, adaptation/reproduction status and required nearby attribution. List only actually used sources publicly; candidate sources stay drafts.
Policy pages: separate editors for Sources & Acknowledgements, Privacy Policy, Terms and Accessibility, with draft, preview, publication version and effective date. Privacy includes data collection, purposes, storage, processors, retention, rights and contact information supplied by the operator. Never invent legal promises. Privacy may link acknowledgements but does not replace it.
Announcements: targeted content, scheduled publish, notification consent and delivery history.
Settings: role management, branding, course languages, notification configuration and feature flags. Billing/ads postponed.
Audit log: actor, action, entity, version and time; no secrets or full private submissions in logs.

## Marking contract
Single choice: admin-defined correct option ID; option labels do not determine correctness.
Multiple choice: admin chooses exact-set or explicitly documented partial-credit scoring.
Short writing: accepted answers or numeric tolerance only when the question has an objectively bounded answer; normalisation rules explicit.
Long writing: rubric review by learner/reviewer. Keyword presence alone cannot certify understanding. Optional AI feedback remains advisory and cannot issue grades/certificates.
Code: behaviour tests and explicitly stated technique requirements; accept alternative correct implementations. Python sandbox is a later phase. Preserve prompts separately from result output, reset fixtures per case, cap output, stop runaway code and expose no credentials.
Each result records answer, question version, marking configuration, score, feedback, help used and evidence basis. Infrastructure failure is not a failed learner answer.
Admin preview must show expected scoring before publication. Validate reference solutions against all authored cases. No fake automatic scores in Phase 1.

## Data entities
Profile, RoleMembership, Course, Chapter, Topic, ContentVersion, Resource, TopicResource, Question, QuestionVersion, Assessment, AssessmentQuestion, Journey, TopicProgress, PrivateNote, Submission, CodeFile, SavedVersion, Attempt, QuestionAttempt, TestResult, RubricReview, WeakTopic, PointAward, CertificateTemplate, CertificateRecord, PolicyPage, SourceReference, Announcement, NotificationPreference, NotificationDelivery, AuditEvent.
Foreign keys and stable IDs; imports upsert without erasing learner work. Notes and files scoped to owner. Version snapshots freeze the assessed requirements. Award unique key: journey + activity + award type. Certificate IDs and issue dates immutable on re-download.

## Permissions to implement before backend writes
Visitor: only published public catalogue/policy pages.
Learner: published learning content; own notes, work, attempts, progress and certificates. No answer keys in learner-facing assessment payloads before permitted reveal.
Content editor: draft authoring and preview; cannot grant roles or issue unsupported results.
Reviewer: specifically assigned submissions and rubric feedback; no private notebook access.
Admin: content publication, templates, operator settings and audited role administration.
Server-enforced RLS and protected functions; user-editable profile data never authorises roles. No service-role key in either frontend. Role changes restricted to trusted server operations.

## Completion and certificates
Course must be fully published. Required activities complete, chapter/final thresholds met, required reviews done and final project accepted. User enters name and confirms start/end dates; validate ordering; preview original per-course certificate. Issuer: Bajinka Academy; independent-study record, actual review basis, no university endorsement. Retakes create fresh journeys and preserve prior records. Points are engagement, not accreditation.

## Release phases
1. Map and navigable responsive shells (this commit).
2. Auth, database permissions, roles and persistent drafts.
3. Admin authoring, validated imports, sources/policy publishing and learner delivery.
4. Notes, code/writing workspace, files, autosave, recovery and versions.
5. Authored practice, marking, isolated Python runner, challenges and cumulative assessments.
6. Progress, revision, journeys, certificates and opt-in notifications.
7. End-to-end verification, accessible mobile/web release and APK signing. Later: additional languages, subscriptions and carefully placed ads.
