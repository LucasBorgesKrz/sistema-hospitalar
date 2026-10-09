-- 07_explain.sql
-- Análise de desempenho com EXPLAIN ANALYZE (PostgreSQL).

-- Com poucos registros o PostgreSQL prefere Seq Scan.
-- Por isso geramos volume (20 mil linhas) e atualizamos as estatísticas.
INSERT INTO consulta (cpf_paciente, crm_medico, preco, imposto, total)
SELECT '11111111101', 'CRM-MA-00001', 100, 15, 115
FROM generate_series(1, 20000);

ANALYZE consulta;

-- Consulta 1: filtro por paciente (usa idx_consulta_paciente).
EXPLAIN ANALYZE
SELECT id_consulta, status
FROM consulta
WHERE cpf_paciente = '11111111102';

-- Consulta 2: filtro por médico + ordenação por data (usa idx_consulta_medico_data).
EXPLAIN ANALYZE
SELECT id_consulta, data_consulta
FROM consulta
WHERE crm_medico = 'CRM-MA-00002'
ORDER BY data_consulta DESC
LIMIT 10;
