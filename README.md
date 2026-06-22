# Tarefa 3 – Análise Polimorfismo 

- Eduarda Fuchs
- Matheus Azevedo
- Thomaz Szeckir


## Descrição do Trabalho

Este trabalho foi desenvolvido na disciplina de Compiladores com o objetivo de implementar a etapa de **Análise Semântica** para a linguagem MiniJava.

Após a construção dos analisadores léxico e sintático nas etapas anteriores, esta atividade tem como finalidade verificar se os programas escritos na linguagem obedecem às regras semânticas definidas pela especificação. Para isso, foram implementadas estruturas de armazenamento de símbolos e mecanismos de validação capazes de identificar inconsistências que não podem ser detectadas apenas pela análise sintática.

A implementação foi realizada em **Java**, utilizando **JFlex** para geração do analisador léxico e **BYACC/J** para geração do analisador sintático.



## Objetivos

Os principais objetivos deste trabalho são:

- Implementar uma tabela de símbolos para armazenamento das informações semânticas do programa;
- Controlar os diferentes escopos existentes na linguagem;
- Verificar a declaração e utilização correta de identificadores;
- Validar chamadas de métodos;
- Verificar compatibilidade de tipos;
- Implementar suporte à herança entre classes;
- Implementar verificação de polimorfismo e sobrescrita de métodos;
- Detectar e reportar erros semânticos de forma adequada.



## Funcionalidades Implementadas

O analisador semântico desenvolvido realiza as seguintes verificações:

### Controle de Escopo

- Controle de escopo global;
- Controle de escopo de classes;
- Controle de escopo de métodos;
- Controle de escopo de variáveis locais.

### Declarações

- Verificação de classes duplicadas;
- Verificação de métodos duplicados;
- Verificação de variáveis duplicadas;
- Verificação de parâmetros duplicados.

### Uso de Identificadores

- Verificação de variáveis não declaradas;
- Verificação de métodos não declarados;
- Verificação de tipos não declarados.

### Sistema de Tipos

- Compatibilidade de tipos em atribuições;
- Compatibilidade de tipos em expressões;
- Compatibilidade de tipos em retornos de métodos;
- Compatibilidade entre parâmetros formais e argumentos.

### Herança

- Verificação da existência da superclasse;
- Registro da hierarquia de herança;
- Busca de atributos herdados;
- Busca de métodos herdados.

### Polimorfismo

- Sobrescrita de métodos;
- Verificação de assinaturas compatíveis;
- Resolução de chamadas considerando herança;
- Compatibilidade entre objetos de subclasses e superclasses.



## Estrutura do Projeto

```text
T3-AnaliseSemantica-main/
│
── README.md
── ARQUIVOS.md
── MODIFICACOES.md
── POLIMORFISMO.md

── lexico.flex
── miniJava.y
── ParserVal.java

── TabSimb.java
── TS_entry.java
── ClasseID.java
── DescClasse.java
── DescMetodo.java

── correto2.mjava
── heranca_ok.mjava
── polimorfismo_ok.mjava

── erro1_naodeclarada.mjava
── erro2_duplicado.mjava
── erro3_metodo_inexistente.mjava
── erro4_argumentos.mjava
── erro5_tipos.mjava
── erro6_tipo_nao_declarado.mjava
── erro7_arg_tipo.mjava
── erro8_super_nao_decl.mjava
── erro9_override_assinatura.mjava


── p1.mjava

── Makefile
── testar.sh
── limpar.sh
```
## Estruturas Implementadas

### Tabela de Símbolos

A tabela de símbolos é responsável por armazenar informações sobre:

- Classes;
- Métodos;
- Variáveis;
- Parâmetros;
- Relações de herança.

Essa estrutura permite realizar consultas durante toda a análise semântica.

### Descritores

Foram utilizados descritores específicos para representar elementos da linguagem:

#### DescClasse

Armazena:

- Nome da classe;
- Superclasse;
- Métodos;
- Atributos.

#### DescMetodo

Armazena:

- Nome do método;
- Tipo de retorno;
- Lista de parâmetros;
- Variáveis locais.

#### TS_entry

Representa uma entrada da tabela de símbolos contendo as informações associadas a cada identificador.

---

## Como Compilar

### Utilizando Makefile

Execute:

```bash
make
```

Caso o ambiente possua as dependências configuradas corretamente, os arquivos necessários serão gerados automaticamente.



### Compilação Manual

#### 1. Gerar o analisador léxico

```bash
jflex lexico.flex
```

#### 2. Gerar o analisador sintático

```bash
byaccj miniJava.y
```

#### 3. Compilar os arquivos Java

```bash
javac *.java
```


## Como Executar

Após a compilação, execute o analisador informando um arquivo MiniJava:

```bash
java Parser correto2.mjava
```

ou

```bash
java Parser heranca_ok.mjava
```

ou

```bash
java Parser polimorfismo_ok.mjava
```



## Execução dos Testes

O projeto disponibiliza arquivos de teste contendo exemplos válidos e inválidos.

Para executar os testes:

```bash
./testar.sh
```

Os arquivos de erro permitem verificar se o analisador detecta corretamente as inconsistências semânticas implementadas.



## Exemplos de Erros Detectados

### Variável não declarada

```java
x = 10;
```

Resultado esperado:

```text
Erro semântico: variável 'x' não declarada.
```

---

### Método inexistente

```java
obj.metodoInexistente();
```

Resultado esperado:

```text
Erro semântico: método não encontrado.
```



### Tipo incompatível

```java
int x;
x = true;
```

Resultado esperado:

```text
Erro semântico: tipos incompatíveis.
```


### Superclasse inexistente

```java
class B extends A {
}
```

Resultado esperado:

```text
Erro semântico: superclasse 'A' não declarada.
```



### Sobrescrita inválida

```java
class A {
    int f(int x) { ... }
}

class B extends A {
    boolean f(int x) { ... }
}
```

Resultado esperado:

```text
Erro semântico: assinatura incompatível na sobrescrita do método.
```


## Passos Realizados Durante o Desenvolvimento

1. Estudo da especificação da linguagem MiniJava;
2. Análise da gramática fornecida;
3. Projeto da tabela de símbolos;
4. Implementação das estruturas auxiliares;
5. Implementação do controle de escopo;
6. Implementação das verificações semânticas básicas;
7. Implementação do suporte à herança;
8. Implementação do suporte ao polimorfismo;
9. Implementação das mensagens de erro;
10. Construção dos casos de teste;
11. Validação dos resultados obtidos.