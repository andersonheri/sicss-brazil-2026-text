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
# -----------------------------------------------------------------------------
# Depois que a LLM classifica todos os documentos (aqui, já feito por
# scripts/03_llm.R), você não confere todos de novo à mão: você confere uma
# AMOSTRA, e usa a concordância nessa amostra como estimativa de confiança
# para o restante. ac_qual_sample() escolhe essa amostra por você.
#
# strategy = "uncertainty" prioriza os documentos em que a própria LLM
# hesitou mais (menor `confidence_score`, ver scripts/03_llm.R): é aí que
# provavelmente estão os erros, então é aí que a revisão humana rende mais
# por documento revisado. As alternativas seriam "stratified" (garante
# representação proporcional de cada categoria), "random" (amostra
# aleatória simples) e "disagreement" (prioriza onde as rodadas de
# self-consistency mais divergiram entre si).
# =============================================================================

resultado <- readRDS(p_data("resultado_llm_precomputado.rds"))

amostra <- ac_qual_sample(resultado, n = 150, strategy = "uncertainty")
cat("\nDistribuicao da amostra por categoria (top da incerteza):\n")
print(table(amostra$categoria))

# Depois da amostragem, o passo seguinte do pipeline real seria:
#   ac_qual_export_for_review(amostra, "outputs/revisao.xlsx", corpus_limpo)
#   humano <- ac_qual_import_human("outputs/revisao_preenchida.xlsx")
# A primeira gera uma planilha para um humano codificar, SEM mostrar o
# rótulo que a LLM deu (evita que o humano apenas confirme a LLM por
# preguiça ou deferência). A segunda lê essa planilha de volta depois de
# preenchida. Nenhuma das duas roda aqui: a primeira precisa do corpus com o
# texto original (que este placeholder não tem, só as categorias), e a
# segunda precisa de uma planilha revisada por um humano de verdade, que
# ainda não existe neste projeto.

# =============================================================================
# 2. CONFIABILIDADE: reconstrução da matriz de confusão de fig4_confusao.csv
# -----------------------------------------------------------------------------
# Para chamar ac_qual_irr()/ac_qual_reliability() de verdade (e não só citar
# números), precisamos de uma tabela com uma LINHA POR DOCUMENTO (doc_id +
# categoria do humano + categoria da LLM). O que temos versionado é a
# matriz já agregada (quantos documentos caíram em cada combinação
# llm × humano), em figuras/dados/fig4_confusao.csv. tidyr::uncount(n)
# desfaz essa agregação: repete cada linha da matriz `n` vezes, uma por
# documento, e cria um doc_id sequencial para cada repetição.
# =============================================================================

confusao <- read.csv(p_figuras("dados", "fig4_confusao.csv"), stringsAsFactors = FALSE)
stopifnot(sum(confusao$n) == 150)

doc_a_doc <- confusao |>
  tidyr::uncount(n) |>
  mutate(doc_id = paste0("d", row_number()))

llm_df    <- doc_a_doc |> select(doc_id, categoria = llm)
humano_df <- doc_a_doc |> select(doc_id, categoria = humano)

# ac_qual_irr() compara dois codificadores (aqui, humano = "gold"/referência
# e LLM = "predicted") e devolve três leituras complementares da mesma
# concordância:
#   - Percent agreement: fração simples de documentos em que os dois
#     concordam. Fácil de entender, mas não desconta o acordo que
#     aconteceria só por acaso.
#   - Cohen's kappa: corrige o percent agreement pela concordância
#     esperada ao acaso, dada a distribuição das categorias.
#   - Krippendorff's alpha: mede a mesma coisa que o kappa, mas com uma
#     definição mais geral, que também funciona com mais de dois
#     codificadores e dados faltantes.
irr <- ac_qual_irr(
  gold      = humano_df,
  predicted = llm_df,
  id_col    = "doc_id",
  cat_col   = "categoria"
)
print(irr)

# ac_qual_reliability() é uma função SEPARADA (não é o mesmo que rodar
# ac_qual_irr() de novo): ela soma duas métricas que a primeira não calcula
#   - Gwet's AC1: alternativa ao kappa mais estável quando uma categoria
#     domina as demais (o "paradoxo do kappa": com concordância alta mas
#     categorias desbalanceadas, o kappa pode cair artificialmente).
#   - F1 macro: média (não ponderada) do F1 de cada categoria. É por isso
#     que ela pune mais a categoria rara que vai mal (Seção 3) do que uma
#     métrica agregada simples puniria.
# e adiciona intervalo de confiança de 95% via bootstrap (reamostragem dos
# 150 documentos, 1000 vezes, para estimar a variabilidade da estimativa)
# a TODAS as métricas, inclusive as que ac_qual_irr() já mostrou.
confiabilidade <- ac_qual_reliability(
  llm     = llm_df,
  human   = humano_df,
  cat_col = "categoria"
)
print(confiabilidade)

# =============================================================================
# 3. MÉTRICAS POR CATEGORIA (precisão, revocação, F1, kappa one-vs-rest)
# -----------------------------------------------------------------------------
# ac_qual_irr()/ac_qual_reliability() só dão métricas agregadas. O slide
# "Por que o número agregado engana" (aula02_tarde.tex) mostra uma quebra por
# categoria; não existe função do acR para isso, então é calculado aqui na
# mão, com as fórmulas padrão (precisão/revocação/F1 a partir da matriz de
# confusão; kappa one-vs-rest tratando cada categoria como um problema
# binário "é esta categoria" vs. "é outra").
# =============================================================================

categorias <- c("punitivista", "preventivo", "garantista", "nao_aplicavel")

metrica_categoria <- function(cat) {
  llm_bin    <- factor(doc_a_doc$llm    == cat, levels = c(TRUE, FALSE))
  humano_bin <- factor(doc_a_doc$humano == cat, levels = c(TRUE, FALSE))
  tab <- table(llm = llm_bin, humano = humano_bin)

  TP <- tab["TRUE", "TRUE"];  FP <- tab["TRUE", "FALSE"]
  FN <- tab["FALSE", "TRUE"]; TN <- tab["FALSE", "FALSE"]
  n_total <- TP + FP + FN + TN

  precisao  <- TP / (TP + FP)
  revocacao <- TP / (TP + FN)
  f1        <- 2 * precisao * revocacao / (precisao + revocacao)

  po <- (TP + TN) / n_total
  pe <- ((TP + FP) / n_total) * ((TP + FN) / n_total) +
        ((FN + TN) / n_total) * ((FP + TN) / n_total)
  kappa <- (po - pe) / (1 - pe)

  tibble(
    categoria = cat, n = as.integer(TP + FP),
    precisao = round(precisao, 3), revocacao = round(revocacao, 3),
    F1 = round(f1, 3), kappa_cat = round(kappa, 3)
  )
}

metricas_por_categoria <- bind_rows(lapply(categorias, metrica_categoria))
print(metricas_por_categoria)

# =============================================================================
# 4. EXPORTAR
# =============================================================================

dir.create(p_outputs(), showWarnings = FALSE, recursive = TRUE)
ac_export(irr, p_outputs("irr.csv"))
ac_export(confiabilidade, p_outputs("reliability.csv"))
ac_export(metricas_por_categoria, p_outputs("metricas_por_categoria.csv"))

message("Concluido. Tabelas salvas em ", p_outputs())
message(
  "Compare estes numeros reais com os slides \"Amostragem e metricas de ",
  "confiabilidade\" e \"Por que o numero agregado engana\" ",
  "(aula02_tarde.tex): se divergirem, o slide deve ser atualizado para ",
  "bater com esta saida, nao o contrario."
)
