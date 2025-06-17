#!/bin/bash
set -e

SERVICE_NAME="celestrox"
INSTALL_DIR="/opt/celestrox/bin"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
DOWNLOAD_URL_BASE="https://raw.githubusercontent.com/alexdsgmoura/celestrox-binaries/refs/heads/main"
PORT=49152  # Porta que será liberada no firewall

# Função para exibir uso
usage() {
  echo "Uso: $0 {install|start|stop|restart|status}"
  exit 1
}

# Verifica se é root
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root."
    exit 1
  fi
}

# Detecta arquitetura
detect_arch() {
  case "$(uname -m)" in
    x86_64)   BIN_NAME="celestrox_amd64" ;;
    i386|i486|i586|i686) BIN_NAME="celestrox_386" ;;
    armv7l)   BIN_NAME="celestrox_armv7" ;;
    aarch64)  BIN_NAME="celestrox_arm64" ;;
    *) echo "Arquitetura não suportada: $(uname -m)"; exit 1 ;;
  esac
}

# Limpa instalações anteriores
cleanup() {
  echo ">>> Removendo instalação anterior (se existir)..."
  systemctl stop "$SERVICE_NAME" --quiet 2>/dev/null || true
  systemctl disable "$SERVICE_NAME" --quiet 2>/dev/null || true
  rm -f "${INSTALL_DIR}/${SERVICE_NAME}" "$SERVICE_FILE"
  systemctl daemon-reload --quiet 2>/dev/null || true
}

# Verifica compatibilidade mínima
check_environment() {
  if ! command -v systemctl &>/dev/null; then
    echo "Este sistema não suporta systemd. Abortando."
    exit 1
  fi

  if [ ! -f /etc/os-release ]; then
    echo "Sistema operacional desconhecido. Abortando."
    exit 1
  fi
}

# Ajusta o SELinux, se estiver ativado
adjust_selinux() {
  if command -v getenforce &>/dev/null; then
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" != "Disabled" ]; then
      echo "SELinux está ativado: $SELINUX_STATUS. Ajustando política..."
      semanage port -a -t http_port_t -p tcp $PORT 2>/dev/null || true
    fi
  fi
}

# Libera a porta no firewall (iptables ou firewalld)
configure_firewall() {
  if systemctl is-active firewalld &>/dev/null; then
    echo "Configurando firewalld..."
    firewall-cmd --permanent --add-port=${PORT}/tcp || true
    firewall-cmd --reload || true
  elif command -v iptables &>/dev/null; then
    echo "Configurando iptables..."
    iptables -C INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || \
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
    if command -v netfilter-persistent &>/dev/null; then
      netfilter-persistent save
    fi
  fi
}

# Cria e ativa o serviço
setup_service() {
  echo ">>> Instalando Celestrox (${BIN_NAME})..."

  mkdir -p "$INSTALL_DIR"
  DOWNLOAD_URL="${DOWNLOAD_URL_BASE}/${BIN_NAME}"

  if command -v wget >/dev/null 2>&1; then
    wget -q -O "${INSTALL_DIR}/${SERVICE_NAME}" "$DOWNLOAD_URL"
  else
    curl -fsSL "$DOWNLOAD_URL" -o "${INSTALL_DIR}/${SERVICE_NAME}"
  fi

  chmod +x "${INSTALL_DIR}/${SERVICE_NAME}"

  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Celestrox Background Service
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${SERVICE_NAME}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME"
  systemctl start "$SERVICE_NAME"

  echo ">>> Celestrox instalado e iniciado com sucesso."
}

# Executa a instalação
run_install() {
  detect_arch
  check_environment
  cleanup
  adjust_selinux
  configure_firewall
  setup_service
}

# Início do script
check_root

case "$1" in
  install)  run_install ;;
  start)    systemctl start "$SERVICE_NAME" ;;
  stop)     systemctl stop "$SERVICE_NAME" ;;
  restart)  systemctl restart "$SERVICE_NAME" ;;
  status)   systemctl status "$SERVICE_NAME" ;;
  *)        usage ;;
esac
