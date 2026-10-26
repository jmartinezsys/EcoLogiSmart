-- Core schema for EcoLogiSmart. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.company_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  business_name text not null,
  contact_name text not null default '',
  email text not null,
  sector text not null default 'Otro',
  city text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_company_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.company_profiles (
    id, business_name, contact_name, email, sector, city
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'business_name', 'Empresa'),
    coalesce(new.raw_user_meta_data ->> 'contact_name', ''),
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'sector', 'Otro'),
    coalesce(new.raw_user_meta_data ->> 'city', '')
  ) on conflict (id) do update set
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_company_created on auth.users;
create trigger on_auth_company_created
  after insert on auth.users
  for each row execute procedure public.handle_new_company_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists company_profiles_set_updated_at on public.company_profiles;
create trigger company_profiles_set_updated_at
  before update on public.company_profiles
  for each row execute procedure public.set_updated_at();

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.company_profiles(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  quantity numeric(12, 2) not null default 0 check (quantity >= 0),
  unit text not null default 'unidades',
  category text not null default '',
  low_stock_threshold numeric(12, 2) not null default 0 check (low_stock_threshold >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists inventory_items_set_updated_at on public.inventory_items;
create trigger inventory_items_set_updated_at
  before update on public.inventory_items
  for each row execute procedure public.set_updated_at();

create index if not exists inventory_items_company_idx
  on public.inventory_items(company_id, name);

create table if not exists public.material_listings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.company_profiles(id) on delete cascade,
  company_name text not null default '',
  city text not null default '',
  title text not null check (length(trim(title)) > 0),
  description text not null default '',
  quantity numeric(12, 2) not null check (quantity > 0),
  unit text not null default 'kg',
  status text not null default 'Disponible'
    check (status in ('Disponible', 'Intercambio', 'Reservado', 'Retirado')),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.stamp_material_company()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or new.company_id <> auth.uid() then
    raise exception 'company_id must match the authenticated user';
  end if;
  select p.business_name, p.city into new.company_name, new.city
    from public.company_profiles as p where p.id = auth.uid();
  if new.company_name is null then
    raise exception 'Company profile not found';
  end if;
  return new;
end;
$$;

drop trigger if exists material_listings_stamp_company on public.material_listings;
create trigger material_listings_stamp_company
  before insert or update on public.material_listings
  for each row execute procedure public.stamp_material_company();

drop trigger if exists material_listings_set_updated_at on public.material_listings;
create trigger material_listings_set_updated_at
  before update on public.material_listings
  for each row execute procedure public.set_updated_at();

create index if not exists material_listings_status_created_idx
  on public.material_listings(status, created_at desc);

create table if not exists public.logistics_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.company_profiles(id) on delete cascade,
  company_name text not null default '',
  destination text not null check (length(trim(destination)) > 0),
  delivery_type text not null default 'Materiales',
  status text not null default 'Abierta'
    check (status in ('Abierta', 'En coordinación', 'Completada', 'Cancelada')),
  created_at timestamptz not null default now()
);

create or replace function public.stamp_route_company()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or new.company_id <> auth.uid() then
    raise exception 'company_id must match the authenticated user';
  end if;
  select p.business_name into new.company_name
    from public.company_profiles as p where p.id = auth.uid();
  if new.company_name is null then
    raise exception 'Company profile not found';
  end if;
  return new;
end;
$$;

drop trigger if exists logistics_requests_stamp_company on public.logistics_requests;
create trigger logistics_requests_stamp_company
  before insert on public.logistics_requests
  for each row execute procedure public.stamp_route_company();

create index if not exists logistics_requests_destination_idx
  on public.logistics_requests(destination, created_at desc);

alter table public.company_profiles enable row level security;
alter table public.inventory_items enable row level security;
alter table public.material_listings enable row level security;
alter table public.logistics_requests enable row level security;

drop policy if exists "Company users read own profile" on public.company_profiles;
create policy "Company users read own profile" on public.company_profiles
  for select to authenticated using ((select auth.uid()) = id);
drop policy if exists "Company users update own profile" on public.company_profiles;
create policy "Company users update own profile" on public.company_profiles
  for update to authenticated using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "Company users manage own inventory" on public.inventory_items;
create policy "Company users manage own inventory" on public.inventory_items
  for all to authenticated using ((select auth.uid()) = company_id)
  with check ((select auth.uid()) = company_id);

drop policy if exists "Authenticated users view available materials" on public.material_listings;
create policy "Authenticated users view available materials" on public.material_listings
  for select to authenticated using (status in ('Disponible', 'Intercambio'));
drop policy if exists "Companies publish own materials" on public.material_listings;
create policy "Companies publish own materials" on public.material_listings
  for insert to authenticated with check ((select auth.uid()) = company_id);
drop policy if exists "Companies update own materials" on public.material_listings;
create policy "Companies update own materials" on public.material_listings
  for update to authenticated using ((select auth.uid()) = company_id)
  with check ((select auth.uid()) = company_id);
drop policy if exists "Companies delete own materials" on public.material_listings;
create policy "Companies delete own materials" on public.material_listings
  for delete to authenticated using ((select auth.uid()) = company_id);

drop policy if exists "Authenticated users view open routes" on public.logistics_requests;
create policy "Authenticated users view open routes" on public.logistics_requests
  for select to authenticated using (status in ('Abierta', 'En coordinación'));
drop policy if exists "Companies create own route requests" on public.logistics_requests;
create policy "Companies create own route requests" on public.logistics_requests
  for insert to authenticated with check ((select auth.uid()) = company_id);
drop policy if exists "Companies update own route requests" on public.logistics_requests;
create policy "Companies update own route requests" on public.logistics_requests
  for update to authenticated using ((select auth.uid()) = company_id)
  with check ((select auth.uid()) = company_id);
drop policy if exists "Companies delete own route requests" on public.logistics_requests;
create policy "Companies delete own route requests" on public.logistics_requests
  for delete to authenticated using ((select auth.uid()) = company_id);

grant select, update on public.company_profiles to authenticated;
grant select, insert, update, delete on public.inventory_items to authenticated;
grant select, insert, update, delete on public.material_listings to authenticated;
grant select, insert, update, delete on public.logistics_requests to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('material-images', 'material-images', true, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Anyone reads published material images" on storage.objects;
create policy "Anyone reads published material images" on storage.objects
  for select to public using (bucket_id = 'material-images');
drop policy if exists "Companies upload own material images" on storage.objects;
create policy "Companies upload own material images" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'material-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Companies update own material images" on storage.objects;
create policy "Companies update own material images" on storage.objects
  for update to authenticated using (
    bucket_id = 'material-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  ) with check (
    bucket_id = 'material-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Companies delete own material images" on storage.objects;
create policy "Companies delete own material images" on storage.objects
  for delete to authenticated using (
    bucket_id = 'material-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
