# Implementação de Herança, Polimorfismo e Sobrescrita

Este documento descreve, passo a passo, como o suporte a **herança**,
**polimorfismo** e **sobrescrita de métodos** foi adicionado ao
analisador semântico do MiniJava, atravessando os três componentes da
ferramenta: o **léxico (JFlex)**, o **sintático (BYACC/J)** e as
**estruturas de tabela de símbolos**.

> Observação rápida sobre diagnósticos: editores modernos podem mostrar
> avisos de "Bison 3.x" no `miniJava.y` (sugerindo `%empty`,
> `%define api.pure`, etc.). Eles são ruído — o projeto usa
> **BYACC/J**, que é a variante Java do *yacc* clássico e não aceita
> essas diretivas. A compilação roda sem conflitos S/R.

---

## 1. O que muda na linguagem

A gramática do MiniJava (Appel) prevê herança simples:

```
ClassDeclaration → class id [ extends id ] { … }
```

Com isso, um programa válido passa a poder fazer:

```java
class A {
    int x;
    public int m() { return 1; }
}

class B extends A {     // B herda x e m de A
    public int m() { return 2; }   // sobrescreve m
}

class C {
    public int p(A obj) { return obj.m(); }
}
```

O analisador precisa, então, lidar com três fenômenos novos:

| Fenômeno        | Onde aparece                                              |
|-----------------|-----------------------------------------------------------|
| **Herança**     | `B extends A` — `B` ganha tudo que `A` declarou           |
| **Polimorfismo** | `A obj = new B();` ou passar `B` onde se espera `A`      |
| **Sobrescrita** | `B.m()` substitui `A.m()` com a **mesma assinatura**      |

---

## 2. Léxico (`lexico.flex`)

O JFlex foi alterado em **uma única linha**: a palavra-chave `extends`
precisa virar um token reconhecido pelo parser. Antes dela, qualquer
ocorrência seria casada pela regra genérica de `Identifier`.

```flex
class         { return Parser.CLASS; }
extends       { return Parser.EXTENDS; }     // ← adicionado
public        { return Parser.PUBLIC; }
```

A ordem importa: a regra de palavra-chave aparece **antes** da regra
`[a-zA-Z][a-zA-Z0-9_]*` (que devolveria `Identifier`). O JFlex aplica a
regra de maior prefixo (*longest match*) e, em empate, a que aparece
primeiro — assim "extends" jamais é classificado como identificador.

O lado do parser ganha o token correspondente em `miniJava.y`:

```
%token CLASS, EXTENDS, PUBLIC, STATIC, VOID, MAIN, APP
```

---

## 3. Gramática (`miniJava.y`)

### 3.1 Regra opcional `HerancaOpt`

A produção de classe foi estendida para aceitar `extends` opcionalmente,
usando uma sub-regra auxiliar:

```yacc
ClassDeclaration : CLASS Identifier { abreClasse($2.sval, $2.ival); }
                   HerancaOpt
                   '{' VarDeclarationList MethodDeclarationList '}'
                   { fechaEscopoClasse(); }
                 ;

HerancaOpt : EXTENDS Identifier { defineHeranca($2.sval, $2.ival); }
           |                          /* sem heranca */
           ;
```

Detalhe importante de **ordem das ações**:

1. `abreClasse(...)` cria o `DescClasse` e o registra na tabela **antes**
   de `HerancaOpt` ser reduzido.
2. `defineHeranca(...)` só roda depois, ligando `classeCorrente` à sua
   superclasse.
3. Só então o corpo da classe (`{ … }`) é processado — agora atributos
   herdados já são visíveis.

Essa ordem é fundamental para o requisito do trabalho: *"todas as
classes, atributos e métodos devem ser declarados antes do seu uso,
permitindo a análise em uma passagem"*. A superclasse precisa ter sido
declarada antes; senão, `defineHeranca` reporta o erro.

### 3.2 Ação `defineHeranca`

