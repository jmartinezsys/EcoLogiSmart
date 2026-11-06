-- Private, client-encrypted company conversations on published materials.
create table if not exists public.company_chat_keys (
  company_id uuid primary key references public.company_profiles(id) on delete cascade,
  agreement_public_key text not null,
  signing_public_key text not null,
  updated_at timestamptz not null default now()
);

alter table public.company_chat_keys enable row level security;
drop policy if exists "Authenticated companies can read chat public keys"
  on public.company_chat_keys;
create policy "Authenticated companies can read chat public keys"
  on public.company_chat_keys for select to authenticated using (true);
drop policy if exists "Companies manage their own chat public keys"
  on public.company_chat_keys;
create policy "Companies manage their own chat public keys"
  on public.company_chat_keys for all to authenticated
  using (company_id = (select auth.uid()))
  with check (company_id = (select auth.uid()));
grant select, insert, update on public.company_chat_keys to authenticated;

create table if not exists public.material_conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.material_listings(id) on delete cascade,
  requester_company_id uuid not null references public.company_profiles(id) on delete cascade,
  requester_company_name text not null default '',
  publisher_company_id uuid not null references public.company_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (listing_id, requester_company_id),
  check (requester_company_id <> publisher_company_id)
);

create or replace function public.open_material_conversation(p_listing_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  publisher_id uuid;
  requester_name text;
  conversation_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  select company_id into publisher_id
    from public.material_listings
    where id = p_listing_id and status in ('Disponible', 'Intercambio');
  if publisher_id is null or publisher_id = auth.uid() then
    raise exception 'Choose another company material that is available';
  end if;
  select business_name into requester_name
    from public.company_profiles where id = auth.uid();
  insert into public.material_conversations (
    listing_id, requester_company_id, requester_company_name,
    publisher_company_id
  ) values (
    p_listing_id, auth.uid(), coalesce(requester_name, 'Empresa'), publisher_id
  )
  on conflict (listing_id, requester_company_id)
  do update set updated_at = now()
  returning id into conversation_id;
  return conversation_id;
end;
$$;

revoke all on function public.open_material_conversation(uuid) from public;
grant execute on function public.open_material_conversation(uuid) to authenticated;

alter table public.material_conversations enable row level security;
drop policy if exists "Conversation participants read their conversations"
  on public.material_conversations;
create policy "Conversation participants read their conversations"
  on public.material_conversations for select to authenticated
  using (
    requester_company_id = (select auth.uid())
    or publisher_company_id = (select auth.uid())
  );
grant select on public.material_conversations to authenticated;

create table if not exists public.material_chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.material_conversations(id) on delete cascade,
  sender_company_id uuid not null references public.company_profiles(id) on delete cascade,
  encrypted_payload jsonb not null
    check (encrypted_payload ? 'version' and encrypted_payload ? 'envelopes'),
  created_at timestamptz not null default now()
);

create index if not exists material_chat_messages_conversation_idx
  on public.material_chat_messages(conversation_id, created_at);

alter table public.material_chat_messages enable row level security;
drop policy if exists "Conversation participants read encrypted messages"
  on public.material_chat_messages;
create policy "Conversation participants read encrypted messages"
  on public.material_chat_messages for select to authenticated
  using (
    exists (
      select 1 from public.material_conversations conversation
      where conversation.id = conversation_id
        and (conversation.requester_company_id = (select auth.uid())
          or conversation.publisher_company_id = (select auth.uid()))
    )
  );
drop policy if exists "Conversation participants send encrypted messages"
  on public.material_chat_messages;
create policy "Conversation participants send encrypted messages"
  on public.material_chat_messages for insert to authenticated
  with check (
    sender_company_id = (select auth.uid())
    and exists (
      select 1 from public.material_conversations conversation
      where conversation.id = conversation_id
        and (conversation.requester_company_id = (select auth.uid())
          or conversation.publisher_company_id = (select auth.uid()))
    )
  );
grant select, insert on public.material_chat_messages to authenticated;

-- If an earlier local draft migration created the plaintext chat table, keep
-- its records untouched but prevent the client roles from reading new plaintext.
do $$
begin
  if to_regclass('public.material_exchange_messages') is not null then
    execute 'revoke all on public.material_exchange_messages from anon, authenticated';
  end if;
end;
$$;

notify pgrst, 'reload schema';
