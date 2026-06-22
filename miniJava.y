%{
  import java.io.*;
  import java.util.ArrayList;
%}


%token CLASS, EXTENDS, PUBLIC, STATIC, VOID, MAIN, APP
%token STRING, INT, BOOLEAN, IF, ELSE, WHILE, SOUT
%token NEW, TRUE, FALSE, THIS, LENGTH, RETURN
%token AND, EQ, NEQ
%token Identifier, Number

%nonassoc '<' EQ NEQ
%left AND
%left '+' '-'
%left '*' '/'
%right '!'
%left '['
%left '.'

%%

Program	:	 ClassDeclarationList  MainClass
        ;

ClassDeclarationList : ClassDeclarationList ClassDeclaration
                     |
                     ;

MainClass	:	APP '{' { abreApp(); } PUBLIC STATIC VOID MAIN '(' STRING '[' ']' Identifier ')' '{' Statement '}' '}'
              { fechaEscopoClasse(); }
          ;

ClassDeclaration	:	CLASS Identifier { abreClasse($2.sval, $2.ival); } HerancaOpt '{' VarDeclarationList MethodDeclarationList  '}'
                      { fechaEscopoClasse(); }
                  ;

HerancaOpt : EXTENDS Identifier { defineHeranca($2.sval, $2.ival); }
           |
           ;

MethodDeclarationList : MethodDeclarationList MethodDeclaration
                      |
                      ;

MethodDeclaration	:	PUBLIC Type Identifier { abreMetodo((TS_entry)$2.obj, $3.sval, $3.ival); } '(' ParamList ')' '{' DeclOrStatList RETURN Exp ';' '}'
                      { verificaRetorno((TS_entry)$11.obj, $11.ival); fechaEscopoMetodo(); }
                  ;

VarDeclarationList : VarDeclarationList VarDeclaration
                   |
                   ;

VarDeclaration	:	Type Identifier ';'  { declaraAtributo((TS_entry)$1.obj, $2.sval, $2.ival); }
                ;

DeclOrStatList : Identifier Identifier ';' { declaraLocal(tipoClasse($1.sval, $1.ival), $2.sval, $2.ival); } DeclOrStatList
                | BaseType Identifier ';'  { declaraLocal((TS_entry)$1.obj, $2.sval, $2.ival); } DeclOrStatList
                |	Identifier '=' Exp ';' { atribuiVar($1.sval, (TS_entry)$3.obj, $1.ival); }  StatementList
                |	Identifier '[' Exp ']' '=' Exp ';' StatementList
                | '{' StatementList '}'
                |	IF '(' Exp ')' Statement ELSE Statement { exigeBool((TS_entry)$3.obj, "if", $3.ival); } StatementList
                |	WHILE '(' Exp ')' Statement { exigeBool((TS_entry)$3.obj, "while", $3.ival); } StatementList
                |	SOUT '(' Exp ')' ';' StatementList
                |
                ;


ParamList : Type Identifier { declaraParametro((TS_entry)$1.obj, $2.sval, $2.ival); } ParamListAux
          |
          ;

ParamListAux : ',' Type Identifier { declaraParametro((TS_entry)$2.obj, $3.sval, $3.ival); } ParamListAux
              |
             ;

BaseType	:	INT '[' ']'  { $$ = new ParserVal(Tp_INTARRAY); }
      |	BOOLEAN          { $$ = new ParserVal(Tp_BOOL);     }
      |	INT              { $$ = new ParserVal(Tp_INT);      }
      ;

Type : BaseType     { $$ = $1; }
     | Identifier   { $$ = new ParserVal(tipoClasse($1.sval, $1.ival)); }
     ;

Statement	:	'{' StatementList '}'
          |	IF '(' Exp ')' Statement ELSE Statement   { exigeBool((TS_entry)$3.obj, "if", $3.ival);    }
          |	WHILE '(' Exp ')' Statement               { exigeBool((TS_entry)$3.obj, "while", $3.ival); }
          |	SOUT '(' Exp ')' ';'
          |	Identifier '=' Exp ';'                    { atribuiVar($1.sval, (TS_entry)$3.obj, $1.ival); }
          |	Identifier '[' Exp ']' '=' Exp ';'
          ;

