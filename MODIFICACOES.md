# O que foi modificado — do original para o analisador semântico

Este documento explica **tudo** o que mudou em relação aos arquivos originais, e **por quê**.

## De onde partimos

Havia duas bases:

1. **Pasta `miniJava 2` (especificação do professor)** — uma gramática que fazia
   **apenas a análise sintática**. Ela reconhecia a estrutura de MiniJava (classes,
   métodos, etc.) mas não fazia *nenhuma* verificação semântica: as ações da gramática
   eram só `System.out.println("ClassDecl -> ...")` para mostrar que reconheceu a regra.
   Foi a base da nossa **gramática** e do **léxico**.

2. **Pasta `analise-semantica` (trabalho anterior)** — analisava uma linguagem
   diferente (variáveis globais + `main`, com arrays). Dela reaproveitamos a **lógica
   de verificação de tipos** e o enum `ClasseID`.

O trabalho foi: pegar a gramática do professor (que só fazia sintaxe) e **adicionar a
análise semântica** — tabela de símbolos com escopos e validações de escopo e
polimorfismo.

---

## 1. `lexico.flex` (analisador léxico)

Base: `miniJava 2/lexico.flex`. Mudanças pequenas:

### 1.1 Rastreio de linha no identificador
**Antes:**
```
[a-zA-Z][a-zA-Z0-9_]* { yyparser.yylval = new ParserVal(yytext());
                        return Parser.Identifier;}
```
**Depois:**
```
[a-zA-Z][a-zA-Z0-9_]* { ParserVal v = new ParserVal(yytext());
                        v.ival = yyline + 1;          /* guarda a linha do identificador */
                        yyparser.yylval = v;
                        return Parser.Identifier; }
```
**Por quê:** para que as mensagens de erro mostrem a **linha exata** onde o
identificador aparece (ex.: "variavel 'x' nao declarada (linha 7)"). O `yyline` do
JFlex é 0-based, por isso o `+1`.

### 1.2 Método `getLine()`
Adicionamos no bloco de código do léxico:
```java
public int getLine() { return yyline; }
```
**Por quê:** o parser usa isso para saber a linha corrente durante a análise de
expressões (ver `linha` no `miniJava.y`).

### 1.3 Mensagem de erro léxico em português
Trocamos `"Error: unexpected character..."` por
`"Erro lexico: caractere inesperado '...' na linha N"`. Só padronização de idioma.

---

## 2. `miniJava.y` (gramática + análise semântica) — o coração da mudança

Base: `miniJava 2/miniJava.y`. Aqui está a maior parte do trabalho.

### 2.1 Removidas as ações de depuração
**Antes**, cada regra tinha um print de teste, por exemplo:
```
ClassDeclaration : CLASS Identifier '{' VarDeclarationList MethodDeclarationList '}'
                   { System.out.println("ClassDecl -> "+$2); }
```
**Depois**, essas ações viraram **ações semânticas reais** (abrir escopo, registrar na
tabela de símbolos, validar). **Por quê:** os prints só serviam para mostrar que o
parser reconheceu a regra; agora cada regra *faz alguma coisa útil* para a análise.

### 2.2 Removida a diretiva `%type <sval> Identifier`
**Por quê:** com `%type <sval>`, o valor `$n` de um `Identifier` viraria diretamente
uma `String`. Mas nós precisamos acessar **dois campos** do identificador: o nome
(`$n.sval`) **e** a linha (`$n.ival`). Por isso tratamos `$n` como um `ParserVal`
completo (acessando `.sval` e `.ival`), como já era feito na `analise-semantica`.

### 2.3 Adicionados operadores `==` e `!=` nas expressões
**Antes**, a gramática declarava os tokens `EQ NEQ` mas **não os usava** em nenhuma
regra de `Exp`. **Depois**, adicionamos:
```
| Exp EQ Exp    { $$ = pv(tipoIgualdade(...)); }
| Exp NEQ Exp   { $$ = pv(tipoIgualdade(...)); }
```
**Por quê:** o léxico já reconhecia `==` e `!=`, mas a gramática os ignorava — então
um programa usando `==` daria erro de sintaxe. Agora são tratados e checados.

### 2.4 Ações intermediárias para abrir/fechar escopos
Adicionamos ações **no meio** das regras de classe e método, por exemplo:
```
ClassDeclaration : CLASS Identifier { abreClasse($2.sval, $2.ival); } '{' ... '}'
                   { fechaEscopoClasse(); }
```
**Por quê:** o parser é *bottom-up* — a regra inteira só "reduz" no final. Mas
precisamos saber **qual classe está ativa** já no começo, antes de processar os
atributos e métodos dentro dela. A ação intermediária `{ abreClasse(...); }` roda
assim que o nome da classe é lido, definindo o "escopo corrente". O mesmo vale para
`abreMetodo(...)` (definir o método corrente antes de analisar parâmetros e corpo).

### 2.5 Ações nas expressões guardam o tipo resultante
Cada regra de `Exp` agora calcula e devolve um **tipo**:
```
| Exp '+' Exp   { $$ = pv(tipoAritmetico((TS_entry)$1.obj, (TS_entry)$3.obj)); }
```
**Por quê:** a análise de tipos é feita "de baixo para cima". Cada subexpressão
informa seu tipo para a expressão maior, que valida e calcula o seu próprio tipo. Ex.:
`x + 4` só é válido se `x` for `int`; o resultado é `int`.

