# Workshop de Análise Automatizada de Texto

**SICSS-Brazil 2026** · FGV, Rio de Janeiro · 29 de julho de 2026
Facilitador: Anderson Henrique (CEM/USP · INCT QualiGov · IPEA)

Materiais das duas aulas: slides em LaTeX, scripts em R e dados de exemplo.

---

## Como começar

**Sempre abra o arquivo `Workshop_SICSS_2026.Rproj` antes de rodar qualquer
script.** Ele fixa o diretório de trabalho na raiz do projeto, que é o que faz
os caminhos relativos funcionarem.

Se você não usa RStudio, rode pelo terminal a partir da raiz:

```bash
Rscript scripts/05_figuras.R
```

O script localiza a raiz do projeto sozinho e avisa qual encontrou. Se ainda
assim falhar, ele diz exatamente o que fazer.

---

## Estrutura da pasta

```
Workshop_SICSS_2026/
├── Workshop_SICSS_2026.Rproj    abra este arquivo primeiro
├── README.md
├── aula01_manha.tex             slides da manhã (105 min)
├── aula02_tarde.tex             slides da tarde (90 min)
├── figuras/
│   ├── fig_top_terms.png        gerados por scripts/05_figuras.R
│   ├── fig_keyness.png
│   ├── fig_lda.png
│   ├── fig_confusao.png
│   └── dados/                   insumos das figuras (CSV)
│       ├── fig1_top_terms.csv
│       ├── fig2_keyness.csv
│       ├── fig3_lda.csv
│       └── fig4_confusao.csv
├── scripts/
│   └── 05_figuras.R             gera as quatro figuras dos slides
├── data/                        corpus e outputs pré-computados
└── outputs/                     tabelas, relatórios e planilhas de revisão
```

---

## Compilar os slides

Os `.tex` usam caminhos relativos (`figuras/fig_*.png`), então compile a partir
da raiz do projeto:

```bash
pdflatex aula01_manha.tex
pdflatex aula01_manha.tex     # segunda passagem, para resolver o sumário
```

Requisitos de LaTeX: `beamer`, `tikz`, `booktabs`, `listings`, `graphicx` e o
pacote de idioma `texlive-lang-portuguese`, necessário para
`\usepackage[brazilian]{babel}`.

---

## Pacotes de R

```r
install.packages(c("tidyverse", "quanteda", "quanteda.textstats",
                   "quanteda.textmodels", "tidytext", "stm",
                   "irr", "irrCAC", "here", "remotes"))

# acR em submissão à CRAN; instalar do GitHub
remotes::install_github("andersonheri/acR")

# Módulo qualitativo (LLM)
install.packages("ellmer")
```

Chaves de API vão no `.Renviron`, nunca no código:

```r
usethis::edit_r_environ()
```

---

## Sobre os dados

Os arquivos em `figuras/dados/` são **ilustrativos**. Reproduzem a forma e a
ordem de grandeza de saídas reais do pipeline (`acR` + `quanteda`), mas não
correspondem a uma análise empírica publicada. Servem para que os slides
compilem e para que você teste o ambiente sem chave de API.

Em `scripts/05_figuras.R`, cada figura tem dois blocos: **(A)** o código do
pipeline real, comentado, e **(B)** a leitura do CSV ilustrativo. Substitua
(B) por (A) quando tiver o corpus. A camada `ggplot2` permanece idêntica.

Nenhuma chamada a API é feita durante o workshop. Os resultados de LLM da aula
da tarde estão pré-computados em `data/`.

---

## Como citar

HENRIQUE, Anderson. *Análise Automatizada de Texto*. 2026. Material didático não
publicado, elaborado para o Summer Institute in Computational Social Science,
Brazil (SICSS-Brazil 2026), Fundação Getulio Vargas, Rio de Janeiro.
CEM-USP / INCT QualiGov.

Pacote `acR`: <https://ahenriquecp.com/acR/>

## Licença

Slides e textos: CC BY 4.0. Código: MIT.
