-- 06_criacao_usuarios_postgresql.sql
-- EXECUTAR SOMENTE EM POSTGRESQL, conectado como administrador.
-- Este arquivo cria os usuários exigidos pelo projeto.

DROP ROLE IF EXISTS paciente_user;
DROP ROLE IF EXISTS medico_user;
DROP ROLE IF EXISTS hospital_manager;
DROP ROLE IF EXISTS hospital_superuser;

CREATE USER hospital_superuser WITH PASSWORD 'Troque_Esta_Senha_Super@2026';
ALTER USER hospital_superuser WITH SUPERUSER CREATEDB CREATEROLE INHERIT;

CREATE USER hospital_manager WITH PASSWORD 'Troque_Esta_Senha_Manager@2026';
ALTER USER hospital_manager WITH NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;

CREATE USER medico_user WITH PASSWORD 'Troque_Esta_Senha_Medico@2026';
ALTER USER medico_user WITH NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;

CREATE USER paciente_user WITH PASSWORD 'Troque_Esta_Senha_Paciente@2026';
ALTER USER paciente_user WITH NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;
