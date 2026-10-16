#!/bin/sh
# Mede a velocidade do modelo (llama-bench) com a imagem atual do llm.
# Para o servidor durante o teste, para não disputar CPU, e sobe de novo no fim.
# Uso: scripts/bench.sh
set -eu
cd "$(dirname "$0")/.."

THREADS=$(grep -E '^THREADS=' .env 2>/dev/null | cut -d= -f2)
MODEL_FILE=Ternary-Bonsai-2-4B-PQ2_0.gguf

docker compose stop llm
trap 'docker compose start llm' EXIT

# pp512: leitura de um prompt de 512 tokens. tg128: geração de 128 tokens.
docker compose run --rm --no-deps --entrypoint /opt/llama/llama-bench llm \
  -m "/models/$MODEL_FILE" -t "${THREADS:-2}" -fa 1 -p 512 -n 128 -r 3
