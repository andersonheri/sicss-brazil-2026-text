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
├── CLAUDE.md                   este arquivo
├── README.md
├── LICENSE                     MIT (código) + CC BY 4.0 (slides)
├── CITATION.cff
├── aula01_manha.tex            64 páginas de projeção (~45 slides)
├── aula02_tarde.tex            32 páginas: 21 no corpo + 11 no apêndice
├── figuras/
│   ├── fig_*.png               geradas por scripts/05_figuras.R (300 dpi)
│   └── dados/fig*.csv          insumos ILUSTRATIVOS das figuras
├── scripts/05_figuras.R        único script existente até agora
├── data/                       vazia: corpus e outputs pré-computados
└── outputs/                    vazia: tabelas, relatórios, planilhas
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

Pendente:

- [ ] `scripts/00_setup.R`: instalação e verificação de pacotes
- [ ] `scripts/01_corpus.R`: coleta e construção do corpus
- [ ] `scripts/02_quantitativo.R`: limpeza, contagem, keyness e LDA
- [ ] `scripts/04_validacao.R`: amostragem, `ac_qual_irr` e métricas
- [ ] `renv.lock`
- [ ] Arquivo com a explicação formal da tarefa da tarde (autor decidiu
      adiar; formato da atividade já está fechado, falta só documentá-lo à
      parte dos slides)

## Restrição de execução no dia

Nenhuma chamada a API durante o workshop. Tudo pré-computado. Os scripts devem
ter dois caminhos: o código real do pipeline, comentado, e o carregamento do
resultado salvo, ativo. Esse padrão já está em `05_figuras.R`, blocos (A) e (B).

## Como pedir trabalho aqui

Ao criar novos scripts, seguir a numeração e o cabeçalho de `05_figuras.R`:
título, autor, objetivo, como rodar, o que entra, o que sai. Ao terminar,
rodar o script e reportar a saída real, sem simular resultado.
