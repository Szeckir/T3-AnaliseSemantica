import java.util.LinkedHashMap;
import java.util.ArrayList;

/**
 * Descritor de um metodo: tipo de retorno, parametros (ordenados) e
 * variaveis locais. Define o escopo mais interno na resolucao de
 * identificadores (local -> parametro -> atributo da classe).
 */
public class DescMetodo
{
   private String   nome;
   private TS_entry tipoRetorno;
   private int      linhaDecl;   // linha onde foi declarado (p/ erros de override)
   private LinkedHashMap<String, TS_entry> parametros; // ordem preservada p/ checar chamadas
   private LinkedHashMap<String, TS_entry> locais;

   public DescMetodo(String nome, TS_entry tipoRetorno) {
      this.nome        = nome;
      this.tipoRetorno = tipoRetorno;
      this.parametros  = new LinkedHashMap<String, TS_entry>();
      this.locais      = new LinkedHashMap<String, TS_entry>();
   }

   public String   getNome()        { return nome;        }
   public TS_entry getTipoRetorno() { return tipoRetorno; }
   public int      getLinhaDecl()   { return linhaDecl;   }
   public void     setLinhaDecl(int ln) { this.linhaDecl = ln; }

   public boolean temParametro(String n) { return parametros.containsKey(n); }
   public boolean temLocal(String n)     { return locais.containsKey(n);     }

   public void addParametro(String n, TS_entry t) { parametros.put(n, t); }
   public void addLocal(String n, TS_entry t)     { locais.put(n, t);     }

   // resolucao: local primeiro, depois parametro; null se nao encontrado
   public TS_entry resolve(String n) {
      if (locais.containsKey(n))     return locais.get(n);
      if (parametros.containsKey(n)) return parametros.get(n);
      return null;
   }

   // tipos dos parametros na ordem de declaracao (p/ checar chamada)
   public ArrayList<TS_entry> tiposParametros() {
      return new ArrayList<TS_entry>(parametros.values());
   }

   public int numParametros() { return parametros.size(); }

   public String assinatura() {
      StringBuilder sb = new StringBuilder(nome + "(");
      boolean primeiro = true;
      for (TS_entry t : parametros.values()) {
         if (!primeiro) sb.append(", ");
         sb.append(t);
         primeiro = false;
      }
      sb.append("): ").append(tipoRetorno == null ? "void" : tipoRetorno);
      return sb.toString();
   }
}
