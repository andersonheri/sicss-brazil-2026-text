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
# fonte, autor...). Pode vir de um CSV (como aqui), de uma planilha, ou de
# qualquer fonte que você consiga transformar num data.frame no R.
#
# ac_corpus() é a porta de entrada do acR: transforma esse data.frame comum
# num objeto que todas as demais funções do pacote sabem processar.
#   - text: qual coluna tem o texto de cada documento.
#   - docid: qual coluna identifica cada documento de forma única (se você
#     não tiver uma, ac_corpus() gera IDs sequenciais sozinho).
#   - meta: quais colunas extras preservar como metadado, para comparar
#     grupos mais adiante (Seção 3). Se você não tem uma coluna de grupo,
#     pode simplesmente omitir este argumento.
# ac_corpus() também detecta colunas chamadas text/texto/doc/content/
# conteudo automaticamente, mas é mais seguro nomear explicitamente, como
# fazemos aqui.
# =============================================================================

bruto <- read.csv(p_data("corpus_atividade.csv"), stringsAsFactors = FALSE)

corpus <- ac_corpus(bruto, text = texto, docid = doc_id, meta = grupo)
corpus

# =============================================================================
# 2. LIMPEZA
# -----------------------------------------------------------------------------
# ac_clean() normaliza o texto antes de contar palavras: sem isso,
# maiúsculas, pontuação e variações informais de escrita fariam a mesma
# palavra ser contada como se fossem termos diferentes.
#   - remove_stopwords: aceita um preset pronto ("pt", "pt-br-extended",
#     "pt-legislativo") ou um vetor de palavras seu. Os presets cobrem
#     artigos, preposições e conjunções; não cobrem jargão específico do seu
#     tema, por isso existe o próximo parâmetro.
#   - extra_stopwords: palavras ADICIONAIS ao preset, específicas do seu
#     corpus (aqui, "bairro" e "município" aparecem demais no corpus de
#     exemplo sem ajudar a distinguir nada). Troque pelas palavras que
#     dominam o SEU corpus sem carregar sentido analítico.
#   - protect: use para siglas ou termos que a limpeza destruiria de outra
#     forma (ex.: c("PT", "STF")); não usamos aqui porque o corpus de
#     exemplo não tem siglas, mas o seu pode ter.
#   - normalize_pt: normaliza português coloquial (ex.: "pra" -> "para"),
#     útil em fala transcrita.
#   - min_char: descarta tokens de 1-2 letras, quase sempre resíduo de
#     pontuação e não palavras de verdade.
#   - verbose: imprime quantos tokens foram removidos em cada etapa. Releia
#     alguns documentos limpos depois: se você não reconhece mais do que
#     eles tratam, a limpeza foi longe demais.
# =============================================================================

