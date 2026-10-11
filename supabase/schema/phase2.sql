create table public.academy_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '' check (length(display_name) <= 120),
 last_topic text,
 study_reminders boolean not null default false,
 updated_at timestamptz not null default now()
);
create table public.academy_drafts (
 user_id uuid not null references auth.users(id) on delete cascade,
 topic_id text not null check(length(topic_id) between 1 and 200),
 notes text not null default '' check(length(notes) <= 200000),
 code text not null default '' check(length(code) <= 200000),
 revision bigint not null default 1,
 updated_at timestamptz not null default now(),
 primary key(user_id,topic_id)
);
create table public.academy_activities (
 id text primary key,
 course_id text not null,
 topic_id text not null,
 title text not null,
 required boolean not null default true,
 published boolean not null default false
);
create table public.academy_progress (
 user_id uuid not null references auth.users(id) on delete cascade,
 activity_id text not null references public.academy_activities(id),
 completed_at timestamptz,
 evidence_basis text not null check(evidence_basis in ('self_reviewed','test_checked','reviewer_checked')),
 points integer not null default 0 check(points >= 0),
 primary key(user_id,activity_id)
);
alter table public.academy_profiles enable row level security;
alter table public.academy_drafts enable row level security;
alter table public.academy_activities enable row level security;
alter table public.academy_progress enable row level security;
create policy profile_owner on public.academy_profiles for all to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy draft_owner on public.academy_drafts for all to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy published_activities on public.academy_activities for select to anon,authenticated using (published);
create policy own_progress on public.academy_progress for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.academy_profiles,public.academy_drafts,public.academy_progress,public.academy_activities from anon,authenticated;
grant select,insert,update,delete on public.academy_profiles,public.academy_drafts to authenticated;
grant select on public.academy_progress to authenticated;
grant select on public.academy_activities to anon,authenticated;
create function public.academy_save_draft(p_topic text,p_notes text,p_code text,p_revision bigint)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare saved public.academy_drafts;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if p_revision = 0 then
  insert into public.academy_drafts(user_id,topic_id,notes,code)
  values(auth.uid(),p_topic,p_notes,p_code)
  on conflict(user_id,topic_id) do nothing returning * into saved;
 else
  update public.academy_drafts set notes=p_notes,code=p_code,revision=revision+1,updated_at=now()
  where user_id=auth.uid() and topic_id=p_topic and revision=p_revision
  returning * into saved;
 end if;
 if saved.user_id is null then raise exception 'DRAFT_CONFLICT'; end if;
 return to_jsonb(saved);
end $$;
revoke execute on function public.academy_save_draft(text,text,text,bigint) from public,anon;
grant execute on function public.academy_save_draft(text,text,text,bigint) to authenticated;
