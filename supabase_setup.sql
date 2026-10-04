-- Presenter Script cloud sync. Run once in Supabase SQL Editor.
-- Each signed-in user owns one private script collection.
begin;

create table if not exists public.presenter_documents (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  version bigint not null default 1 check (version > 0),
  updated_at timestamptz not null default now()
);

alter table public.presenter_documents enable row level security;
revoke all on public.presenter_documents from public, anon, authenticated;
grant select, insert, update on public.presenter_documents to authenticated;

drop policy if exists presenter_read_own on public.presenter_documents;
create policy presenter_read_own on public.presenter_documents
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists presenter_insert_own on public.presenter_documents;
create policy presenter_insert_own on public.presenter_documents
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists presenter_update_own on public.presenter_documents;
create policy presenter_update_own on public.presenter_documents
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Compare-and-save in a single database transaction; stale devices cannot
-- silently overwrite a newer version. RLS applies to every statement.
create or replace function public.save_presenter_document(
  p_data jsonb, p_expected_version bigint
) returns jsonb
language plpgsql security invoker set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_row public.presenter_documents%rowtype;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_expected_version is null or p_expected_version < 0 then
    raise exception 'Invalid version';
  end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object'
     or jsonb_typeof(p_data->'slides') is distinct from 'array' then
    raise exception 'Invalid document';
  end if;
  if jsonb_array_length(p_data->'slides') < 1 then raise exception 'No slides'; end if;
  if octet_length(p_data::text) > 2000000 then raise exception 'Document exceeds 2MB'; end if;

  if p_expected_version = 0 then
    insert into public.presenter_documents (user_id, data)
    values (v_user, p_data) on conflict (user_id) do nothing
    returning * into v_row;
    if found then
      return jsonb_build_object('conflict', false, 'version', v_row.version,
        'updated_at', v_row.updated_at);
    end if;
  else
    update public.presenter_documents
    set data = p_data, version = version + 1, updated_at = now()
    where user_id = v_user and version = p_expected_version
    returning * into v_row;
    if found then
      return jsonb_build_object('conflict', false, 'version', v_row.version,
        'updated_at', v_row.updated_at);
    end if;
  end if;
  select * into v_row from public.presenter_documents where user_id = v_user;
  return jsonb_build_object('conflict', true, 'version', coalesce(v_row.version, 0),
    'data', v_row.data, 'updated_at', v_row.updated_at);
end;
$$;

revoke all on function public.save_presenter_document(jsonb, bigint) from public, anon;
grant execute on function public.save_presenter_document(jsonb, bigint) to authenticated;

-- Transactional permission checks: temporary users/rows never survive commit.
savepoint security_validation;
insert into auth.users (id) values
 ('10000000-0000-4000-8000-000000000001'),
 ('10000000-0000-4000-8000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
do $$
declare r jsonb;
begin
  r := public.save_presenter_document('{"slides":[{"title":"test-A"}]}', 0);
  if r->>'conflict' <> 'false' or (r->>'version')::bigint <> 1 then
    raise exception 'Own document creation failed';
  end if;
  r := public.save_presenter_document('{"slides":[{"title":"new-A"}]}', 1);
  if r->>'conflict' <> 'false' or (r->>'version')::bigint <> 2 then
    raise exception 'Own document update failed';
  end if;
  r := public.save_presenter_document('{"slides":[{"title":"stale-A"}]}', 1);
  if r->>'conflict' <> 'true' then raise exception 'Stale overwrite was allowed'; end if;
end;
$$;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
do $$
declare n integer;
begin
  select count(*) into n from public.presenter_documents;
  if n <> 0 then raise exception 'Another user can read private documents'; end if;
  update public.presenter_documents set version = version + 1
    where user_id = '10000000-0000-4000-8000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'Another user can edit private documents'; end if;
  begin
    insert into public.presenter_documents (user_id, data)
      values ('10000000-0000-4000-8000-000000000001', '{"slides":[]}');
    raise exception 'Another user can insert private documents';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
set local role anon;
do $$
begin
  begin
    perform 1 from public.presenter_documents;
    raise exception 'Anonymous read was allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.save_presenter_document('{"slides":[{}]}', 0);
    raise exception 'Anonymous write was allowed';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
rollback to security_validation;
commit;
