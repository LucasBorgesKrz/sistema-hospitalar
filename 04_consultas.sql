-- 04_consultas.sql
-- SELECT: lê dados sem alterar registros.
-- AS: cria um apelido para tabela ou coluna e facilita a leitura do resultado.
-- JOIN: combina registros relacionados; retorna apenas correspondências entre as tabelas.
-- LEFT JOIN: mantém também registros da tabela da esquerda sem correspondência.
-- GROUP BY: agrupa linhas por uma ou mais colunas para permitir agregações.
-- COUNT: conta registros. SUM: soma valores. AVG: calcula média. MIN/MAX: menor/maior valor.
-- HAVING: filtra os grupos depois do GROUP BY.
-- WHERE: filtra linhas antes da agregação.
-- ORDER BY: ordena o resultado.
-- Subconsulta: executa uma consulta dentro de outra para obter dados usados pela consulta externa.
-- IN: verifica se um valor pertence ao conjunto retornado pela subconsulta.


-- 1. JOIN: mostra cada consulta junto do paciente e do médico relacionados.
SELECT c.id_consulta, p.nome AS paciente, m.nome AS medico, c.data_consulta, c.status
FROM consulta c
JOIN paciente p ON p.cpf = c.cpf_paciente
JOIN medico m ON m.crm = c.crm_medico
ORDER BY c.data_consulta;

-- 2. JOIN: mostra os diagnósticos vinculando consulta, paciente e médico.
SELECT p.nome AS paciente, m.nome AS medico, d.descricao, d.gravidade
FROM diagnostico d
JOIN consulta c ON c.id_consulta = d.id_consulta
JOIN paciente p ON p.cpf = c.cpf_paciente
JOIN medico m ON m.crm = c.crm_medico;

-- 3. GROUP BY + COUNT: conta quantas consultas cada médico possui.
SELECT m.crm, m.nome, COUNT(c.id_consulta) AS total_consultas
FROM medico m
LEFT JOIN consulta c ON c.crm_medico = m.crm
GROUP BY m.crm, m.nome
ORDER BY total_consultas DESC;

-- 4. GROUP BY + COUNT/SUM: calcula quantidade e faturamento por forma de pagamento.
SELECT forma_pagamento, COUNT(*) AS quantidade, SUM(valor) AS faturamento
FROM pagamento
GROUP BY forma_pagamento
ORDER BY faturamento DESC;

-- 5. GROUP BY + HAVING: retorna médicos que possuem pelo menos uma consulta.
SELECT m.crm, m.nome, COUNT(c.id_consulta) AS total
FROM medico m
JOIN consulta c ON c.crm_medico = m.crm
GROUP BY m.crm, m.nome
HAVING COUNT(c.id_consulta) >= 1;

-- 6. Subconsulta IN: encontra pacientes cujo CPF aparece na tabela de consultas.
SELECT nome
FROM paciente
WHERE cpf IN (SELECT cpf_paciente FROM consulta);

-- 7. Subconsulta com AVG: encontra médicos cujo preço está acima da média geral.
SELECT nome, preco_consulta
FROM medico m
WHERE preco_consulta > (SELECT AVG(m2.preco_consulta) FROM medico m2);

-- 8. Subconsulta IN: retorna medicamentos que aparecem em alguma receita.
SELECT nome, principio_ativo, estoque
FROM medicamento
WHERE id_medicamento IN (SELECT id_medicamento FROM receita);

-- 9. JOIN + GROUP BY + COUNT: conta quantas vezes cada medicamento foi prescrito.
SELECT med.nome, COUNT(r.id_receita) AS total_receitas
FROM medicamento med
LEFT JOIN receita r ON r.id_medicamento = med.id_medicamento
GROUP BY med.id_medicamento, med.nome
ORDER BY total_receitas DESC;

-- 10. GROUP BY + COUNT: conta leitos livres, ocupados e em manutenção.
SELECT l.status, COUNT(*) AS quantidade
FROM leito l
GROUP BY l.status;

-- 11. JOIN múltiplo: mostra a localização do leito e a unidade de cada internação.
SELECT p.nome AS paciente, u.nome AS unidade, q.numero AS quarto,
       l.numero AS leito, i.data_entrada, i.status
FROM internacao i
JOIN paciente p ON p.cpf = i.cpf_paciente
JOIN leito l ON l.id_leito = i.id_leito
JOIN quarto q ON q.id_quarto = l.id_quarto
JOIN unidade u ON u.id_unidade = q.id_unidade;

-- 12. AVG/MIN/MAX: calcula média, menor e maior preço das consultas.
SELECT ROUND(AVG(preco),2) AS media,
       MIN(preco) AS menor,
       MAX(preco) AS maior
FROM consulta;

-- 13. Subconsulta com AVG: retorna consultas com preço acima da média.
SELECT id_consulta, preco, total
FROM consulta
WHERE preco > (SELECT AVG(preco) FROM consulta)
ORDER BY preco DESC;

-- 14. JOIN + WHERE: mostra receitas com quantidade igual ou superior a 2.
SELECT r.id_receita, p.nome AS paciente, med.nome AS medicamento,
       r.dosagem, r.quantidade
FROM receita r
JOIN consulta c ON c.id_consulta = r.id_consulta
JOIN paciente p ON p.cpf = c.cpf_paciente
JOIN medicamento med ON med.id_medicamento = r.id_medicamento
WHERE r.quantidade >= 2;

-- 15. GROUP BY + COUNT: contabiliza consultas por status.
SELECT status, COUNT(*) AS quantidade
FROM consulta
GROUP BY status
ORDER BY quantidade DESC;
