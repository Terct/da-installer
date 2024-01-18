#!/bin/bash

# Função para validar a chave com qualquer quantidade de caracteres
function validarChave() {
  local chave=$1

  # Verifica se a chave não está vazia
  if [ -n "$chave" ]; then
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

      # Constrói a URL com os parâmetros
      url="https://installer.dagestao.com/install"
      case $app_opcao in
        1) url+="?app=typebot&key=$chave_instalacao" ;;
        2) url+="?app=n8n&key=$chave_instalacao" ;;
        3) url+="?app=evolution&key=$chave_instalacao" ;;
        4) url+="?app=rabbitmq&key=$chave_instalacao" ;;
        5) url+="?app=chatwoot&key=$chave_instalacao" ;;
        *) echo "Opção inválida." ;;
      esac

      # Realiza a instalação com base na opção escolhida
      if [ -n "$url" ]; then

        seu_ip=$(hostname -I | cut -d' ' -f1)
        bash -c "$(curl -fsSL $url | bash -s $seu_ip $chave_instalacao)"

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