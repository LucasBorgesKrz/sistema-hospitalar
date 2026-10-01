-- 07_explain_postgresql.sql
-- EXECUTAR SOMENTE EM POSTGRESQL.
EXPLAIN ANALYZE
SELECT c.id_consulta, p.nome AS paciente, m.nome AS medico, c.data_consulta
FROM consulta c
JOIN paciente p ON p.cpf = c.cpf_paciente
JOIN medico m ON m.crm = c.crm_medico
WHERE c.crm_medico = 'CRM-MA-00001'
ORDER BY c.data_consulta;

EXPLAIN ANALYZE
SELECT e.id_exame, e.tipo, e.status, e.data_envio
FROM exame e
JOIN paciente p ON p.cpf = e.cpf_paciente
WHERE e.cpf_paciente = '11111111101'
ORDER BY e.data_envio DESC;

EXPLAIN ANALYZE
SELECT forma_pagamento, COUNT(*) AS quantidade, SUM(valor) AS total
FROM pagamento
WHERE data_pagamento >= DATE '2025-01-01'
GROUP BY forma_pagamento;
