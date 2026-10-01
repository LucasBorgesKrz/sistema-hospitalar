-- 06_permissoes.sql
-- Permissões do sistema hospitalar.
-- Os usuários devem existir antes da execução.
-- Os GRANTs são explícitos por tabela para maior compatibilidade com validadores SQL.

-- Manager: administra os dados, mas não é superusuário.
GRANT USAGE ON SCHEMA public TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON paciente TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON medico TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON consulta TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON diagnostico TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON receita TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON especialidade TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON convenio TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON unidade TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON quarto TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON leito TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON medicamento TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON internacao TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON exame TO hospital_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON pagamento TO hospital_manager;

-- Médico: pode acessar e alterar todos os dados.
GRANT USAGE ON SCHEMA public TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON paciente TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON medico TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON consulta TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON diagnostico TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON receita TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON especialidade TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON convenio TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON unidade TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON quarto TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON leito TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON medicamento TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON internacao TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON exame TO medico_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON pagamento TO medico_user;

-- Paciente: pode consultar informações, enviar exames e registrar pagamentos.
GRANT USAGE ON SCHEMA public TO paciente_user;
GRANT SELECT ON paciente TO paciente_user;
GRANT SELECT ON consulta TO paciente_user;
GRANT SELECT ON diagnostico TO paciente_user;
GRANT SELECT ON receita TO paciente_user;
GRANT SELECT ON medicamento TO paciente_user;
GRANT SELECT ON exame TO paciente_user;
GRANT INSERT ON exame TO paciente_user;
GRANT SELECT ON pagamento TO paciente_user;
GRANT INSERT ON pagamento TO paciente_user;

-- Segurança: o paciente não pode alterar nem excluir registros existentes.
REVOKE UPDATE, DELETE ON paciente FROM paciente_user;
REVOKE UPDATE, DELETE ON consulta FROM paciente_user;
REVOKE UPDATE, DELETE ON diagnostico FROM paciente_user;
REVOKE UPDATE, DELETE ON receita FROM paciente_user;
REVOKE UPDATE, DELETE ON medicamento FROM paciente_user;
REVOKE UPDATE, DELETE ON exame FROM paciente_user;
REVOKE UPDATE, DELETE ON pagamento FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON medico FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON especialidade FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON convenio FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON unidade FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON quarto FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON leito FROM paciente_user;
REVOKE INSERT, UPDATE, DELETE ON internacao FROM paciente_user;
