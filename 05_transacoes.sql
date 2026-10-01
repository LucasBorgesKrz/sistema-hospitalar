-- 05_transacoes.sql
-- PostgreSQL: duas transações, uma confirmada e outra desfeita.
-- BEGIN: inicia uma transação e agrupa várias operações em uma unidade lógica.
-- SET/UPDATE: altera dados; aqui UPDATE modifica estoque, pagamento e consulta.
-- UPDATE: altera registros existentes.
-- COMMIT: confirma definitivamente as alterações da transação.
-- ROLLBACK: desfaz as alterações realizadas desde o último BEGIN.

START TRANSACTION;

UPDATE medicamento
SET estoque = estoque - 1
WHERE id_medicamento = 1
  AND estoque > 0;

UPDATE pagamento
SET status = 'Pago',
    forma_pagamento = 'Pix',
    data_pagamento = CURRENT_DATE
WHERE id_consulta = 1;

COMMIT;

START TRANSACTION;

UPDATE consulta
SET status = 'Cancelada'
WHERE id_consulta = 2;

ROLLBACK;

SELECT id_consulta, status
FROM consulta
WHERE id_consulta = 2;
