/*
 * ========================================
 * QUERY 05: INSIGHTS AVANÇADOS
 * ========================================
 * 
 * Objetivo: Análises complexas e correlações entre variáveis
 * Técnicas SQL: CTEs complexas, Múltiplos JOINs, Agregações aninhadas, ROLLUP
 */

-- ========================================
-- 5.1 Correlação: Vacinação x Redução de Casos
-- ========================================

WITH periodos AS (
    -- Período ANTES de alta cobertura (primeiros 2 meses)
    SELECT 
        estado,
        AVG(casos_novos) AS media_casos_antes
    FROM covid_casos
    WHERE data BETWEEN (SELECT MIN(data) FROM covid_casos) 
        AND date((SELECT MIN(data) FROM covid_casos), '+60 days')
    GROUP BY estado
),
periodos_depois AS (
    -- Período DEPOIS de alta cobertura (últimos 2 meses)
    SELECT 
        estado,
        AVG(casos_novos) AS media_casos_depois
    FROM covid_casos
    WHERE data >= date((SELECT MAX(data) FROM covid_casos), '-60 days')
    GROUP BY estado
),
cobertura_atual AS (
    SELECT 
        estado,
        ROUND(SUM(doses_2d_acumuladas) * 100.0 / MAX(populacao_faixa) * 8, 2) AS cobertura_2d_pct
FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY estado
)
SELECT 
    e.nome AS estado,
    ROUND(pa.media_casos_antes, 0) AS casos_diarios_antes,
    ROUND(pd.media_casos_depois, 0) AS casos_diarios_depois,
    ca.cobertura_2d_pct,
    -- Variação percentual de casos
    ROUND(
        (pd.media_casos_depois - pa.media_casos_antes) * 100.0 / NULLIF(pa.media_casos_antes, 0),
        2
    ) AS variacao_casos_pct,
    CASE 
        WHEN pd.media_casos_depois < pa.media_casos_antes THEN 'Redução'
        ELSE 'Aumento'
    END AS tendencia
FROM periodos pa
INNER JOIN periodos_depois pd ON pa.estado = pd.estado
INNER JOIN cobertura_atual ca ON pa.estado = ca.estado
INNER JOIN estados e ON pa.estado = e.sigla
WHERE ca.cobertura_2d_pct > 50  -- Filtrar estados com cobertura mínima
ORDER BY variacao_casos_pct ASC;

-- ========================================
-- 5.2 Análise Multidimensional: Casos, Óbitos e Vacinação
-- ========================================

WITH metricas_estado AS (
    SELECT 
        c.estado,
        MAX(c.casos_acumulados) AS total_casos,
        MAX(c.obitos_acumulados) AS total_obitos,
        ROUND(MAX(c.obitos_acumulados) * 100.0 / NULLIF(MAX(c.casos_acumulados), 0), 2) AS letalidade
    FROM covid_casos c
    GROUP BY c.estado
),
vac_estado AS (
    SELECT 
        estado,
        SUM(doses_2d_acumuladas) AS doses_2d
    FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY estado
)
SELECT 
    e.nome AS estado,
    e.regiao,
    e.populacao,
    me.total_casos,
    me.total_obitos,
    me.letalidade AS letalidade_pct,
    ve.doses_2d,
    ROUND(ve.doses_2d * 100.0 / e.populacao, 2) AS cobertura_2d_pct,
    -- Classificação composta
    CASE 
        WHEN me.letalidade < 2 AND ve.doses_2d * 100.0 / e.populacao > 80 THEN 'Excelente'
        WHEN me.letalidade < 2.5 AND ve.doses_2d * 100.0 / e.populacao > 70 THEN 'Bom'
        WHEN me.letalidade < 3 AND ve.doses_2d * 100.0 / e.populacao > 60 THEN 'Regular'
        ELSE 'Necessita Atenção'
    END AS status_geral
FROM metricas_estado me
INNER JOIN vac_estado ve ON me.estado = ve.estado
INNER JOIN estados e ON me.estado = e.sigla
ORDER BY status_geral, e.nome;

-- ========================================
-- 5.3 Análise com ROLLUP (Totalizações Hierárquicas)
-- ========================================

-- Nota: SQLite não suporta ROLLUP nativamente, usaremos UNION para simular

-- Total por Região e Estado
SELECT 
    e.regiao,
    e.nome AS estado,
    SUM(v.doses_2d_acumuladas) AS total_doses
FROM vacinacao v
INNER JOIN estados e ON v.estado = e.sigla
WHERE v.data = (SELECT MAX(data) FROM vacinacao)
GROUP BY e.regiao, e.nome

UNION ALL

-- Subtotal por Região
SELECT 
    e.regiao,
    'TOTAL ' || e.regiao AS estado,
    SUM(v.doses_2d_acumuladas)
FROM vacinacao v
INNER JOIN estados e ON v.estado = e.sigla
WHERE v.data = (SELECT MAX(data) FROM vacinacao)
GROUP BY e.regiao

UNION ALL

-- Total Geral
SELECT 
    'BRASIL',
    'TOTAL GERAL',
    SUM(v.doses_2d_acumuladas)