StatementList : StatementList Statement
              |
              ;

Exp	:	Exp AND Exp   { $$ = pv(tipoLogico((TS_entry)$1.obj, (TS_entry)$3.obj));     }
    | Exp '<' Exp   { $$ = pv(tipoRelacional((TS_entry)$1.obj, (TS_entry)$3.obj));  }
    | Exp EQ Exp    { $$ = pv(tipoIgualdade((TS_entry)$1.obj, (TS_entry)$3.obj));   }
    | Exp NEQ Exp   { $$ = pv(tipoIgualdade((TS_entry)$1.obj, (TS_entry)$3.obj));   }
    | Exp '+' Exp   { $$ = pv(tipoAritmetico((TS_entry)$1.obj, (TS_entry)$3.obj)); }
    | Exp '-' Exp   { $$ = pv(tipoAritmetico((TS_entry)$1.obj, (TS_entry)$3.obj)); }
    | Exp '/' Exp   { $$ = pv(tipoAritmetico((TS_entry)$1.obj, (TS_entry)$3.obj)); }
    | Exp '*' Exp   { $$ = pv(tipoAritmetico((TS_entry)$1.obj, (TS_entry)$3.obj)); }
    |	Exp '[' Exp ']'                              { $$ = pv(Tp_INT);  /* array: semantica ignorada */ }
    |	Exp '.' LENGTH                               { $$ = pv(Tp_INT);  /* array: semantica ignorada */ }
    |	Exp '.' Identifier '(' RealParamList ')'     { $$ = pv(chamadaMetodo((TS_entry)$1.obj, $3.sval, (ArrayList<TS_entry>)$5.obj)); }
    |	Number        { $$ = pv(Tp_INT);  }
    |	TRUE          { $$ = pv(Tp_BOOL); }
    |	FALSE         { $$ = pv(Tp_BOOL); }
    |	Identifier    { $$ = pv(usoVar($1.sval, $1.ival)); }
    |	THIS          { $$ = pv(tipoThis()); }
    |	NEW INT '[' Exp ']'        { $$ = pv(Tp_INTARRAY); /* array: semantica ignorada */ }
    |	NEW Identifier '(' ')'     { $$ = pv(novoObjeto($2.sval, $2.ival)); }
    |	'!' Exp       { $$ = pv(tipoNeg((TS_entry)$2.obj)); }
    |	'(' Exp ')'   { $$ = $2; }
    ;

RealParamList : Exp RealParamListAux  { ArrayList<TS_entry> l = (ArrayList<TS_entry>)$2.obj;
                                        l.add(0, (TS_entry)$1.obj);
                                        $$ = new ParserVal((Object)l); }
              |                       { $$ = new ParserVal((Object)new ArrayList<TS_entry>()); }
              ;

RealParamListAux : ',' Exp RealParamListAux { ArrayList<TS_entry> l = (ArrayList<TS_entry>)$3.obj;
                                              l.add(0, (TS_entry)$2.obj);
                                              $$ = new ParserVal((Object)l); }
                 |                          { $$ = new ParserVal((Object)new ArrayList<TS_entry>()); }
                 ;