### 2.6 Helper `pv()` para guardar a linha das expressões
Adicionamos:
```java
private ParserVal pv(TS_entry t) {
  ParserVal v = new ParserVal((Object)t);
  v.ival = linha;       // guarda a linha corrente
  return v;
}
```
**Por quê:** erros em `if`/`while`/`return` precisam apontar a linha **da condição/
expressão**, não a linha do fim da construção. Empacotando a linha junto com o tipo,
conseguimos reportar a linha correta.

### 2.7 Todo o bloco de código Java (depois do segundo `%%`) é novo
Foi onde escrevemos as **ações semânticas**. As principais funções adicionadas:

| Função | O que faz |
|---|---|
| `abreApp` / `abreClasse` | Registra a classe na tabela e define como escopo corrente |
| `abreMetodo` | Registra a assinatura do método **antes** do corpo (permite recursão) |
| `declaraAtributo` / `declaraParametro` / `declaraLocal` | Inserem símbolos e detectam duplicatas |
| `tipoClasse` / `novoObjeto` | Resolvem um nome de classe usado como tipo / em `new` |
| `usoVar` | Resolve um identificador na cadeia de escopos (local → param → atributo) |
| `tipoThis` | Tipo de `this` (a classe corrente) |
| `chamadaMetodo` | **Despacho polimórfico**: valida `obj.metodo(args)` |
| `atribuiVar` | Valida atribuição `id = exp` |
| `tipoAritmetico` / `tipoRelacional` / `tipoLogico` / `tipoIgualdade` / `tipoNeg` | Checagem de tipos dos operadores |
| `exigeBool` | Condição de `if`/`while` deve ser booleana |
| `verificaRetorno` | Tipo do `return` deve casar com o do método |
| `erroSem` | Imprime erro semântico e conta |
| `fimAnalise` | No final, lista a tabela e mostra o total de erros |

### 2.8 `yylex`, `yyerror` e `main` ajustados
- `yylex`: passou a guardar a **linha corrente** (`linha = lexer.getLine() + 1`).
- `yyerror`: mensagem de erro **sintático** em português com a linha.
- `main`: ao final do `yyparse()`, chama **`fimAnalise()`** (que lista a tabela e o
  total de erros), em vez de só imprimir `"done!"` como no original.
- Adicionado `import java.util.ArrayList;` (usado na lista de argumentos das chamadas).

---

## 3. Arquivos de tabela de símbolos — **novos**

Estes arquivos **não existiam** na pasta do professor. Foram criados do zero para
implementar o controle de escopo (a parte central do trabalho).

### 3.1 `TS_entry.java`
Representa um **tipo** da linguagem. Tipos base (`int`, `boolean`, `int[]`, `erro`) são
objetos únicos (singletons); um **tipo-classe** guarda uma referência ao `DescClasse`
correspondente (usado no despacho de método).

> Observação: na `analise-semantica` existia um `TS_entry` com a ideia de "entrada da
> tabela". Aqui ele foi **reescrito** para representar especificamente um *tipo*,
> incluindo tipo-classe — necessário porque agora temos classes.

### 3.2 `DescClasse.java` (novo)
Descritor de uma **classe**: guarda seus **atributos** (campo → tipo) e seus
**métodos** (nome → `DescMetodo`). É o escopo de classe.

### 3.3 `DescMetodo.java` (novo)
Descritor de um **método**: tipo de retorno, **parâmetros** (em ordem, para checar
chamadas) e **variáveis locais**. É o escopo mais interno. O método `resolve(nome)`
procura primeiro nas locais e depois nos parâmetros.

### 3.4 `TabSimb.java` (reescrito)
**Antes** (na `analise-semantica`): uma **lista plana** de símbolos — servia para uma
linguagem só com variáveis globais.
**Depois:** um mapa de **classes** (`nome → DescClasse`), formando a estrutura
aninhada de escopos (global → classe → método). **Por quê:** sem escopos aninhados não
há como fazer "controle de escopo", que é o foco do trabalho.

---

## 4. `ClasseID.java` — reaproveitado

Veio da `analise-semantica` **sem alterações**. A diferença é que **agora os valores
são usados de verdade**: `NomeStruct` (classe), `CampoStruct` (atributo), `NomeFuncao`
(método), `NomeParam`, `VarLocal`, `TipoBase`. No trabalho anterior, vários desses
valores estavam definidos mas nunca eram usados.

---

## 5. Arquivos sem alteração

- **`ParserVal.java`** — idêntico ao do professor (a "união" de valores do byacc/j).
- **`Makefile`** — idêntico ao do professor.

---

## 6. Arquivos novos de apoio

- **`README.md`** — exigido pelo enunciado: explica a estrutura da tabela de símbolos e
  as validações.
- **`limpar.sh`** — apaga os arquivos gerados automaticamente (`Parser.java`,
  `Yylex.java`, `*.class`).
- **`*.mjava`** — programas de teste em MiniJava: `p1.mjava` e `correto2.mjava`
  (corretos) e os `erro*.mjava` (cada um provoca uma validação a disparar).

---

## Resumo em uma frase

Pegamos a gramática do professor (que **só reconhecia** programas MiniJava) e
adicionamos uma **tabela de símbolos com escopos aninhados** e um conjunto de
**ações semânticas** que validam escopo (declarações, usos, duplicatas) e polimorfismo
(despacho de método por tipo de objeto) — mantendo a análise em uma única passagem.
