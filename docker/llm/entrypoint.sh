#!/bin/sh
# Baixa o modelo no volume /models na primeira subida e inicia o llama-server.
set -eu

: "${MODEL_REPO:=prism-ml/Ternary-Bonsai-2-4B-gguf}"
: "${MODEL_FILE:=Ternary-Bonsai-2-4B-PQ2_0.gguf}"
: "${THREADS:=2}"
: "${CTX_SIZE:=8192}"
: "${PARALLEL:=1}"
: "${TEMPERATURE:=0.2}"
API_KEYS_FILE=/run/secrets/api_keys
MODEL_PATH="/models/${MODEL_FILE}"

if [ ! -s "$API_KEYS_FILE" ]; then
  echo "Nenhuma chave de API em ${API_KEYS_FILE}. Rode scripts/new-api-key.sh." >&2
  exit 1
fi

if [ ! -f "$MODEL_PATH" ]; then
  echo "Baixando ${MODEL_REPO}/${MODEL_FILE}..."
  curl -fL --retry 3 -o "${MODEL_PATH}.part" \
    "https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}"
  mv "${MODEL_PATH}.part" "$MODEL_PATH"
fi

# Parâmetros recomendados pela PrismML para o modo sem thinking.
# Escuta em 0.0.0.0 só dentro da rede do Docker; a porta não é publicada no host.
exec /opt/llama/llama-server \
  -m "$MODEL_PATH" --alias bonsai \
  --host 0.0.0.0 --port 8080 \
  --api-key-file "$API_KEYS_FILE" \
  -t "$THREADS" -c "$CTX_SIZE" -np "$PARALLEL" -fa on \
  --reasoning off \
  --temp "$TEMPERATURE" --top-p 0.8 --top-k 20 --min-p 0 \
  --presence-penalty 1.5 --repeat-penalty 1.0 --repeat-last-n 64 \
  "$@"
