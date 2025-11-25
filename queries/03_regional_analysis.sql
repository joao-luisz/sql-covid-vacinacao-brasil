/*
 * ========================================
 * QUERY 03: ANÁLISE REGIONAL COMPARATIVA
 * ========================================
 * 
 * Objetivo: Comparar desempenho entre estados e regiões
 * Técnicas SQL: JOINs, RANK(), DENSE_RANK(), CASE, Subqueries
 */

-- ========================================
-- 3.1 Ranking de Estados por Cobertura Vacinal
-- ========================================

WITH cobertura_estados AS (
    SELECT 
        v.estado,
        SUM(v.doses_2d_acumuladas) AS total_2d
    FROM vacinacao v
    WHERE v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY v.estado
)
SELECT 
    RANK() OVER (ORDER BY ce.total_2d * 100.0 / e.populacao DESC) AS ranking,
    e.nome AS estado,
    e.regiao,
    e.populacao,
    ce.total_2d AS doses_2d,
    ROUND(ce.total_2d * 100.0 / e.populacao, 2) AS cobertura_pct,
    -- Classificação
    CASE 
        WHEN ce.total_2d * 100.0 / e.populacao >= 90 THEN 'Excelente'
        WHEN ce.total_2d * 100.0 / e.populacao >= 75 THEN 'Bom'
        WHEN ce.total_2d * 100.0 / e.populacao >= 60 THEN 'Regular'
        ELSE 'Baixo'
    END AS classificacao
FROM cobertura_estados ce
INNER JOIN estados e ON ce.estado = e.sigla
ORDER BY ranking;

-- ========================================
-- 3.2 Comparação Entre Regiões do Brasil
-- ========================================

WITH dados_regiao AS (
    SELECT 
        e.regiao,
        SUM(e.populacao) AS populacao_total,
        MAX(c.casos_acumulados) AS casos_totais,
        MAX(c.obitos_acumulados) AS obitos_totais
    FROM covid_casos c
    INNER JOIN estados e ON c.estado = e.sigla
    WHERE c.data = (SELECT MAX(data) FROM covid_casos)
    GROUP BY e.regiao
),
vacinacao_regiao AS (
    SELECT 
        e.regiao,
        SUM(v.doses_2d_acumuladas) AS doses_2d_total
    FROM vacinacao v
    INNER JOIN estados e ON v.estado = e.sigla
    WHERE v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY e.regiao
)
SELECT 
    dr.regiao,
    dr.populacao_total,
    dr.casos_totais,
    dr.obitos_totais,
    vr.doses_2d_total,
    -- Indicadores por 100k habitantes
    ROUND(dr.casos_totais * 100000.0 / dr.populacao_total, 2) AS casos_por_100k,
    ROUND(dr.obitos_totais * 100000.0 / dr.populacao_total, 2) AS obitos_por_100k,
    -- Letalidade
    ROUND(dr.obitos_totais * 100.0 / NULLIF(dr.casos_totais, 0), 2) AS letalidade_pct,
    -- Cobertura vacinal
    ROUND(vr.doses_2d_total * 100.0 / dr.populacao_total, 2) AS cobertura_2d_pct
FROM dados_regiao dr
INNER JOIN vacinacao_regiao vr ON dr.regiao = vr.regiao
ORDER BY dr.regiao;

-- ========================================
-- 3.3 Melhores e Piores Desempenhos
-- ========================================

-- Top 5 estados com MELHOR cobertura vacinal
WITH cobertura AS (
    SELECT 
        e.nome AS estado,
        ROUND(SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao, 2) AS cobertura_pct
    FROM vacinacao v
    INNER JOIN estados e ON v.estado = e.sigla
    WHERE v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY e.nome, e.populacao
)
SELECT 
    'Top 5 - Melhor Cobertura' AS categoria,
    estado,
    cobertura_pct
FROM cobertura
ORDER BY cobertura_pct DESC
LIMIT 5;

-- Top 5 estados com PIOR cobertura vacinal
-- (executar separadamente ou usar UNION)

-- ========================================
-- 3.4 Relação Casos x População
-- ========================================

SELECT 
    e.nome AS estado,
    e.regiao,
    CASE 
        WHEN e.populacao >= 10000000 THEN 'Grande'
        WHEN e.populacao >= 5000000 THEN 'Médio'
        ELSE 'Pequeno'
    END AS porte_populacional,
    e.populacao,
    MAX(c.casos_acumulados) AS casos_totais,
    ROUND(MAX(c.casos_acumulados) * 100000.0 / e.populacao, 2) AS casos_por_100k
FROM covid_casos c
INNER JOIN estados e ON c.estado = e.sigla
GROUP BY e.nome, e.regiao, e.populacao
ORDER BY casos_por_100k DESC;

-- ========================================
-- 3.5 Estados Acima e Abaixo da Média Nacional
-- ========================================

WITH media_nacional AS (
    SELECT 
        AVG(cobertura_pct) AS media_cobertura
    FROM (
        SELECT 
            SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao AS cobertura_pct
        FROM vacinacao v
        INNER JOIN estados e ON v.estado = e.sigla
        WHERE v.data = (SELECT MAX(data) FROM vacinacao)
        GROUP BY e.sigla, e.populacao
    )
)
SELECT 
    e.nome AS estado,
    ROUND(SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao, 2) AS cobertura_pct,
    ROUND(mn.media_cobertura, 2) AS media_nacional,
    ROUND(
        (SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao) - mn.media_cobertura,
        2
    ) AS diferenca_media,
    CASE 
        WHEN SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao > mn.media_cobertura 
        THEN 'Acima da Média'
        ELSE 'Abaixo da Média'
    END AS posicionamento
FROM vacinacao v
INNER JOIN estados e ON v.estado = e.sigla
CROSS JOIN media_nacional mn
WHERE v.data = (SELECT MAX(data) FROM vacinacao)
GROUP BY e.nome, e.populacao, mn.media_cobertura
ORDER BY cobertura_pct DESC;

-- ========================================
-- 3.6 Análise de Disparidade Regional
-- ========================================

WITH cobertura_estados AS (
    SELECT 
        e.regiao,
        e.nome AS estado,
        ROUND(SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao, 2) AS cobertura_pct
    FROM vacinacao v
    INNER JOIN estados e ON v.estado = e.sigla
    WHERE v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY e.regiao, e.nome, e.populacao
),
estatisticas_regiao AS (
    SELECT 
        regiao,
        MAX(cobertura_pct) AS max_cobertura,
        MIN(cobertura_pct) AS min_cobertura,
        ROUND(AVG(cobertura_pct), 2) AS media_cobertura
    FROM cobertura_estados
    GROUP BY regiao
)
SELECT 
    regiao,
    min_cobertura,
    media_cobertura,
    max_cobertura,
    ROUND(max_cobertura - min_cobertura, 2) AS amplitude,
    -- Percentual de disparidade interna
    ROUND(
        (max_cobertura - min_cobertura) * 100.0 / NULLIF(max_cobertura, 0),
        2
    ) AS disparidade_pct
FROM estatisticas_regiao
ORDER BY disparidade_pct DESC;

-- ========================================
-- INSIGHTS ESPERADOS:
-- ========================================
/*
✓ Regiões Sul e Sudeste tendem a ter melhor cobertura vacinal
✓ Estados com maior PIB per capita vacinam mais rápido
✓ Pode haver grande disparidade dentro de uma mesma região
✓ População total não é fator determinante de sucesso vacinal
*/
