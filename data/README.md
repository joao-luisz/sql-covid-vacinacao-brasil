# Dados do Projeto

Este diretório contém os scripts para download e os datasets utilizados no projeto.

## 📥 Fontes de Dados

### COVID-19 - Casos e Óbitos
- **Fonte:** Brasil.IO (dados consolidados do Ministério da Saúde)
- **URL:** https://brasil.io/dataset/covid19/
- **Período:** Últimos 6 meses
- **Granularidade:** Por estado
- **Variáveis:**
  - `data`: Data do registro
  - `estado`: Sigla do estado (UF)
  - `casos_acumulados`: Total de casos confirmados
  - `obitos_acumulados`: Total de óbitos
  - `casos_novos`: Novos casos no dia
  - `obitos_novos`: Novos óbitos no dia
  - `populacao_estimada`: População estimada do estado

### Vacinação
- **Fonte:** Dados simulados baseados em padrões reais de OpenDataSUS
- **Período:** Últimos 6 meses
- **Granularidade:** Por estado e faixa etária
- **Variáveis:**
  - `data`: Data do registro
  - `estado`: Sigla do estado (UF)
  - `faixa_etaria`: Grupo etário (0-17, 18-29, etc.)
  - `doses_1d_acumuladas`: Total de primeiras doses
  - `doses_2d_acumuladas`: Total de segundas doses
  - `doses_reforco_acumuladas`: Total de doses de reforço
  - `doses_*_novas`: Doses aplicadas no dia
  - `populacao_faixa`: População da faixa etária

## 🚀 Como Executar

```bash
# Instalar dependências
pip install pandas requests

# Executar script de download
python download_data.py
```

## 📝 Notas

Os dados de vacinação são simulados mas seguem padrões realistas (maiores taxas em idosos, progressão temporal coerente). Para análise com dados 100% reais do OpenDataSUS, acesse: https://opendatasus.saude.gov.br/
