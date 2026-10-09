-- 06_criacao_usuarios_postgresql.sql
-- Cria a ROLE de grupo (sem login) e os usuários (com login).
-- Executar como administrador do banco.

-- Limpeza segura: remove permissões penduradas antes de apagar cada role.
-- Limpeza segura: remove permissões penduradas antes de apagar cada role.
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['paciente_user','medico_user','role_leitura'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('REVOKE ALL ON ALL TABLES IN SCHEMA public FROM %I', r);
      EXECUTE format('REVOKE ALL ON SCHEMA public FROM %I', r);
      EXECUTE format('DROP ROLE %I', r);
    END IF;
  END LOOP;
END $$;

-- ROLE de grupo: concentra permissões comuns; não faz login.
CREATE ROLE role_leitura NOLOGIN;

-- Usuários: cada um herda a role de leitura.
CREATE USER medico_user WITH PASSWORD 'Troque_Esta_Senha_Medico@2026'
  NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;
CREATE USER paciente_user WITH PASSWORD 'Troque_Esta_Senha_Paciente@2026'
  NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;

GRANT role_leitura TO medico_user;
GRANT role_leitura TO paciente_user;
