# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 00: instalação e verificação de pacotes
#
# Autor: Anderson Henrique (CEM/USP)
#
# OBJETIVO
# --------
# Conferir se todos os pacotes usados nos scripts do workshop estão instalados
# e, se não estiverem, instalá-los. Rode isto ANTES de qualquer outro script,
# de preferência um dia antes do workshop (alguns pacotes demoram para
# compilar).
#
# COMO RODAR
# ----------
# Rscript scripts/00_setup.R
#
# O QUE ENTRA
# -----------
# Nada. Este script não depende de dados do projeto.
#
# O QUE SAI
# ---------
# Mensagens no console dizendo o que já estava instalado e o que foi
# instalado agora. Não grava nenhum arquivo.
# =============================================================================

# =============================================================================
# 1. PACOTES DO CRAN
# -----------------------------------------------------------------------------
# Agrupados por onde são usados, só para documentação; a instalação é única.
# =============================================================================

pacotes_cran <- c(
  # Núcleo tidyverse usado em todos os scripts numéricos
  "dplyr", "readr", "forcats", "ggplot2", "tibble",
  # Texto (scripts/05_figuras.R, scripts/06_atividade.R)
  "tidytext",
  # Modelagem de tópicos e texto (usados pelo acR por baixo, e no Demo de KWIC)
  "quanteda", "quanteda.textstats", "quanteda.textmodels", "topicmodels",
  # Confiabilidade entre codificadores (scripts/04_validacao.R)
  "irr", "irrCAC",
  # Utilitários de projeto
  "here", "remotes", "rstudioapi",
  # Camada de LLM (scripts/03_llm.R, scripts/06_atividade.R)
  "ellmer",
  # Reprodutibilidade do ambiente (renv.lock)
  "renv"
)

faltando_cran <- pacotes_cran[!vapply(pacotes_cran, requireNamespace,
                                      logical(1), quietly = TRUE)]

if (length(faltando_cran) > 0) {
  message("Instalando do CRAN: ", paste(faltando_cran, collapse = ", "))
  install.packages(faltando_cran)
} else {
  message("Todos os pacotes do CRAN ja estao instalados.")
}

# =============================================================================
# 2. acR (GitHub, ainda nao esta no CRAN)
# =============================================================================

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

if (!requireNamespace("acR", quietly = TRUE)) {
  message("Instalando acR do GitHub (andersonheri/acR)...")
  remotes::install_github("andersonheri/acR")
} else {
  message("acR ja esta instalado (versao ",
          as.character(utils::packageVersion("acR")), ").")
}

# =============================================================================
# 3. CONFERÊNCIA FINAL
# =============================================================================

todos <- c(pacotes_cran, "acR")
status <- vapply(todos, requireNamespace, logical(1), quietly = TRUE)

cat("\n-- Status final -----------------------------------------------\n")
for (i in seq_along(todos)) {
  cat(sprintf("  [%s] %s\n", ifelse(status[i], "OK", "FALTA"), todos[i]))
}
cat("-----------------------------------------------------------------\n")

if (!all(status)) {
  stop(
    "Pacotes ainda faltando: ", paste(todos[!status], collapse = ", "),
    ". Instale manualmente e rode este script de novo.",
    call. = FALSE
  )
}

message("Ambiente pronto. Pode seguir para scripts/01_corpus.R.")
