-- Run this in Supabase SQL Editor: Dashboard → SQL Editor → New Query

-- Profiles table (links to auth.users, stores app-specific data)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  name text,
  dietary_preferences text[] default '{}',
  health_goals text,
  composio_entity_id text,
  calendar_connected boolean default false,
  onboarding_data jsonb,
  created_at timestamptz default now()
);

-- Meal templates saved by user
create table if not exists public.meal_templates (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  description text,
  restaurant_name text,
  order_url text,
  calories int,
  tags text[] default '{}',
  created_at timestamptz default now()
);

-- AI-generated recommendation sessions
create table if not exists public.recommendations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  generated_at timestamptz default now(),
  location text,
  travel_context text,
  calendar_summary jsonb default '[]',
  recommendations_json jsonb default '{}',
  window_start timestamptz,
  window_end timestamptz
);

-- Meal scores (1-5 stars) — drives future recommendations
create table if not exists public.meal_scores (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  recommendation_id uuid references public.recommendations,
  meal_name text not null,
  score int check (score >= 1 and score <= 5) not null,
  notes text,
  eaten_at timestamptz default now()
);

-- Chat message history
create table if not exists public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  role text check (role in ('user', 'assistant')) not null,
  content text not null,
  created_at timestamptz default now()
);

-- User location / travel context (one per user)
create table if not exists public.user_locations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade unique not null,
  city text not null,
  address text,
  travel_note text,
  updated_at timestamptz default now()
);

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.meal_templates enable row level security;
alter table public.recommendations enable row level security;
alter table public.meal_scores enable row level security;
alter table public.chat_messages enable row level security;
alter table public.user_locations enable row level security;

-- RLS Policies: users can only access their own rows
create policy "profiles_own" on public.profiles for all using (auth.uid() = id);
create policy "meal_templates_own" on public.meal_templates for all using (auth.uid() = user_id);
create policy "recommendations_own" on public.recommendations for all using (auth.uid() = user_id);
create policy "meal_scores_own" on public.meal_scores for all using (auth.uid() = user_id);
create policy "chat_messages_own" on public.chat_messages for all using (auth.uid() = user_id);
create policy "user_locations_own" on public.user_locations for all using (auth.uid() = user_id);

-- Auto-create profile row on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
