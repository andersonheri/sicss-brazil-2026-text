# =============================================================================
# SICSS-Brazil 2026 | Workshop de Análise Automatizada de Texto
# Script 05: geração das figuras usadas nos slides
#
# Autor: Anderson Henrique (CEM/USP)
#
# COMO RODAR
# ----------
# Qualquer uma destas três formas funciona, de qualquer diretório:
#   (1) Abra Workshop_SICSS_2026.Rproj e rode: source("scripts/05_figuras.R")
#   (2) No terminal:  Rscript scripts/05_figuras.R
#   (3) No RStudio, abra este arquivo e clique em Source.
# O script localiza sozinho a raiz do projeto. Não é preciso setwd().
#
# SOBRE OS DADOS
# --------------
# As figuras 1 a 4 usam os CSVs em figuras/dados/, que são ILUSTRATIVOS:
# reproduzem a forma e a ordem de grandeza de saídas reais do pipeline
# (acR + quanteda), mas não correspondem a uma análise empírica publicada.
# Cada uma tem dois blocos: (A) o código do pipeline real, comentado, e
# (B) a leitura do CSV ilustrativo. Troque (B) por (A) quando tiver o corpus.
# A camada ggplot2 não muda.
#
# As figuras 5 a 8 (nuvem de palavras, nuvem comparativa, cluster e curva de
# seleção de k) rodam de verdade sobre data/corpus_atividade.csv, o mesmo
# corpus fictício (16 falas de um plenário municipal fictício) usado pelos
# scripts numerados 01 a 06. Também são ilustrativas (o corpus é fictício),
# mas aqui as funções do acR são chamadas de verdade, não simuladas.
#
# Saídas: figuras/fig_top_terms.png, fig_keyness.png, fig_lda.png,
#         fig_confusao.png, fig_wordcloud.png, fig_wordcloud_comparativo.png,
#         fig_cluster.png, fig_lda_tune.png, sessionInfo_figuras.txt
# =============================================================================

# =============================================================================
# 0. LOCALIZAR A RAIZ DO PROJETO
# -----------------------------------------------------------------------------
# Este bloco existe porque o erro mais comum ao rodar scripts em R é o diretório
# de trabalho estar em outro lugar. A função procura, em ordem: o pacote here,
# o caminho do próprio arquivo e o diretório atual. De cada candidato, sobe até
# quatro níveis procurando o arquivo-sentinela .workshop-root.
#
# O marcador é o arquivo .workshop-root, e não a pasta figuras/, porque pode
# haver cópias antigas do material em pastas vizinhas. O sentinela elimina a
# ambiguidade: só a raiz correta o contém.
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

# Atalhos de caminho. Use SEMPRE estes, nunca caminhos soltos.
p_dados   <- function(...) file.path(RAIZ, "figuras", "dados", ...)
p_figuras <- function(...) file.path(RAIZ, "figuras", ...)

# Conferência explícita dos insumos, antes de qualquer processamento
arquivos_esperados <- c("fig1_top_terms.csv", "fig2_keyness.csv",
                        "fig3_lda.csv", "fig4_confusao.csv")
faltando <- arquivos_esperados[!file.exists(p_dados(arquivos_esperados))]
if (length(faltando) > 0) {
  stop("Arquivos ausentes em figuras/dados/: ",
       paste(faltando, collapse = ", "), call. = FALSE)
}

# As figuras 5 a 8 (nuvem, cluster, seleção de k) precisam do corpus de
# texto de verdade, não só dos CSVs agregados acima.
if (!file.exists(file.path(RAIZ, "data", "corpus_atividade.csv"))) {
  stop("Arquivo ausente: data/corpus_atividade.csv (usado pelas figuras 5 a 8).",
       call. = FALSE)
}

# =============================================================================
# 1. PACOTES
# =============================================================================
pacotes <- c("readr", "dplyr", "forcats", "ggplot2", "tidytext", "acR",
             "ggwordcloud", "cluster")
faltam  <- pacotes[!vapply(pacotes, requireNamespace, logical(1),
                           quietly = TRUE)]
