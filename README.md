# ai-server

Servidor de IA de teste: modelo ternário **Ternary-Bonsai-2-4B** (PrismML) rodando no
`llama-server`, atrás do Caddy (HTTPS automático) e protegido por chaves de API.
A API é compatível com OpenAI (`/v1/chat/completions`, `/v1/models`).

```
internet ──443──> caddy (TLS) ──rede docker──> llm:8080 (llama-server + chaves de API)
```

Nenhum segredo vai para o git: as chaves ficam em `secrets/api-keys` e a configuração
em `.env`, ambos só no servidor.

## 1. Oracle Cloud (console)

1. Criar instância **VM.Standard.A1.Flex**, 2 OCPU / 12 GB, imagem **Ubuntu 24.04**,
   com a sua chave SSH pública.
2. Reservar um IP público e associar à VM.
3. Na Security List / NSG da subnet, regras de entrada:
   - TCP 22 só do seu IP;
   - TCP 80, TCP 443 e UDP 443 de `0.0.0.0/0`.
4. Domínio é opcional: com `DOMAIN=<IP>` o Caddy emite um certificado
   Let's Encrypt para o próprio IP (perfil shortlived, renovado sozinho).

## 2. Na VPS

```sh
ssh ubuntu@<ip>
git clone https://github.com/samantunes/ai-server.git
cd ai-server
sudo sh scripts/vps-setup.sh   # atualizações, SSH só com chave, firewall, Docker
exit                           # reentrar para o grupo docker valer
```

```sh
ssh ubuntu@<ip>
cd ai-server
cp .env.example .env && nano .env      # DOMAIN=<IP público>
scripts/new-api-key.sh minha-app       # guarde a chave exibida
docker compose up -d --build           # 1ª vez baixa o modelo (~1,1 GB)
docker compose logs -f llm             # espere "model loaded"
```

## 3. Testar

```sh
curl https://<DOMAIN>/v1/models                       # 401
curl https://<DOMAIN>/v1/chat/completions \
  -H "Authorization: Bearer <chave>" -H "Content-Type: application/json" \
  -d '{"model":"bonsai","messages":[{"role":"user","content":"Oi"}]}'
```

Nas aplicações, qualquer SDK compatível com OpenAI funciona. Com o LiteLLM:

```python
import litellm

r = litellm.completion(
    model="openai/bonsai",              # prefixo openai/ = servidor compatível com OpenAI
    api_base="https://<DOMAIN>/v1",
    api_key="sk-...",
    messages=[{"role": "user", "content": "Oi"}],
    stream=True,
    timeout=300,                        # CPU lenta: prompts longos demoram
)
for chunk in r:
    print(chunk.choices[0].delta.content or "", end="")
```

A temperatura padrão é `TEMPERATURE` no `.env` (0.2); o cliente pode sobrescrever.

## Operação

| Tarefa | Comando |
|---|---|
| Nova chave | `scripts/new-api-key.sh <app> && docker compose restart llm` |
| Revogar chave | apagar a linha em `secrets/api-keys` e `docker compose restart llm` |
| Atualizar código | `git pull && docker compose up -d --build` |
| Logs | `docker compose logs -f` |
| Medir velocidade | `scripts/bench.sh` |
| Compilar para a CPU da VPS | `LLAMA_SOURCE=native` no `.env` e `docker compose up -d --build` |

## Teste local

O mesmo `compose.yaml` roda na sua máquina (o Dockerfile escolhe o binário x64 ou arm64):
`.env` com `DOMAIN=localhost`, `CADDYFILE=Caddyfile.local`, `HTTP_PORT=8180`, `HTTPS_PORT=8443` e use `curl -k https://localhost:8443/...`.
