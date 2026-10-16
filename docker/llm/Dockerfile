# llama-server do fork da PrismML (necessário para os modelos ternários Bonsai).
# Escolhe o binário pela arquitetura: arm64 na VPS Ampere, x64 para testar local.
FROM ubuntu:24.04

ARG TARGETARCH
ARG PRISM_RELEASE=prism-b10777-e3de715

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl libgomp1 libssl3 \
 && rm -rf /var/lib/apt/lists/*

RUN case "$TARGETARCH" in \
      amd64) ARCH=x64 ;; \
      arm64) ARCH=arm64 ;; \
      *) echo "arquitetura não suportada: $TARGETARCH" >&2; exit 1 ;; \
    esac \
 && mkdir -p /opt/llama \
 && curl -fsSL "https://github.com/PrismML-Eng/llama.cpp/releases/download/${PRISM_RELEASE}/llama-${PRISM_RELEASE}-bin-ubuntu-${ARCH}.tar.gz" \
    | tar -xz -C /opt/llama --strip-components=1

RUN useradd --system --uid 10001 --home-dir /models --shell /usr/sbin/nologin llm \
 && mkdir -p /models && chown llm:llm /models

COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER llm
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=10m \
  CMD curl -fsS http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
