#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Função para validar a chave com qualquer quantidade de caracteres
function validarChave() {
  local chave=$1

  # Verifica se a chave não está vazia
  if [ -n "$chave" ]; then
    return 0 # Chave válida
  else
    return 1 # Chave inválida
  fi
}

# Exibe as opções para o usuário

echo -e "${YELLOW}Escolha uma opção:"
echo "1. Instalar"
echo -e "2. Desinstalar${NC}"


# Lê a opção escolhida pelo usuário
read -p "opção: " opcao
echo ""

# Verifica a opção escolhida
case $opcao in
1) # Opção de instalação
  echo -e "${YELLOW}Digite sua chave de instalação.${NC}"

  read -p "chave: " chave_instalacao
  echo ""

  # Valida a chave
  if validarChave "$chave_instalacao"; then

    echo -e "${YELLOW}Escolha uma aplicação para instalar:"
    echo "1. Typebot"
    echo "2. n8n"
    echo "3. Evolution"
    echo "4. RabbitMQ"
    echo "5. Chatwoot"
    echo -e "${NC}"

    # Lê a opção de aplicação escolhida
    read -p "opção: " app_opcao
    echo ""

    # Constrói a URL com os parâmetros

    url="https://installer.dagestao.com/subscription-key"

    case $app_opcao in
    1) app_nome="typebot" ;;
    2) app_nome="n8n" ;;
    3) app_nome="evolution" ;;
    4) app_nome="rabbitmq" ;;
    5) app_nome="chatwoot" ;;
    *) echo "Opção inválida." ;;
    esac

    # Realiza a instalação com base na opção escolhida
    if [ -n "$url" ]; then

      seu_ip=$(hostname -I | cut -d' ' -f1)

      bash -c "$(curl -fsSL "$url?key=$chave_instalacao&ip=$seu_ip&app=$app_nome")"

    else
      echo "Opção inválida."
    fi
  else
    echo "Chave inválida. Operação cancelada."
  fi
  ;;

2) # Opção de desinstalação
  echo "Escolha uma aplicação para desinstalar:"
  echo "1. Typebot"
  echo "2. n8n"
  echo "3. Evolution"
  echo "4. RabbitMQ"
  echo "5. Chatwoot"

  # Lê a opção de aplicação escolhida
  read app_opcao

  # Realiza a desinstalação com base na opção escolhida
  case $app_opcao in
  1) sudo apt remove typebot -y ;;
  2) sudo apt remove n8n -y ;;
  3) sudo apt remove evolution -y ;;
  4) sudo apt remove rabbitmq-server -y ;; # Desinstalação do RabbitMQ
  5) sudo apt remove chatwoot -y ;;
  *) echo "Opção inválida." ;;
  esac
  ;;

*) echo "Opção inválida." ;;
esac

echo "Operação concluída."
