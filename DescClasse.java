import java.util.LinkedHashMap;

/**
 * Descritor de uma classe: seus atributos (campos) e metodos.
 * Define o escopo de classe na resolucao de identificadores.
 */
public class DescClasse
{
   private String   nome;
   private TS_entry tipo;        // o tipo-classe correspondente (instancias desta classe)
   private DescClasse superclasse;   // null se nao herda (suporte a polimorfismo)
   private LinkedHashMap<String, TS_entry>   atributos;
   private LinkedHashMap<String, DescMetodo> metodos;

   public DescClasse(String nome) {
      this.nome        = nome;
      this.superclasse = null;
      this.atributos   = new LinkedHashMap<String, TS_entry>();
      this.metodos     = new LinkedHashMap<String, DescMetodo>();
      // o tipo-classe aponta de volta para este descritor
      this.tipo        = new TS_entry(nome, ClasseID.NomeStruct, this);
   }

   public String     getNome()        { return nome;        }
   public TS_entry   getTipo()        { return tipo;        }   // tipo usado p/ objetos desta classe
   public DescClasse getSuperclasse() { return superclasse; }
   public void       setSuperclasse(DescClasse s) { this.superclasse = s; }

   // ---- atributos: versao "propria" (so esta classe) p/ checagem de duplicacao ----
   public boolean  temAtributo(String n) { return atributos.containsKey(n); }
   public void     addAtributo(String n, TS_entry t) { atributos.put(n, t); }
   public TS_entry getAtributo(String n) { return atributos.get(n); }

   // ---- atributos: versao "visivel" (sobe na cadeia de heranca) ----
   public boolean temAtributoVisivel(String n) {
      for (DescClasse c = this; c != null; c = c.superclasse)
         if (c.atributos.containsKey(n)) return true;
      return false;
   }
   public TS_entry getAtributoVisivel(String n) {
      for (DescClasse c = this; c != null; c = c.superclasse)
         if (c.atributos.containsKey(n)) return c.atributos.get(n);
      return null;
   }

   // ---- metodos: versao "propria" (so esta classe) p/ checagem de duplicacao ----
   public boolean    temMetodo(String n) { return metodos.containsKey(n); }
   public void       addMetodo(DescMetodo m) { metodos.put(m.getNome(), m); }
   public DescMetodo getMetodo(String n) { return metodos.get(n); }

   // ---- metodos: versao "visivel" (sobe na cadeia de heranca) ----
   public DescMetodo getMetodoVisivel(String n) {
      for (DescClasse c = this; c != null; c = c.superclasse)
         if (c.metodos.containsKey(n)) return c.metodos.get(n);
      return null;
   }

   public LinkedHashMap<String, TS_entry>   getAtributos() { return atributos; }
   public LinkedHashMap<String, DescMetodo> getMetodos()   { return metodos;   }
}