```java
private void defineHeranca(String nomePai, int ln) {
    DescClasse pai = tabela.getClasse(nomePai);
    if (pai == null) {
        erroSem(ln, "superclasse '" + nomePai + "' nao declarada");
        return;
    }
    if (pai == classeCorrente) { /* C extends C */ ... }
    for (DescClasse c = pai; c != null; c = c.getSuperclasse())
        if (c == classeCorrente) { /* ciclo */ ... }
    classeCorrente.setSuperclasse(pai);
}
```

Três verificações: existência da superclasse, auto-herança e ciclo.

---

## 4. Estruturas da tabela de símbolos

### 4.1 `DescClasse.java` — o coração da herança

Cada `DescClasse` ganhou um campo `superclasse` apontando para outro
`DescClasse`. Para preservar a semântica certa em cada situação, os
lookups foram **duplicados** em duas famílias:

| Família        | Quando usar                                              | Comportamento              |
|----------------|----------------------------------------------------------|----------------------------|
| `temAtributo` / `getAtributo` / `temMetodo` / `getMetodo` | Detecção de **duplicação** ao declarar | só olha **esta** classe |
| `temAtributoVisivel` / `getAtributoVisivel` / `getMetodoVisivel` | **Resolução de nomes** durante a análise do corpo | sobe na cadeia da superclasse |

Implementação da família "visível":

```java
public TS_entry getAtributoVisivel(String n) {
    for (DescClasse c = this; c != null; c = c.superclasse)
        if (c.atributos.containsKey(n)) return c.atributos.get(n);
    return null;
}
```

Loop simples subindo na cadeia até achar ou esgotar.

### 4.2 Resolução de variável dentro de um método

A regra de escopo passa a ser:

```
local → parâmetro → atributo da classe (subindo na cadeia) → ERRO
```

Implementada em `usoVar`:

```java
private TS_entry usoVar(String nome, int ln) {
    if (metodoCorrente != null) {
        TS_entry t = metodoCorrente.resolve(nome);
        if (t != null) return t;
    }
    if (classeCorrente != null && classeCorrente.temAtributoVisivel(nome))
        return classeCorrente.getAtributoVisivel(nome);
    erroSem(ln, "variavel '" + nome + "' nao declarada");
    return Tp_ERRO;
}
```

A única mudança em relação à versão anterior foi trocar `temAtributo` /
`getAtributo` por `temAtributoVisivel` / `getAtributoVisivel`. Toda a
cadeia de herança fica acessível "de graça".

### 4.3 Despacho de método (`chamadaMetodo`)

Para `obj.m(args)`, a busca de `m` agora sobe na cadeia do tipo
declarado de `obj`:

```java
DescClasse c = tipoObj.getClasseRef();
DescMetodo m = c.getMetodoVisivel(metodo);   // ← sobe na cadeia
```

Se `B extends A` e `A` declara `m()`, então `B.getMetodoVisivel("m")`
encontra o método de `A`. Se `B` sobrescreve `m`, encontra o de `B`
primeiro — exatamente o comportamento esperado de despacho por tipo
declarado.

---

## 5. Polimorfismo — compatibilidade por subtipagem

A função `compativel(destino, origem)` era o "guardião" de todas as
verificações de tipo: atribuição, argumento de chamada, e retorno.
Antes ela só aceitava **tipos idênticos**. Agora aceita também
`origem` como **subtipo** de `destino`:

```java
private boolean compativel(TS_entry destino, TS_entry origem) {
    if (destino == Tp_ERRO || origem == Tp_ERRO) return true;
    if (destino == origem) return true;
    if (destino.isClasse() && origem.isClasse())
        return ehSubtipo(origem.getClasseRef(), destino.getClasseRef());
    return false;
}

private boolean ehSubtipo(DescClasse sub, DescClasse sup) {
    for (DescClasse c = sub; c != null; c = c.getSuperclasse())
        if (c == sup) return true;
    return false;
}
```

Como `compativel` é o **único ponto** consultado por `atribuiVar`,
`chamadaMetodo` e `verificaRetorno`, essa única alteração libera
polimorfismo em **todos** os contextos:

