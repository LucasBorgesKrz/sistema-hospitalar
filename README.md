# 🏥 Sistema Hospitalar - Banco de Dados

## 1. Descrição do domínio

O projeto representa um sistema hospitalar para controlar pacientes, médicos, especialidades, convênios, unidades hospitalares, quartos, leitos, consultas, diagnósticos, receitas, medicamentos, internações e pagamentos.

O banco permite acompanhar o atendimento desde o cadastro do paciente e do médico até a consulta, diagnóstico, prescrição, internação e pagamento.

**SGBD utilizado:** PostgreSQL.

## 2. Modelo lógico

O modelo foi ampliado a partir das entidades originais, preservando **PACIENTE, MEDICO, CONSULTA, DIAGNOSTICO e RECEITA** e adicionando entidades necessárias para representar melhor o domínio.

### Tabelas e principais relacionamentos

- **PACIENTE**: PK `cpf`.
- **MEDICO**: PK `crm`.
- **ESPECIALIDADE**: PK `id_especialidade`.
- **CONVENIO**: PK `id_convenio`.
- **UNIDADE**: PK `id_unidade`.
- **QUARTO**: PK `id_quarto`, FK `id_unidade`.
- **LEITO**: PK `id_leito`, FK `id_quarto`.
- **MEDICAMENTO**: PK `id_medicamento`.
- **CONSULTA**: PK `id_consulta`, FKs `cpf_paciente`, `crm_medico` e `id_convenio`.
- **DIAGNOSTICO**: PK `id_diagnostico`, FK `id_consulta`.
- **RECEITA**: PK `id_receita`, FKs `id_consulta` e `id_medicamento`.
- **INTERNACAO**: PK `id_internacao`, FKs `cpf_paciente`, `id_leito` e `crm_medico_responsavel`.
- **PAGAMENTO**: PK `id_pagamento`, FK `id_consulta`.
- - **EXAME**: PK `id_exame`, FKs `cpf_paciente` e `id_consulta`.

### Cardinalidades principais

- PACIENTE 1:N CONSULTA
- MEDICO 1:N CONSULTA
- CONVENIO 1:N CONSULTA
- CONSULTA 1:N DIAGNOSTICO
- CONSULTA 1:N RECEITA
- MEDICAMENTO 1:N RECEITA
- UNIDADE 1:N QUARTO
- QUARTO 1:N LEITO
- PACIENTE 1:N INTERNACAO
- LEITO 1:N INTERNACAO
- MEDICO 1:N INTERNACAO
- CONSULTA 1:1 PAGAMENTO
## 3. Modelo físico e restrições

O arquivo `01_ddl.sql` cria **14 tabelas** no PostgreSQL, com:

- **PK** e **FK**: integridade referencial entre todas as entidades.
- **NOT NULL**: campos obrigatórios (nome, datas, valores).
- **UNIQUE**: usuário, nomes de entidades, `(id_unidade, numero)` em quartos, `id_consulta` em pagamento (1:1).
- **CHECK**: preços e estoque não negativos, sexo, status, percentuais de 0 a 100, `data_saida >= data_entrada`.
- **DEFAULT**: `ativo = TRUE`, status inicial, `CURRENT_DATE` e `CURRENT_TIMESTAMP`.

O arquivo `02_inserts.sql` carrega **15 registros por tabela** (210 no total).

## 4. Justificativa dos tipos de dados

| Tipo | Onde é usado | Por quê |
|---|---|---|
| `NUMERIC(10,2)` | preços, imposto, total, valor | Exato, sem erro de arredondamento de `FLOAT`. Essencial para dinheiro. |
| `TIMESTAMPTZ` | `data_consulta`, `data_registro`, `data_envio` | Guarda o fuso horário e evita ambiguidade entre unidades em fusos diferentes. |
| `DATE` | nascimento, entrada/saída, pagamento | Quando a hora não importa. |
| `TEXT` | diagnóstico, observações, instruções, descrições | Texto clínico sem limite fixo. |
| `VARCHAR(n)` | CPF, CRM, nome, telefone, status | Tamanho conhecido, limita entradas inválidas. |
| `INT GENERATED ALWAYS AS IDENTITY` | chaves substitutas | Padrão SQL moderno que substitui `SERIAL`: o banco não aceita ID manual por engano. |
| `BOOLEAN` | `ativo` | Verdadeiro/falso sem códigos soltos. |

`cpf` (paciente) e `crm` (médico) são chaves naturais informadas no cadastro, validadas por `CHECK`.

## 5. Estratégia de indexação

Arquivo: `03_indices.sql` (**12 índices**). O PostgreSQL cria índice automático só para PK e UNIQUE, **não para FK**, então indexamos as FKs usadas em `JOIN` e as colunas de `WHERE`/`ORDER BY`. Não indexamos tudo, para não penalizar `INSERT`/`UPDATE`/`DELETE`.

