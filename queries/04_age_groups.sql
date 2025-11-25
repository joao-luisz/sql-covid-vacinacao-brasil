/*
 * ========================================
 * QUERY 04: ANÁLISE POR FAIXA ETÁRIA
 * ========================================
 * 
 * Objetivo: Identificar padrões e gaps de vacinação por idade
 * Técnicas SQL: CASE (categorização), GROUP BY, Subqueries
 */

-- ========================================
-- 4.1 Cobertura Vacinal por Faixa Etária (Nacional)
-- ========================================

WITH total_faixas AS (
    SELECT 
        faixa_etaria,
        SUM(populacao_faixa) AS pop_total_faixa,
        SUM(doses_1d_acumuladas) AS doses_1d_total,
        SUM(doses_2d_acumuladas) AS doses_2d_total,
        SUM(doses_reforco_acumuladas) AS doses_reforco_total
    FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY faixa_etaria
)
SELECT 
    faixa_etaria,
    pop_total_faixa AS populacao,
    doses_1d_total,
    doses_2d_total,
    doses_reforco_total,
    -- Cobertura percentual
    ROUND(doses_1d_total * 100.0 / pop_total_faixa, 2) AS cobertura_1d_pct,
    ROUND(doses_2d_total * 100.0 / pop_total_faixa, 2) AS cobertura_2d_pct,
    ROUND(doses_reforco_total * 100.0 / pop_total_faixa, 2) AS cobertura_reforco_pct,
    -- Taxa de conclusão (quem tomou 1ª dose e completou com 2ª)
    ROUND(doses_2d_total * 100.0 / NULLIF(doses_1d_total, 0), 2) AS taxa_conclusao_pct
FROM total_faixas
ORDER BY 
    CASE faixa_etaria
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
-- 4.2 Faixas com Menor Adesão (Gap de Vacinação)
-- ========================================

WITH cobertura_faixas AS (
    SELECT 
        faixa_etaria,
        ROUND(
            SUM(doses_2d_acumuladas) * 100.0 / SUM(populacao_faixa),
            2
        ) AS cobertura_2d_pct
    FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY faixa_etaria
)
SELECT 
    faixa_etaria,
    cobertura_2d_pct,
    -- Gap em relação à meta de 90%
    ROUND(90 - cobertura_2d_pct, 2) AS gap_meta_90,
    CASE 
        WHEN cobertura_2d_pct >= 90 THEN 'Meta Atingida'
        WHEN cobertura_2d_pct >= 75 THEN 'Próximo da Meta'
        WHEN cobertura_2d_pct >= 60 THEN 'Baixa Cobertura'
        ELSE 'Crítico'
    END AS status
FROM cobertura_faixas
ORDER BY cobertura_2d_pct ASC;

-- ========================================
-- 4.3 Comparação de Priorização Etária
-- ========================================

SELECT 
    CASE 
        WHEN faixa_etaria IN ('60-69', '70-79', '80+') THEN 'Grupo Prioritário'
        WHEN faixa_etaria IN ('40-49', '50-59') THEN 'Adultos'
        ELSE 'Jovens'
    END AS grupo,
    SUM(doses_2d_acumuladas) AS doses_total,
    SUM(populacao_faixa) AS populacao_total,
    ROUND(
        SUM(doses_2d_acumuladas) * 100.0 / SUM(populacao_faixa),
        2
    ) AS cobertura_pct
FROM vacinacao v
WHERE data = (SELECT MAX(data) FROM vacinacao)
GROUP BY 
    CASE 
        WHEN faixa_etaria IN ('60-69', '70-79', '80+') THEN 'Grupo Prioritário'
        WHEN faixa_etaria IN ('40-49', '50-59') THEN 'Adultos'
        ELSE 'Jovens'
    END
ORDER BY cobertura_pct DESC;

-- ========================================
-- 4.4 Estados com Melhor Cobertura em Idosos
-- ========================================

WITH cobertura_idosos AS (
    SELECT 
        v.estado,
        SUM(v.doses_2d_acumuladas) AS doses_idosos,
        SUM(v.populacao_faixa) AS pop_idosos
    FROM vacinacao v
    WHERE faixa_etaria IN ('60-69', '70-79', '80+')
        AND data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY v.estado
)
SELECT 
    e.nome AS estado,
    e.regiao,
    ci.pop_idosos,
    ci.doses_idosos,
    ROUND(ci.doses_idosos * 100.0 / ci.pop_idosos, 2) AS cobertura_idosos_pct,
    RANK() OVER (ORDER BY ci.doses_idosos * 100.0 / ci.pop_idosos DESC) AS ranking
FROM cobertura_idosos ci
INNER JOIN estados e ON ci.estado = e.sigla
ORDER BY ranking
LIMIT 10;

-- ========================================
-- 4.5 Evolução da Cobertura por Faixa ao Longo do Tempo
-- ========================================

WITH cobertura_mensal AS (
    SELECT 
        strftime('%Y-%m', data) AS mes,
        faixa_etaria,
        SUM(doses_2d_novas) AS doses_mes,
        MAX(doses_2d_acumuladas) AS doses_acumuladas,
        MAX(populacao_faixa) AS populacao
    FROM vacinacao
    GROUP BY strftime('%Y-%m', data), faixa_etaria
)
SELECT 
    mes,
    faixa_etaria,
    doses_acumuladas,
    ROUND(doses_acumuladas * 100.0 / populacao, 2) AS cobertura_pct
FROM cobertura_mensal
WHERE faixa_etaria IN ('18-29', '60-69', '80+')  -- Amostra de 3 faixas
ORDER BY faixa_etaria, mes;

-- ========================================
-- 4.6 Análise de Desistência (Gap entre 1ª e 2ª Dose)
-- ========================================

WITH doses_por_faixa AS (
    SELECT 
        faixa_etaria,
        SUM(doses_1d_acumuladas) AS total_1d,
        SUM(doses_2d_acumuladas) AS total_2d
    FROM vacinacao
    WHERE data = (SELECT MAX(data) FROM vacinacao)
    GROUP BY faixa_etaria
)
SELECT 
    faixa_etaria,
    total_1d,
    total_2d,
    total_1d - total_2d AS pessoas_nao_completaram,
    ROUND((total_1d - total_2d) * 100.0 / total_1d, 2) AS taxa_desistencia_pct,
    CASE 
        WHEN (total_1d - total_2d) * 100.0 / total_1d < 10 THEN 'Baixa'
        WHEN (total_1d - total_2d) * 100.0 / total_1d < 20 THEN 'Moderada'
        ELSE 'Alta'
    END AS nivel_desistencia
FROM doses_por_faixa
ORDER BY taxa_desistencia_pct DESC;

-- ========================================
-- INSIGHTS ESPERADOS:
-- ========================================
/*
✓ Idosos (60+) devem ter cobertura superior a 90%
✓ Jovens (18-29) tendem a ter menor adesão
✓ Pode haver gap significativo entre 1ª e 2ª dose em faixas jovens
✓ Estados do Sul/Sudeste vacinam melhor em todas as faixas
*/