| Situação                                  | Funciona porque         |
|-------------------------------------------|--------------------------|
| `A x; x = new B();`                       | `ehSubtipo(B, A) = true` |
| `f(B)` chamada para parâmetro tipo `A`    | mesma função             |
| `return new B();` num método que retorna `A` | mesma função          |

---

## 6. Sobrescrita de métodos

Sobrescrita exige duas coisas:

1. Permitir que `B` declare `m` mesmo se `A` já tinha `m` — sem cair na
   regra de "método duplicado".
2. **Validar** que a assinatura bate (mesmo retorno, mesmos tipos de
   parâmetros, na mesma ordem). Senão, é erro.

### 6.1 Por que dois lookups separados?

A duplicação na detecção (`temMetodo` "próprio" vs. `getMetodoVisivel`
"em cadeia") resolve o ponto 1: ao declarar `B.m`, perguntamos se
**`B` em si** já tem `m` — não se algum ancestral tem. Logo, override
não dispara o erro de duplicação.

### 6.2 Validação tardia da assinatura

O parser registra o método **antes** de ler os parâmetros (para
permitir recursão dentro do próprio corpo). Portanto, no momento de
`abreMetodo`, ainda não sabemos a lista completa de parâmetros — não
dá para validar a assinatura aí.

Solução: validar **na ação de fim de método**, quando todos os
parâmetros já foram empilhados em `metodoCorrente`:

```java
private void fechaEscopoMetodo() {
    if (metodoCorrente != null && classeCorrente != null
        && classeCorrente.getSuperclasse() != null) {
        DescMetodo pai = classeCorrente.getSuperclasse()
                                       .getMetodoVisivel(metodoCorrente.getNome());
        if (pai != null && !mesmaAssinatura(pai, metodoCorrente))
            erroSem(metodoCorrente.getLinhaDecl(),
                    "sobrescrita invalida de '" + metodoCorrente.getNome()
                    + "': assinatura difere de '" + pai.assinatura() + "'");
    }
    metodoCorrente = null;
}
```

`mesmaAssinatura` compara retorno e tipos de parâmetros posição-a-posição
(comparação por identidade, já que tipos são singletons em `Parser`).

Para que a mensagem de erro aponte para a linha **correta** (a da
declaração do método `B.m`, não a do `}` final), `DescMetodo` ganhou
`linhaDecl`, preenchido em `abreMetodo`.

---

## 7. Visualização — `TabSimb.listar()`

Para inspeção, a listagem final agora exibe a relação de herança:

```
Classe: A
   atributo  x           : int
   metodo    m(): int

Classe: B extends A
   metodo    m(): int
```

Uma linha em `TabSimb.java` faz isso:

```java
String h = c.getSuperclasse() == null ? "" : " extends " + c.getSuperclasse().getNome();
System.out.println("\nClasse: " + c.getNome() + h);
```

---

## 8. Resumo de impacto por arquivo

| Arquivo            | Mudança                                                        |
|--------------------|----------------------------------------------------------------|
| `lexico.flex`      | +1 regra: token `extends`                                      |
| `miniJava.y`       | token `EXTENDS`; `HerancaOpt`; `defineHeranca`; `ehSubtipo`; `compativel` com subtipo; `mesmaAssinatura`; validação no `fechaEscopoMetodo`; usos de `…Visivel` |
| `DescClasse.java`  | campo `superclasse`; getters/setters; família `…Visivel`       |
| `DescMetodo.java`  | campo `linhaDecl` (para localizar o erro de override)          |
| `TabSimb.java`     | listagem mostra `extends X`                                    |

---

## 9. Como verificar

```sh
make build          # gera Yylex.java, Parser.java, .class
./testar.sh         # roda todos os .mjava
```

Casos diretamente relacionados a este documento:

- `heranca_ok.mjava` — herança simples + sobrescrita válida
- `polimorfismo_ok.mjava` — atributo herdado + subtipagem em atribuição
  e em argumento
- `erro8_super_nao_decl.mjava` — `extends` para classe inexistente
- `erro9_override_assinatura.mjava` — override com assinatura
  incompatível
