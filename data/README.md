# Procedência dos dados

Vacinação é sempre sintética. Casos são sintéticos por padrão; `--mode brasil-io` tenta baixar casos públicos do Brasil.IO e falha explicitamente se não conseguir. Consulte `provenance.json` gerado a cada execução e o README principal. Não publicar resultados como descobertas epidemiológicas.

A simulação usa semente 42 e 180 dias terminando em 2022-03-31. Populações fixas e proporções etárias são parâmetros do exercício. CSVs e banco local são derivados reproduzíveis.
