# llama-server do fork da PrismML (necessário para os modelos ternários Bonsai).
#
# LLAMA_SOURCE=release (padrão): binário pronto da release; já inclui variantes
#   para várias CPUs e escolhe a melhor ao iniciar.
# LLAMA_SOURCE=native: compila na própria máquina com -mcpu=native. A imagem só
#   roda em CPUs iguais à que compilou.
ARG LLAMA_SOURCE=release
ARG PRISM_RELEASE=prism-b10777-e3de715

FROM ubuntu:24.04 AS base
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl libgomp1 libssl3 \
 && rm -rf /var/lib/apt/lists/*

# Binário pronto: arm64 na VPS Ampere, x64 para testar local.
FROM base AS llama-release
ARG TARGETARCH
ARG PRISM_RELEASE
RUN case "$TARGETARCH" in \
      amd64) ARCH=x64 ;; \
      arm64) ARCH=arm64 ;; \
      *) echo "arquitetura não suportada: $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && mkdir -p /opt/llama \
 && curl -fsSL "https://github.com/PrismML-Eng/llama.cpp/releases/download/${PRISM_RELEASE}/llama-${PRISM_RELEASE}-bin-ubuntu-${ARCH}.tar.gz" \
    | tar -xz -C /opt/llama --strip-components=1

# Compilado na máquina, otimizado para a CPU dela.
FROM ubuntu:24.04 AS llama-build
ARG PRISM_RELEASE
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential cmake git ca-certificates libssl-dev \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "$PRISM_RELEASE" https://github.com/PrismML-Eng/llama.cpp /src
WORKDIR /src
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=ON -DBUILD_SHARED_LIBS=OFF \
      -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_UI=OFF \
 && cmake --build build -j"$(nproc)" --target llama-server llama-bench \
 && mkdir -p /opt/llama && cp build/bin/llama-server build/bin/llama-bench /opt/llama/

FROM base AS llama-native
COPY --from=llama-build /opt/llama /opt/llama

FROM llama-${LLAMA_SOURCE} AS final

RUN useradd --system --uid 10001 --home-dir /models --shell /usr/sbin/nologin llm \
 && mkdir -p /models && chown llm:llm /models

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER llm
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=10m \
  CMD curl -fsS http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
