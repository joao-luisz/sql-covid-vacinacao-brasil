/*
 * ========================================
 * SCRIPT DE CARGA DE DADOS
 * ========================================
 * 
 * Este script importa os dados dos arquivos CSV para o banco de dados.
 * 
 * ATENÇÃO: A sintaxe varia conforme o SGBD:
 * - SQLite: Usa .mode csv e .import
 * - PostgreSQL: Usa COPY
 * - MySQL: Usa LOAD DATA INFILE
 * 
 * O exemplo abaixo é para SQLite (mais comum para portfólio local).
 */

-- ========================================
-- IMPORTAÇÃO PARA SQLITE
-- ========================================

-- Execute estes comandos no terminal SQLite:
/*
sqlite3 covid_vacinacao.db

.read database/schema.sql

.mode csv
.headers on

.import --skip 1 data/covid_casos.csv covid_casos
.import --skip 1 data/vacinacao.csv vacinacao

-- Verifica importação
SELECT COUNT(*) AS total_casos FROM covid_casos;
SELECT COUNT(*) AS total_vacinacao FROM vacinacao;
*/

-- ========================================
-- IMPORTAÇÃO ALTERNATIVA (PostgreSQL)
-- ========================================

/*
-- Criar banco
CREATE DATABASE covid_vacinacao;
\c covid_vacinacao

-- Executar schema
\i database/schema.sql

-- Importar dados
COPY covid_casos(data, estado, casos_acumulados, obitos_acumulados, casos_novos, obitos_novos, populacao_estimada)
FROM '/caminho/absoluto/data/covid_casos.csv'
DELIMITER ','
CSV HEADER;

COPY vacinacao(data, estado, faixa_etaria, doses_1d_acumuladas, doses_2d_acumuladas, doses_reforco_acumuladas, doses_1d_novas, doses_2d_novas, doses_reforco_novas, populacao_faixa)
FROM '/caminho/absoluto/data/vacinacao.csv'
DELIMITER ','
CSV HEADER;
*/

-- ========================================
-- VALIDAÇÃO DOS DADOS
-- ========================================

-- Verifica total de registros
SELECT 'COVID Casos' AS tabela, COUNT(*) AS total FROM covid_casos
UNION ALL
SELECT 'Vacinação', COUNT(*) FROM vacinacao
UNION ALL
SELECT 'Estados', COUNT(*) FROM estados;

-- Verifica período dos dados
SELECT 
    'COVID' AS fonte,
    MIN(data) AS data_inicio,
    MAX(data) AS data_fim,
    COUNT(DISTINCT data) AS dias_distintos
FROM covid_casos
UNION ALL
SELECT 
    'Vacinação',
    MIN(data),
    MAX(data),
    COUNT(DISTINCT data)
FROM vacinacao;

-- Verifica estados cobertos
SELECT 
    'COVID' AS fonte,
    COUNT(DISTINCT estado) AS estados_distintos
FROM covid_casos
UNION ALL
SELECT 
    'Vacinação',
    COUNT(DISTINCT estado)
FROM vacinacao;
