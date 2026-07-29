# Workshop de Análise Automatizada de Texto

**SICSS-Brazil 2026** · FGV, Rio de Janeiro · 29 de julho de 2026
Facilitador: Anderson Henrique (CEM/USP · INCT QualiGov · IPEA)

Materiais das duas aulas: slides em LaTeX, scripts em R e dados de exemplo.

---

## Como começar

**Sempre abra o arquivo `Workshop_SICSS_2026.Rproj` antes de rodar qualquer
script.** Ele fixa o diretório de trabalho na raiz do projeto, que é o que faz
os caminhos relativos funcionarem.

Se você não usa RStudio, rode pelo terminal a partir da raiz, na ordem:

```bash
Rscript scripts/00_setup.R          # confere/instala os pacotes
Rscript scripts/01_corpus.R         # constrói o corpus (ilustrativo, de fábrica)
Rscript scripts/02_quantitativo.R   # limpeza, contagem, keyness, LDA
Rscript scripts/03_llm.R            # gera o placeholder da classificação por LLM
Rscript scripts/04_validacao.R      # amostragem e métricas de confiabilidade
Rscript scripts/05_figuras.R        # gera as 8 figuras usadas nos slides
Rscript scripts/06_atividade.R      # script-modelo da atividade da tarde
```

Cada script localiza a raiz do projeto sozinho e avisa qual encontrou. Se
ainda assim falhar, ele diz exatamente o que fazer. Todos rodam de forma
independente (nenhum depende de outro já ter rodado antes).

**Nota de locale:** se `scripts/05_figuras.R` gerar acentos quebrados nas
figuras (ex.: "Frequência" virando "Frequ..ncia"), seu terminal está sem
`LANG`/`LC_ALL` configurados. Rode com
`LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8 Rscript scripts/05_figuras.R`.

---

## Estrutura da pasta

```
Workshop_SICSS_2026/
├── Workshop_SICSS_2026.Rproj    abra este arquivo primeiro
├── .Rprofile                    ativa o renv (source("renv/activate.R"))
├── renv.lock                    versões travadas dos pacotes do CRAN
├── renv/                        infraestrutura do renv (library/ não versionada)
├── README.md
├── CLAUDE.md                    contexto do projeto (convenções, decisões)
├── ATIVIDADE_TARDE.md           explicação da tarefa da tarde para os alunos
├── aula01_manha.tex             slides da manhã (105 min)
├── aula02_tarde.tex             slides da tarde (90 min)
├── figuras/
│   ├── fig_top_terms.png        gerados por scripts/05_figuras.R (300 dpi)
│   ├── fig_keyness.png
│   ├── fig_lda.png
│   ├── fig_confusao.png
│   ├── fig_wordcloud.png
│   ├── fig_wordcloud_comparativo.png
│   ├── fig_cluster.png
│   ├── fig_lda_tune.png
│   └── dados/                   insumos das figuras 1 a 4 (CSV ilustrativo)
│       ├── fig1_top_terms.csv
│       ├── fig2_keyness.csv
│       ├── fig3_lda.csv
│       └── fig4_confusao.csv
├── scripts/
│   ├── 00_setup.R                instala/confere pacotes
│   ├── 01_corpus.R               coleta e construção do corpus
│   ├── 02_quantitativo.R         limpeza, contagem, keyness, LDA
│   ├── 03_llm.R                  codebook e classificação por LLM (placeholder)
│   ├── 04_validacao.R            amostragem, ac_qual_irr, ac_qual_reliability
│   ├── 05_figuras.R              gera as 8 figuras dos slides
│   └── 06_atividade.R            script-modelo para os alunos levarem
├── data/
│   ├── corpus_atividade.csv      corpus fictício usado pelos scripts acima
│   └── resultado_llm_precomputado.rds  placeholder citado nos slides
└── outputs/                      tabelas, relatórios e planilhas de revisão
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

O projeto usa `renv`. Para reproduzir o ambiente exato (versões travadas em
`renv.lock`):

```r
install.packages("renv")
renv::restore()
```

`renv::restore()` reinstala os pacotes do CRAN nas versões do `renv.lock`.
O `acR` não entra nesse lockfile (é instalado do GitHub, ainda em submissão
à CRAN) e precisa ser instalado à parte:

```r
remotes::install_github("andersonheri/acR")
```

Sem `renv`, a lista equivalente para instalar manualmente é a que
`scripts/00_setup.R` confere e instala:

```r
install.packages(c("tidyverse", "quanteda", "quanteda.textstats",
                   "quanteda.textmodels", "tidytext", "topicmodels",
                   "stopwords", "irr", "irrCAC", "here", "remotes",
                   "ellmer", "renv"))

remotes::install_github("andersonheri/acR")
```

Para as figuras 5 a 8 (nuvem de palavras, cluster), instale também:

```r
install.packages(c("ggwordcloud", "cluster"))
```

Chaves de API vão no `.Renviron`, nunca no código:

```r
usethis::edit_r_environ()
```

---

## Sobre os dados

Os arquivos em `figuras/dados/` (figuras 1 a 4) são **ilustrativos**.
Reproduzem a forma e a ordem de grandeza de saídas reais do pipeline (`acR` +
`quanteda`), mas não correspondem a uma análise empírica publicada. Servem
para que os slides compilem e para que você teste o ambiente sem chave de
API. Em `scripts/05_figuras.R`, cada uma dessas quatro tem dois blocos:
**(A)** o código do pipeline real, comentado, e **(B)** a leitura do CSV
ilustrativo. Substitua (B) por (A) quando tiver o corpus. A camada `ggplot2`
permanece idêntica.

As figuras 5 a 8 (nuvem de palavras, nuvem comparativa, cluster e curva de
seleção de k) rodam de verdade sobre `data/corpus_atividade.csv` — um corpus
fictício (16 falas de um plenário municipal fictício), mas com as funções do
`acR` chamadas de verdade, não simuladas.

`data/corpus_atividade.csv` e `data/resultado_llm_precomputado.rds` também
são fictícios/ilustrativos, gerados por `scripts/03_llm.R`. Nenhuma chamada a
API é feita durante o workshop: os resultados de LLM da aula da tarde já
estão pré-computados.

---

## Como citar

HENRIQUE, Anderson. *Análise Automatizada de Texto*. 2026. Material didático não
publicado, elaborado para o Summer Institute in Computational Social Science,
Brazil (SICSS-Brazil 2026), Fundação Getulio Vargas, Rio de Janeiro.
CEM-USP / INCT QualiGov.

Pacote `acR`: <https://ahenriquecp.com/acR/>

## Licença

Slides e textos: CC BY 4.0. Código: MIT.
