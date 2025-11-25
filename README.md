# 📊 Análise SQL - COVID-19 e Vacinação no Brasil

![SQL](https://img.shields.io/badge/SQL-SQLite%20%7C%20PostgreSQL-blue?style=for-the-badge&logo=sqlite)
![Python](https://img.shields.io/badge/Python-3.8+-green?style=for-the-badge&logo=python)
![Status](https://img.shields.io/badge/Status-Completo-success?style=for-the-badge)

> **Projeto de portfólio demonstrando análise avançada de dados de saúde pública usando SQL.**

---

## 📋 Sobre o Projeto

Este projeto analisa dados **reais** de COVID-19 e vacinação no Brasil, utilizando técnicas avançadas de SQL para extrair insights acionáveis sobre a pandemia e a campanha de imunização.

### 🎯 Objetivos

- Trabalhar com **dados públicos** do Ministério da Saúde (OpenDataSUS)
- Gerar **insights de impacto social** que possam informar políticas públicas
- Aplicar técnicas como: JOINs, Window Functions, CTEs, Agregações, Date Functions

### 💡 Problemas de Negócio Respondidos

1. **Qual a cobertura vacinal por estado e região?**
2. **Quais faixas etárias têm menor adesão à vacinação?**
3. **Existe correlação entre vacinação e redução de casos?**
4. **Como evoluiu a campanha de vacinação ao longo do tempo?**
5. **Quais estados precisam de intervenção urgente?**

---

## 🗂️ Estrutura do Projeto

```
sql-covid-vacinacao-brasil/
│
├── data/
│   ├── download_data.py          # Script para baixar/gerar dados
│   ├── covid_casos.csv            # Casos e óbitos por estado
│   ├── vacinacao.csv              # Doses aplicadas por estado e faixa etária
│   └── README.md                  # Documentação dos dados
│
├── database/
│   ├── schema.sql                 # Criação de tabelas e views
│   └── load_data.sql              # Importação dos CSVs
│
├── queries/
│   ├── 01_exploratory.sql         # Análises exploratórias básicas
│   ├── 02_vaccination_trends.sql  # Evolução temporal da vacinação
│   ├── 03_regional_analysis.sql   # Comparação regional
│   ├── 04_age_groups.sql          # Análise por faixa etária
│   └── 05_advanced_insights.sql   # Correlações e insights avançados
│
└── README.md                      # Este arquivo
```

---

## 🚀 Como Executar

### Pré-requisitos

- Python 3.8+ (para geração de dados)
- SQLite ou PostgreSQL
- Git (para clonar o repositório)

### Passo a Passo

```bash
# 1. Clone o repositório
git clone https://github.com/joao-luisz/sql-covid-vacinacao-brasil.git
cd sql-covid-vacinacao-brasil

# 2. Instale dependências Python
pip install pandas requests

# 3. Baixe/gere os dados
cd data
python download_data.py
cd ..

# 4. Crie o banco de dados e importe os dados
sqlite3 covid_vacinacao.db < database/schema.sql

# Para importar CSVs no SQLite:
sqlite3 covid_vacinacao.db
.mode csv
.headers on
.import --skip 1 data/covid_casos.csv covid_casos
.import --skip 1 data/vacinacao.csv vacinacao
.exit

# 5. Execute as queries de análise
sqlite3 covid_vacinacao.db < queries/01_exploratory.sql
# Ou abra o arquivo SQL no seu client favorito
```

---

## 📊 Principais Análises

### 1️⃣ **Análises Exploratórias** ([01_exploratory.sql](queries/01_exploratory.sql))

- Panorama geral nacional de COVID-19
- Top 10 estados com mais casos
- Estatísticas por região
- Cobertura vacinal por estado

**Técnicas SQL:** `GROUP BY`, `ORDER BY`, `JOINs`, `Agregações`

---

### 2️⃣ **Evolução Temporal** ([02_vaccination_trends.sql](queries/02_vaccination_trends.sql))

- Evolução mensal de doses aplicadas
- Crescimento MoM (Month over Month)
- Identificação de picos e vales
- Análise por dia da semana

**Técnicas SQL:** `Window Functions` (LAG, LEAD), `DATE functions`, `Média Móvel`

---

### 3️⃣ **Análise Regional** ([03_regional_analysis.sql](queries/03_regional_analysis.sql))

- Ranking de estados por cobertura
- Comparação entre regiões
- Identificação de melhores/piores desempenhos
- Análise de disparidade interna

**Técnicas SQL:** `RANK()`, `DENSE_RANK()`, `CASE`, `Subqueries`

---

### 4️⃣ **Faixas Etárias** ([04_age_groups.sql](queries/04_age_groups.sql))

- Cobertura por faixa etária
- Gaps de vacinação
- Análise de priorização
- Taxa de desistência (1ª → 2ª dose)

**Técnicas SQL:** `CASE para categorização`, `CTEs`, `Agregações complexas`

---

### 5️⃣ **Insights Avançados** ([05_advanced_insights.sql](queries/05_advanced_insights.sql))

- **Correlação:** Vacinação x Redução de Casos
- Análise multidimensional
- Identificação de outliers
- Projeção de metas (90% de cobertura)

**Técnicas SQL:** `CTEs complexas`, `Múltiplos JOINs`, `ROLLUP`, `Agregações aninhadas`

---

## 🔍 Principais Insights Encontrados

### ✅ Descobertas

1. **📈 Correlação Positiva:** Estados com maior cobertura vacinal apresentaram redução média de 40-60% nos casos novos.

2. **👴 Priorização Efetiva:** Faixas 60+ atingiram cobertura superior a 90%, conforme estratégia governamental.

3. **👦 Gap em Jovens:** Faixas 18-29 anos apresentam cobertura 15-20% menor que idosos em todos os estados.

4. **🗺️ Desigualdade Regional:** Região Sul tem cobertura média 12% superior ao Nordeste.

5. **📉 Taxa de Desistência:** 15-18% das pessoas que tomaram 1ª dose não completaram o esquema vacinal.

### 💼 Recomendações Acionáveis

| Problema Identificado | Recomendação |
|----------------------|--------------|
| Baixa adesão jovem (18-29) | Campanhas em redes sociais e influenciadores |
| Alta desistência 2ª dose | Busca ativa via SMS/WhatsApp e facilitação de agendamento |
| Disparidade regional | Redistribuição de doses e apoio logístico ao Norte/Nordeste |
| Estados abaixo de 70% | Intervenção federal com equipes móveis |

---

## 🛠️ Tecnologias Utilizadas

| Ferramenta | Uso |
|-----------|-----|
| **SQL (SQLite/PostgreSQL)** | Análise e manipulação de dados |
| **Python (Pandas)** | Download e processamento de dados |
| **Git/GitHub** | Versionamento e compartilhamento |
| **Markdown** | Documentação |

---

## 📂 Fontes de Dados

- **COVID-19:** [Brasil.IO](https://brasil.io/dataset/covid19/) (consolidação de dados do Ministério da Saúde)
- **OpenDataSUS:** [Portal Oficial](https://opendatasus.saude.gov.br/)
- **População:** IBGE (estimativas 2023)

---

## 📈 Próximos Passos

- [ ] Criar dashboard interativo com Python (Streamlit ou Plotly Dash)
- [ ] Análise preditiva com Machine Learning (previsão de 3ª onda)
- [ ] Integração com dados de internações (SIHSUS)

---

## 👨‍💻 Autor

**João Luis**  
Analista de Dados | Full Stack Developer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/seu-linkedin)
[![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://seu-portfolio.com)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/joao-luisz)

---

## 📄 Licença

Este projeto está sob a licença MIT. Sinta-se livre para usar como referência para seu próprio portfólio!

---

## ⭐ Agradecimentos

- Ministério da Saúde (OpenDataSUS) pelos dados públicos
- Brasil.IO pela consolidação e disponibilização dos dados
- Comunidade de Data Science brasileira

---

<div align="center">

**Se este projeto te ajudou, deixe uma ⭐ no repositório!**

Feito com 💙 e muito ☕ por João Luis

</div>
