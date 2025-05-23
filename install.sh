#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script deve ser executado como root."
  exit 1
fi

usage() {
  echo "Uso: $0 {install|start|stop|restart|status}"
  exit 1
}

INSTALL_DIR="/opt/celestrox/bin"
SERVICE_NAME="celestrox"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
DOWNLOAD_URL_BASE="https://raw.githubusercontent.com/alexdsgmoura/celestrox-binaries/refs/heads/main"

# Detecta arquitetura e define BIN_NAME
detect_arch() {
  local arch
  case "$(uname -m)" in
    x86_64)   arch=amd64   ;;
    i386|i486|i586|i686) arch=386    ;;
    armv7l)   arch=armv7   ;;
    aarch64)  arch=arm64   ;;
    *)
      echo "Arquitetura não suportada: $(uname -m)"
      exit 1
      ;;
  esac
  BIN_NAME="celestrox_${arch}"
}

# Função que remove qualquer rastro da instalação anterior
cleanup() {
  echo ">>> Removendo instalação anterior (se existir)..."

  # Para e desabilita o serviço, se estiver registrado
  if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
    systemctl stop   "$SERVICE_NAME" --quiet 2>/dev/null || true
    systemctl disable "$SERVICE_NAME" --quiet 2>/dev/null || true
  fi

  # Remove binário e unit file
  rm -f "${INSTALL_DIR}/${SERVICE_NAME}" \
        "$SERVICE_FILE"

  # Recarrega o systemd para limpar caches
  systemctl daemon-reload --quiet 2>/dev/null || true

  echo ">>> Limpeza concluída."
}

if [ $# -eq 0 ]; then
  usage
fi

COMMAND="$1"
shift

case "$COMMAND" in

  install)
    detect_arch
    cleanup

    echo ">>> Instalando Celestrox (${BIN_NAME}) em ${INSTALL_DIR}..."

    mkdir -p "$INSTALL_DIR"
    DOWNLOAD_URL="${DOWNLOAD_URL_BASE}/${BIN_NAME}"

    if command -v wget >/dev/null 2>&1; then
      wget -q -O "${INSTALL_DIR}/${SERVICE_NAME}" "$DOWNLOAD_URL"
    else
      curl -fsSL "$DOWNLOAD_URL" -o "${INSTALL_DIR}/${SERVICE_NAME}"
    fi

    chmod 755 "${INSTALL_DIR}/${SERVICE_NAME}"

    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Extra features of Celestrox system
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${SERVICE_NAME}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload --quiet
    systemctl enable "$SERVICE_NAME" --quiet
    systemctl start  "$SERVICE_NAME" --quiet

    echo ">>> Celestrox instalado e iniciado com sucesso."
    ;;

  start)
    systemctl start "$SERVICE_NAME" --quiet
    ;;

  stop)
    systemctl stop "$SERVICE_NAME" --quiet
    ;;

  restart)
    systemctl restart "$SERVICE_NAME" --quiet
    ;;

  status)
    systemctl status "$SERVICE_NAME"
    ;;

  *)
    usage
    ;;
esac
