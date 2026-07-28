# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 06: caixa de ferramentas do acR para o SEU projeto
#
# Autor: Anderson Henrique (CEM/USP)
#
# OBJETIVO
# --------
# Este script não é uma demonstração para assistir. É um ponto de partida para
# você levar e adaptar depois do workshop, rodando sobre o corpus da SUA
# pesquisa. Cada seção cobre uma etapa do pipeline (limpeza, descrição,
# comparação entre grupos, tópicos, camada qualitativa com LLM) com a sintaxe
# real do acR (v0.3.2), testada contra o pacote instalado, não copiada de
# memória.
#
# COMO USAR
# ---------
# 1. Rode a Seção 1 com o mini-corpus de exemplo incluso, só para ver o
#    script funcionando de ponta a ponta sem precisar de nada seu.
# 2. Depois, troque a Seção 1 pelo SEU corpus (um CSV com uma coluna de texto
#    e, se houver, uma coluna de grupo) e rode de novo a partir dali.
# 3. As seções 5 e 6 (LLM) exigem chave de API e NÃO devem ser rodadas
#    durante o workshop. Rode em casa, com sua própria chave em .Renviron.
#
# O QUE ENTRA (exemplo incluso)
# ------------------------------
# data/corpus_atividade.csv: 16 falas fictícias de um plenário municipal
# fictício sobre a reforma de uma praça, com uma coluna `grupo` (situacao /
# oposicao). É um corpus de brinquedo, só para o script rodar; não representa
# nenhum caso real.
#
# O QUE SAI
# ---------
# Nada é salvo automaticamente. Cada seção imprime ou plota o resultado; use
# ac_export() (Seção 7) quando quiser salvar uma tabela específica.
# =============================================================================

# =============================================================================
# 0. LOCALIZAR A RAIZ DO PROJETO
# -----------------------------------------------------------------------------
# Bloco idêntico ao de scripts/05_figuras.R, reaproveitado conforme convenção
# do projeto.
# =============================================================================

localizar_raiz <- function(marcador = ".workshop-root") {

  candidatos <- character(0)

  if (requireNamespace("here", quietly = TRUE)) {
    r <- try(here::here(), silent = TRUE)
    if (!inherits(r, "try-error")) candidatos <- c(candidatos, r)
  }

  args <- commandArgs(trailingOnly = FALSE)
  arq  <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(arq) > 0) {
    candidatos <- c(candidatos, dirname(normalizePath(arq[1], mustWork = FALSE)))
  }

  frames <- sys.frames()
  if (length(frames) > 0) {
    ofile <- try(frames[[1]]$ofile, silent = TRUE)
    if (!inherits(ofile, "try-error") && !is.null(ofile)) {
      candidatos <- c(candidatos,
                      dirname(normalizePath(ofile, mustWork = FALSE)))
    }
  }

  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      isTRUE(try(rstudioapi::isAvailable(), silent = TRUE))) {
    p <- try(rstudioapi::getSourceEditorContext()$path, silent = TRUE)
    if (!inherits(p, "try-error") && !is.null(p) && nzchar(p)) {
      candidatos <- c(candidatos, dirname(normalizePath(p, mustWork = FALSE)))
    }
  }

  candidatos <- c(candidatos, getwd())

  for (dir_base in unique(candidatos)) {
    atual <- dir_base
    for (i in seq_len(4)) {
      if (file.exists(file.path(atual, marcador))) {
        return(normalizePath(atual))
      }
      pai <- dirname(atual)
      if (identical(pai, atual)) break
      atual <- pai
    }
  }

  stop(
    "Nao encontrei o arquivo-sentinela '", marcador, "'.\n",
    "Diretorio de trabalho atual: ", getwd(), "\n\n",
    "Solucao 1: abra Workshop_SICSS_2026.Rproj no RStudio e rode de novo.\n",
    "Solucao 2: setwd('caminho/ate/Workshop_SICSS_2026') e rode de novo.",
    call. = FALSE
  )
}

RAIZ <- localizar_raiz()
message("Raiz do projeto: ", RAIZ)
p_data <- function(...) file.path(RAIZ, "data", ...)

library(acR)

# =============================================================================
# 1. CARREGAR O CORPUS
# -----------------------------------------------------------------------------
# Troque este bloco pelo SEU corpus: um data.frame com uma coluna de texto e,
# se fizer sentido para sua pergunta, uma coluna de grupo (partido, período,
# fonte, autor...). `ac_corpus()` detecta colunas chamadas text/texto/doc/
# content/conteudo automaticamente, mas é mais seguro nomear explicitamente.
# =============================================================================

bruto <- read.csv(p_data("corpus_atividade.csv"), stringsAsFactors = FALSE)

corpus <- ac_corpus(bruto, text = texto, docid = doc_id, meta = grupo)
corpus

