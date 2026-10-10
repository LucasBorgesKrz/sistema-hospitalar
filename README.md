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

Saída completa:

**Consulta 1**
```
Index Scan using idx_consulta_paciente on consulta  (cost=0.29..8.31 rows=1 width=13) (actual time=0.010..0.012 rows=2.00 loops=1)
  Index Cond: ((cpf_paciente)::text = '11111111102'::text)
  Index Searches: 1
  Buffers: shared hit=4
Planning:
  Buffers: shared hit=45
Planning Time: 0.161 ms
Execution Time: 0.034 ms
```

**Consulta 2**
```
Limit  (cost=0.29..8.31 rows=1 width=12) (actual time=0.009..0.014 rows=2.00 loops=1)
  Buffers: shared hit=5
  ->  Index Scan Backward using idx_consulta_medico_data on consulta  (cost=0.29..8.31 rows=1 width=12) (actual time=0.008..0.013 rows=2.00 loops=1)
        Index Cond: ((crm_medico)::text = 'CRM-MA-00002'::text)
        Index Searches: 1
        Buffers: shared hit=5
Planning:
  Buffers: shared hit=28 read=3
Planning Time: 1.834 ms
Execution Time: 0.038 ms
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

## 11. Backup do PostgreSQL

O script `08_backup.sh` faz o backup lógico do banco com `pg_dump` no formato customizado (`-Fc`).

- **Conexão:** a `DATABASE_URL` é lida de `~/.hospital_env`, fora do repositório, então a senha nunca é versionada.
- **Nome com data:** `hospital_AAAA-MM-DD_HH-MM-SS.dump`, salvo em `~/backups_hospital`.
- **Tratamento de erros:** `set -euo pipefail`. Se o `pg_dump` falhar, o arquivo parcial é apagado, o erro vai para o log e o script sai com código 1.
- **Retenção de 30 dias:** `find ... -mtime +30 -delete` remove os dumps antigos.
- **Log:** cada execução registra início, sucesso (com o tamanho do arquivo) ou erro em `backup.log`.

### Agendamento (cron)

    0 2 * * * /workspaces/sistema-hospitalar/08_backup.sh >> /tmp/cron_backup.log 2>&1

A expressão executa o script todos os dias às 2h (minuto 0, hora 2, qualquer dia, mês e dia da semana). A configuração foi conferida com `crontab -l`. O Codespaces hiberna, então o disparo real das 2h não acontece lá. Em produção o script rodaria em um servidor sempre ligado.

### Regra 3-2-1

A regra 3-2-1 pede 3 cópias dos dados, em 2 tipos de mídia diferentes, com 1 cópia fora do local principal.

- **Cópia 1:** o banco em produção (PostgreSQL remoto).
- **Cópia 2:** o dump gerado pelo `08_backup.sh`, em outra mídia (disco do ambiente de backup).
- **Cópia 3 (fora do local):** em produção, o dump seria enviado a um armazenamento externo (por exemplo, um bucket S3 ou GCS). Este passo **não foi implementado** neste trabalho, que cobre a geração, a retenção e o teste do backup.

## 12. Teste de restauração

Um backup só vale se for testado. O teste foi feito em um PostgreSQL 18 descartável, em um container Docker, com a mesma versão do `pg_dump`.

    docker run -d --name pg_teste -e POSTGRES_PASSWORD=teste -p 5433:5432 postgres:18
    psql "postgresql://postgres:teste@localhost:5433/postgres" -c "CREATE DATABASE teste_restore;"
    pg_restore --no-owner --no-privileges -d "postgresql://postgres:teste@localhost:5433/teste_restore" ~/backups_hospital/hospital_<data>.dump

O `--no-owner --no-privileges` evita erros por roles do banco original que não existem no banco de teste. As permissões do projeto ficam no `06_permissoes.sql`.

**Verificação da integridade:** o script `08_contagem.sql` conta as linhas de todas as tabelas do schema `public`. Rodei o script no banco original e no restaurado, e o `diff` entre as duas saídas foi vazio.

| Tabela | Original | Restaurado |
|---|---|---|
| consulta | 40017 | 40017 |
| convenio | 15 | 15 |
| diagnostico | 16 | 16 |
| especialidade | 15 | 15 |
| exame | 15 | 15 |
| internacao | 15 | 15 |
| leito | 15 | 15 |
| medicamento | 15 | 15 |
| medico | 15 | 15 |
| paciente | 15 | 15 |
| pagamento | 17 | 17 |
| quarto | 15 | 15 |
| receita | 16 | 16 |
| unidade | 15 | 15 |

As 14 tabelas têm contagens idênticas, então o backup está íntegro. A evidência está em `evidencias/teste_restauracao.txt` e `evidencias/backup.log`.

## 13. Introdução ao MongoDB

O script `09_mongodb.js` cria o banco `hospital_mongo` com 3 collections ligadas ao domínio hospitalar e 18 documentos: `medicos` (4), `pacientes` (6) e `consultas` (8).

### 13.1 Modelagem: Embedding vs Referencing

A regra usada foi modelar pelo padrão de acesso. Dados lidos sempre juntos ficam embutidos. Dados lidos separadamente ou que crescem sem limite ficam referenciados.

**Embedding (dados embutidos)**

- `pacientes.convenio` e `pacientes.contatos`: o convênio e os contatos são lidos junto com o paciente. Cada paciente tem poucos, o tamanho é limitado e não há outro uso que exija uma collection própria.
- `medicos.especialidade`: a especialidade é consultada junto com o médico e muda raramente.
- `consultas.receitas`: a receita pertence a uma consulta e só é lida com ela. Fica embutida (no PostgreSQL ela é a tabela `receita`).

**Referencing (referências por `_id`)**

- `consultas.paciente_id` e `consultas.medico_id`: o número de consultas de um paciente ou médico cresce indefinidamente (a tabela `consulta` tem 40 mil linhas no PostgreSQL). Embutir as consultas no paciente faria o documento crescer sem controle. Elas também são consultadas de forma independente, por data, status e médico.

### 13.2 Flexibilidade de esquema

Nem todos os documentos têm os mesmos campos, e nenhum DDL foi necessário:

- `alergias` existe só em alguns pacientes.
- `acompanhante` existe só em pacientes que precisam de um (por exemplo, uma criança).
- `convenio` não existe em pacientes particulares.
- `telemedicina` e `convenios_aceitos` existem só em alguns médicos.
- `receitas` varia de 0 a 2 itens por consulta.

No PostgreSQL, cada um desses casos exigiria colunas opcionais (NULL) ou tabelas auxiliares.

### 13.3 Consultas realizadas

- `find` com filtro e projeção: pacientes da Unimed, em ordem alfabética (`sort`), mostrando só nome e plano.
- Filtro com comparação: consultas realizadas com valor >= 250, da mais cara para a mais barata.
- Filtro por campo inexistente: pacientes particulares (`$exists: false`).
- Filtro em array: pacientes com alguma alergia.
- Junção com `$lookup`: consultas realizadas com o nome do paciente e do médico.
- Busca por texto (`$text`) em `diagnostico`.

A saída completa está em `mongodb_saida.txt`.

### 13.4 Índices e explain()

Foram criados 3 índices: simples e único em `pacientes.cpf`, composto em `consultas` (`paciente_id` ascendente e `data_hora` descendente) e de texto em `consultas.diagnostico`. O `explain("executionStats")` da consulta "consultas de um paciente, da mais recente para a mais antiga" foi executado antes e depois do índice composto:

]633;E;echo;6c1bedec-bc7d-45ec-bfaf-5f05614923fb]633;C
    == explain ANTES do índice composto ==
    {
      estagio: 'COLLSCAN (varre tudo)',
      docsExaminados: 8,
      retornados: 2
    }
    
    == Criando índices ==
    cpf_1
    paciente_id_1_data_hora_-1
    diagnostico_text
    
    == explain DEPOIS do índice composto ==
    {
      estagio: 'IXSCAN (usa índice)',
      docsExaminados: 2,
      retornados: 2
    }
    

Antes do índice composto, o plano é `COLLSCAN` (a collection inteira é varrida). Depois, passa a ser `IXSCAN` (o índice é usado). Como a collection de teste é pequena, a diferença em documentos examinados é pequena. O ganho aumenta com o volume, e o mesmo índice resolve o filtro por paciente e a ordenação por data.

## 14. Comparação: PostgreSQL vs MongoDB no domínio hospitalar

| Critério | PostgreSQL | MongoDB |
|---|---|---|
| Modelo | Tabelas com esquema fixo e chaves estrangeiras | Documentos com esquema flexível |
| Integridade | Forte: FK, constraints, transações ACID entre várias tabelas | Mais frouxa: referências por `_id` não são verificadas pelo banco |
| Relacionamentos | JOINs eficientes entre muitas entidades | Embedding evita joins, mas `$lookup` é mais limitado |
| Evolução do esquema | Exige migração (`ALTER TABLE`) | Campos novos aparecem sem migração |
| Consultas analíticas | SQL completo (agregações, janelas, relatórios) | Pipeline de agregação, bom para documentos, mais trabalhoso para relatórios relacionais |

**Onde o PostgreSQL é mais adequado:** dados com regras rígidas de integridade, como `pagamento`, `internacao`, `leito` e `quarto` (um leito só pode ter uma internação ativa por vez, e um pagamento não pode existir sem consulta). Esses casos pedem transações ACID e chaves estrangeiras, e os relatórios cruzam muitas tabelas (ver `04_consultas.sql` e `05_transacoes.sql`).

**Onde o MongoDB se sobressai:** o prontuário eletrônico do paciente, que reúne em um só documento dados heterogêneos (alergias, acompanhante, laudos de exames de tipos diferentes, histórico de receitas) e é lido de uma vez só. Também serve para logs de eventos e dados de dispositivos médicos, com formatos variáveis e alto volume de escrita.

**Conclusão:** em um sistema hospitalar real, as duas tecnologias se complementam. O PostgreSQL guarda o núcleo transacional e financeiro, e o MongoDB guarda dados flexíveis, como o prontuário.

## 15. Arquivos desta etapa

- `08_backup.sh`: backup diário com `pg_dump -Fc`, retenção de 30 dias e tratamento de erros.
- `08_contagem.sql`: contagem de linhas por tabela, usada no teste de restauração.
- `evidencias/`: saída da comparação (`teste_restauracao.txt`) e log do backup (`backup.log`).
- `09_mongodb.js`: criação das collections, inserção, consultas, índices e `explain()` no MongoDB.
- `mongodb_saida.txt`: saída da execução do `09_mongodb.js`.
