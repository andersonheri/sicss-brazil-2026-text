# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 03: codebook e classificação por LLM (aula da tarde)
#
# Autor: Anderson Henrique (CEM/USP)
#
# COMO RODAR
# ----------
# Qualquer uma destas três formas funciona, de qualquer diretório:
#   (1) Abra Workshop_SICSS_2026.Rproj e rode: source("scripts/03_llm.R")
#   (2) No terminal:  Rscript scripts/03_llm.R
#   (3) No RStudio, abra este arquivo e clique em Source.
# O script localiza sozinho a raiz do projeto. Não é preciso setwd().
#
# SOBRE OS DADOS
# --------------
# Este script NÃO chama a API de LLM. Não há corpus real nem chave de API
# disponíveis ainda para este projeto, então o bloco (B) monta um resultado
# ILUSTRATIVO por documento cujas agregações reproduzem exatamente os números
# já impressos no slide de aula02_tarde.tex (118/84/27/71 documentos por
# categoria; conf_media e k_unanime por categoria). Não é uma classificação
# real, é um placeholder estrutural para que o slide e a atividade da tarde
# funcionem sem chamada de API no dia do workshop.
#
# Quando houver corpus e codebook reais, o bloco (A) mostra o pipeline
# verdadeiro a ser usado no lugar do bloco (B), no mesmo padrão de
# scripts/05_figuras.R.
#
# Saída: data/resultado_llm_precomputado.rds
# =============================================================================

# =============================================================================
# 0. LOCALIZAR A RAIZ DO PROJETO
# -----------------------------------------------------------------------------
# Bloco idêntico ao de scripts/05_figuras.R, reaproveitado conforme convenção
# do projeto (CLAUDE.md: "novos scripts devem reaproveitar o bloco
# localizar_raiz() de 05_figuras.R").
# =============================================================================

localizar_raiz <- function(marcador = ".workshop-root") {

  candidatos <- character(0)

  # (a) pacote here, se instalado e se apontar para um projeto válido
  if (requireNamespace("here", quietly = TRUE)) {
    r <- try(here::here(), silent = TRUE)
    if (!inherits(r, "try-error")) candidatos <- c(candidatos, r)
  }

  # (b) caminho do script quando executado via Rscript
  args <- commandArgs(trailingOnly = FALSE)
  arq  <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(arq) > 0) {
    candidatos <- c(candidatos, dirname(normalizePath(arq[1], mustWork = FALSE)))
  }

  # (c) caminho do script quando executado via source()
  frames <- sys.frames()
  if (length(frames) > 0) {
    ofile <- try(frames[[1]]$ofile, silent = TRUE)
    if (!inherits(ofile, "try-error") && !is.null(ofile)) {
      candidatos <- c(candidatos,
                      dirname(normalizePath(ofile, mustWork = FALSE)))
    }
  }

  # (d) arquivo aberto no editor do RStudio
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      isTRUE(try(rstudioapi::isAvailable(), silent = TRUE))) {
    p <- try(rstudioapi::getSourceEditorContext()$path, silent = TRUE)
    if (!inherits(p, "try-error") && !is.null(p) && nzchar(p)) {
      candidatos <- c(candidatos, dirname(normalizePath(p, mustWork = FALSE)))
    }
  }

  # (e) último recurso: diretório de trabalho atual
  candidatos <- c(candidatos, getwd())

  # De cada candidato, sobe até quatro níveis procurando o sentinela
  for (dir_base in unique(candidatos)) {
    atual <- dir_base
    for (i in seq_len(4)) {
      if (file.exists(file.path(atual, marcador))) {
        return(normalizePath(atual))
      }
      pai <- dirname(atual)
      if (identical(pai, atual)) break   # chegou à raiz do sistema
      atual <- pai
    }
  }

  stop(
    "Nao encontrei o arquivo-sentinela '", marcador, "'.\n",
    "Diretorio de trabalho atual: ", getwd(), "\n\n",
    "Solucao 1: abra Workshop_SICSS_2026.Rproj no RStudio e rode de novo.\n",
    "Solucao 2: setwd('caminho/ate/Workshop_SICSS_2026') e rode de novo.\n\n",
    "A raiz do projeto e a pasta que contem, lado a lado:\n",
    "  .workshop-root, scripts/, figuras/ e figuras/dados/",
    call. = FALSE
  )
}

RAIZ <- localizar_raiz()
message("Raiz do projeto: ", RAIZ)

# p_data() (e não p_dados(), usado em 05_figuras.R para figuras/dados/) aponta
# para a pasta data/ na raiz, onde vive o resultado pré-computado citado nos
# slides da aula da tarde.
p_data <- function(...) file.path(RAIZ, "data", ...)

