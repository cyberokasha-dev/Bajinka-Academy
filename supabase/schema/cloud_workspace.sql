-- Cloud learner workspace. Existing phase2 tables remain intact.
create table if not exists public.academy_workspaces (
 user_id uuid primary key references auth.users(id) on delete cascade,
 payload jsonb not null check (jsonb_typeof(payload)='object' and octet_length(payload::text)<=5000000),
 revision bigint not null default 1 check (revision>0),
 updated_at timestamptz not null default now()
);
alter table public.academy_workspaces enable row level security;
create policy workspace_owner_select on public.academy_workspaces for select to authenticated using ((select auth.uid())=user_id);
create policy workspace_owner_insert on public.academy_workspaces for insert to authenticated with check ((select auth.uid())=user_id);
create policy workspace_owner_update on public.academy_workspaces for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
revoke all on public.academy_workspaces from public,anon,authenticated;
grant select,insert,update on public.academy_workspaces to authenticated;
create or replace function public.academy_save_workspace(p_payload jsonb,p_revision bigint)
returns bigint language plpgsql security invoker set search_path='' as $$
declare v_revision bigint;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if p_payload->>'format' is distinct from 'bajinka-device-backup' then raise exception 'Invalid workspace format'; end if;
 if p_revision=0 then
  insert into public.academy_workspaces(user_id,payload) values(auth.uid(),p_payload)
  on conflict(user_id) do nothing returning revision into v_revision;
 else
  update public.academy_workspaces set payload=p_payload,revision=revision+1,updated_at=now()
  where user_id=auth.uid() and revision=p_revision returning revision into v_revision;
 end if;
 if v_revision is null then raise exception 'WORKSPACE_CONFLICT'; end if;
 return v_revision;
end $$;
revoke execute on function public.academy_save_workspace(jsonb,bigint) from public,anon;
grant execute on function public.academy_save_workspace(jsonb,bigint) to authenticated;
