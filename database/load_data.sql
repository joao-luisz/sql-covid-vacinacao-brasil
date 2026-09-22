-- A importação é feita por database/load_data.py, com mapeamento explícito de colunas.
-- O antigo .import posicional não correspondia ao schema (id e municipio).
SELECT 'casos' AS tabela, COUNT(*) AS linhas FROM covid_casos
UNION ALL SELECT 'vacinacao', COUNT(*) FROM vacinacao;
PRAGMA foreign_key_check;
