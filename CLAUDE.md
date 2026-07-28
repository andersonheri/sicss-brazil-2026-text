# CLAUDE.md

Contexto do projeto para o Claude Code. Leia antes de qualquer alteração.

## O que é este repositório

Materiais do **Workshop de Análise Automatizada de Texto**, ministrado por
Anderson Henrique (CEM/USP · INCT QualiGov · IPEA) no **SICSS-Brazil 2026**,
na FGV do Rio de Janeiro, em **29 de julho de 2026**.

São duas aulas, em turnos:

| Aula | Horário | Formato | Arquivo |
|---|---|---|---|
| Manhã | 10h15 às 12h00 (105 min) | Estado da arte, conceitual, com demos curtas | `aula01_manha.tex` |
| Tarde | 13h30 às 15h00 (90 min) | Oficina aplicada ao projeto de cada aluno | `aula02_tarde.tex` |

Público: pós-graduação em ciências sociais, **heterogêneo em R** (do iniciante
ao avançado). Idioma: **português**.

## Tese que organiza o material

> A automação não relaxa nenhuma exigência da análise de conteúdo clássica.
> Ela transfere o ônus da validação do momento da codificação para o momento
> da auditoria.

Todo slide deve se conectar a isso. O eixo é **validação**, não ferramenta.

## Estrutura

```
.
├── Workshop_SICSS_2026.Rproj   abrir antes de rodar scripts em R
├── .workshop-root              sentinela usado por 05_figuras.R; NÃO apagar
├── .Rprofile                   ativa o renv (source("renv/activate.R"))
├── renv.lock                   versões travadas dos pacotes do CRAN
├── renv/                       infraestrutura do renv (library/ não versionada)
├── CLAUDE.md                   este arquivo
├── README.md
├── ATIVIDADE_TARDE.md          explicação da tarefa da tarde para os alunos
├── LICENSE                     MIT (código) + CC BY 4.0 (slides)
├── CITATION.cff
├── aula01_manha.tex            64 páginas de projeção (~45 slides)
├── aula02_tarde.tex            32 páginas: 21 no corpo + 11 no apêndice
├── figuras/
│   ├── fig_*.png               geradas por scripts/05_figuras.R (300 dpi)
│   └── dados/fig*.csv          insumos ILUSTRATIVOS das figuras
├── scripts/
│   ├── 00_setup.R              instala/confere pacotes
│   ├── 01_corpus.R             coleta e construção do corpus
│   ├── 02_quantitativo.R       limpeza, contagem, keyness, LDA
│   ├── 03_llm.R                codebook e classificação por LLM (placeholder)
│   ├── 04_validacao.R          amostragem, ac_qual_irr, ac_qual_reliability
│   ├── 05_figuras.R            gera as figuras dos slides
│   └── 06_atividade.R          script-modelo para os alunos levarem
├── data/
│   ├── corpus_atividade.csv    corpus fictício, usado pelos scripts acima
│   └── resultado_llm_precomputado.rds  placeholder, citado nos slides
└── outputs/                    top_termos.csv, keyness.csv, irr.csv, reliability.csv
```

## Convenções obrigatórias

### Estilo de escrita (preferências do autor)

- **Não usar travessão** (`---` ou `—`) no corpo do texto. Reescreva a frase
  com vírgula, parênteses ou dois períodos. Não troque mecanicamente por outro
  sinal.
- Em enumerações, usar "e" antes do último item: "PT, PL e PSOL".
- Evitar excesso de dois-pontos, clichês motivacionais e contrastes artificiais.
- Linguagem direta, didática, com raciocínio progressivo. Clareza importa mais
  que sofisticação.
- Análise crítica é esperada: apontar riscos, gargalos e contrapontos, e não
  apenas validar ideias.

### Integridade factual

- **Nunca inventar referências**, resultados, números ou funções de pacote.
- Marcar com `[VERIFICAR]` o que não foi confirmado. Já existe uma marcação
  assim na literatura sobre inferência com rótulos imperfeitos (2023--2026).
- As figuras usam dados **ilustrativos**, e isso está rotulado em cada slide
  como "Saída ilustrativa, gerada para fins didáticos". **Manter esse rótulo.**

### LaTeX

- Classe: `beamer`, `aspectratio=169`, tema `Madrid`, `\usepackage[brazilian]{babel}`.
- Cores: `azulUNI` `#1F4E79`, `azulUNIclaro` `#447296`, `laranjaDestaque` `#C85A1E`.
- Dois estilos de `listings`: `Restilo` (código R) e `Rsaida` (saída de console,
  fundo cinza, sem realce).
