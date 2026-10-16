#!/bin/sh
# Preparação única da VM Ubuntu 24.04 na Oracle Cloud. Pode rodar de novo sem problema.
# Uso: sudo sh scripts/vps-setup.sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode com sudo." >&2
  exit 1
fi
ADMIN_USER="${SUDO_USER:-ubuntu}"

echo "==> Atualizando o sistema"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl git openssl unattended-upgrades iptables-persistent
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "==> SSH só com chave"
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'CONF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
CONF
systemctl reload ssh

# A imagem Ubuntu da OCI rejeita tudo exceto a 22 no INPUT. Abre 80/443 antes
# do REJECT. Feito antes do Docker para não salvar as regras dele no rules.v4.
echo "==> Firewall do host (80/443)"
opened=0
for rule in "tcp 80" "tcp 443" "udp 443"; do
  set -- $rule
  if ! iptables -C INPUT -p "$1" --dport "$2" -j ACCEPT 2>/dev/null; then
    pos=$(iptables -L INPUT --line-numbers -n | awk '/REJECT/ {print $1; exit}')
    iptables -I INPUT "${pos:-1}" -p "$1" --dport "$2" -m state --state NEW -j ACCEPT
    opened=1
  fi
done
if [ "$opened" -eq 1 ] && ! command -v docker >/dev/null; then
  netfilter-persistent save
fi

echo "==> Docker"
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
usermod -aG docker "$ADMIN_USER"

echo
echo "Pronto. Saia e entre de novo no SSH para usar o docker sem sudo."
