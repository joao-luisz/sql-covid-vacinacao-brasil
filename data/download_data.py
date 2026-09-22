"""
Demonstração de SQL: casos sintéticos ou Brasil.IO; vacinação sempre sintética.
"""

import argparse
import json
from pathlib import Path
import numpy as np
import pandas as pd
import os
ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
END_DATE = "2022-03-31"
SEED = 42

# URLs dos dados públicos do OpenDataSUS
# Nota: Usando URLs simplificadas para demonstração. Para produção, usar a API oficial.

def baixar_dados_covid():
    """Baixa dados de casos e óbitos de COVID-19 por estado."""
    print("📥 Baixando dados de COVID-19...")
    
    # URL do Brasil.IO (dados consolidados e limpos)
    url = "https://data.brasil.io/dataset/covid19/caso_full.csv.gz"
    
    try:
        # Baixa apenas uma amostra para o portfólio (ultimos 6 meses)
        df = pd.read_csv(url, compression='gzip')
        
        # Filtra dados relevantes
        df = df[df['place_type'] == 'state']  # Apenas dados por estado
        df['date'] = pd.to_datetime(df['date'])
        
        # Últimos 6 meses de dados
        data_inicial = df['date'].max() - pd.DateOffset(months=6)
        df = df[df['date'] >= data_inicial]
        
        # Seleciona colunas importantes
        colunas = ['date', 'state', 'city', 'last_available_confirmed', 'last_available_deaths', 
                   'new_confirmed', 'new_deaths', 'estimated_population']
        df = df[colunas]
        
        # Renomeia para PT-BR
        df = df.rename(columns={
            'date': 'data',
            'state': 'estado',
            'city': 'municipio',
            'last_available_confirmed': 'casos_acumulados',
            'last_available_deaths': 'obitos_acumulados',
            'new_confirmed': 'casos_novos',
            'new_deaths': 'obitos_novos',
            'estimated_population': 'populacao_estimada'
        })
        
        # Salva CSV
        output_path = DATA / 'covid_casos.csv'
        df.to_csv(output_path, index=False, encoding='utf-8')
        print(f"✅ Dados de COVID-19 salvos em {output_path}")
        print(f"   Total de registros: {len(df):,}")
        
        return df
        
    except Exception as e:
        print(f"❌ Erro ao baixar dados de COVID-19: {e}")
        raise RuntimeError("Download falhou. Para simulação explícita, use --mode synthetic.") from e


def criar_dataset_demonstracao_covid():
    """Cria um dataset de demonstração inteiramente sintético para exercício de SQL."""
    import numpy as np
    
    print("🔨 Criando dataset de demonstração...")
    
    estados = ['SP', 'RJ', 'MG', 'BA', 'PR', 'RS', 'PE', 'CE', 'PA', 'SC', 
               'GO', 'MA', 'ES', 'PB', 'AM', 'RN', 'MT', 'AL', 'PI', 'DF',
               'MS', 'SE', 'RO', 'TO', 'AC', 'AP', 'RR']
    
    populacao_estados = {
        'SP': 46649132, 'RJ': 17463349, 'MG': 21411923, 'BA': 14985284,
        'PR': 11597484, 'RS': 11466630, 'PE': 9674793, 'CE': 9240580,
        'PA': 8777124, 'SC': 7338473, 'GO': 7206589, 'MA': 7153262,
        'ES': 4108508, 'PB': 4059905, 'AM': 4269995, 'RN': 3560903,
        'MT': 3567234, 'AL': 3365351, 'PI': 3289290, 'DF': 3094325,
        'MS': 2839188, 'SE': 2338474, 'RO': 1815278, 'TO': 1607363,
        'AC': 906876, 'AP': 877613, 'RR': 652713
    }
    
    # Gera 180 dias de dados (6 meses)
    datas = pd.date_range(end=END_DATE, periods=180, freq='D')
    
    registros = []
    for estado in estados:
        pop = populacao_estados.get(estado, 3000000)
        
        # Simula casos acumulados crescentes
        casos_base = np.random.randint(int(pop * 0.15), int(pop * 0.25))
        
        casos_acumulados = casos_base
        obitos_acumulados = int(casos_base * 0.02)
        for i, data in enumerate(datas):
            # Crescimento diário simulado
            casos_novos = max(0, int(np.random.normal(casos_base * 0.001, casos_base * 0.0005)))
            casos_acumulados += casos_novos
            
            # Óbitos (aproximadamente 1-2% dos casos)
            obitos_novos = max(0, int(casos_novos * np.random.uniform(0.01, 0.02)))
            obitos_acumulados += obitos_novos
            
            registros.append({
                'data': data.strftime('%Y-%m-%d'),
                'estado': estado,
                'municipio': None,
                'casos_acumulados': casos_acumulados,
                'obitos_acumulados': obitos_acumulados,
                'casos_novos': casos_novos,
                'obitos_novos': obitos_novos,
                'populacao_estimada': pop
            })
    
    df = pd.DataFrame(registros)
    output_path = DATA / 'covid_casos.csv'
    df.to_csv(output_path, index=False, encoding='utf-8')
    print(f"✅ Dataset de demonstração criado em {output_path}")
    print(f"   Total de registros: {len(df):,}")
    
    return df


