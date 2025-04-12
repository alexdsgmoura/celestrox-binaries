#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Seu servidor precisa estar em ambiente root"
  exit 1
fi

# Função de uso
usage() {
  echo "Uso: $0 {install|start|stop|restart|status}"
  exit 1
}

INSTALL_DIR="/opt/celestrox/bin"
SERVICE_NAME="celestrox"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Base URL para download dos binários (ajuste para o local correto dos seus binários)
DOWNLOAD_URL_BASE="https://raw.githubusercontent.com/alexdsgmoura/celestrox-binaries/refs/heads/main"

# Detecta a arquitetura do sistema e define o nome do arquivo a ser baixado
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
      echo "Arquitetura '$ARCH_RAW' não suportada."
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
    echo "Iniciando instalação..."
    detect_arch
    echo "Arquitetura detectada: $(uname -m) -> ${ARCH}"

    # Cria o diretório de instalação, se não existir
    mkdir -p "$INSTALL_DIR"

    # Constrói a URL do download
    DOWNLOAD_URL="${DOWNLOAD_URL_BASE}/${BIN_NAME}"
    echo "Baixando binário de: $DOWNLOAD_URL"
    
    # Baixa o binário utilizando wget ou curl, dependendo do que estiver disponível
    if command -v wget >/dev/null 2>&1; then
      wget -O "${INSTALL_DIR}/${SERVICE_NAME}" "$DOWNLOAD_URL" || {
        echo "Erro ao baixar o binário com wget."
        exit 1
      }
    elif command -v curl >/dev/null 2>&1; then
      curl -fsSL "$DOWNLOAD_URL" -o "${INSTALL_DIR}/${SERVICE_NAME}" || {
        echo "Erro ao baixar o binário com curl."
        exit 1
      }
    else
      echo "Nenhum dos comandos wget ou curl está instalado!"
      exit 1
    fi

    # Concede permissão de execução ao binário (755 - leitura e execução para todos, escrita para o dono)
    chmod 755 "${INSTALL_DIR}/${SERVICE_NAME}"
    echo "Binário instalado em ${INSTALL_DIR}/${SERVICE_NAME}"

    # Cria o arquivo de serviço do systemd
    echo "Criando serviço systemd em ${SERVICE_FILE}"
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

    # Recarrega o systemd para reconhecer o novo serviço
    systemctl daemon-reload

    # Habilita o serviço para iniciar com o sistema
    systemctl enable "$SERVICE_NAME"

    # Inicia o serviço imediatamente
    systemctl start "$SERVICE_NAME"

    echo "Instalação concluída! Use '$0 start|stop|restart|status' para gerenciar o serviço."
    ;;

  start)
    systemctl start "$SERVICE_NAME"
    echo "Serviço ${SERVICE_NAME} iniciado."
    ;;

  stop)
    systemctl stop "$SERVICE_NAME"
    echo "Serviço ${SERVICE_NAME} parado."
    ;;

  restart)
    systemctl restart "$SERVICE_NAME"
    echo "Serviço ${SERVICE_NAME} reiniciado."
    ;;

  status)
    systemctl status "$SERVICE_NAME"
    ;;

  *)
    usage
    ;;
esac
