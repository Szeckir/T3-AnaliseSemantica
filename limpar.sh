#!/bin/sh
# Apaga tudo o que e' gerado automaticamente pelo build,
# deixando apenas os arquivos-fonte do trabalho.
# Uso: ./limpar.sh   (rode de dentro da pasta do projeto)

cd "$(dirname "$0")" || exit 1

rm -f Parser.java Yylex.java   # gerados por byaccj / jflex
rm -f *.class                  # bytecode compilado
rm -f y.output                 # log de debug do byacc
rm -f *~                       # backups de editor

echo "Limpeza concluida. Arquivos-fonte preservados."