- Margens: `\setbeamersize{text margin left=0.55cm, text margin right=0.55cm}`.
- Frames com `lstlisting` precisam de `[fragile]`.
- `aula02_tarde.tex` **não** usa `\AtBeginSection`, de propósito: com 20 minutos
  de exposição, slides de roteiro custam caro.

**Verificação obrigatória após editar qualquer `.tex`:**

```bash
pdflatex -interaction=nonstopmode aula01_manha.tex
pdflatex -interaction=nonstopmode aula01_manha.tex   # 2ª passagem
grep -c "^!" aula01_manha.log            # deve ser 0
grep -c "Overfull" aula01_manha.log      # deve ser 0 ou 1 (resíduo de 1,1 pt)
```

`Overfull \vbox` significa texto vazando abaixo do slide. `Overfull \hbox`
significa vazando à direita. Ambos precisam ser corrigidos, não ignorados.

### R

- Caminhos **sempre** relativos à raiz, resolvidos pelos helpers `p_dados()` e
  `p_figuras()` definidos em `05_figuras.R`. Nunca usar `setwd()` dentro do
  script nem caminho absoluto.
- Novos scripts devem reaproveitar o bloco `localizar_raiz()` de `05_figuras.R`.
- `set.seed(1234)` em tudo que tenha componente aleatório.
- Chaves de API vivem no `.Renviron`, nunca no código. `.gitignore` já protege.
- Comentar decisões substantivas, não sintaxe óbvia.
- Ambiente confirmado do autor: **R 4.3.2, macOS, aarch64**.

## Pacote acR

O autor mantém o `acR` (v0.3.2): <https://ahenriquecp.com/acR/>

Funções usadas nos slides, todas confirmadas na documentação oficial:

`ac_import` · `ac_corpus` · `ac_fetch_camara` · `ac_fetch_senado` ·
`ac_clean` · `ac_clean_stopwords` · `ac_tokenize` · `ac_count` ·
`ac_top_terms` · `ac_plot_top_terms` · `ac_tf_idf` · `ac_plot_tf_idf` ·
`ac_keyness` · `ac_plot_keyness` · `ac_lda` · `ac_plot_lda_topics` ·
`ac_qual_codebook` · `ac_qual_code` · `ac_qual_sample` ·
`ac_qual_export_for_review` · `ac_qual_import_human` · `ac_qual_irr` ·
`ac_qual_reliability` · `ac_qual_report` · `ac_export`

**Não invente funções do `acR`.** Se precisar de algo fora dessa lista,
consulte <https://ahenriquecp.com/acR/reference/> antes, ou use base R.
Já houve um caso: `ac_plot_confusion()` foi assumida e depois substituída por
`table()` porque não estava documentada.

## Estado atual

Concluído:

- [x] Slides das duas aulas, compilando sem erro
- [x] `scripts/05_figuras.R`, executado com sucesso pelo autor
- [x] Quatro figuras em PNG, 300 dpi, geradas em `ggplot2`
- [x] Estrutura do projeto, README, LICENSE, CITATION.cff, .gitignore
- [x] Git inicializado, branch `main`, primeiro commit feito

Concluído (adicional):

- [x] `scripts/03_llm.R`: gera `data/resultado_llm_precomputado.rds`
      (placeholder ilustrativo, número por categoria bate com o slide de
      aula02_tarde.tex; ver comentário no topo do script)
- [x] `data/resultado_llm_precomputado.rds`, versionado via exceção no
      `.gitignore`
- [x] Push para `github.com/andersonheri/sicss-brazil-2026-text`
- [x] `scripts/06_atividade.R`: script-modelo com exemplos reais do `acR`
      (assinaturas conferidas contra o pacote instalado, não de memória) para
      os alunos levarem e adaptarem ao próprio corpus. Rodado com sucesso
      sobre o corpus de exemplo.
- [x] `data/corpus_atividade.csv`: corpus de exemplo fictício (16 falas de um
      plenário municipal fictício sobre uma reforma de praça), só para o
      script rodar de fábrica; alunos trocam pelo próprio corpus
- [x] Exercício da tarde redesenhado para formato individual e online: sem
      troca de codebook entre colegas, confiabilidade testada por
      dupla-codificação interna (o próprio aluno codifica os mesmos 5
      documentos duas vezes, cego entre as rodadas). `aula02_tarde.tex`
      atualizado (seção Atividade e as duas referências cruzadas antes
      dela), recompilado sem erro.
- [x] Corrigidos os blocos "Demo 3" e "Demo 4" de `aula01_manha.tex`
      (frequência, distintividade/keyness, KWIC e LDA), que chamavam
      `ac_count()`/`ac_keyness()`/`ac_lda()` passando o resultado de
      `ac_tokenize()` onde a assinatura real espera `ac_corpus`, e usavam um
      argumento `ref` inexistente em `ac_keyness()` (o certo é `group`).
      Achado ao conferir contra o pacote `acR` instalado localmente (Rd db e
      testthat), não de memória. Recompilado sem erro.
