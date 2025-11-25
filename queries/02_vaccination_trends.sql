/*
 * ========================================
 * QUERY 02: EVOLUÇÃO TEMPORAL DA VACINAÇÃO
 * ========================================
 * 
 * Objetivo: Analisar tendências temporais da campanha de vacinação
 * Técnicas SQL: Window Functions (LAG, LEAD), DATE functions, CTEs
 */

-- ========================================
-- 2.1 Evolução Mensal de Doses Aplicadas
-- ========================================

SELECT 
    strftime('%Y-%m', data) AS mes,
    SUM(doses_1d_novas) AS doses_1d_mes,
    SUM(doses_2d_novas) AS doses_2d_mes,
    SUM(doses_reforco_novas) AS doses_reforco_mes,
    SUM(doses_1d_novas + doses_2d_novas + doses_reforco_novas) AS total_doses_mes,
    -- Média diária no mês
    ROUND(AVG(doses_1d_novas + doses_2d_novas + doses_reforco_novas), 0) AS media_diaria
FROM vacinacao
GROUP BY strftime('%Y-%m', data)
ORDER BY mes;

-- ========================================
-- 2.2 Crescimento Mensal (MoM - Month over Month)
-- ========================================

WITH doses_mensais AS (
    SELECT 
        strftime('%Y-%m', data) AS mes,
        SUM(doses_1d_novas + doses_2d_novas + doses_reforco_novas) AS total_doses
    FROM vacinacao
    GROUP BY strftime('%Y-%m', data)
)
SELECT 
    mes,
    total_doses,
    -- Doses do mês anterior (Window Function LAG)
    LAG(total_doses) OVER (ORDER BY mes) AS doses_mes_anterior,
    -- Crescimento absoluto
    total_doses - LAG(total_doses) OVER (ORDER BY mes) AS crescimento_absoluto,
    -- Crescimento percentual
    ROUND(
        (total_doses - LAG(total_doses) OVER (ORDER BY mes)) * 100.0 / 
        NULLIF(LAG(total_doses) OVER (ORDER BY mes), 0),
        2
    ) AS crescimento_pct
FROM doses_mensais
ORDER BY mes;

-- ========================================
-- 2.3 Identificação de Ondas de Vacinação
-- ========================================

WITH doses_diarias AS (
    SELECT 
        data,
        SUM(doses_1d_novas + doses_2d_novas + doses_reforco_novas) AS total_doses
    FROM vacinacao
    GROUP BY data
),
media_movel AS (
    SELECT 
        data,
        total_doses,
        -- Média móvel de 7 dias
        ROUND(
            AVG(total_doses) OVER (
                ORDER BY data 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            0
        ) AS media_7d
    FROM doses_diarias
)
SELECT 
    data,
    total_doses,
    media_7d,
    -- Classifica dias como "Alto" ou "Baixo" ritmo
    CASE 
        WHEN total_doses > media_7d * 1.2 THEN 'Alto'
        WHEN total_doses < media_7d * 0.8 THEN 'Baixo'
        ELSE 'Normal'
    END AS ritmo_vacinacao
FROM media_movel
ORDER BY data DESC
LIMIT 30;  -- Últimos 30 dias

-- ========================================
-- 2.4 Picos e Vales de Vacinação
-- ========================================

WITH doses_diarias AS (
    SELECT 
        data,
        SUM(doses_1d_novas + doses_2d_novas + doses_reforco_novas) AS total_doses
    FROM vacinacao
    GROUP BY data
)
SELECT 
    'Maior dia de vacinação' AS metrica,
    data,
    total_doses
FROM doses_diarias
WHERE total_doses = (SELECT MAX(total_doses) FROM doses_diarias)

UNION ALL

SELECT 
    'Menor dia de vacinação',
    data,
    total_doses
FROM doses_diarias
WHERE total_doses = (SELECT MIN(total_doses) FROM doses_diarias)
    AND total_doses > 0;  -- Ignora dias sem vacinação

-- ========================================
-- 2.5 Análise Semanal - Dias da Semana
-- ========================================

WITH dia_semana_doses AS (
    SELECT 
        CASE CAST(strftime('%w', data) AS INTEGER)
            WHEN 0 THEN 'Domingo'
            WHEN 1 THEN 'Segunda'
            WHEN 2 THEN 'Terça'
            WHEN 3 THEN 'Quarta'
            WHEN 4 THEN 'Quinta'
            WHEN 5 THEN 'Sexta'
            WHEN 6 THEN 'Sábado'
        END AS dia_semana,
        CAST(strftime('%w', data) AS INTEGER) AS dia_num,
        SUM(doses_1d_novas + doses_2d_novas + doses_reforco_novas) AS total_doses
    FROM vacinacao
    GROUP BY strftime('%w', data)
)
SELECT 
    dia_semana,
    total_doses,
    ROUND(AVG(total_doses) OVER (), 0) AS media_semanal,
    ROUND(
        (total_doses - AVG(total_doses) OVER ()) * 100.0 / 
        AVG(total_doses) OVER (),
        2
    ) AS desvio_media_pct
FROM dia_semana_doses
ORDER BY dia_num;

-- ========================================
-- 2.6 Aceleração da Vacinação por Estado
-- ========================================

WITH primeira_ultima_dose AS (
    SELECT 
        estado,
        MIN(data) AS data_inicio,
        MAX(data) AS data_fim,
        SUM(doses_2d_novas) AS total_2d
    FROM vacinacao
    WHERE doses_2d_novas > 0
    GROUP BY estado
)
SELECT 
    e.nome AS estado,
    pud.data_inicio,
    pud.data_fim,
    pud.total_2d,
    -- Dias de campanha
    CAST(julianday(pud.data_fim) - julianday(pud.data_inicio) AS INTEGER) AS dias_campanha,
    -- Velocidade média (doses/dia)
    ROUND(
        pud.total_2d * 1.0 / 
        NULLIF(julianday(pud.data_fim) - julianday(pud.data_inicio), 0),
        0
    ) AS doses_por_dia
FROM primeira_ultima_dose pud
INNER JOIN estados e ON pud.estado = e.sigla
ORDER BY doses_por_dia DESC
LIMIT 10;

-- ========================================
-- INSIGHTS ESPERADOS:
-- ========================================
/*
✓ Crescimento acelerado nos primeiros meses (grupos prioritários)
✓ Possível redução no ritmo após vacinação de idosos
✓ Fins de semana podem ter menor aplicação de doses
✓ Estados com melhor estrutura vacinam mais rápido
*/