# =============================================================================
# 2. LIMPEZA
# -----------------------------------------------------------------------------
# `remove_stopwords` aceita um preset (pt, pt-br-extended, pt-legislativo) ou
# um vetor próprio. `protect` preserva siglas/termos que a limpeza destruiria.
# =============================================================================

sw <- ac_clean_stopwords(
  preset = "pt-br-extended",
  add    = c("bairro", "municipio")   # ajuste para o vocabulario do SEU corpus
)

corpus_limpo <- ac_clean(
  corpus,
  remove_stopwords = "pt-br-extended",
  extra_stopwords   = sw,
  normalize_pt      = TRUE,
  min_char          = 3L,
  verbose           = TRUE
)

# =============================================================================
# 3. DESCRITIVA: frequência, tf-idf e keyness
# -----------------------------------------------------------------------------
# ac_count() opera sobre o CORPUS (não sobre o resultado de ac_tokenize());
# ele chama ac_tokenize() internamente. Isso vale para os três usos abaixo.
# =============================================================================

contagem <- ac_count(corpus_limpo)
ac_top_terms(contagem, n = 15) |> ac_plot_top_terms()

# Por grupo, se houver uma coluna de grupo no seu corpus:
contagem_grupo <- ac_count(corpus_limpo, by = "grupo")
ac_top_terms(contagem_grupo, n = 8, by = "grupo")

# TF-IDF: o que é distintivo de cada grupo, não apenas frequente
tfidf <- ac_tf_idf(contagem_grupo, by = "grupo")
head(tfidf[order(-tfidf$tf_idf), ], 10)

# Keyness: teste estatístico entre EXATAMENTE dois grupos.
# group = nome da coluna; target = o valor que vira o grupo-alvo.
# O outro valor da coluna vira automaticamente o grupo de referência
# (não existe argumento `ref` nesta função).
kn <- ac_keyness(contagem_grupo, group = "grupo", target = "situacao")
ac_plot_keyness(kn)

# =============================================================================
# 4. TÓPICOS (LDA) — opcional, exige corpus razoavelmente grande
# -----------------------------------------------------------------------------
# ac_lda() também opera sobre o CORPUS, não sobre tokens. Com um corpus
# pequeno como o de exemplo, os tópicos tendem a ser instáveis; isso é
# esperado e é, em si, uma lição sobre tamanho mínimo de corpus para LDA.
# =============================================================================

# lda <- ac_lda(corpus_limpo, k = 3, seed = 1234)
# ac_plot_lda_topics(lda)

# =============================================================================
# 5. CAMADA QUALITATIVA: codebook e classificação por LLM
# -----------------------------------------------------------------------------
# NÃO rode esta seção durante o workshop: exige chave de API (.Renviron) e
# faz chamadas cobradas por token. Rode em casa, sobre o corpus do seu
# projeto.
# =============================================================================

# codebook <- ac_qual_codebook(
#   name         = "meu_codebook",
#   instructions = "Descreva aqui, em uma frase, o que a LLM deve fazer.",
#   categories   = list(
#     categoria_1 = list(
#       definition   = "Defina o que ESTA categoria significa.",
#       examples_pos = c("Um exemplo real ou verossímil do seu corpus."),
#       examples_neg = c("Um exemplo de caso-limite que NAO se encaixa aqui.")
#     ),
#     categoria_2 = list(
#       definition   = "Defina a segunda categoria, e por que ela e diferente
#                        da primeira."
#     )
#   )
# )
#
# chat_obj <- ellmer::chat_anthropic(model = "claude-sonnet-4-20250514")
#
# resultado <- ac_qual_code(
#   corpus        = corpus_limpo,
#   codebook      = codebook,
#   chat          = chat_obj,
#   k_consistency = 3L,
#   confidence    = "total"
# )
#
# table(resultado$categoria)

# =============================================================================
# 6. VALIDAÇÃO: amostra para revisão humana e concordância humano-LLM
# -----------------------------------------------------------------------------
# Também depende da Seção 5 já ter rodado (variável `resultado`).
# =============================================================================

# amostra <- ac_qual_sample(resultado, n = 10, strategy = "uncertainty")
# ac_qual_export_for_review(amostra, "outputs/revisao.xlsx", corpus_limpo)
# # Codifique manualmente outputs/revisao.xlsx, depois:
# humano <- ac_qual_import_human("outputs/revisao_preenchida.xlsx")
#
# irr <- ac_qual_irr(gold = humano, predicted = resultado,
#                    id_col = "doc_id", cat_col = "categoria")
# irr

# =============================================================================
# 7. EXPORTAR UMA TABELA (quando quiser salvar algo específico)
# =============================================================================

# ac_export(kn, path = p_data("../outputs/keyness_meu_projeto.xlsx"))

message(
  "Script rodado ate a Secao 4 (descritiva e keyness) com o corpus de ",
  "exemplo. Troque a Secao 1 pelo seu proprio corpus para continuar dai."
)
