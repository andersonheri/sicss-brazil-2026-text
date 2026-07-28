# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 04: amostragem para revisão humana e métricas de confiabilidade
#
# Autor: Anderson Henrique (CEM/USP)
#
# COMO RODAR
# ----------
# Qualquer uma destas três formas funciona, de qualquer diretório:
#   (1) Abra Workshop_SICSS_2026.Rproj e rode: source("scripts/04_validacao.R")
#   (2) No terminal:  Rscript scripts/04_validacao.R
#   (3) No RStudio, abra este arquivo e clique em Source.
#
# SOBRE OS DADOS
# --------------
# Este script tem duas partes independentes, e ambas rodam de verdade:
#
# Seção 1: ac_qual_sample() de verdade sobre data/resultado_llm_precomputado.rds
# (o placeholder de scripts/03_llm.R). Mostra o mecanismo real de amostragem
# por incerteza. NÃO segue para ac_qual_export_for_review()/
# ac_qual_import_human(): esses dois exigem, respectivamente, o corpus com o
# texto original e uma planilha revisada por um humano de verdade, nenhum dos
# dois existe neste projeto ainda.
#
# Seção 2: reconstrói, documento a documento, a MESMA matriz de confusão
# ilustrativa já usada em figuras/dados/fig4_confusao.csv (a que gera
# figuras/fig_confusao.png), e roda ac_qual_irr() e ac_qual_reliability() de
# verdade sobre ela. Os números impressos aqui são a saída real dessas duas
# funções, não uma reprodução manual do texto do slide — por isso podem (e
# devem) divergir um pouco do que está em aula02_tarde.tex hoje. Ver a nota
# no final do script.
#
# Achado ao escrever este script: o slide "Amostragem e métricas em quatro
# linhas" (aula02_tarde.tex) mostra um único ac_qual_irr() devolvendo Gwet's
# AC1 e F1 macro. Essas duas métricas não existem em ac_qual_irr() (que
# calcula percent_agreement, cohen_kappa, fleiss_kappa e krippendorff); só
# ac_qual_reliability() as calcula. São duas chamadas, não uma.
#
# Saída: outputs/irr.csv, outputs/reliability.csv
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
p_data     <- function(...) file.path(RAIZ, "data", ...)
p_figuras  <- function(...) file.path(RAIZ, "figuras", ...)
p_outputs  <- function(...) file.path(RAIZ, "outputs", ...)

library(acR)
library(dplyr)
set.seed(1234)

# =============================================================================
# 1. AMOSTRAGEM PARA REVISÃO HUMANA (mecanismo real)
# =============================================================================

resultado <- readRDS(p_data("resultado_llm_precomputado.rds"))

amostra <- ac_qual_sample(resultado, n = 150, strategy = "uncertainty")
cat("\nDistribuicao da amostra por categoria (top da incerteza):\n")
print(table(amostra$categoria))

# ac_qual_export_for_review(amostra, path, corpus_limpo) e
# ac_qual_import_human() ficam de fora: exigem, respectivamente, o corpus com
# o texto original e uma planilha revisada por um humano de verdade.

# =============================================================================
# 2. CONFIABILIDADE: reconstrução da matriz de confusão de fig4_confusao.csv
# -----------------------------------------------------------------------------
# Expande a tabela (llm, humano, n) em uma linha por documento, para poder
# chamar ac_qual_irr()/ac_qual_reliability() de verdade.
# =============================================================================

confusao <- read.csv(p_figuras("dados", "fig4_confusao.csv"), stringsAsFactors = FALSE)
stopifnot(sum(confusao$n) == 150)

doc_a_doc <- confusao |>
  tidyr::uncount(n) |>
  mutate(doc_id = paste0("d", row_number()))

llm_df    <- doc_a_doc |> select(doc_id, categoria = llm)
humano_df <- doc_a_doc |> select(doc_id, categoria = humano)

# --- ac_qual_irr(): percent agreement, Cohen's kappa, Krippendorff's alpha ---
irr <- ac_qual_irr(
  gold      = humano_df,
  predicted = llm_df,
  id_col    = "doc_id",
  cat_col   = "categoria"
)
print(irr)

# --- ac_qual_reliability(): krippendorff, Gwet AC1, F1 macro, percent agreement,
# com bootstrap (chamada SEPARADA de ac_qual_irr(); ver nota no topo) ---
confiabilidade <- ac_qual_reliability(
  llm     = llm_df,
  human   = humano_df,
  cat_col = "categoria"
)
print(confiabilidade)

# =============================================================================
# 3. EXPORTAR
# =============================================================================

dir.create(p_outputs(), showWarnings = FALSE, recursive = TRUE)
ac_export(irr, p_outputs("irr.csv"))
ac_export(confiabilidade, p_outputs("reliability.csv"))

message("Concluido. Tabelas salvas em ", p_outputs())
message(
  "Compare estes numeros reais com o slide \"Amostragem e metricas em quatro ",
  "linhas\" (aula02_tarde.tex): se divergirem, o slide deve ser atualizado ",
  "para bater com esta saida, nao o contrario."
)
