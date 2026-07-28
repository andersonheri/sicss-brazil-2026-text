# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 01: coleta e construção do corpus
#
# Autor: Anderson Henrique (CEM/USP)
#
# COMO RODAR
# ----------
# Qualquer uma destas três formas funciona, de qualquer diretório:
#   (1) Abra Workshop_SICSS_2026.Rproj e rode: source("scripts/01_corpus.R")
#   (2) No terminal:  Rscript scripts/01_corpus.R
#   (3) No RStudio, abra este arquivo e clique em Source.
#
# SOBRE OS DADOS
# --------------
# O bloco (A) mostra a coleta real via API (Câmara e Senado), comentada:
# requer internet e não é executada aqui. O bloco (B), ativo, constrói o
# corpus a partir de data/corpus_atividade.csv, o mesmo corpus fictício
# (16 falas de um plenário municipal fictício) usado em scripts/06_atividade.R.
# Reaproveitá-lo aqui evita inventar um segundo corpus ilustrativo do zero, e
# mantém uma única fonte de dados de exemplo no projeto.
#
# Saída: nenhum arquivo. O objeto `corpus` fica disponível na sessão para
# scripts/02_quantitativo.R, que o reconstrói de forma independente (cada
# script deste projeto roda sozinho, sem depender de outro ter rodado antes).
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
# 1. COLETA
# -----------------------------------------------------------------------------
# (A) Com API real. NÃO RODE isto durante o workshop: precisa de internet,
# demora (paginação + sleep entre chamadas) e não é reprodutível de um dia
# para o outro (o acervo de discursos muda). Descomente em casa.
# =============================================================================

# disc_camara <- ac_fetch_camara(
#   data_inicio   = "2024-03-11",
#   data_fim      = "2024-03-15",
#   tipo_discurso = "plenario",
#   n_max         = 300L
# )
#
# disc_senado <- ac_fetch_senado(
#   data_inicio = "2024-03-11",
#   data_fim    = "2024-03-15",
#   n_max       = 100L
# )
#
# bruto <- dplyr::bind_rows(disc_camara, disc_senado)
# corpus <- ac_corpus(bruto, text = texto, docid = id_discurso, meta = partido)

# (B) Versão ilustrativa: reaproveita o corpus fictício da atividade, só para
# demonstrar a etapa. NÃO representa nenhuma coleta real da Câmara ou do
# Senado.
bruto  <- read.csv(p_data("corpus_atividade.csv"), stringsAsFactors = FALSE)
corpus <- ac_corpus(bruto, text = texto, docid = doc_id, meta = grupo)

print(corpus)

message(
  "Corpus construido com ", nrow(corpus), " documentos (ilustrativo). ",
  "Troque o bloco (B) pelo (A) quando tiver acesso a internet e quiser ",
  "coletar dados reais."
)