FROM vacinacao v
WHERE v.data = (SELECT MAX(data) FROM vacinacao)

ORDER BY regiao, estado;

-- ========================================
-- 5.4 Top Insights Acionáveis (Resumo Executivo)
-- ========================================

WITH ranking_problemas AS (
    SELECT 
        'Baixa Cobertura em Jovens' AS problema,
        COUNT(*) AS estados_afetados,
        'Intensificar campanhas direcionadas (redes sociais)' AS recomendacao
    FROM vacinacao v
    INNER JOIN estados e ON v.estado = e.sigla
    WHERE v.faixa_etaria = '18-29'
        AND v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY v.estado
    HAVING SUM(v.doses_2d_acumuladas) * 100.0 / SUM(v.populacao_faixa) < 70
    
    UNION ALL
    
    SELECT 
        'Alta Taxa de Desistência (1ª → 2ª dose)',
        COUNT(DISTINCT estado),
        'Busca ativa e facilitação de agendamento'
    FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY estado
    HAVING (SUM(doses_1d_acumuladas) - SUM(doses_2d_acumuladas)) * 100.0 / SUM(doses_1d_acumuladas) > 15
)
SELECT * FROM ranking_problemas;

-- ========================================
-- 5.5 Projeção de Meta (Quanto falta para 90% de cobertura)
-- ========================================

WITH situacao_atual AS (
    SELECT 
        v.estado,
        e.populacao,
        SUM(v.doses_2d_acumuladas) AS doses_aplicadas,
        ROUND(SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao, 2) AS cobertura_atual
    FROM vacinacao v
    INNER JOIN estados e ON v.estado = e.sigla
    WHERE v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY v.estado, e.populacao
)
SELECT 
    e.nome AS estado,
    sa.cobertura_atual || '%' AS cobertura,
    CASE 
        WHEN sa.cobertura_atual >= 90 THEN 'Meta Atingida'
        ELSE CAST(ROUND((e.populacao * 0.9) - sa.doses_aplicadas, 0) AS INTEGER) || ' doses'
    END AS faltam_para_90pct,
    CASE 
        WHEN sa.cobertura_atual >= 90 THEN 0
        ELSE ROUND(((e.populacao * 0.9) - sa.doses_aplicadas) * 100.0 / e.populacao, 2)
    END AS pct_populacional_restante
FROM situacao_atual sa
INNER JOIN estados e ON sa.estado = e.sigla
ORDER BY pct_populacional_restante DESC;

-- ========================================
-- 5.6 Análise de Outliers (Estados Excepcionais)
-- ========================================

WITH estatisticas_gerais AS (
    SELECT 
        AVG(cobertura) AS media_nacional,
        -- Desvio padrão simulado (SQLite não tem STDDEV)
        AVG(ABS(cobertura - (SELECT AVG(cobertura) FROM (
            SELECT SUM(doses_2d_acumuladas) * 100.0 / SUM(populacao_faixa) AS cobertura
            FROM vacinacao v
            WHERE data = (SELECT MAX(data) FROM vacinacao)
            GROUP BY estado
        )))) AS desvio_medio
    FROM (
        SELECT 
            estado,
            SUM(doses_2d_acumuladas) * 100.0 / SUM(populacao_faixa) AS cobertura
        FROM vacinacao
        WHERE data = (SELECT MAX(data) FROM vacinacao)
        GROUP BY estado
    )
),
cobertura_estados AS (
    SELECT 
        v.estado,
        e.nome,
        ROUND(SUM(v.doses_2d_acumuladas) * 100.0 / e.populacao, 2) AS cobertura
    FROM vacinacao v
    INNER JOIN estados e ON v.estado = e.sigla
    WHERE v.data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY v.estado, e.nome, e.populacao
)
SELECT 
    ce.nome AS estado,
    ce.cobertura,
    ROUND(eg.media_nacional, 2) AS media_nacional,
    ROUND(ce.cobertura - eg.media_nacional, 2) AS diferenca_media,
    CASE 
        WHEN ce.cobertura > eg.media_nacional + (eg.desvio_medio * 1.5) THEN 'Desempenho Excepcional'
        WHEN ce.cobertura < eg.media_nacional - (eg.desvio_medio * 1.5) THEN 'Necessita Intervenção'
        ELSE 'Normal'
    END AS classificacao
FROM cobertura_estados ce
CROSS JOIN estatisticas_gerais eg
WHERE ce.cobertura > eg.media_nacional + (eg.desvio_medio * 1.5)
    OR ce.cobertura < eg.media_nacional - (eg.desvio_medio * 1.5)
ORDER BY ce.cobertura DESC;

-- ========================================
-- INSIGHTS ESPERADOS:
-- ========================================
/*
✓ Correlação positiva: maior vacinação → menor crescimento de casos
✓ Estados com baixa letalidade + alta vacinação são referência
✓ Jovens são principal gap em quase todos os estados
✓ Necessidade de 10-20% adicional para atingir meta de 90%
✓ Desigualdade regional persiste mesmo com avanço da campanha
*/