| Índice | Colunas | Justificativa |
|---|---|---|
| `idx_consulta_paciente` | `consulta(cpf_paciente)` | FK; busca e JOIN de consultas por paciente. |
| `idx_consulta_medico_data` | `consulta(crm_medico, data_consulta)` | Composto: filtra por médico e já entrega ordenado por data. |
| `idx_consulta_status` | `consulta(status)` | Filtro frequente por situação da consulta. |
| `idx_diagnostico_consulta` | `diagnostico(id_consulta)` | FK; diagnósticos de uma consulta. |
| `idx_receita_consulta` | `receita(id_consulta)` | FK; receitas de uma consulta. |
| `idx_internacao_paciente_status` | `internacao(cpf_paciente, status)` | Internações ativas de um paciente. |
| `idx_internacao_leito` | `internacao(id_leito)` | FK; ocupação de leitos. |
| `idx_pagamento_data_status` | `pagamento(data_pagamento, status)` | Relatórios financeiros por período e situação. |
| `idx_medicamento_principio` | `medicamento(principio_ativo)` | Pesquisa por princípio ativo. |
| `idx_quarto_unidade` | `quarto(id_unidade)` | FK; quartos de uma unidade. |
| `idx_exame_paciente_data` | `exame(cpf_paciente, data_envio)` | Exames de um paciente, mais recentes primeiro. |
| `idx_exame_consulta` | `exame(id_consulta)` | FK; exames ligados a uma consulta. |

## 6. Consultas SQL

Arquivo: `04_consultas.sql`, com **15 consultas** (JOIN, GROUP BY, HAVING, subconsultas e agregações).

## 7. Transações

Arquivo: `05_transacoes.sql`. O PostgreSQL usa MVCC, então leituras não bloqueiam escritas durante essas transações.

**Transação 1 (COMMIT):** registra um atendimento completo. Um `INSERT` em `consulta` usa `RETURNING id_consulta` dentro de um `WITH` e repassa o ID para `pagamento` e `receita`. Depois, um `SAVEPOINT` e o `INSERT` em `diagnostico`. Grava em **4 tabelas**.

**Transação 2 (SAVEPOINT + ROLLBACK TO):** insere `consulta` e `pagamento`, cria o `SAVEPOINT antes_receita`, insere uma `receita` e a desfaz com `ROLLBACK TO SAVEPOINT`. No `COMMIT`, só consulta e pagamento permanecem: a atomicidade é parcial e controlada.

**Transação 3 (ROLLBACK):** cancela uma consulta com `UPDATE` e desfaz tudo com `ROLLBACK`; o `SELECT` final confirma que o status original foi preservado.

## 8. Controle de acesso

Arquivos: `06_criacao_usuarios_postgresql.sql` e `06_permissoes.sql`. Aplica o **princípio do menor privilégio**: parte de `REVOKE ALL` e concede só o necessário.

- **`role_leitura`** (ROLE de grupo, `NOLOGIN`): `SELECT` nas tabelas de apoio (especialidade, convênio, unidade, quarto, leito, medicamento).
- **`medico_user`** (herda `role_leitura`): lê dados clínicos; `INSERT`/`UPDATE` em consulta, diagnóstico, receita e internação; `UPDATE` em exame e leito. **Não tem `DELETE`.** Lê `paciente` **sem a coluna `senha`** (permissão por coluna).
- **`paciente_user`** (herda `role_leitura`): `SELECT` em consulta, diagnóstico, receita, exame e pagamento; `INSERT` apenas em exame e pagamento. Não altera nem exclui nada.
- `REVOKE DELETE` explícito para os dois usuários.

**Testes executados:**
- `SET ROLE paciente_user; DELETE FROM consulta;` → `ERROR: permission denied for table consulta`
- `SET ROLE medico_user; SELECT senha FROM paciente;` → `ERROR: permission denied for table paciente`

> Limitações: não há Row Level Security, então o paciente enxerga todas as consultas, não só as dele (melhoria futura). As senhas nos scripts são apenas de demonstração.

## 9. EXPLAIN ANALYZE

Arquivo: `07_explain.sql`. Com 15 linhas por tabela o PostgreSQL prefere `Seq Scan`, então o script gera **20 mil consultas** com `generate_series` e executa `ANALYZE consulta` para atualizar as estatísticas.

**Consulta 1: filtro por paciente**
```sql
EXPLAIN ANALYZE SELECT id_consulta, status FROM consulta WHERE cpf_paciente = '11111111102';
```
Resultado: **`Index Scan using idx_consulta_paciente`**, execução em ~0,043 ms. O índice foi usado.

**Consulta 2: médico + ordenação**
```sql
EXPLAIN ANALYZE SELECT id_consulta, data_consulta FROM consulta
WHERE crm_medico = 'CRM-MA-00002' ORDER BY data_consulta DESC LIMIT 10;
```
Resultado: **`Index Scan Backward using idx_consulta_medico_data`** com `Limit`, execução em ~0,042 ms. O índice composto já entrega as linhas ordenadas, então o PostgreSQL **dispensa um `Sort`** separado.

Saída completa (cole aqui o texto da aba Raw):

```
COLE AQUI A SAÍDA RAW DOS DOIS EXPLAIN
```

## 10. Organização dos arquivos

```
01_ddl.sql                          -> 14 tabelas e restrições
02_inserts.sql                      -> 15 registros por tabela
03_indices.sql                      -> 12 índices
04_consultas.sql                    -> 15 consultas
05_transacoes.sql                   -> 3 transações
06_criacao_usuarios_postgresql.sql  -> role e usuários
06_permissoes.sql                   -> GRANT e REVOKE
07_explain.sql                      -> EXPLAIN ANALYZE
```

**Ordem de execução:** 01, 02, 03, 04, 05, 06 (criação), 06 (permissões), 07. O `07` vai por último porque insere 20 mil linhas de teste.
