# Estrutura de Arquivos — MiniJava Semântico

Este documento descreve, em detalhes, o papel de cada arquivo do projeto de
análise semântica de MiniJava. O projeto implementa um analisador léxico
(JFlex), sintático (BYACC/J) e semântico (ações embutidas na gramática) que
verifica regras de tipos e escopos de um subconjunto de Java.

## Visão geral do fluxo

```
 .mjava  ──►  lexico.flex (JFlex)  ──►  Yylex.java  ──┐
                                                     ├──►  Parser.class  ──►  Tabela de Símbolos + Erros
            miniJava.y (BYACC/J)  ──►  Parser.java  ──┘
```

Os arquivos `Yylex.java` e `Parser.java` são **gerados** pelo build e não
ficam versionados — são produzidos a partir de `lexico.flex` e `miniJava.y`.

---

## Código-fonte Java (estruturas semânticas)

### `ClasseID.java`
Enumeração que classifica cada entrada da tabela de símbolos quanto à sua
categoria:
- `TipoBase` — tipos primitivos (`int`, `boolean`, `int[]`, `erro`).
- `VarGlobal`, `VarLocal`, `NomeParam` — variáveis em diferentes escopos.
- `NomeFuncao` — métodos.
- `NomeStruct` — tipos-classe (instâncias de uma classe declarada).
- `CampoStruct` — atributos de uma classe.

### `TS_entry.java`
Representa **um tipo** da linguagem. Há dois construtores: um para tipos
base (singletons criados no Parser) e outro para tipo-classe, que guarda
referência ao `DescClasse` correspondente (usado no despacho de métodos
`obj.metodo(...)`). O `toString()` devolve o identificador do tipo,
permitindo concatenação direta em mensagens de erro.

### `DescMetodo.java`
Descritor de um método. Guarda:
- nome e tipo de retorno (`TS_entry`);
- `parametros` em `LinkedHashMap` (preserva a ordem de declaração — essencial
  para checar chamadas posicionalmente);
- `locais` (variáveis locais declaradas no corpo).

Oferece `resolve(nome)` que aplica a regra de escopo interna do método
(local → parâmetro → `null`), `tiposParametros()` para verificação de
chamadas e `assinatura()` para listagem final.

### `DescClasse.java`
Descritor de uma classe. Mantém os `atributos` (campos) e `metodos`
(`LinkedHashMap` para preservar ordem), além de um `TS_entry` próprio
representando o **tipo-classe** dessa classe (usado quando se declara
`C obj;`). É o segundo nível do escopo aninhado.

### `TabSimb.java`
Tabela de símbolos **global**: dicionário de classes declaradas. Junto
com `DescClasse` e `DescMetodo` forma a hierarquia:

```
TabSimb  →  DescClasse  →  DescMetodo
(global)   (atributos    (parâmetros
            + métodos)     + locais)
```

A regra de resolução no corpo de um método é:
`local → parâmetro → atributo da classe corrente → ERRO`.

O método `listar()` imprime a tabela formatada ao final da análise.

### `ParserVal.java`
Classe gerada pelo **BYACC/J** que cumpre o papel da `union` do yacc em C.
Cada token/não-terminal carrega um `ParserVal` com campos `ival` (linha
do identificador, p.ex.), `sval` (lexema) e `obj` (usado para passar
`TS_entry` entre regras). Não deve ser editada manualmente.

---

## Especificações do compilador

### `lexico.flex`
Especificação do **analisador léxico** para JFlex. Define:
- palavras-chave (`class`, `public`, `if`, `while`, `new`, `this`, etc.);
- tratamento especial para `class App` e `System.out.println`;
- token `Identifier` que, além do lexema, guarda em `ival` a **linha**
  (1-based) do identificador — essa linha é usada nas mensagens de erro
  semântico;
- token `Number`, operadores compostos (`&&`, `==`, `!=`) e simples
  (devolvidos como o próprio caractere);
- diretivas `$TRACE_ON` / `$TRACE_OFF` que ligam/desligam o debug do parser;
- regra de erro léxico para caracteres inesperados.

