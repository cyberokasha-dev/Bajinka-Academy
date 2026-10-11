# Google setup — owner action

Learner client uses Supabase Google OAuth. No Google client secret belongs in Flutter or GitHub.

1. In Google Cloud create an OAuth web client and configure consent.
2. Google authorised redirect URI: `https://zesvwdewewylotohcsgn.supabase.co/auth/v1/callback`.
3. Supabase → Authentication → Providers → Google: enter client ID and secret and enable Google.
4. Supabase → Authentication → URL Configuration: site URL and allowed redirect URL must include `https://cyberokasha-dev.github.io/Bajinka-Academy/` (preserve trailing slash).
5. Test Google sign-in, refresh session, save/reopen a private draft and sign out.

Button uses the official Google multicolour G asset bundled locally, not a recreated letter. Source: https://developers.google.com/identity/images/g-logo.png; branding: https://developers.google.com/identity/branding-guidelines. Android OAuth callback wiring is deferred; its sign-in control directs learners to web until configured.

Phase 2 includes private profiles, autosaved topic notes/code, scoped local recovery, optimistic revision conflicts and Home progress from published activities. It does not publish lessons or create fake progress. Reminder setting records a preference only.
