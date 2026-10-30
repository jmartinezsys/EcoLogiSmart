-- Add exchange requests and actionable shared logistics routes.
alter table public.material_listings
  add column if not exists exchange_for text,
  add column if not exists category text not null default '';

alter table public.logistics_requests
  add column if not exists origin text not null default '',
  add column if not exists travel_date date,
  add column if not exists cargo_description text not null default '';

drop policy if exists "Authenticated users view available materials"
  on public.material_listings;
drop policy if exists "Companies view own and available materials"
  on public.material_listings;
create policy "Companies view own and available materials"
  on public.material_listings for select to authenticated
  using (
    company_id = (select auth.uid())
    or status in ('Disponible', 'Intercambio')
  );

drop policy if exists "Authenticated users view open routes"
  on public.logistics_requests;
drop policy if exists "Companies view own and open routes"
  on public.logistics_requests;
create policy "Companies view own and open routes"
  on public.logistics_requests for select to authenticated
  using (
    company_id = (select auth.uid())
    or status in ('Abierta', 'En coordinación')
  );

create table if not exists public.material_exchange_requests (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.material_listings(id) on delete cascade,
  requester_company_id uuid not null references public.company_profiles(id) on delete cascade,
  requester_company_name text not null default '',
  offered_product text not null check (length(trim(offered_product)) > 0),
  message text not null default '',
  status text not null default 'Pendiente'
    check (status in ('Pendiente', 'Aceptada', 'Rechazada', 'Cancelada')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.material_exchange_requests
  add column if not exists offered_quantity numeric(12, 2) not null default 0
    check (offered_quantity >= 0),
  add column if not exists offered_unit text not null default 'unidades';

create or replace function public.stamp_exchange_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  listing_owner uuid;
  requester_name text;
begin
  if auth.uid() is null or new.requester_company_id <> auth.uid() then
    raise exception 'requester_company_id must match the authenticated user';
  end if;
  select company_id into listing_owner
    from public.material_listings where id = new.listing_id;
  if listing_owner is null or listing_owner = auth.uid() then
    raise exception 'A company can only request an exchange from another company';
  end if;
  if not exists (
    select 1 from public.material_listings
    where id = new.listing_id and status = 'Intercambio'
  ) then
    raise exception 'This material is no longer open for exchange';
  end if;
  select business_name into requester_name
    from public.company_profiles where id = auth.uid();
  new.requester_company_name := coalesce(requester_name, 'Empresa');
  new.status := 'Pendiente';
  return new;
end;
$$;

drop trigger if exists material_exchange_requests_stamp
  on public.material_exchange_requests;
create trigger material_exchange_requests_stamp
  before insert on public.material_exchange_requests
  for each row execute procedure public.stamp_exchange_request();

drop trigger if exists material_exchange_requests_updated_at
  on public.material_exchange_requests;
create trigger material_exchange_requests_updated_at
  before update on public.material_exchange_requests
  for each row execute procedure public.set_updated_at();

create index if not exists material_exchange_listing_created_idx
  on public.material_exchange_requests(listing_id, created_at desc);
create index if not exists material_exchange_requester_created_idx
  on public.material_exchange_requests(requester_company_id, created_at desc);

alter table public.material_exchange_requests enable row level security;

drop policy if exists "Companies view exchange requests they participate in"
  on public.material_exchange_requests;
create policy "Companies view exchange requests they participate in"
  on public.material_exchange_requests for select to authenticated
  using (
    requester_company_id = (select auth.uid())
    or exists (
      select 1 from public.material_listings listing
      where listing.id = listing_id
        and listing.company_id = (select auth.uid())
    )
  );

drop policy if exists "Companies request exchanges from other listings"
  on public.material_exchange_requests;
create policy "Companies request exchanges from other listings"
  on public.material_exchange_requests for insert to authenticated
  with check (
    requester_company_id = (select auth.uid())
    and exists (
      select 1 from public.material_listings listing
      where listing.id = listing_id
        and listing.company_id <> (select auth.uid())
        and listing.status = 'Intercambio'
    )
  );

drop policy if exists "Requesters cancel their pending exchanges"
  on public.material_exchange_requests;
create policy "Requesters cancel their pending exchanges"
  on public.material_exchange_requests for update to authenticated
  using (requester_company_id = (select auth.uid()) and status = 'Pendiente')
  with check (requester_company_id = (select auth.uid()) and status = 'Cancelada');

drop policy if exists "Listing owners respond to pending exchanges"
  on public.material_exchange_requests;
create policy "Listing owners respond to pending exchanges"
  on public.material_exchange_requests for update to authenticated
  using (
    status = 'Pendiente'
    and exists (
      select 1 from public.material_listings listing
      where listing.id = listing_id and listing.company_id = (select auth.uid())
    )
  )
  with check (
    status in ('Aceptada', 'Rechazada')
    and exists (
      select 1 from public.material_listings listing
      where listing.id = listing_id and listing.company_id = (select auth.uid())
    )
  );

grant select, insert on public.material_exchange_requests to authenticated;
grant update (status) on public.material_exchange_requests to authenticated;

create table if not exists public.route_join_requests (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.logistics_requests(id) on delete cascade,
  requester_company_id uuid not null references public.company_profiles(id) on delete cascade,
  requester_company_name text not null default '',
  message text not null default '',
  status text not null default 'Pendiente'
    check (status in ('Pendiente', 'Aceptada', 'Rechazada', 'Cancelada')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.stamp_route_join_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  route_owner uuid;
  requester_name text;
begin
  if auth.uid() is null or new.requester_company_id <> auth.uid() then
    raise exception 'requester_company_id must match the authenticated user';
  end if;
  select company_id into route_owner
    from public.logistics_requests where id = new.route_id;
  if route_owner is null or route_owner = auth.uid() then
    raise exception 'A company can only join another company route';
  end if;
  if not exists (
    select 1 from public.logistics_requests
    where id = new.route_id and status = 'Abierta'
  ) then
    raise exception 'This route is no longer open';
  end if;
  select business_name into requester_name
    from public.company_profiles where id = auth.uid();
  new.requester_company_name := coalesce(requester_name, 'Empresa');
  new.status := 'Pendiente';
  return new;
end;
$$;

drop trigger if exists route_join_requests_stamp on public.route_join_requests;
create trigger route_join_requests_stamp
  before insert on public.route_join_requests
  for each row execute procedure public.stamp_route_join_request();

drop trigger if exists route_join_requests_updated_at on public.route_join_requests;
create trigger route_join_requests_updated_at
  before update on public.route_join_requests
  for each row execute procedure public.set_updated_at();

create index if not exists route_join_route_created_idx
  on public.route_join_requests(route_id, created_at desc);
create index if not exists route_join_requester_created_idx
  on public.route_join_requests(requester_company_id, created_at desc);

alter table public.route_join_requests enable row level security;

drop policy if exists "Companies view route requests they participate in"
  on public.route_join_requests;
create policy "Companies view route requests they participate in"
  on public.route_join_requests for select to authenticated
  using (
    requester_company_id = (select auth.uid())
    or exists (
      select 1 from public.logistics_requests route
      where route.id = route_id and route.company_id = (select auth.uid())
    )
  );

drop policy if exists "Companies request to join other open routes"
  on public.route_join_requests;
create policy "Companies request to join other open routes"
  on public.route_join_requests for insert to authenticated
  with check (
    requester_company_id = (select auth.uid())
    and exists (
      select 1 from public.logistics_requests route
      where route.id = route_id
        and route.company_id <> (select auth.uid())
        and route.status = 'Abierta'
    )
  );

drop policy if exists "Requesters cancel their pending route requests"
  on public.route_join_requests;
create policy "Requesters cancel their pending route requests"
  on public.route_join_requests for update to authenticated
  using (requester_company_id = (select auth.uid()) and status = 'Pendiente')
  with check (requester_company_id = (select auth.uid()) and status = 'Cancelada');

drop policy if exists "Route owners respond to pending join requests"
  on public.route_join_requests;
create policy "Route owners respond to pending join requests"
  on public.route_join_requests for update to authenticated
  using (
    status = 'Pendiente'
    and exists (
      select 1 from public.logistics_requests route
      where route.id = route_id and route.company_id = (select auth.uid())
    )
  )
  with check (
    status in ('Aceptada', 'Rechazada')
    and exists (
      select 1 from public.logistics_requests route
      where route.id = route_id and route.company_id = (select auth.uid())
    )
  );

grant select, insert on public.route_join_requests to authenticated;
grant update (status) on public.route_join_requests to authenticated;

drop policy if exists "Companies update own route requests"
  on public.logistics_requests;
create policy "Companies update own route requests"
  on public.logistics_requests for update to authenticated
  using (company_id = (select auth.uid()))
  with check (company_id = (select auth.uid()));
grant update (status) on public.logistics_requests to authenticated;
