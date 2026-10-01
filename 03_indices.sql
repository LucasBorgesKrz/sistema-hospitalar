-- 03_indices.sql
-- CREATE INDEX: cria um índice para acelerar filtros, JOINs e ordenações.
-- IF NOT EXISTS: evita erro se o índice já existir.
-- CREATE INDEX: cria estruturas que aceleram buscas em colunas usadas com frequência.
-- Os índices abaixo apoiam JOINs, filtros, ordenações e consultas por status/data.

-- Acelera consultas filtradas ou relacionadas pelo CPF do paciente.
CREATE INDEX idx_consulta_paciente ON consulta(cpf_paciente);
-- Acelera buscas de consultas de um médico e ordenações por data.
CREATE INDEX idx_consulta_medico_data ON consulta(crm_medico, data_consulta);
-- Acelera filtros de consultas por status.
CREATE INDEX idx_consulta_status ON consulta(status);
-- Acelera a localização dos diagnósticos de uma consulta.
CREATE INDEX idx_diagnostico_consulta ON diagnostico(id_consulta);
-- Acelera a localização das receitas de uma consulta.
CREATE INDEX idx_receita_consulta ON receita(id_consulta);
-- Acelera buscas de internações por paciente e status.
CREATE INDEX idx_internacao_paciente_status ON internacao(cpf_paciente, status);
-- Acelera consultas que localizam internações por leito.
CREATE INDEX idx_internacao_leito ON internacao(id_leito);
-- Acelera filtros de pagamentos por data e status.
CREATE INDEX idx_pagamento_data_status ON pagamento(data_pagamento, status);
-- Acelera buscas de medicamentos pelo princípio ativo.
CREATE INDEX idx_medicamento_principio ON medicamento(principio_ativo);
-- Acelera buscas de quartos pertencentes a uma unidade.
CREATE INDEX idx_quarto_unidade ON quarto(id_unidade);

-- Acelera buscas de exames por paciente e data de envio.
CREATE INDEX idx_exame_paciente_data ON exame(cpf_paciente, data_envio);
-- Acelera buscas de exames vinculados a uma consulta.
CREATE INDEX idx_exame_consulta ON exame(id_consulta);