%%

  private Yylex lexer;
  private int   linha    = 1;    // linha aproximada corrente (1-based)
  private int   numErros = 0;    // contador de erros semanticos

  // ---------------- tabela de simbolos ----------------
  private TabSimb tabela = new TabSimb();

  // escopo corrente
  private DescClasse classeCorrente = null;
  private DescMetodo metodoCorrente = null;

  // -------- tipos base (singletons usados como "tags" de tipo) --------
  public static final TS_entry Tp_INT      = new TS_entry("int",     ClasseID.TipoBase);
  public static final TS_entry Tp_BOOL     = new TS_entry("boolean", ClasseID.TipoBase);
  public static final TS_entry Tp_INTARRAY = new TS_entry("int[]",   ClasseID.TipoBase);
  public static final TS_entry Tp_ERRO     = new TS_entry("erro",    ClasseID.TipoBase);

  // ==================== ACOES SEMANTICAS ====================

  private void erroSem(int ln, String msg) {
    numErros++;
    System.out.println("Erro semantico (linha " + ln + "): " + msg);
  }

  // -------------------- escopos (classe / metodo) --------------------

  // abre a classe que contem o main (classe App)
  private void abreApp() {
    DescClasse c = new DescClasse("App");
    tabela.addClasse(c);
    classeCorrente = c;
    // main e' tratado como um metodo (estatico, void) para abrir um escopo
    DescMetodo m = new DescMetodo("main", null);
    c.addMetodo(m);
    metodoCorrente = m;
  }

  // abre uma classe comum
  private void abreClasse(String nome, int ln) {
    if (tabela.temClasse(nome)) {
      erroSem(ln, "classe '" + nome + "' ja declarada");
      classeCorrente = new DescClasse(nome);   // descritor temporario, fora da tabela
    } else {
      classeCorrente = new DescClasse(nome);
      tabela.addClasse(classeCorrente);
    }
    metodoCorrente = null;
  }

  private void fechaEscopoClasse() {
    classeCorrente = null;
    metodoCorrente = null;
  }

  // abre um metodo; a assinatura e' registrada ANTES do corpo (permite recursao)
  private void abreMetodo(TS_entry tipoRet, String nome, int ln) {
    if (classeCorrente.temMetodo(nome))
      erroSem(ln, "metodo '" + nome + "' ja declarado na classe '" + classeCorrente.getNome() + "'");
    metodoCorrente = new DescMetodo(nome, tipoRet);
    metodoCorrente.setLinhaDecl(ln);
    classeCorrente.addMetodo(metodoCorrente);   // visivel ja no proprio corpo
  }

  // ao fechar o metodo, se ele sobrescreve um metodo herdado, exige mesma assinatura
  private void fechaEscopoMetodo() {
    if (metodoCorrente != null && classeCorrente != null
        && classeCorrente.getSuperclasse() != null) {
      DescMetodo pai = classeCorrente.getSuperclasse().getMetodoVisivel(metodoCorrente.getNome());
      if (pai != null && !mesmaAssinatura(pai, metodoCorrente))
        erroSem(metodoCorrente.getLinhaDecl(),
                "sobrescrita invalida de '" + metodoCorrente.getNome()
                + "': assinatura difere de '" + pai.assinatura() + "'");
    }
    metodoCorrente = null;
  }

  private boolean mesmaAssinatura(DescMetodo a, DescMetodo b) {
    if (a.getTipoRetorno() != b.getTipoRetorno()) return false;
    ArrayList<TS_entry> pa = a.tiposParametros();
    ArrayList<TS_entry> pb = b.tiposParametros();
    if (pa.size() != pb.size()) return false;
    for (int i = 0; i < pa.size(); i++) if (pa.get(i) != pb.get(i)) return false;
    return true;
  }

  // -------------------- heranca --------------------
  private void defineHeranca(String nomePai, int ln) {
    if (classeCorrente == null) return;
    DescClasse pai = tabela.getClasse(nomePai);
    if (pai == null) { erroSem(ln, "superclasse '" + nomePai + "' nao declarada"); return; }
    if (pai == classeCorrente) { erroSem(ln, "classe '" + nomePai + "' nao pode herdar de si mesma"); return; }
    // checagem simples de ciclo (defensiva: heranca so referencia classes ja declaradas)
    for (DescClasse c = pai; c != null; c = c.getSuperclasse())
       if (c == classeCorrente) { erroSem(ln, "ciclo de heranca envolvendo '" + nomePai + "'"); return; }
    classeCorrente.setSuperclasse(pai);
  }

  // -------------------- declaracoes --------------------

  private void declaraAtributo(TS_entry tipo, String nome, int ln) {
    if (classeCorrente.temAtributo(nome))
      erroSem(ln, "atributo '" + nome + "' ja declarado na classe '" + classeCorrente.getNome() + "'");
    else
      classeCorrente.addAtributo(nome, tipo);
  }

  private void declaraParametro(TS_entry tipo, String nome, int ln) {
    if (metodoCorrente.temParametro(nome))
      erroSem(ln, "parametro '" + nome + "' ja declarado no metodo '" + metodoCorrente.getNome() + "'");
    else
      metodoCorrente.addParametro(nome, tipo);
  }

  private void declaraLocal(TS_entry tipo, String nome, int ln) {
    if (metodoCorrente.temLocal(nome))
      erroSem(ln, "variavel local '" + nome + "' ja declarada no metodo '" + metodoCorrente.getNome() + "'");
    else if (metodoCorrente.temParametro(nome))
      erroSem(ln, "variavel local '" + nome + "' colide com parametro de mesmo nome");
    else
      metodoCorrente.addLocal(nome, tipo);
  }

  // -------------------- tipos / resolucao --------------------

  // resolve um nome de classe usado como tipo; erro se nao declarada
  private TS_entry tipoClasse(String nome, int ln) {
    DescClasse c = tabela.getClasse(nome);
    if (c == null) { erroSem(ln, "tipo '" + nome + "' nao declarado"); return Tp_ERRO; }
    return c.getTipo();
  }

  // uso de um identificador numa expressao: local -> parametro -> atributo -> erro
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

  private TS_entry tipoThis() {
    if (classeCorrente == null) return Tp_ERRO;
    return classeCorrente.getTipo();
  }

  // new C() : C deve ser classe declarada; devolve o tipo-classe
  private TS_entry novoObjeto(String nome, int ln) {
    DescClasse c = tabela.getClasse(nome);
    if (c == null) { erroSem(ln, "classe '" + nome + "' nao declarada"); return Tp_ERRO; }
    return c.getTipo();
  }

  // -------------------- polimorfismo: despacho de metodo --------------------
  // e.metodo(args) : e precisa ser tipo-classe; o metodo deve existir na classe;
  //                  numero e tipos dos argumentos devem casar com os parametros.
  private TS_entry chamadaMetodo(TS_entry tipoObj, String metodo, ArrayList<TS_entry> args) {
    if (tipoObj == Tp_ERRO) return Tp_ERRO;
    if (!tipoObj.isClasse()) {
      erroSem(linha, "chamada de metodo '" + metodo + "' sobre algo que nao e' objeto");
      return Tp_ERRO;
    }
    DescClasse c = tipoObj.getClasseRef();
    DescMetodo m = c.getMetodoVisivel(metodo);
    if (m == null) {
      erroSem(linha, "metodo '" + metodo + "' nao existe na classe '" + c.getNome() + "'");
      return Tp_ERRO;
    }
    ArrayList<TS_entry> params = m.tiposParametros();
    if (args.size() != params.size()) {
      erroSem(linha, "metodo '" + metodo + "' espera " + params.size()
                     + " argumento(s), recebeu " + args.size());
      return m.getTipoRetorno();
    }
    for (int i = 0; i < args.size(); i++) {
      if (!compativel(params.get(i), args.get(i)))
        erroSem(linha, "argumento " + (i + 1) + " de '" + metodo + "': esperado "
                       + params.get(i) + ", recebido " + args.get(i));
    }
    return m.getTipoRetorno();
  }

  // -------------------- atribuicao --------------------
  private void atribuiVar(String nome, TS_entry tipoExp, int ln) {
    TS_entry destino = usoVar(nome, ln);   // reaproveita resolucao + erro de nao declarada
    if (destino == Tp_ERRO) return;
    if (!compativel(destino, tipoExp))
      erroSem(ln, "tipos incompativeis na atribuicao a '" + nome
                  + "' (esperado " + destino + ", recebido " + tipoExp + ")");
  }

  // compatibilidade de atribuicao/argumento: mesmo tipo OU origem subtipo de destino
  private boolean compativel(TS_entry destino, TS_entry origem) {
    if (destino == Tp_ERRO || origem == Tp_ERRO) return true;   // erro ja reportado
    if (destino == origem) return true;                         // tipos base (singletons)
    if (destino.isClasse() && origem.isClasse())
      return ehSubtipo(origem.getClasseRef(), destino.getClasseRef());
    return false;
  }

  // sub e' subclasse (direta ou transitiva) de sup, ou sub == sup
  private boolean ehSubtipo(DescClasse sub, DescClasse sup) {
    for (DescClasse c = sub; c != null; c = c.getSuperclasse())
      if (c == sup) return true;
    return false;
  }

  // -------------------- operadores --------------------
  private TS_entry tipoAritmetico(TS_entry a, TS_entry b) {
    if (a == Tp_ERRO || b == Tp_ERRO) return Tp_ERRO;
    if (a != Tp_INT || b != Tp_INT) { erroSem(linha, "operando de expressao aritmetica deve ser int"); return Tp_ERRO; }
    return Tp_INT;
  }

  private TS_entry tipoRelacional(TS_entry a, TS_entry b) {
    if (a == Tp_ERRO || b == Tp_ERRO) return Tp_ERRO;
    if (a != Tp_INT || b != Tp_INT) { erroSem(linha, "operando de '<' deve ser int"); return Tp_ERRO; }
    return Tp_BOOL;
  }

  private TS_entry tipoIgualdade(TS_entry a, TS_entry b) {
    if (a == Tp_ERRO || b == Tp_ERRO) return Tp_ERRO;
    if (compativel(a, b) || compativel(b, a)) return Tp_BOOL;
    erroSem(linha, "operandos incompativeis em comparacao de igualdade");
    return Tp_ERRO;
  }

  private TS_entry tipoLogico(TS_entry a, TS_entry b) {
    if (a == Tp_ERRO || b == Tp_ERRO) return Tp_ERRO;
    if (a != Tp_BOOL || b != Tp_BOOL) { erroSem(linha, "operando de '&&' deve ser boolean"); return Tp_ERRO; }
    return Tp_BOOL;
  }

  private TS_entry tipoNeg(TS_entry a) {
    if (a == Tp_ERRO) return Tp_ERRO;
    if (a != Tp_BOOL) { erroSem(linha, "operando de '!' deve ser boolean"); return Tp_ERRO; }
    return Tp_BOOL;
  }

  private void exigeBool(TS_entry t, String ctx, int ln) {
    if (t == Tp_ERRO) return;
    if (t != Tp_BOOL) erroSem(ln, "condicao do '" + ctx + "' deve ser boolean");
  }

  // tipo da expressao de return deve casar com o retorno declarado do metodo
  private void verificaRetorno(TS_entry tipoExp, int ln) {
    if (metodoCorrente == null || metodoCorrente.getTipoRetorno() == null) return;
    if (!compativel(metodoCorrente.getTipoRetorno(), tipoExp))
      erroSem(ln, "tipo do return incompativel no metodo '" + metodoCorrente.getNome()
                     + "' (esperado " + metodoCorrente.getTipoRetorno() + ", recebido " + tipoExp + ")");
  }

  // empacota um tipo no valor semantico, guardando a linha corrente (p/ mensagens de erro)
  private ParserVal pv(TS_entry t) {
    ParserVal v = new ParserVal((Object)t);
    v.ival = linha;
    return v;
  }

  // -------------------- final da analise --------------------
  public void fimAnalise() {
    tabela.listar();
    System.out.println();
    if (numErros == 0)
      System.out.println(">> Analise concluida: nenhum erro semantico encontrado.");
    else
      System.out.println(">> Analise concluida: " + numErros + " erro(s) semantico(s).");
  }

  // ==================== INFRAESTRUTURA (byacc/j) ====================

  private int yylex () {
    int yyl_return = -1;
    try {
      yylval = new ParserVal(0);
      yyl_return = lexer.yylex();
      linha = lexer.getLine() + 1;   // 1-based
    }
    catch (IOException e) {
      System.err.println("Erro de E/S: " + e.getMessage());
    }
    return yyl_return;
  }

  public void yyerror (String error) {
    System.out.println("Erro sintatico (linha " + linha + "): " + error);
  }

  public Parser(Reader r) {
    lexer = new Yylex(r, this);
  }

  public void setDebug(boolean debug) { yydebug = debug; }

  public static void main(String args[]) throws IOException {
    Parser yyparser;
    if (args.length > 0) {
      yyparser = new Parser(new FileReader(args[0]));
    } else {
      System.out.print("> ");
      yyparser = new Parser(new InputStreamReader(System.in));
    }
    yyparser.yyparse();
    yyparser.fimAnalise();
  }
