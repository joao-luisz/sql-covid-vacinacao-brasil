/*
 * ========================================
 * SCHEMA DO BANCO DE DADOS
 * Projeto: Análise SQL - COVID-19 e Vacinação Brasil
 * ========================================
 * 
 * Este script cria as tabelas para armazenar dados de COVID-19 e Vacinação.
 * Execute este script antes de importar os dados CSV.
 */

-- Desabilita foreign keys temporariamente para facilitar recriação
PRAGMA foreign_keys = OFF;

-- Remove tabelas se já existirem
DROP TABLE IF EXISTS vacinacao;
DROP TABLE IF EXISTS covid_casos;
DROP TABLE IF EXISTS estados;

-- ========================================
-- TABELA DIMENSIONAL: Estados
-- ========================================
CREATE TABLE estados (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sigla TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    regiao TEXT NOT NULL,
    populacao INTEGER,
    
    -- Índices
    CONSTRAINT ck_sigla CHECK (length(sigla) = 2),
    CONSTRAINT ck_regiao CHECK (regiao IN ('Norte', 'Nordeste', 'Centro-Oeste', 'Sudeste', 'Sul'))
);

-- Insere dados dos estados brasileiros
INSERT INTO estados (sigla, nome, regiao, populacao) VALUES
('AC', 'Acre', 'Norte', 906876),
('AL', 'Alagoas', 'Nordeste', 3365351),
('AP', 'Amapá', 'Norte', 877613),
('AM', 'Amazonas', 'Norte', 4269995),
('BA', 'Bahia', 'Nordeste', 14985284),
('CE', 'Ceará', 'Nordeste', 9240580),
('DF', 'Distrito Federal', 'Centro-Oeste', 3094325),
('ES', 'Espírito Santo', 'Sudeste', 4108508),
('GO', 'Goiás', 'Centro-Oeste', 7206589),
('MA', 'Maranhão', 'Nordeste', 7153262),
('MT', 'Mato Grosso', 'Centro-Oeste', 3567234),
('MS', 'Mato Grosso do Sul', 'Centro-Oeste', 2839188),
('MG', 'Minas Gerais', 'Sudeste', 21411923),
('PA', 'Pará', 'Norte', 8777124),
('PB', 'Paraíba', 'Nordeste', 4059905),
('PR', 'Paraná', 'Sul', 11597484),
('PE', 'Pernambuco', 'Nordeste', 9674793),
('PI', 'Piauí', 'Nordeste', 3289290),
('RJ', 'Rio de Janeiro', 'Sudeste', 17463349),
('RN', 'Rio Grande do Norte', 'Nordeste', 3560903),
('RS', 'Rio Grande do Sul', 'Sul', 11466630),
('RO', 'Rondônia', 'Norte', 1815278),
('RR', 'Roraima', 'Norte', 652713),
('SC', 'Santa Catarina', 'Sul', 7338473),
('SP', 'São Paulo', 'Sudeste', 46649132),
('SE', 'Sergipe', 'Nordeste', 2338474),
('TO', 'Tocantins', 'Norte', 1607363);

-- ========================================
-- TABELA FATO: Casos de COVID-19
-- ========================================
CREATE TABLE covid_casos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data DATE NOT NULL,
    estado TEXT NOT NULL,
    casos_acumulados INTEGER DEFAULT 0,
    obitos_acumulados INTEGER DEFAULT 0,
    casos_novos INTEGER DEFAULT 0,
    obitos_novos INTEGER DEFAULT 0,
    populacao_estimada INTEGER,
    
    -- Foreign Key
    FOREIGN KEY (estado) REFERENCES estados(sigla),
    
    -- Constraints
    CONSTRAINT ck_casos_positivos CHECK (casos_acumulados >= 0),
    CONSTRAINT ck_obitos_positivos CHECK (obitos_acumulados >= 0)
);

-- Índices para otimizar queries
CREATE INDEX idx_covid_data ON covid_casos(data);
CREATE INDEX idx_covid_estado ON covid_casos(estado);
CREATE INDEX idx_covid_estado_data ON covid_casos(estado, data);

-- ========================================
-- TABELA FATO: Vacinação
-- ========================================
CREATE TABLE vacinacao (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    data DATE NOT NULL,
    estado TEXT NOT NULL,
    faixa_etaria TEXT NOT NULL,
    doses_1d_acumuladas INTEGER DEFAULT 0,
    doses_2d_acumuladas INTEGER DEFAULT 0,
    doses_reforco_acumuladas INTEGER DEFAULT 0,
    doses_1d_novas INTEGER DEFAULT 0,
    doses_2d_novas INTEGER DEFAULT 0,
    doses_reforco_novas INTEGER DEFAULT 0,
    populacao_faixa INTEGER,
    
    -- Foreign Key
    FOREIGN KEY (estado) REFERENCES estados(sigla),
    
    -- Constraints
    CONSTRAINT ck_faixa CHECK (faixa_etaria IN ('0-17', '18-29', '30-39', '40-49', '50-59', '60-69', '70-79', '80+')),
    CONSTRAINT ck_doses_positivas CHECK (doses_1d_acumuladas >= 0)
);

-- Índices para otimizar queries
CREATE INDEX idx_vac_data ON vacinacao(data);
CREATE INDEX idx_vac_estado ON vacinacao(estado);
CREATE INDEX idx_vac_faixa ON vacinacao(faixa_etaria);
CREATE INDEX idx_vac_estado_data ON vacinacao(estado, data);

-- Reabilita foreign keys
PRAGMA foreign_keys = ON;

-- ========================================
-- VIEWS AUXILIARES
-- ========================================

-- View: Dados consolidados por estado e data
CREATE VIEW vw_covid_diario AS
SELECT 
    c.data,
    e.sigla AS estado,
    e.nome AS estado_nome,
    e.regiao,
    c.casos_novos,
    c.obitos_novos,
    c.casos_acumulados,
    c.obitos_acumulados,
    e.populacao,
    -- Métricas calculadas
    ROUND(CAST(c.casos_acumulados AS FLOAT) / e.populacao * 100000, 2) AS casos_por_100k,
    ROUND(CAST(c.obitos_acumulados AS FLOAT) / e.populacao * 100000, 2) AS obitos_por_100k,
    ROUND(CAST(c.obitos_acumulados AS FLOAT) / NULLIF(c.casos_acumulados, 0) * 100, 2) AS letalidade_pct
FROM covid_casos c
INNER JOIN estados e ON c.estado = e.sigla;

-- View: Vacinação consolidada por estado
CREATE VIEW vw_vacinacao_resumo AS
SELECT 
    v.data,
    e.sigla AS estado,
    e.nome AS estado_nome,
    e.regiao,
    SUM(v.doses_1d_acumuladas) AS total_1d,
    SUM(v.doses_2d_acumuladas) AS total_2d,
    SUM(v.doses_reforco_acumuladas) AS total_reforco,
    e.populacao,
    -- Cobertura vacinal
    ROUND(CAST(SUM(v.doses_1d_acumuladas) AS FLOAT) / e.populacao * 100, 2) AS cobertura_1d_pct,
    ROUND(CAST(SUM(v.doses_2d_acumuladas) AS FLOAT) / e.populacao * 100, 2) AS cobertura_2d_pct
FROM vacinacao v
INNER JOIN estados e ON v.estado = e.sigla
GROUP BY v.data, e.sigla, e.nome, e.regiao, e.populacao;

-- ========================================
-- Finalização
-- ========================================
-- Schema criado com sucesso!
-- Próximo passo: Executar load_data.sql ou importar os CSVs manualmente