# =============================================================================
# 1. PACOTES
# =============================================================================
pacotes <- c("tibble", "dplyr")
faltam  <- pacotes[!vapply(pacotes, requireNamespace, logical(1),
                           quietly = TRUE)]
if (length(faltam) > 0) {
  stop("Instale antes: install.packages(c('",
       paste(faltam, collapse = "', '"), "'))", call. = FALSE)
}

library(dplyr)

# =============================================================================
# 2. REPRODUTIBILIDADE E PARÂMETROS GLOBAIS
# =============================================================================
set.seed(1234)

MODELO <- "claude-sonnet-4-20250514"

# Contagens e metas de agregação exatamente como aparecem no slide
# "Classificação com LLM, e o que ela devolve" (aula02_tarde.tex).
metas <- tribble(
  ~categoria,       ~n,  ~conf_media, ~k_unanime,
  "punitivista",    118, 0.91,        0.86,
  "preventivo",      84, 0.83,        0.71,
  "garantista",      27, 0.68,        0.48,
  "nao_aplicavel",   71, 0.95,        0.94
)

# =============================================================================
# 3. CODEBOOK E CLASSIFICAÇÃO
# =============================================================================

# (A) Com o pipeline real, quando houver corpus e chave de API:
# codebook  <- ac_qual_codebook(
#   categorias = c("punitivista", "preventivo", "garantista", "nao_aplicavel"),
#   descricoes = list(...)
# )
# chat_obj  <- ellmer::chat_anthropic(model = MODELO)
# resultado <- ac_qual_code(corpus        = corpus_limpo,
#                           codebook      = codebook,
#                           chat          = chat_obj,
#                           k_consistency = 3L,
#                           confidence    = "total")

# (B) Versão ilustrativa: um resultado por documento (300 no total) cuja
# agregação por categoria bate exatamente com as metas acima. `confianca` é
# a confiança total por documento (0 a 1); `k_unanime` indica se as 3
# passagens do modelo concordaram (k_consistency = 3L).
simular_categoria <- function(categoria, n, conf_media, k_unanime, dp = 0.05) {

  # Confiança por documento: gera n-1 valores em torno da meta e resolve o
  # último analiticamente, para que a média da categoria bata exatamente com
  # conf_media (evita ficar reamostrando até acertar por sorte).
  base <- rnorm(n - 1, mean = conf_media, sd = dp)
  base <- pmin(pmax(base, 0.05), 0.99)
  ultimo <- n * conf_media - sum(base)
  ultimo <- pmin(pmax(ultimo, 0.05), 0.99)
  confianca <- c(base, ultimo)
  # pequeno ajuste final para eliminar o resíduo do clipping
  confianca <- confianca + (conf_media - mean(confianca))
  confianca <- round(pmin(pmax(confianca, 0.05), 0.99), 2)

  # Unanimidade por documento: número exato de "sim" tal que a proporção
  # arredondada a duas casas bate com k_unanime.
  n_unanime <- round(n * k_unanime)
  unanime   <- sample(c(rep(TRUE, n_unanime), rep(FALSE, n - n_unanime)))

  tibble(categoria = categoria, confianca = confianca, k_unanime = unanime)
}

resultado <- metas |>
  rowwise() |>
  reframe(simular_categoria(categoria, n, conf_media, k_unanime)) |>
  mutate(doc_id = row_number(), modelo = MODELO) |>
  select(doc_id, categoria, confianca, k_unanime, modelo)

# =============================================================================
# 4. CONFERÊNCIA (a agregação deve bater com o slide)
# =============================================================================
conferencia <- resultado |>
  group_by(categoria) |>
  summarise(
    n          = n(),
    conf_media = round(mean(confianca), 2),
    k_unanime  = round(mean(k_unanime), 2),
    .groups    = "drop"
  )

print(conferencia)

if (!isTRUE(all.equal(
  conferencia |> arrange(categoria) |> select(-categoria) |> as.data.frame(),
  metas |> arrange(categoria) |> select(n, conf_media, k_unanime) |> as.data.frame()
))) {
  stop("A agregacao nao bateu com as metas do slide. Confira sementes e n.",
       call. = FALSE)
}

# =============================================================================
# 5. SALVAR
# =============================================================================
dir.create(p_data(), showWarnings = FALSE, recursive = TRUE)
saveRDS(resultado, p_data("resultado_llm_precomputado.rds"))
message("Salvo: ", p_data("resultado_llm_precomputado.rds"))
message(
  "ATENCAO: placeholder ilustrativo, nao e uma classificacao real por LLM. ",
  "Ver comentario no topo deste script."
)
