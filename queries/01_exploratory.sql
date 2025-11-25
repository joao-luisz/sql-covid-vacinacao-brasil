/*
 * ========================================
 * QUERY 01: ANÁLISES EXPLORATÓRIAS BÁSICAS
 * ========================================
 * 
 * Objetivo: Entender o panorama geral dos dados de COVID-19 e Vacinação
 * Técnicas SQL: Agregações, GROUP BY, ORDER BY, ROUND
 */

-- ========================================
-- 1.1 Visão Geral Nacional - COVID-19
-- ========================================

SELECT 
    'Panorama COVID-19 Brasil' AS analise,
    COUNT(DISTINCT estado) AS total_estados,
    MIN(data) AS primeira_data,
    MAX(data) AS ultima_data,
    SUM(casos_novos) AS total_casos_periodo,
    SUM(obitos_novos) AS total_obitos_periodo,
    ROUND(AVG(casos_novos), 2) AS media_casos_diarios,
    ROUND(AVG(obitos_novos), 2) AS media_obitos_diarios
FROM covid_casos;

-- ========================================
-- 1.2 Top 10 Estados com Mais Casos Acumulados
-- ========================================

SELECT 
    e.nome AS estado,
    e.regiao,
    MAX(c.casos_acumulados) AS total_casos,
    MAX(c.obitos_acumulados) AS total_obitos,
    e.populacao,
    -- Casos por 100 mil habitantes
    ROUND(MAX(c.casos_acumulados) * 100000.0 / e.populacao, 2) AS casos_por_100k,
    -- Taxa de letalidade
    ROUND(MAX(c.obitos_acumulados) * 100.0 / NULLIF(MAX(c.casos_acumulados), 0), 2) AS letalidade_pct
FROM covid_casos c
INNER JOIN estados e ON c.estado = e.sigla
GROUP BY e.nome, e.regiao, e.populacao
ORDER BY total_casos DESC
LIMIT 10;

-- ========================================
-- 1.3 Estatísticas por Região
-- ========================================

SELECT 
    e.regiao,
    COUNT(DISTINCT e.sigla) AS total_estados,
    SUM(e.populacao) AS populacao_total,
    SUM(MAX(c.casos_acumulados)) AS total_casos,
    SUM(MAX(c.obitos_acumulados)) AS total_obitos,
    ROUND(SUM(MAX(c.casos_acumulados)) * 100000.0 / SUM(e.populacao), 2) AS casos_por_100k,
    ROUND(SUM(MAX(c.obitos_acumulados)) * 100.0 / NULLIF(SUM(MAX(c.casos_acumulados)), 0), 2) AS letalidade_pct
FROM covid_casos c
INNER JOIN estados e ON c.estado = e.sigla
GROUP BY e.regiao
ORDER BY total_casos DESC;

-- ========================================
-- 1.4 Panorama de Vacinação Nacional
-- ========================================

SELECT 
    'Panorama Vacinação Brasil' AS analise,
    COUNT(DISTINCT estado) AS total_estados,
    COUNT(DISTINCT faixa_etaria) AS total_faixas,
    SUM(doses_1d_novas) AS total_1d_aplicadas,
    SUM(doses_2d_novas) AS total_2d_aplicadas,
    SUM(doses_reforco_novas) AS total_reforco_aplicadas,
    SUM(doses_1d_novas + doses_2d_novas + doses_reforco_novas) AS total_doses
FROM vacinacao;

-- ========================================
-- 1.5 Cobertura Vacinal por Estado (Última Data)
-- ========================================

WITH ultima_data AS (
    SELECT MAX(data) AS data_ref
    FROM vacinacao
),
vacinacao_atual AS (
    SELECT 
        v.estado,
        SUM(v.doses_1d_acumuladas) AS total_1d,
        SUM(v.doses_2d_acumuladas) AS total_2d,
        SUM(v.doses_reforco_acumuladas) AS total_reforco
    FROM vacinacao v
    INNER JOIN ultima_data ud ON v.data = ud.data_ref
    GROUP BY v.estado
)
SELECT 
    e.nome AS estado,
    e.regiao,
    e.populacao,
    va.total_1d,
    va.total_2d,
    va.total_reforco,
    -- Cobertura percentual
    ROUND(va.total_1d * 100.0 / e.populacao, 2) AS cobertura_1d_pct,
    ROUND(va.total_2d * 100.0 / e.populacao, 2) AS cobertura_2d_pct,
    ROUND(va.total_reforco * 100.0 / e.populacao, 2) AS cobertura_reforco_pct
FROM vacinacao_atual va
INNER JOIN estados e ON va.estado = e.sigla
ORDER BY cobertura_2d_pct DESC;

-- ========================================
-- 1.6 Distribuição de Doses por Faixa Etária
-- ========================================

WITH total_nacional AS (
    SELECT SUM(doses_2d_acumuladas) AS total
    FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
)
SELECT 
    v.faixa_etaria,
    SUM(v.doses_2d_acumuladas) AS doses_aplicadas,
    ROUND(SUM(v.doses_2d_acumuladas) * 100.0 / tn.total, 2) AS percentual_total
FROM vacinacao v
CROSS JOIN total_nacional tn
WHERE v.data = (SELECT MAX(data) FROM vacinacao)
GROUP BY v.faixa_etaria, tn.total
ORDER BY 
    CASE v.faixa_etaria
        WHEN '0-17' THEN 1
        WHEN '18-29' THEN 2
        WHEN '30-39' THEN 3
        WHEN '40-49' THEN 4
        WHEN '50-59' THEN 5
        WHEN '60-69' THEN 6
        WHEN '70-79' THEN 7
        WHEN '80+' THEN 8
    END;

-- ========================================
-- INSIGHTS ESPERADOS:
-- ========================================
/*
✓ Estados mais populosos têm mais casos em absoluto, mas não necessariamente maior incidência
✓ Regiões Norte e Nordeste podem ter letalidade maior por dificuldades de acesso à saúde
✓ Cobertura vacinal deve ser maior em faixas etárias 60+ (grupos prioritários)
✓ Estados desenvolvidos (SP, RJ, SC) tendem a ter maior cobertura vacinal
*/