def criar_dados_vacinacao():
    """Cria dados de vacinação por estado."""
    print("💉 Criando dados de vacinação...")
    
    estados = ['SP', 'RJ', 'MG', 'BA', 'PR', 'RS', 'PE', 'CE', 'PA', 'SC', 
               'GO', 'MA', 'ES', 'PB', 'AM', 'RN', 'MT', 'AL', 'PI', 'DF',
               'MS', 'SE', 'RO', 'TO', 'AC', 'AP', 'RR']
    
    populacao_estados = {
        'SP': 46649132, 'RJ': 17463349, 'MG': 21411923, 'BA': 14985284,
        'PR': 11597484, 'RS': 11466630, 'PE': 9674793, 'CE': 9240580,
        'PA': 8777124, 'SC': 7338473, 'GO': 7206589, 'MA': 7153262,
        'ES': 4108508, 'PB': 4059905, 'AM': 4269995, 'RN': 3560903,
        'MT': 3567234, 'AL': 3365351, 'PI': 3289290, 'DF': 3094325,
        'MS': 2839188, 'SE': 2338474, 'RO': 1815278, 'TO': 1607363,
        'AC': 906876, 'AP': 877613, 'RR': 652713
    }
    
    faixas_etarias = ['0-17', '18-29', '30-39', '40-49', '50-59', '60-69', '70-79', '80+']
    
    datas = pd.date_range(end=END_DATE, periods=180, freq='D')
    
    registros = []
    for estado in estados:
        pop = populacao_estados.get(estado, 3000000)
        
        for faixa in faixas_etarias:
            # Simulação de cobertura vacinal por faixa etária
            if faixa == '80+':
                cobertura_alvo = 0.95
            elif faixa in ['60-69', '70-79']:
                cobertura_alvo = 0.90
            elif faixa in ['40-49', '50-59']:
                cobertura_alvo = 0.85
            else:
                cobertura_alvo = 0.70
            
            pop_faixa = int(pop * (1 / len(faixas_etarias)))
            
            doses_acumuladas_1d = 0
            doses_acumuladas_2d = 0
            doses_acumuladas_ref = 0
            
            for i, data in enumerate(datas):
                # Simula progressão da vacinação
                progresso = min(1.0, (i + 1) / len(datas))
                
                doses_1d = int(pop_faixa * cobertura_alvo * progresso)
                doses_2d = int(doses_1d * 0.85)
                doses_ref = int(doses_2d * 0.60)
                
                doses_novas_1d = max(0, doses_1d - doses_acumuladas_1d)
                doses_novas_2d = max(0, doses_2d - doses_acumuladas_2d)
                doses_novas_ref = max(0, doses_ref - doses_acumuladas_ref)
                
                doses_acumuladas_1d = doses_1d
                doses_acumuladas_2d = doses_2d
                doses_acumuladas_ref = doses_ref
                
                registros.append({
                    'data': data.strftime('%Y-%m-%d'),
                    'estado': estado,
                    'faixa_etaria': faixa,
                    'doses_1d_acumuladas': doses_acumuladas_1d,
                    'doses_2d_acumuladas': doses_acumuladas_2d,
                    'doses_reforco_acumuladas': doses_acumuladas_ref,
                    'doses_1d_novas': doses_novas_1d,
                    'doses_2d_novas': doses_novas_2d,
                    'doses_reforco_novas': doses_novas_ref,
                    'populacao_faixa': pop_faixa
                })
    
    df = pd.DataFrame(registros)
    output_path = DATA / 'vacinacao.csv'
    df.to_csv(output_path, index=False, encoding='utf-8')
    print(f"✅ Dados de vacinação salvos em {output_path}")
    print(f"   Total de registros: {len(df):,}")
    
    return df


def main():
    parser = argparse.ArgumentParser(description="Dados de demonstração; vacinação sempre sintética.")
    parser.add_argument("--mode", choices=["synthetic", "brasil-io"], default="synthetic")
    args = parser.parse_args()
    DATA.mkdir(parents=True, exist_ok=True)
    np.random.seed(SEED)
    covid = criar_dataset_demonstracao_covid() if args.mode == "synthetic" else baixar_dados_covid()
    vaccination = criar_dados_vacinacao()
    manifest = {
        "covid_source": "synthetic" if args.mode == "synthetic" else "Brasil.IO caso_full.csv.gz",
        "vaccination_source": "synthetic", "seed": SEED,
        "synthetic_end_date": END_DATE,
        "covid_rows": len(covid), "vaccination_rows": len(vaccination),
        "limitation": "Não permite inferências epidemiológicas reais nem estimar eficácia vacinal."
    }
    (DATA / "provenance.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
    print(json.dumps(manifest, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
