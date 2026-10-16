#!/bin/sh
# Gera uma chave de API e adiciona em secrets/api-keys.
# Uso: scripts/new-api-key.sh <nome-da-aplicacao>
# Para revogar: apague a linha da chave no arquivo e reinicie o llm.
set -eu

NAME="${1:?uso: $0 <nome-da-aplicacao>}"
DIR="$(cd "$(dirname "$0")/.." && pwd)/secrets"
FILE="$DIR/api-keys"

mkdir -p "$DIR"
# O diretório 700 protege as chaves de outros usuários do host;
# o arquivo precisa ser legível pelo usuário do container (uid 10001).
chmod 700 "$DIR"
touch "$FILE"
chmod 644 "$FILE"

KEY="sk-$(openssl rand -hex 32)"
printf '# %s %s\n%s\n' "$NAME" "$(date -u +%Y-%m-%dT%H:%MZ)" "$KEY" >> "$FILE"

echo "Chave para '$NAME' (guarde agora, ela não será mostrada de novo):"
echo "$KEY"
echo
echo "Aplique com: docker compose restart llm"