if (length(faltam) > 0) {
  stop("Instale antes: install.packages(c('",
       paste(faltam, collapse = "', '"), "'))", call. = FALSE)
}

library(readr)
library(dplyr)
library(forcats)
library(ggplot2)
library(acR)

# =============================================================================
# 2. REPRODUTIBILIDADE E PARÂMETROS GLOBAIS
# =============================================================================
set.seed(1234)

AZUL       <- "#1F4E79"   # azulUNI dos slides
AZUL_CLARO <- "#447296"   # azulUNIclaro
LARANJA    <- "#C85A1E"   # laranjaDestaque
CINZA      <- "#4D4D4D"

# Tema comum: fundo branco, grade discreta, sem bordas laterais,
# título alinhado à esquerda e em azul, como no restante do material.
tema_slides <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title          = element_text(colour = AZUL, face = "bold",
                                         size = base_size + 1, hjust = 0),
      plot.title.position = "plot",
      axis.title          = element_text(colour = CINZA),
      axis.text           = element_text(colour = CINZA),
      panel.grid.minor    = element_blank(),
      panel.grid.major    = element_line(colour = "#E4E4E4", linewidth = 0.3),
      plot.background     = element_rect(fill = "white", colour = NA),
      panel.background    = element_rect(fill = "white", colour = NA),
      strip.text          = element_text(colour = AZUL, face = "bold",
                                         hjust = 0)
    )
}

# Dimensões pensadas para meia coluna de um slide 16:9.
salvar <- function(plot, arquivo, largura = 6.4, altura = 3.4, dpi = 300) {
  destino <- p_figuras(arquivo)
  ggsave(destino, plot, width = largura, height = altura,
         dpi = dpi, units = "in", bg = "white")
  message("Salvo: ", destino)
}

# =============================================================================
# 3. FIGURA 1. Termos mais frequentes
# =============================================================================

# (A) Com o pipeline real:
# tokens   <- ac_tokenize(corpus_limpo)
# contagem <- ac_count(tokens)
# dados_f1 <- ac_top_terms(contagem, n = 15)

# (B) Versão ilustrativa:
dados_f1 <- read_csv(p_dados("fig1_top_terms.csv"), show_col_types = FALSE)

fig1 <- dados_f1 |>
  mutate(termo = fct_reorder(termo, n)) |>
  ggplot(aes(x = n, y = termo)) +
  geom_col(fill = AZUL, width = 0.72) +
  labs(
    title = "Termos mais frequentes no corpus (n = 300 pronunciamentos)",
    x     = "Frequência absoluta",
    y     = NULL
  ) +
  tema_slides() +
  theme(panel.grid.major.y = element_blank())

salvar(fig1, "fig_top_terms.png")

# =============================================================================
# 4. FIGURA 2. Keyness entre dois grupos
# -----------------------------------------------------------------------------
# Convenção do gráfico: valores positivos indicam sobre-representação no
# grupo-alvo (PT); negativos, no grupo de referência (PL). O sinal é apenas
# convenção de exibição; a estatística subjacente é o qui-quadrado.
# =============================================================================

# (A) Com o pipeline real:
# kn       <- ac_keyness(tokens, target = "PT", ref = "PL")
# dados_f2 <- tibble::as_tibble(kn)

# (B) Versão ilustrativa:
dados_f2 <- read_csv(p_dados("fig2_keyness.csv"), show_col_types = FALSE)

fig2 <- dados_f2 |>
  mutate(termo = fct_reorder(termo, keyness)) |>
  ggplot(aes(x = keyness, y = termo, fill = grupo)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = "#808080", linewidth = 0.35) +
  scale_fill_manual(values = c("PT" = AZUL, "PL" = LARANJA), guide = "none") +
  labs(
    title = "Termos distintivos: PT (azul) e PL (laranja)",
    x     = "Keyness (qui-quadrado assinalado)",
    y     = NULL
  ) +
  tema_slides() +
  theme(panel.grid.major.y = element_blank())

salvar(fig2, "fig_keyness.png")

# =============================================================================
# 5. FIGURA 3. Tópicos do LDA
# -----------------------------------------------------------------------------
# beta é a probabilidade do termo dentro do tópico. Note que o tópico 4 captura
# vocabulário procedimental, e não substantivo. Isso precisa ser reportado, e
# não escondido.
# =============================================================================

