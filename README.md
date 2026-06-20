# Tarefa 3 — Análise Semântica para MiniJava

Analisador semântico de uma passagem para a linguagem **MiniJava**, construído sobre a
especificação de gramática fornecida pelo professor. O foco do trabalho é o **controle
de escopo** e o **polimorfismo** (despacho de método por tipo de objeto).

## Como compilar e testar

### Dependências
- **JFlex** — gerador do analisador léxico.
- **BYACC/J** — versão do `yacc` que gera código Java (flag `-J`). **Atenção:** é o
  BYACC/J (de <https://byaccj.sourceforge.net/>), *não* o `byacc` comum. O `byacc`
  padrão não gera Java.
- **JDK** (`javac`/`java`).

No macOS, o JFlex sai pelo Homebrew (`brew install jflex`). O BYACC/J não está no
Homebrew: baixe o fonte, compile (`cc -O -Wno-implicit-function-declaration -o yacc *.c`)
e coloque o binário no PATH com o nome `byaccj`.

### Build e execução
```sh
make build              # gera Yylex.java + Parser.java e compila
java Parser p1.mjava    # roda a análise semântica sobre um arquivo .mjava
```
Sem argumento, o `Parser` lê da entrada padrão.

A saída lista a tabela de símbolos (classes, atributos e métodos com suas assinaturas)
e a conclusão: `nenhum erro` ou a contagem de erros semânticos.

## Estrutura da tabela de símbolos

A tabela é **aninhada em três níveis**, espelhando os escopos da linguagem:

```
TabSimb (escopo global)
 └── classes: Map<nome, DescClasse>
      DescClasse (escopo de classe)
       ├── atributos: Map<nome, tipo>            (campos)
       └── metodos:   Map<nome, DescMetodo>
            DescMetodo (escopo de método)
             ├── tipoRetorno
             ├── parametros: Map<nome, tipo>     (ordenado)
             └── locais:     Map<nome, tipo>     (variáveis locais)
```

Arquivos:
- **`TabSimb.java`** — tabela global; guarda o `Map` de classes e faz a listagem final.
- **`DescClasse.java`** — descritor de classe: seus atributos e métodos.
- **`DescMetodo.java`** — descritor de método: retorno, parâmetros (ordem preservada
  para checar chamadas) e variáveis locais.
- **`TS_entry.java`** — representa um **tipo**. Tipos base (`int`, `boolean`, `int[]`,
  `erro`) são *singletons*; um **tipo-classe** guarda referência ao seu `DescClasse`
  (usado no despacho de método).
- **`ClasseID.java`** — enum da classe do identificador (`NomeStruct` p/ classe,
  `CampoStruct` p/ atributo, `NomeFuncao` p/ método, `NomeParam`, `VarLocal`, `TipoBase`).

### Resolução de identificadores (controle de escopo)
Ao analisar o corpo de um método, um identificador é resolvido na ordem:

```
variável local  →  parâmetro  →  atributo da classe corrente  →  ERRO (não declarada)
```

`this` resolve para a classe corrente. O parser mante `classeCorrente` e
`metodoCorrente` (atualizados por ações intermediárias na gramática) para saber qual
escopo está ativo a cada momento.

### Análise em uma passagem
Como exigido, toda classe, atributo e método é declarado antes do uso. Para suportar
**recursão**, ao entrar em um método sua assinatura é registrada na classe **antes** de
analisar o corpo — assim `this.ComputeFac(num-1)` (em `p1.mjava`) resolve. Entre
classes, a ordem "declarar antes de usar" garante que uma classe referenciada em `new C()`
ou como tipo já está na tabela (a classe `App`, que contém o `main`, vem por último).

## Validações executadas

### Escopo (foco)
- Classe usada como tipo ou em `new C()` deve estar **declarada antes**.
- Classe declarada mais de uma vez.
- Atributo duplicado na mesma classe.
- Método duplicado na mesma classe.
- Parâmetro duplicado no mesmo método.
- Variável local duplicada; local que colide com parâmetro de mesmo nome.
- Identificador usado sem declaração (não resolvível na cadeia de escopos).

### Polimorfismo / despacho de método (foco)
- `e.metodo(args)`: `e` deve ter tipo-classe; a classe deve **declarar** o método;
  o **número** de argumentos deve casar com o de parâmetros; o **tipo** de cada
  argumento deve ser compatível com o parâmetro correspondente.
- `new C()`: `C` deve ser uma classe declarada.

### Tipos (suporte)
- Atribuição compatível (`int=int`, `boolean=boolean`, `tipo-classe = mesmo tipo-classe`).
- `+ - * /` exigem `int`, resultam `int`.
- `<` exige `int`, resulta `boolean`.
- `&&` e `!` exigem `boolean`.
- `== !=` entre operandos compatíveis, resultam `boolean`.
- Condição de `if`/`while` deve ser `boolean`.
- Tipo da expressão do `return` deve casar com o retorno declarado do método.

Os erros usam propagação de um tipo especial `erro`: uma vez detectado um erro numa
subexpressão, ele não gera novos erros em cascata acima.

## Arquivos de teste

| Arquivo | O que exercita |
|---|---|
| `p1.mjava` | Correto — fatorial recursivo (exemplo do professor). |
| `correto2.mjava` | Correto — atributos, parâmetro de tipo-classe, chamada de método entre objetos. |
| `erro1_naodeclarada.mjava` | Escopo — uso de variável não declarada. |
| `erro2_duplicado.mjava` | Escopo — atributo declarado duas vezes. |
| `erro3_metodo_inexistente.mjava` | Polimorfismo — método inexistente na classe do objeto. |
| `erro4_argumentos.mjava` | Polimorfismo — número de argumentos incompatível. |
| `erro7_arg_tipo.mjava` | Polimorfismo — tipo de argumento incompatível. |
| `erro5_tipos.mjava` | Tipos — condição de `if` não booleana e `return` incompatível. |
| `erro6_tipo_nao_declarado.mjava` | Escopo — uso de classe (tipo) nunca declarada. |

## Decisões e simplificações

- **Sem herança**: a gramática do professor não tem `extends`. "Polimorfismo" aqui é o
  **despacho de método por tipo de objeto** (`obj.metodo(...)`), não subtipagem. Sem
  herança, compatibilidade de tipo-classe é igualdade de classe.
- **Arrays**: a sintaxe aceita `int[]`, `length` e `new int[...]`, mas — conforme o
  enunciado ("não serão tratados arrays") — **não há checagem semântica de arrays**;
  acessos de array recebem tipo `int` sem validação.
- **Tipos**: a linguagem tem `int`, `boolean`, `int[]` e tipo-classe (não há `double`).
- **`main`**: a classe `App` que contém o `main` (token especial `class App`, que evita
  o conflito S/R) é tratada como uma classe sem atributos, com o `main` como um método.
- **Linhas dos erros**: erros de declaração e de uso de identificador apontam a linha
  exata do identificador; erros de `if`/`while`/`return` apontam a linha da condição /
  expressão de retorno.

## Estrutura do projeto

```
miniJava.y        gramática + ações semânticas + métodos auxiliares (núcleo do analisador)
lexico.flex       analisador léxico (JFlex)
TabSimb.java      tabela de símbolos global
DescClasse.java   descritor de classe
DescMetodo.java   descritor de método
TS_entry.java     representação de tipo
ClasseID.java     enum das classes de identificador
ParserVal.java    valor semântico do byacc/j
Makefile          build
*.mjava           casos de teste
docs/             documento de design (spec)
```
