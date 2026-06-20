#!/bin/sh
# Roda a analise semantica sobre todos os casos de teste .mjava de uma vez,
# em vez de chamar "java Parser <arquivo>" um por um.
# Uso: ./testar.sh            (roda todos os *.mjava)
#      ./testar.sh erro       (roda so os que comecam com "erro")

cd "$(dirname "$0")" || exit 1

# Garante que o Parser esta compilado antes de rodar os testes.
if [ ! -f Parser.class ]; then
    echo ">> Parser.class nao encontrado, compilando (make build)..."
    make build || { echo "FALHA no build."; exit 1; }
    echo
fi

# Filtro opcional pelo prefixo do nome do arquivo (default: todos).
PREFIXO="${1:-}"
ARQUIVOS=$(ls ${PREFIXO}*.mjava 2>/dev/null | sort)

if [ -z "$ARQUIVOS" ]; then
    echo "Nenhum arquivo ${PREFIXO}*.mjava encontrado."
    exit 1
fi

for f in $ARQUIVOS; do
    echo "============================================================"
    echo ">> $f"
    echo "============================================================"
    java Parser "$f"
    echo
done
