-- 06_permissoes.sql
-- Princípio do menor privilégio: cada perfil recebe só o necessário.

-- Ponto de partida limpo: tira tudo antes de conceder (REVOKE).
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM medico_user, paciente_user, role_leitura;

GRANT USAGE ON SCHEMA public TO role_leitura;

-- ROLE de leitura: só consulta tabelas de apoio (sem dados pessoais).
GRANT SELECT ON especialidade, convenio, unidade, quarto, leito, medicamento
  TO role_leitura;

-- MÉDICO: lê dados clínicos e registra atendimentos. NUNCA exclui.
-- Em paciente, a coluna senha fica de fora (permissão por coluna).
GRANT SELECT (cpf, nome, data_nascimento, telefone, endereco, sexo, ativo)
  ON paciente TO medico_user;
GRANT SELECT ON consulta, diagnostico, receita, exame, internacao, pagamento
  TO medico_user;
GRANT INSERT, UPDATE ON consulta, diagnostico, receita, internacao
  TO medico_user;
GRANT UPDATE ON exame, leito TO medico_user;

-- PACIENTE: consulta o próprio atendimento, envia exame e paga.
GRANT SELECT ON consulta, diagnostico, receita, exame, pagamento
  TO paciente_user;
GRANT INSERT ON exame, pagamento TO paciente_user;

-- REVOKE explícito: reforça que nenhum dos dois pode excluir dados.
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM medico_user, paciente_user;
