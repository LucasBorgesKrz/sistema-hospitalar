-- 06_criacao_usuarios_postgresql.sql
-- Cria a ROLE de grupo (sem login) e os usuários (com login).
-- Executar como administrador do banco.

DROP ROLE IF EXISTS paciente_user;
DROP ROLE IF EXISTS medico_user;
DROP ROLE IF EXISTS role_leitura;

-- ROLE de grupo: concentra permissões comuns; não faz login.
CREATE ROLE role_leitura NOLOGIN;

-- Usuários: cada um herda a role de leitura.
CREATE USER medico_user WITH PASSWORD 'Troque_Esta_Senha_Medico@2026'
  NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;
CREATE USER paciente_user WITH PASSWORD 'Troque_Esta_Senha_Paciente@2026'
  NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;

GRANT role_leitura TO medico_user;
GRANT role_leitura TO paciente_user;
