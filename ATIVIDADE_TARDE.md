# Atividade da tarde: SICSS-Brazil 2026

Workshop de Análise Automatizada de Texto, 29 de julho de 2026. Esta é a
tarefa da oficina das 13h55 às 14h30, para você fazer sozinho, no seu
próprio projeto de pesquisa.

## Objetivo

Sair da oficina com o esqueleto validável de uma medida de texto para a sua
própria pesquisa, já submetido a um teste de confiabilidade. Não é sobre
escrever um codebook perfeito. É sobre descobrir onde ele quebra antes de
gastar dinheiro, tempo e reputação num projeto maior.

## Antes de começar

- Rode `scripts/00_setup.R` (uma vez, de preferência antes do workshop).
- Tenha em mente um projeto de pesquisa seu, mesmo que ainda em rascunho: uma
  pergunta que dependa de classificar textos em categorias (posição
  política, tom, enquadramento, tipo de argumento e outras).
- Se você ainda não tem um corpus próprio pronto, use
  `data/corpus_atividade.csv` (um corpus fictício incluso, só para o
  exercício funcionar) e adapte para o seu tema depois.

## Passo a passo (35 minutos)

| Tempo | Etapa | Produto |
|---|---|---|
| 5 min | Defina a pergunta e a unidade de registro do seu projeto | Pergunta e unidade de registro definidas |
| 15 min | Escreva o codebook, de 2 a 4 categorias | Definição, critério de inclusão, critério de exclusão e 2 exemplos-limite por categoria |
| 10 min | Dupla-codificação interna: aplique o codebook duas vezes | 5 documentos do seu corpus, codificados em duas rodadas cegas entre si |
| 5 min | Calcule a concordância e diagnostique | A categoria com maior desacordo, e a reescrita proposta |

### O que um codebook operacional precisa ter

1. Nome curto e estável, que vira nome de variável.
2. Definição em uma ou duas frases, sem circularidade.
3. Critério de inclusão: o que basta para atribuir a categoria.
4. Critério de exclusão: o que parece a categoria, mas não é.
5. Dois exemplos-limite do próprio corpus.
6. Categoria residual explícita, para o que não se encaixa em nenhuma outra.

### Como conduzir a dupla-codificação interna

1. Escolha 5 documentos do seu corpus, de preferência casos que pareçam
   difíceis.
2. Codifique-os com o codebook (rodada 1) e anote as respostas sem
   revisá-las depois.
3. Depois de alguns minutos, sem consultar a rodada 1, codifique os mesmos 5
   documentos de novo (rodada 2).
4. Só então compare rodada 1 com rodada 2.

Concordância bruta = acordos entre as duas rodadas dividido por 5. Com 5
documentos, nenhuma métrica corrigida pelo acaso é confiável (nem kappa, nem
alpha). O objetivo aqui não é o número, é localizar o desacordo.

**A pergunta que interessa:** para cada discordância, você leu o documento
de forma diferente na segunda rodada, ou aplicou uma regra diferente? O
primeiro caso é problema de unidade de registro ou ambiguidade do texto. O
segundo é problema de definição.

## Materiais

- `scripts/06_atividade.R`: script-modelo do `acR` com a sintaxe real
  (conferida contra o pacote instalado, não escrita de memória) para
  corpus, limpeza, descritiva e keyness. Adapte à sua pesquisa.
- `data/corpus_atividade.csv`: corpus de exemplo (16 falas fictícias de um
  plenário municipal fictício), caso você ainda não tenha corpus próprio
  pronto para hoje.
- Quem preferir papel, use papel: o produto é o raciocínio, não o arquivo.

## Apresentação (3 minutos, roteiro fixo e cronometrado)

1. A pergunta de pesquisa e a unidade de registro escolhida. (30 s)
2. Uma categoria do codebook, lida em voz alta. (30 s)
3. A categoria com maior desacordo entre as duas rodadas, e o diagnóstico:
   circular, não exaustiva, não exclusiva, abstrata demais ou rara demais?
   (60 s)
4. A reescrita proposta para essa definição. (30 s)
5. Qual método você usaria, entre dicionário, supervisionado e LLM, e por
   quê. (30 s)

Quem apresenta recebe uma pergunta de outro participante, escolhido pelo
facilitador. Pergunta, não sugestão. A melhor costuma ser: "que documento
faria essa categoria falhar?"

## Critério de sucesso

Não é ter um codebook perfeito. É ter descoberto onde ele quebra antes de
gastar dinheiro, tempo e reputação. Quem apresenta um desacordo bem
diagnosticado aprendeu mais do que quem apresenta concordância perfeita em
cinco documentos fáceis. Se o seu codebook sobreviveu intacto ao teste,
desconfie: ou as categorias são triviais, ou os cinco documentos eram
fáceis demais.
