-- 002_core_tenancy_down.sql  v0.2
drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_workspace_created on workspaces;
drop function if exists public.handle_new_user();
drop function if exists public.handle_new_workspace();
drop table if exists memberships cascade;
drop table if exists users cascade;
drop table if exists workspaces cascade;
