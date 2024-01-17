#!/bin/bash

# Função para validar a chave
function validarChave() {
  local chave=$1
  local padrao="^[0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{12\}$"

  if [[ $chave =~ $padrao ]]; then
    return 0  # Chave válida
  else
    return 1  # Chave inválida
  fi
}

# Exibe as opções para o usuário
echo "Escolha uma opção:"
echo "1. Instalar"
echo "2. Desinstalar"

# Lê a opção escolhida pelo usuário
read opcao

# Verifica a opção escolhida
case $opcao in
  1) # Opção de instalação
    echo "Digite sua chave de instalação:"
    read chave_instalacao

    # Valida a chave
    if validarChave "$chave_instalacao"; then
      echo "Chave válida. Continuando com a instalação."

      echo "Escolha uma aplicação para instalar:"
      echo "1. Typebot"
      echo "2. n8n"
      echo "3. Evolution"
      echo "4. RabbitMQ"
      echo "5. Chatwoot"

      # Lê a opção de aplicação escolhida
      read app_opcao

      # Realiza a instalação com base na opção escolhida
      case $app_opcao in
        1) bash -c "$(curl -fsSL https://shell.dagestao.com/installer/typebot-installer.sh)" ;;
        2) bash -c "$(curl -fsSL https://shell.dagestao.com/installer/n8n-queue-installer.sh)" ;;
        3) bash -c "$(curl -fsSL https://shell.dagestao.com/installer/evolution-mongodb-installer.sh)" ;;
        4) sudo apt install rabbitmq-server -y ;; # Instalação do RabbitMQ
        5) sudo apt install chatwoot -y ;;
        *) echo "Opção inválida." ;;
      esac
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
    else
      echo "Chave inválida. Operação cancelada."
    fi
    ;;

  *) echo "Opção inválida." ;;
esac

echo "Operação concluída."
