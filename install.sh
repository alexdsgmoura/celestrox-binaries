#!/bin/bash
set -e

# Verifica se é root
if [ "$(id -u)" -ne 0 ]; then
  exit 1
fi

# Função de uso
usage() {
  exit 1
}

INSTALL_DIR="/opt/celestrox/bin"
SERVICE_NAME="celestrox"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
DOWNLOAD_URL_BASE="https://raw.githubusercontent.com/alexdsgmoura/celestrox-binaries/refs/heads/main"

# Detecta a arquitetura e define o nome do binário
detect_arch() {
  ARCH_RAW=$(uname -m)
  case "$ARCH_RAW" in
    x86_64)
      ARCH="amd64"
      ;;
    i386|i486|i586|i686)
      ARCH="386"
      ;;
    armv7l)
      ARCH="armv7"
      ;;
    aarch64)
      ARCH="arm64"
      ;;
    *)
      exit 1
      ;;
  esac
  BIN_NAME="celestrox_${ARCH}"
}

# Verifica se um comando foi passado
if [ $# -eq 0 ]; then
  usage
fi

COMMAND="$1"

case "$COMMAND" in
  install)
    detect_arch
    mkdir -p "$INSTALL_DIR" > /dev/null 2>&1
    DOWNLOAD_URL="${DOWNLOAD_URL_BASE}/${BIN_NAME}"
    
    if command -v wget >/dev/null 2>&1; then
      wget -q -O "${INSTALL_DIR}/${SERVICE_NAME}" "$DOWNLOAD_URL" > /dev/null 2>&1 || exit 1
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL "$DOWNLOAD_URL" -o "${INSTALL_DIR}/${SERVICE_NAME}" > /dev/null 2>&1 || exit 1
    else
      exit 1
    fi

    chmod 755 "${INSTALL_DIR}/${SERVICE_NAME}" > /dev/null 2>&1

    # Cria o arquivo de serviço do systemd
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Serviço Celestrox - Recursos Extras do Celestrox
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${SERVICE_NAME}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Recarrega o systemd e gerencia o serviço de forma silenciosa
    systemctl daemon-reload --quiet > /dev/null 2>&1
    systemctl enable "$SERVICE_NAME" --quiet > /dev/null 2>&1
    systemctl start "$SERVICE_NAME" --quiet > /dev/null 2>&1
    ;;

  start)
    systemctl start "$SERVICE_NAME" --quiet > /dev/null 2>&1
    ;;

  stop)
    systemctl stop "$SERVICE_NAME" --quiet > /dev/null 2>&1
    ;;

  restart)
    systemctl restart "$SERVICE_NAME" --quiet > /dev/null 2>&1
    ;;

  status)
    systemctl status "$SERVICE_NAME" --quiet > /dev/null 2>&1
    ;;

  *)
    usage
    ;;
esac