### `miniJava.y`
Coração do projeto: gramática **BYACC/J** com as ações semânticas
embutidas. Contém:
- declarações de tokens e precedência de operadores;
- regras gramaticais para `Program`, `ClassDeclaration`, `MethodDeclaration`,
  `VarDeclaration`, `DeclOrStatList`, `Statement`, `Exp`, etc.;
- ações que chamam rotinas como `abreClasse`, `abreMetodo`,
  `declaraAtributo`, `declaraLocal`, `atribuiVar`, `exigeBool`,
  `verificaRetorno`, `tipoClasse`, `fechaEscopoMetodo`,
  `fechaEscopoClasse` — responsáveis por construir a tabela de símbolos
  e emitir erros semânticos com número de linha.

### `Makefile`
Automação do build:
- `make` / `make all` — gera `Yylex.java` (via `jflex`), `Parser.java`
  (via `byaccj -tv -J`) e compila tudo com `javac`;
- `make run` — executa `java Parser`;
- `make build` — `clean` + recompila tudo;
- `make clean` — remove artefatos gerados (`*.class`, `Yylex.java`,
  `Parser.java`, `y.output`).

---

## Scripts utilitários

### `testar.sh`
Roda a análise semântica sobre **todos** os `.mjava` da pasta de uma só
vez. Recompila automaticamente se `Parser.class` não existir. Aceita um
prefixo opcional, ex.: `./testar.sh erro` roda só os casos de erro.

### `limpar.sh`
Apaga os artefatos gerados pelo build (`Parser.java`, `Yylex.java`,
`*.class`, `y.output`, backups `*~`), preservando apenas os fontes do
trabalho. Útil antes de empacotar a entrega.

---

## Arquivos de teste (`.mjava`)

### `p1.mjava` e `correto2.mjava`
Programas **válidos** que devem passar pela análise semântica sem
nenhum erro. Servem como linha-base: a tabela de símbolos é montada e
listada ao final.

### `heranca_ok.mjava` e `polimorfismo_ok.mjava`
Programas **válidos** que exercitam o foco do trabalho: herança com
`extends`, sobrescrita de método com mesma assinatura, acesso a atributo
herdado e atribuição/passagem de argumento com subtipagem (`A x = new B();`).

### Casos de erro (cada um isola **uma** regra semântica)

- **`erro1_naodeclarada.mjava`** — uso de variável que não existe em
  nenhum escopo (local, parâmetro ou atributo).
- **`erro2_duplicado.mjava`** — declaração duplicada de identificador no
  mesmo escopo (atributo, parâmetro ou local repetidos).
- **`erro3_metodo_inexistente.mjava`** — chamada `obj.m(...)` em que `m`
  não pertence à classe do receptor.
- **`erro4_argumentos.mjava`** — número de argumentos passados ≠ número
  de parâmetros declarados.
- **`erro5_tipos.mjava`** — incompatibilidade de tipos em expressão ou
  atribuição (ex.: somar `int` com `boolean`).
- **`erro6_tipo_nao_declarado.mjava`** — uso de um nome de classe que
  nunca foi declarada como tipo de variável.
- **`erro7_arg_tipo.mjava`** — chamada de método com **quantidade
  correta** de argumentos, mas com **tipo incompatível** em alguma
  posição.
- **`erro8_super_nao_decl.mjava`** — `extends` referenciando uma classe
  que nunca foi declarada.
- **`erro9_override_assinatura.mjava`** — método de subclasse com mesmo
  nome de um método herdado, mas com assinatura incompatível (override
  inválido).

Todos esses casos imprimem mensagens com o número da linha do
identificador problemático, graças ao `ival` carregado pelo lexer.

---

## Documentação

### `README.md`
Documento principal do projeto: descrição, como compilar, como executar,
exemplos de uso e referências.

### `MODIFICACOES.md`
Histórico das alterações feitas em relação à versão original do trabalho
(o que foi acrescentado, por que, e onde no código está).

### `ARQUIVOS.md`
Este arquivo — descreve em detalhes o papel de cada arquivo do projeto.