- [x] `scripts/00_setup.R`: confere e instala os pacotes do CRAN e o `acR`
      (GitHub). Rodado com sucesso; todos os pacotes já estavam instalados.
- [x] `scripts/01_corpus.R`: bloco (A) real (`ac_fetch_camara`/
      `ac_fetch_senado`, comentado) e bloco (B) ativo, que reaproveita
      `data/corpus_atividade.csv`. Rodado com sucesso.
- [x] `scripts/02_quantitativo.R`: limpeza, contagem, tf-idf, keyness e LDA
      sobre o corpus de exemplo, exportando `outputs/top_termos.csv` e
      `outputs/keyness.csv` via `ac_export()`. Rodado com sucesso.
- [x] `scripts/04_validacao.R`: `ac_qual_sample()` real sobre
      `data/resultado_llm_precomputado.rds`, e reconstrução documento a
      documento da matriz de `figuras/dados/fig4_confusao.csv` para rodar
      `ac_qual_irr()` e `ac_qual_reliability()` de verdade. Exporta
      `outputs/irr.csv` e `outputs/reliability.csv`.
- [x] **Achado ao escrever o script acima:** o slide "Amostragem e métricas"
      de `aula02_tarde.tex` mostrava um único `ac_qual_irr()` devolvendo
      Gwet's AC1 e F1 macro, métricas que só existem em
      `ac_qual_reliability()` (função separada). Corrigido: o slide agora
      mostra as duas chamadas, com os números reais calculados pelo script
      (percent agreement 0,833; kappa 0,760; alpha 0,761; AC1 0,783; F1
      macro 0,786; antes eram 0,833/0,741/0,733/0,788/0,793, escritos à mão
      sem rodar a função). O κ citado no slide seguinte também foi
      atualizado de 0,74 para 0,76 para bater com o novo número.
- [x] `data/resultado_llm_precomputado.rds` corrigido: a coluna se chamava
      `confianca`, mas a saída real de `ac_qual_code()` usa
      `confidence_score` (conferido em `tests/testthat/test-ac_qual_code.R`
      do pacote instalado). Com o nome errado, `ac_qual_sample(strategy =
      "uncertainty")` caía silenciosamente para amostragem aleatória (aviso
      "coluna não encontrada", sem erro). Corrigido; a estratégia de
      incerteza agora funciona de verdade sobre o placeholder.
- [x] `renv.lock` gerado com `renv::init()`. O `acR` fica com `Source:
      unknown` no lockfile porque, neste ambiente, foi instalado como
      pacote local do próprio autor, não via `remotes::install_github()`
      (sem os campos `Remote*` no DESCRIPTION) — por isso continua exigindo
      instalação manual à parte, documentada no README. Isso ativa `renv`
      neste projeto: abrir R aqui a partir de agora carrega
      `renv/activate.R` via `.Rprofile`.
- [x] `ATIVIDADE_TARDE.md`: explicação formal da tarefa da tarde para os
      alunos (formato individual, dupla-codificação interna, materiais,
      roteiro de apresentação, critério de sucesso).
- [x] Reconciliada a tabela por categoria do slide "Por que o número
      agregado engana" com `figuras/dados/fig4_confusao.csv`. Não existe
      função do `acR` para isso, então `scripts/04_validacao.R` calcula
      precisão/revocação/F1/kappa one-vs-rest na mão, a partir da matriz de
      confusão real, e exporta `outputs/metricas_por_categoria.csv`. Números
      antigos (escritos à mão) trocados pelos reais: punitivista
      0,918/0,862/0,889/0,809; preventivo 0,767/0,805/0,786/0,702; garantista
      0,471/0,667/0,552/0,505; nao_aplicavel 0,966/0,875/0,918/0,897. O texto
      abaixo da tabela também mudou: a fraqueza de "garantista" está na
      **precisão** (0,47), não na revocação como dizia antes (o valor 0,47
      já existia no slide antigo, só com o rótulo trocado).

Pendente:

- [ ] Nada crítico identificado para o workshop de amanhã.

## Restrição de execução no dia

Nenhuma chamada a API durante o workshop. Tudo pré-computado. Os scripts devem
ter dois caminhos: o código real do pipeline, comentado, e o carregamento do
resultado salvo, ativo. Esse padrão já está em `05_figuras.R`, blocos (A) e (B).

## Como pedir trabalho aqui

Ao criar novos scripts, seguir a numeração e o cabeçalho de `05_figuras.R`:
título, autor, objetivo, como rodar, o que entra, o que sai. Ao terminar,
rodar o script e reportar a saída real, sem simular resultado.
