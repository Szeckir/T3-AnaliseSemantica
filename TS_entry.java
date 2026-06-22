
public class TS_entry
{
   private String    id;          
   private ClasseID  classe;      
   private DescClasse classeRef;  
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
