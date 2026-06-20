%%

%byaccj
%line

%{
  private Parser yyparser;

  public Yylex(java.io.Reader r, Parser yyparser) {
    this(r);
    this.yyparser = yyparser;
  }

  /* expoe a linha corrente (0-based no JFlex) para o parser */
  public int getLine() { return yyline; }
%}

NL  = \n | \r | \r\n

%%

"$TRACE_ON"  { yyparser.setDebug(true);  }
"$TRACE_OFF" { yyparser.setDebug(false); }

class         { return Parser.CLASS; }
"class App"   { return Parser.APP; }
public        { return Parser.PUBLIC; }
static        { return Parser.STATIC; }
void          { return Parser.VOID; }
main          { return Parser.MAIN; }
String        { return Parser.STRING; }
int           { return Parser.INT; }
boolean       { return Parser.BOOLEAN; }
if            { return Parser.IF; }
else          { return Parser.ELSE; }
while         { return Parser.WHILE; }
"System.out.println" { return Parser.SOUT; }
new           { return Parser.NEW; }
true          { return Parser.TRUE; }
false         { return Parser.FALSE; }
this          { return Parser.THIS; }
length        { return Parser.LENGTH; }
return        { return Parser.RETURN; }

[a-zA-Z][a-zA-Z0-9_]* { ParserVal v = new ParserVal(yytext());
                        v.ival = yyline + 1;          /* guarda a linha do identificador */
                        yyparser.yylval = v;
                        return Parser.Identifier; }
[0-9]+        { return Parser.Number; }

"&&"          { return Parser.AND; }
"=="          { return Parser.EQ; }
"!="          { return Parser.NEQ; }

";" |
"{" |
"}" |
"=" |
"(" |
")" |
"[" |
"]" |
"*" |
"/" |
"+" |
"," |
"-" |
"<" |
"!" |
"\."    { return (int) yycharat(0); }

[ \t]+      { }
{NL}+       { }
"//" .*     { }
.    { System.err.println("Erro lexico: caractere inesperado '"+yytext()+"' na linha "+(yyline+1)); return YYEOF; }
