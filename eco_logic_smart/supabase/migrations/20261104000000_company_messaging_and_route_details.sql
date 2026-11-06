-- Add detailed pickup/delivery addresses and transport mode for shared routes.
alter table public.logistics_requests
  add column if not exists origin_address text not null default '',
  add column if not exists destination_address text not null default '',
  add column if not exists transport_type text not null default 'Camión',
  add column if not exists recipient_company_id uuid
    references public.company_profiles(id) on delete set null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'logistics_recipient_not_owner'
      and conrelid = 'public.logistics_requests'::regclass
  ) then
    alter table public.logistics_requests
      add constraint logistics_recipient_not_owner
      check (recipient_company_id is null or recipient_company_id <> company_id);
  end if;
end;
$$;

drop policy if exists "Authenticated users view open routes"
  on public.logistics_requests;
drop policy if exists "Companies view own and open routes"
  on public.logistics_requests;
drop policy if exists "Companies view routes shared or sent directly"
  on public.logistics_requests;
create policy "Companies view routes shared or sent directly"
  on public.logistics_requests for select to authenticated
  using (
    company_id = (select auth.uid())
    or recipient_company_id = (select auth.uid())
    or (recipient_company_id is null and status in ('Abierta', 'En coordinación'))
  );

create or replace function public.respond_direct_route_proposal(
  p_route_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or p_status not in ('En coordinación', 'Cancelada') then
    raise exception 'Invalid direct route response';
  end if;
  update public.logistics_requests
    set status = p_status
    where id = p_route_id
      and recipient_company_id = auth.uid()
      and status = 'Abierta';
  if not found then
    raise exception 'Direct route proposal not found or already answered';
  end if;
end;
$$;

revoke all on function public.respond_direct_route_proposal(uuid, text) from public;
grant execute on function public.respond_direct_route_proposal(uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
