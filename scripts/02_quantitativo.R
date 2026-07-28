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
# -----------------------------------------------------------------------------
# ac_corpus() é a porta de entrada do acR: recebe um data.frame comum (aqui,
# lido de um CSV) e devolve um objeto estruturado que todas as outras funções
# do pacote sabem ler. `text` diz qual coluna tem o texto de cada documento;
# `docid`, qual coluna identifica cada documento de forma única; `meta`
# preserva a coluna `grupo` como metadado, para podermos comparar os dois
# lados do debate mais adiante (Seção 4).
# =============================================================================

bruto  <- read.csv(p_data("corpus_atividade.csv"), stringsAsFactors = FALSE)
corpus <- ac_corpus(bruto, text = texto, docid = doc_id, meta = grupo)

# =============================================================================
# 2. LIMPEZA
# -----------------------------------------------------------------------------
# ac_clean() normaliza o texto antes de contar palavras. Sem isso, "Reforma"
# e "reforma," seriam tratadas como dois termos diferentes só por causa de
# maiúscula e pontuação, inflando artificialmente o vocabulário.
#
# Os parâmetros abaixo, em ordem de aplicação:
#   - remove_stopwords = "pt-br-extended": remove um preset de palavras
#     funcionais do português (artigos, preposições, conjunções etc.), que
#     não carregam sentido sozinhas e só disputariam espaço nas contagens com
#     os termos que de fato interessam.
#   - normalize_pt = TRUE: aplica normalizações do português coloquial (ex.:
#     "pra" vira "para"), úteis quando o corpus tem fala transcrita, como é o
#     caso de pronunciamentos e discursos.
#   - min_char = 3L: descarta tokens de 1-2 letras que sobraram da limpeza
#     (resíduos de pontuação, siglas partidas etc.), que quase nunca carregam
#     sentido analítico sozinhos.
#   - verbose = TRUE: imprime quantos tokens foram removidos em cada etapa.
#     Use esse número para checar se a limpeza não foi longe demais: se você
#     perdeu mais de 60% dos tokens, ou tem muitos documentos vazios ao
#     final, releia alguns documentos limpos antes de seguir.
# =============================================================================

corpus_limpo <- ac_clean(
  corpus,
  remove_stopwords = "pt-br-extended",
  normalize_pt      = TRUE,
  min_char          = 3L,
  verbose           = TRUE
)

# =============================================================================
# 3. DESCRITIVA: frequência e tf-idf
# -----------------------------------------------------------------------------
# ac_count(corpus, by = "grupo") conta quantas vezes cada palavra aparece,
# agregando por grupo em vez de por documento (por isso "by"): o resultado
# tem uma linha por combinação palavra-grupo, não por documento.
#
# ac_top_terms() simplesmente corta essa tabela nas `n` palavras mais
# frequentes de cada grupo. É o retrato mais simples do corpus: mostra do que
# se fala, mas ainda não diz o que é DISTINTIVO de cada lado (para isso,
# veja a Seção 4).
#
# ac_tf_idf() pondera cada palavra pela sua frequência inversa entre grupos:
# uma palavra que aparece em todos os grupos por igual (ex.: "praça") ganha
# peso baixo, mesmo sendo frequente; uma palavra concentrada em um só grupo
# ganha peso alto. É outra forma de destacar o vocabulário característico,
# sem precisar de um teste estatístico como o da Seção 4.
# =============================================================================

contagem_grupo <- ac_count(corpus_limpo, by = "grupo")

top_termos <- ac_top_terms(contagem_grupo, n = 10, by = "grupo")
print(top_termos)

tfidf <- ac_tf_idf(contagem_grupo, by = "grupo")

# =============================================================================
# 4. KEYNESS: o que distingue os dois grupos, com teste estatístico
# -----------------------------------------------------------------------------
# ac_keyness() compara a frequência observada de cada termo em um grupo-alvo
# (`target`) com a frequência esperada se os dois grupos usassem o
# vocabulário do mesmo jeito. `group` é o nome da coluna que separa os dois
# lados (aqui, "situacao" vs. "oposicao"); `target` é qual dos dois valores
# vira o "alvo" da comparação — o outro é automaticamente o grupo de
# referência. Valores positivos de `keyness` indicam termos mais típicos do
# alvo; negativos, mais típicos da referência. Ao contrário do tf-idf, aqui
# há um valor-p por trás: dá para dizer se a diferença de frequência é maior
# do que se esperaria por acaso.
# =============================================================================

kn <- ac_keyness(contagem_grupo, group = "grupo", target = "situacao")
print(kn)

# =============================================================================
# 5. TÓPICOS (LDA)
# -----------------------------------------------------------------------------
# ac_lda() ajusta um modelo de tópicos: em vez de comparar dois grupos que
# você já definiu (como na Seção 4), ele tenta DESCOBRIR agrupamentos de
# palavras que tendem a aparecer juntas, sem usar a coluna "grupo" em nenhum
# momento. `k` é quantos tópicos pedir ao modelo (uma escolha do
# pesquisador, não algo que o algoritmo determina sozinho — ver "a armadilha
# do k" no slide da manhã); `seed` fixa a aleatoriedade do ajuste, para que
# rodar de novo dê o mesmo resultado.
#
# Com um corpus de 16 documentos (k = 2 aqui, o mínimo que faz sentido
# testar), o resultado é ilustrativo e instável por natureza: serve para
# mostrar a mecânica da função, não para tirar conclusão substantiva. Com o
# seu próprio corpus, espere precisar de bem mais que 16 documentos antes de
# os tópicos começarem a fazer sentido de forma estável.
# =============================================================================

lda <- ac_lda(corpus_limpo, k = 2, seed = 1234)
print(lda)

# =============================================================================
# 6. EXPORTAR TABELAS
# -----------------------------------------------------------------------------
# ac_export() salva um data.frame/tibble em disco no formato que a extensão
# do arquivo indicar (aqui, ".csv"). É o mesmo padrão usado para levar
# resultados do R para um artigo ou planilha de revisão.
# =============================================================================

dir.create(p_outputs(), showWarnings = FALSE, recursive = TRUE)
ac_export(top_termos, p_outputs("top_termos.csv"))
ac_export(kn, p_outputs("keyness.csv"))

message("Concluido. Tabelas salvas em ", p_outputs())
