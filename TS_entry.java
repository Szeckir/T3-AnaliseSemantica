/**
 * Representa um TIPO da linguagem MiniJava.
 *
 * Tipos base (int, boolean, int[], erro) sao singletons criados no Parser.
 * Um tipo-classe e criado uma vez por classe declarada e guarda uma
 * referencia para o seu DescClasse (usado no despacho de metodos).
 */
public class TS_entry
{
   private String    id;          // nome do tipo: "int", "boolean", "int[]", "erro" ou nome da classe
   private ClasseID  classe;      // TipoBase para tipos base; NomeStruct para tipo-classe
   private DescClasse classeRef;  // != null somente para tipo-classe

   // construtor para tipos base (int, boolean, int[], erro)
   public TS_entry(String umId, ClasseID umaClasse) {
      id        = umId;
      classe    = umaClasse;
      classeRef = null;
   }

   // construtor para tipo-classe
   public TS_entry(String umId, ClasseID umaClasse, DescClasse ref) {
      id        = umId;
      classe    = umaClasse;
      classeRef = ref;
   }

   public String     getId()       { return id;        }
   public ClasseID   getClasse()   { return classe;    }
   public DescClasse getClasseRef(){ return classeRef; }
   public boolean    isClasse()    { return classeRef != null; }

   public String toString() { return id; }
}
