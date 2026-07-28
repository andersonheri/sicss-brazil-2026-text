# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 02: limpeza, contagem, keyness e LDA
#
# Autor: Anderson Henrique (CEM/USP)
#
# COMO RODAR
# ----------
# Qualquer uma destas três formas funciona, de qualquer diretório:
#   (1) Abra Workshop_SICSS_2026.Rproj e rode: source("scripts/02_quantitativo.R")
#   (2) No terminal:  Rscript scripts/02_quantitativo.R
#   (3) No RStudio, abra este arquivo e clique em Source.
#
# SOBRE OS DADOS
# --------------
# Roda sobre o mesmo corpus ilustrativo de scripts/01_corpus.R e
# scripts/06_atividade.R (data/corpus_atividade.csv, 16 falas fictícias de um
# plenário municipal fictício). Este script é independente: reconstrói o
# corpus sozinho, não depende de nenhum outro script ter rodado antes. Troque
# a Seção 1 pelo seu próprio corpus quando for rodar de verdade.
#
# Com um corpus de 16 documentos, o LDA da Seção 5 é ilustrativo e instável
# por natureza (ver "A armadilha do k" em aula01_manha.tex): serve para
# mostrar a mecânica, não para tirar conclusão substantiva.
#
# Saída: outputs/top_termos.csv, outputs/keyness.csv
# =============================================================================

# =============================================================================
# 0. LOCALIZAR A RAIZ DO PROJETO
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
p_data    <- function(...) file.path(RAIZ, "data", ...)
p_outputs <- function(...) file.path(RAIZ, "outputs", ...)

library(acR)
set.seed(1234)

# =============================================================================
# 1. CORPUS
# =============================================================================

bruto  <- read.csv(p_data("corpus_atividade.csv"), stringsAsFactors = FALSE)
corpus <- ac_corpus(bruto, text = texto, docid = doc_id, meta = grupo)

# =============================================================================
# 2. LIMPEZA
# =============================================================================

sw <- ac_clean_stopwords(preset = "pt-br-extended")

corpus_limpo <- ac_clean(
  corpus,
  remove_stopwords = "pt-br-extended",
  extra_stopwords   = sw,
  normalize_pt      = TRUE,
  min_char          = 3L,
  verbose           = TRUE
)

# =============================================================================
# 3. DESCRITIVA: frequência e tf-idf
# =============================================================================

contagem_grupo <- ac_count(corpus_limpo, by = "grupo")

top_termos <- ac_top_terms(contagem_grupo, n = 10, by = "grupo")
print(top_termos)

tfidf <- ac_tf_idf(contagem_grupo, by = "grupo")

# =============================================================================
# 4. KEYNESS: o que distingue os dois grupos
# =============================================================================

kn <- ac_keyness(contagem_grupo, group = "grupo", target = "situacao")
print(kn)

# =============================================================================
# 5. TÓPICOS (LDA) — ilustrativo; corpus pequeno demais para conclusão
# substantiva, serve para mostrar a mecânica (ver comentário no topo)
# =============================================================================

lda <- ac_lda(corpus_limpo, k = 2, seed = 1234)
print(lda)

# =============================================================================
# 6. EXPORTAR TABELAS
# =============================================================================

dir.create(p_outputs(), showWarnings = FALSE, recursive = TRUE)
ac_export(top_termos, p_outputs("top_termos.csv"))
ac_export(kn, p_outputs("keyness.csv"))

message("Concluido. Tabelas salvas em ", p_outputs())