corpus_limpo <- ac_clean(
  corpus,
  remove_stopwords = "pt-br-extended",
  extra_stopwords   = c("bairro", "municipio"),
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

# Contagem simples: quantas vezes cada palavra aparece no corpus inteiro.
# ac_top_terms() corta para as `n` mais frequentes; ac_plot_top_terms() faz
# o gráfico de barras. É o retrato mais básico do corpus: mostra do que se
# fala, mas ainda não o que é diferente entre grupos.
contagem <- ac_count(corpus_limpo)
ac_top_terms(contagem, n = 15) |> ac_plot_top_terms()

# A mesma contagem, mas agregada por grupo em vez de por documento
# (by = "grupo"): o resultado tem uma linha por combinação palavra-grupo.
# Só funciona se o seu corpus tiver uma coluna de grupo de verdade.
contagem_grupo <- ac_count(corpus_limpo, by = "grupo")
ac_top_terms(contagem_grupo, n = 8, by = "grupo")

# TF-IDF: pondera cada palavra pela frequência inversa entre grupos. Uma
# palavra que aparece em todos os grupos por igual ganha peso baixo, mesmo
# sendo frequente; uma palavra concentrada num só grupo ganha peso alto.
# Destaca vocabulário DISTINTIVO, não apenas frequente.
tfidf <- ac_tf_idf(contagem_grupo, by = "grupo")
head(tfidf[order(-tfidf$tf_idf), ], 10)

# Keyness: mesma ideia do tf-idf (o que é distintivo de um grupo), mas com
# um teste estatístico por trás, entre EXATAMENTE dois grupos.
#   - group: nome da coluna que separa os dois lados.
#   - target: qual dos dois valores vira o "alvo" da comparação. O OUTRO
#     valor da coluna vira automaticamente o grupo de referência (não
#     existe argumento `ref` nesta função: só dá para comparar dois grupos
#     de cada vez, e o segundo é sempre "o resto").
# Valores positivos de `keyness` indicam termos mais típicos do alvo;
# negativos, mais típicos da referência.
kn <- ac_keyness(contagem_grupo, group = "grupo", target = "situacao")
ac_plot_keyness(kn)

# =============================================================================
# 4. TÓPICOS (LDA) — opcional, exige corpus razoavelmente grande
# -----------------------------------------------------------------------------
# ac_lda() ajusta um modelo de tópicos: em vez de comparar grupos que você
# já definiu (Seção 3), ele tenta DESCOBRIR agrupamentos de palavras que
# tendem a aparecer juntas, sem usar nenhuma coluna de grupo.
#   - k: quantos tópicos pedir. Escolha do pesquisador, não algo que o
#     algoritmo determina sozinho (ver "a armadilha do k" no slide da
#     manhã); teste mais de um valor e leia os termos de cada tópico antes
#     de se comprometer com um k final.
#   - seed: fixa a aleatoriedade do ajuste, para poder reproduzir o
#     resultado depois.
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
#
# ac_qual_codebook() estrutura as categorias que a LLM vai usar para
# classificar cada documento. Para cada categoria, escreva:
#   - definition: o que ELA é, numa frase sem circularidade (não escreva
#     "categoria X é o que é X"; escreva o critério observável).
#   - examples_pos: um ou dois exemplos REAIS do seu corpus que se encaixam.
#   - examples_neg: um ou dois exemplos que PARECEM se encaixar mas não se
#     encaixam, para desambiguar de categorias vizinhas. É a mesma lógica
#     de um codebook em papel, só que estruturada para a LLM ler.
#
# ac_qual_code() classifica cada documento do corpus de acordo com esse
# codebook, usando o modelo passado em `chat` (um objeto do pacote ellmer).
#   - k_consistency = 3L: classifica cada documento 3 vezes e usa a
#     categoria mais votada; a concordância entre as 3 rodadas vira o
#     confidence_score de cada documento (1,0 = as 3 concordaram). Rodar só
#     1 vez custa menos, mas não dá nenhum sinal de quão estável é a
#     resposta do modelo.
#   - confidence = "total": resume essa concordância numa única coluna
#     confidence_score por documento.
# O resultado é um tibble com doc_id, categoria (o rótulo escolhido),
# confidence_score e confidence_level ("alta"/"media"/"baixa").
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
# Também depende da Seção 5 já ter rodado (variável `resultado`). Este é o
# passo que a tese do workshop inteiro pede: nenhuma classificação
# automática vale sem checar uma amostra contra um humano.
#
# ac_qual_sample(strategy = "uncertainty") escolhe os documentos em que a
# LLM hesitou mais (confidence_score mais baixo) para você revisar à mão:
# é aí que os erros tendem a se concentrar, então é aí que a revisão rende
# mais por documento revisado.
#
# ac_qual_export_for_review() gera uma planilha para você (ou outra pessoa)
# codificar, SEM mostrar o rótulo que a LLM deu, para não influenciar o
# julgamento humano. Depois de codificada à mão,
# ac_qual_import_human() lê essa planilha de volta.
#
# ac_qual_irr() compara os dois conjuntos de rótulos (humano = "gold",
# LLM = "predicted") e devolve percent agreement, Cohen's kappa e
# Krippendorff's alpha. Se quiser também Gwet's AC1 e F1 macro (métricas que
# ac_qual_irr() NÃO calcula), use a função separada ac_qual_reliability(),
# como em scripts/04_validacao.R.
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
# -----------------------------------------------------------------------------
# ac_export() salva um data.frame/tibble no formato que a extensão do
# arquivo indicar: ".csv" para CSV, ".xlsx" para Excel, ".tex" para uma
# tabela LaTeX pronta para colar num artigo, ".rds" para preservar o objeto
# R exatamente como está. É o último passo antes de levar um resultado do
# R para fora dele.
# =============================================================================

# ac_export(kn, path = p_data("../outputs/keyness_meu_projeto.xlsx"))

message(
  "Script rodado ate a Secao 4 (descritiva e keyness) com o corpus de ",
  "exemplo. Troque a Secao 1 pelo seu proprio corpus para continuar dai."
)