# (A) Com o pipeline real:
# lda      <- ac_lda(tokens, k = 4, seed = 1234)
# dados_f3 <- tidytext::tidy(lda, matrix = "beta") |>
#   group_by(topic) |> slice_max(beta, n = 5) |> ungroup() |>
#   rename(topico = topic, termo = term)

# (B) Versão ilustrativa:
dados_f3 <- read_csv(p_dados("fig3_lda.csv"), show_col_types = FALSE)

fig3 <- dados_f3 |>
  # reorder_within evita que a ordenação de um painel contamine os demais
  mutate(termo = tidytext::reorder_within(termo, beta, topico)) |>
  ggplot(aes(x = beta, y = termo)) +
  geom_col(fill = AZUL_CLARO, width = 0.70) +
  tidytext::scale_y_reordered() +
  facet_wrap(~ topico, scales = "free_y", ncol = 2) +
  labs(
    title = NULL,
    x     = "beta (probabilidade do termo no tópico)",
    y     = NULL
  ) +
  tema_slides(base_size = 9) +
  theme(panel.grid.major.y = element_blank())

salvar(fig3, "fig_lda.png", largura = 6.6, altura = 3.8)

# =============================================================================
# 6. FIGURA 4. Matriz de confusão (humano contra LLM)
# -----------------------------------------------------------------------------
# A diagonal são os acertos. Fora da diagonal está o diagnóstico: quais
# categorias o modelo confunde e, portanto, qual definição do codebook precisa
# ser reescrita.
# =============================================================================

# (A) Com o pipeline real:
# conf <- table(
#   llm    = resultado$categoria[match(humano$doc_id, resultado$doc_id)],
#   humano = humano$categoria
# )
# dados_f4 <- tibble::as_tibble(conf)

# (B) Versão ilustrativa:
dados_f4 <- read_csv(p_dados("fig4_confusao.csv"), show_col_types = FALSE)

niveis  <- c("punitivista", "preventivo", "garantista", "nao_aplicavel")
rotulos <- c("punitivista", "preventivo", "garantista", "não aplic.")

