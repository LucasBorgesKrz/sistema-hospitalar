-- 05_transacoes.sql
-- PostgreSQL: transações com BEGIN, COMMIT, ROLLBACK, SAVEPOINT e RETURNING.

-- ============================================================
-- TRANSAÇÃO 1: atendimento completo (COMMIT)
-- Insere em 4 tabelas: consulta, pagamento, receita e diagnostico.
-- RETURNING captura o id_consulta gerado e o repassa às tabelas filhas.
-- ============================================================
BEGIN;

WITH nova AS (
  INSERT INTO consulta (cpf_paciente, crm_medico, preco, imposto, total)
  VALUES ('11111111101', 'CRM-MA-00001', 200.00, 30.00, 230.00)
  RETURNING id_consulta
),
pag AS (
  INSERT INTO pagamento (id_consulta, valor, forma_pagamento, status)
  SELECT id_consulta, 230.00, 'Pix', 'Pendente' FROM nova
)
INSERT INTO receita (id_consulta, id_medicamento, medicamento, descricao)
SELECT id_consulta, 1, 'Medicamento 1', 'Tomar 1 comprimido a cada 8h' FROM nova;

SAVEPOINT antes_diagnostico;

INSERT INTO diagnostico (id_consulta, descricao, gravidade)
SELECT max(id_consulta), 'Quadro leve, acompanhamento em retorno', 'Leve'
FROM consulta
WHERE cpf_paciente = '11111111101';

COMMIT;

-- ============================================================
-- TRANSAÇÃO 2: SAVEPOINT desfazendo só parte (COMMIT parcial)
-- Consulta e pagamento são confirmados; a receita é desfeita.
-- ============================================================
BEGIN;

WITH nova AS (
  INSERT INTO consulta (cpf_paciente, crm_medico, preco, imposto, total)
  VALUES ('11111111102', 'CRM-MA-00002', 100.00, 15.00, 115.00)
  RETURNING id_consulta
)
INSERT INTO pagamento (id_consulta, valor, forma_pagamento, status)
SELECT id_consulta, 115.00, 'Dinheiro', 'Pendente' FROM nova;

SAVEPOINT antes_receita;

INSERT INTO receita (id_consulta, id_medicamento, medicamento, descricao)
SELECT max(id_consulta), 2, 'Medicamento 2', 'Receita de teste'
FROM consulta WHERE cpf_paciente = '11111111102';

-- desfaz só a receita; consulta e pagamento continuam
ROLLBACK TO SAVEPOINT antes_receita;

COMMIT;

-- ============================================================
-- TRANSAÇÃO 3: ROLLBACK completo
-- Altera o status temporariamente e desfaz tudo.
-- ============================================================
BEGIN;

UPDATE consulta
SET status = 'Cancelada'
WHERE id_consulta = 2;

ROLLBACK;

SELECT id_consulta, status
FROM consulta
WHERE id_consulta = 2;
