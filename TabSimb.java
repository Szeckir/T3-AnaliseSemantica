import java.util.LinkedHashMap;

public class TabSimb
{
   private LinkedHashMap<String, DescClasse> classes;

   public TabSimb() {
      classes = new LinkedHashMap<String, DescClasse>();
   }

   public boolean    temClasse(String nome) { return classes.containsKey(nome); }
   public void       addClasse(DescClasse c) { classes.put(c.getNome(), c);     }
   public DescClasse getClasse(String nome)  { return classes.get(nome);        }

   // listagem final da tabela de simbolos
   public void listar() {
      System.out.println("\n=================== TABELA DE SIMBOLOS ===================");
      for (DescClasse c : classes.values()) {
         String h = c.getSuperclasse() == null ? "" : " extends " + c.getSuperclasse().getNome();
         System.out.println("\nClasse: " + c.getNome() + h);

         for (java.util.Map.Entry<String, TS_entry> a : c.getAtributos().entrySet())
            System.out.println("   atributo  " + String.format("%-12s", a.getKey()) + ": " + a.getValue());

         for (DescMetodo m : c.getMetodos().values())
            System.out.println("   metodo    " + m.assinatura());
      }
      System.out.println("\n==========================================================");
   }
}
