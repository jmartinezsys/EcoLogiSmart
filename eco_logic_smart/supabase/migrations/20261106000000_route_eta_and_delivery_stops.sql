-- Approximate road-route choices and one requested delivery stop per joining company.
alter table public.logistics_requests
  add column if not exists estimated_distance_meters double precision,
  add column if not exists estimated_duration_seconds integer,
  add column if not exists route_option integer,
  add column if not exists departure_time time without time zone
    not null default time '08:00';

alter table public.route_join_requests
  add column if not exists delivery_city text not null default '',
  add column if not exists delivery_address text not null default '',
  add column if not exists estimated_distance_meters double precision,
  add column if not exists estimated_duration_seconds integer,
  add column if not exists route_option integer;

notify pgrst, 'reload schema';