fig4 <- dados_f4 |>
  mutate(
    llm    = factor(llm,    levels = rev(niveis), labels = rev(rotulos)),
    humano = factor(humano, levels = niveis,      labels = rotulos)
  ) |>
  ggplot(aes(x = humano, y = llm, fill = n)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  geom_text(aes(label = n, colour = n > 30), size = 3.2, show.legend = FALSE) +
  scale_fill_gradient(low = "#EAF0F6", high = AZUL, guide = "none") +
  scale_colour_manual(values = c("TRUE" = "white", "FALSE" = CINZA)) +
  labs(
    title = "Matriz de confusão (n = 150)",
    x     = "Codificação humana (gold standard)",
    y     = "Classificação do LLM"
  ) +
  coord_fixed() +
  tema_slides(base_size = 9) +
  theme(
    panel.grid  = element_blank(),
    axis.text.x = element_text(angle = 25, hjust = 1)
  )

salvar(fig4, "fig_confusao.png", largura = 4.6, altura = 3.6)

# =============================================================================
# 7. CORPUS PARA AS FIGURAS 5 A 8 (nuvem, cluster, seleção de k)
# -----------------------------------------------------------------------------
# Diferente das figuras 1 a 4 (que só leem CSVs de estatísticas já
# agregadas), nuvem de palavras e clustering precisam do TEXTO de verdade
# por documento. Reaproveitamos o mesmo corpus ilustrativo usado pelos
# scripts numerados (data/corpus_atividade.csv: 16 falas fictícias de um
# plenário municipal fictício), em vez de inventar um quinto conjunto de
# dados de exemplo.
# =============================================================================

p_data_raiz <- function(...) file.path(RAIZ, "data", ...)

bruto_corpus  <- read_csv(p_data_raiz("corpus_atividade.csv"), show_col_types = FALSE)
corpus_ilust  <- ac_corpus(bruto_corpus, text = texto, docid = doc_id, meta = grupo)
corpus_limpo_ilust <- ac_clean(
  corpus_ilust,
  remove_stopwords = "pt-br-extended",
  extra_stopwords   = c("bairro", "municipio"),
  normalize_pt      = TRUE,
  min_char          = 3L
)

# =============================================================================
# 8. FIGURA 5. Nuvem de palavras
# -----------------------------------------------------------------------------
# ac_wordcloud() parte de uma tabela de frequência (ac_count()) e desenha
# cada termo com tamanho proporcional a `n`. É a versão "de impacto visual"
# da Figura 1 (frequência), útil para abertura de slide ou pôster; para
# leitura analítica precisa, a tabela/barra da Figura 1 continua sendo mais
# honesta (tamanho de fonte não é uma escala perceptualmente linear).
# =============================================================================

contagem_ilust <- ac_count(corpus_limpo_ilust)

fig5 <- ac_wordcloud(contagem_ilust, max_words = 40) +
  tema_slides()

salvar(fig5, "fig_wordcloud.png", largura = 5.4, altura = 3.6)

# =============================================================================
# 9. FIGURA 6. Nuvem de palavras comparativa
# -----------------------------------------------------------------------------
# ac_plot_wordcloud_comparative() usa TF-IDF (tratando cada grupo como um
# "documento") para destacar o vocabulário DISTINTIVO de cada grupo, e
# desenha uma nuvem por grupo lado a lado. É a versão visual da Figura 2
# (keyness): mesma pergunta ("o que é característico de cada lado"),
# leitura mais rápida à custa de precisão estatística (aqui não há teste
# de significância nem intervalo, só o ranking de TF-IDF).
# =============================================================================

fig6 <- ac_plot_wordcloud_comparative(
  corpus_limpo_ilust,
  group     = grupo,
  max_words = 25,
  seed      = 1234
) +
  tema_slides()

salvar(fig6, "fig_wordcloud_comparativo.png", largura = 6.6, altura = 3.6)

# =============================================================================
# 10. FIGURA 7. Clustering de documentos
# -----------------------------------------------------------------------------
# ac_cluster_documents() dá UMA etiqueta por documento (hard clustering),
# diferente do LDA (Figura 3), que dá uma MISTURA de tópicos por
# documento (soft clustering). Serve quando a pergunta é "quantos tipos de
# documento existem, e quais são" — não "quais temas se misturam em cada
# documento". method = "hclust" (padrão) permite o dendrograma abaixo, que
# mostra a própria estrutura de fusão dos grupos, não só o resultado
# final.
# =============================================================================

cluster_ilust <- ac_cluster_documents(corpus_limpo_ilust, k = 2, min_docs = 1L)

fig7 <- ac_plot_cluster(cluster_ilust, kind = "dendrogram") +
  tema_slides(base_size = 9)

salvar(fig7, "fig_cluster.png", largura = 5.4, altura = 3.6)

# =============================================================================
# 11. FIGURA 8. Curva de seleção de k (LDA)
# -----------------------------------------------------------------------------
# ac_lda_tune() ajusta o LDA da Figura 3 para vários valores de k e calcula
# a perplexidade de cada um (quanto menor, melhor o modelo prevê palavras
# que não viu). ac_plot_lda_tune() desenha a curva; o "cotovelo" (ponto
# onde ganhos adicionais de k passam a ser pequenos) é a pista quantitativa
# para escolher k, complementando a leitura qualitativa dos tópicos (ver
# "A armadilha do k" nos slides).
# =============================================================================

tune_ilust <- ac_lda_tune(corpus_limpo_ilust, k_range = 2:6, seed = 1234)

fig8 <- ac_plot_lda_tune(tune_ilust) +
  tema_slides()

salvar(fig8, "fig_lda_tune.png", largura = 5.4, altura = 3.4)

# =============================================================================
# 12. REGISTRO DO AMBIENTE
# -----------------------------------------------------------------------------
# Sem isto, o script é compartilhável, mas não replicável.
# =============================================================================
writeLines(capture.output(sessionInfo()), p_figuras("sessionInfo_figuras.txt"))
message("Concluido: 8 figuras geradas em ", p_figuras())
