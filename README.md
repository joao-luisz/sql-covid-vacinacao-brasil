# OpenDataSUS Analytics: laboratório de SQL

Projeto de portfólio para organizar séries temporais, validar dados e construir consultas analíticas em **Python/Pandas e SQLite**. O nome histórico do repositório foi preservado.

**Vacinação é sempre sintética. O modo padrão também simula os casos de COVID-19. Os resultados não são evidências epidemiológicas nem permitem avaliar eficácia de vacinas.**

## Problema
Como integrar dados em granularidades diferentes, calcular indicadores sem duplicar populações e manter rastreabilidade entre fonte, transformação e resultado?

## Dados e procedência
| Componente | Origem | Limite |
| --- | --- | --- |
| Casos, modo `synthetic` (padrão) | Simulação NumPy, semente 42 | Nenhuma observação real |
| Casos, modo `brasil-io` | Download de `caso_full.csv.gz` do Brasil.IO, recorte dos últimos seis meses disponíveis | Requer acesso à fonte e schema compatível; não é coleta atual em tempo real |
| Vacinação | Gerador determinístico por estado, faixa etária e dia | Coberturas e diferenças entre doses são parâmetros programados |
| População | Constantes existentes no código | Referência temporal não comprovada; não apresentar como estimativa IBGE 2023 validada |

A simulação permite executar o estudo localmente sem depender da obtenção de microdados de vacinação. Não é uma amostra anonimizada de pacientes. `data/provenance.json` registra o modo, a semente e as contagens de cada execução. Se o download falhar, a execução falha explicitamente; não troca a origem dos dados silenciosamente.

## Arquitetura e SQL
`CSV → validação de chaves → SQLite → views → consultas analíticas`

- `data/download_data.py`: geração sintética ou download dos casos.
- `database/schema.sql`: dimensão de estados, tabelas de casos e vacinação, índices e views.
- `database/load_data.py`: carga por nomes de colunas, chaves e integridade referencial.
- `queries/01_exploratory.sql`: agregações e JOINs.
- `queries/02_vaccination_trends.sql`: LAG, médias móveis e evolução temporal.
- `queries/03_regional_analysis.sql`: rankings e comparações regionais demonstrativas.
- `queries/04_age_groups.sql`: segmentação etária e fechamento mensal.
- `queries/05_advanced_insights.sql`: CTEs, comparação de períodos e totalizações com UNION ALL.

## Como executar
Python 3.10+; execute na raiz do repositório:

```bash
git clone https://github.com/joao-luisz/sql-covid-vacinacao-brasil.git
cd sql-covid-vacinacao-brasil
python -m venv .venv
# Linux/macOS: source .venv/bin/activate
# Windows: .venv\Scripts\activate
python -m pip install -r requirements.txt
python data/download_data.py --mode synthetic
python database/load_data.py
```

A carga recria **apenas o banco local de demonstração** `covid_vacinacao.db`. Não aponte este fluxo para dados de produção. Ela também executa os arquivos de consultas para detectar erros SQL. Para experimentar casos da fonte pública, use `--mode brasil-io`; a vacinação permanece simulada e as janelas temporais podem não coincidir.

## Qualidade de dados e correções
Chaves esperadas: casos `(data, estado)`; vacinação `(data, estado, faixa_etaria)`. A carga rejeita chaves nulas/duplicadas e verifica relações com estados. Foram corrigidos importação posicional incompatível, nome da coluna de reforço, agregação regional aninhada e denominador de cobertura. O modo sintético usa uma janela fixa e semente reproduzível.

## Limitações
- O motor implementado é SQLite. O schema não é diretamente compatível com PostgreSQL.
- A distribuição etária é uniforme por construção e não representa a demografia brasileira.
- Doses agregadas não identificam pessoas nem demonstram abandono individual.
- Classificações e metas nas consultas são exercícios, sem validade operacional ou clínica.
- A comparação de períodos não calcula um coeficiente de correlação. O antigo valor −0,85 não tinha cálculo reproduzível e foi retirado. Um coeficiente negativo indicaria associação inversa, não “correlação positiva”.
- Foram retiradas afirmações de processamento de 5 GB e descobertas regionais que não eram sustentadas pelos arquivos.

## Aprendizados
Granularidade, denominadores e procedência importam tanto quanto a sintaxe SQL. Dados sintéticos são úteis para demonstrar métodos, desde que suas limitações sejam explícitas.

[LinkedIn](https://linkedin.com/in/joaolfleite) · [GitHub](https://github.com/joao-luisz)

Código sob [MIT](LICENSE). A licença do código não substitui as condições de uso das fontes externas.
