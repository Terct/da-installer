#!/bin/bash

echo -e "\033[1;32m    ____     ___        ___                ______          __            \033[0m"
echo -e "\033[1;32m   / __ \   ( _ )      /   |              / ____/__  _____/ /_____ _____ \033[0m"
echo -e "\033[1;32m  / / / /  / __ \/|   / /| |    ______   / / __/ _ \/ ___/ __/ __  / __ \ \033[0m"
echo -e "\033[1;32m / /_/ /  / /_/  <   / ___ |   /_____/  / /_/ /  __(__  ) /_/ /_/ / /_/ / \033[0m"
echo -e "\033[1;32m/_____/   \____/\/  /_/  |_|            \____/\___/____/\__/\__,_/\____/  \033[0m"


GPG_FILE="/etc/apt/keyrings/docker.gpg"

# Verifica se o arquivo GPG já existe
if [ ! -f "$GPG_FILE" ]; then

    # Adicionando a chave GPG e o repositório do Docker
    echo -e "\n\033[1;34m[INFO]\033[0m Adicionando a chave GPG e o repositório do Docker..."
    sudo apt-get update > /dev/null
    sudo apt-get install ca-certificates curl gnupg > /dev/null
    sudo install -m 0755 -d /etc/apt/keyrings > /dev/null
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "$GPG_FILE" > /dev/null
    sudo chmod a+r "$GPG_FILE" > /dev/null

    # Adicionando o repositório ao Apt sources
    echo -e "\n\033[1;34m[INFO]\033[0m Adicionando o repositório ao Apt sources..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=$GPG_FILE] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update > /dev/null
else
    echo -e "\033[1;32m - Verificação Completa\033[0m"
fi


# Instalação adicional do Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y > /dev/null
# Verifica se a rede Docker "dagestao_network" existe
if [[ ! "$(docker network ls -q -f name=dagestao_network)" ]]; then
    # Pergunta ao usuário se deseja instalar a rede Docker
    read -p "A rede Docker 'dagestao_network' não foi encontrada. Deseja instalá-la? (y/n): " install_network

    if [[ $install_network == "y" || $install_network == "yes" ]]; then
        # Executa o comando de instalação
        bash -c "$(curl -fsSL https://shell.dagestao.com/installer/treafik-installer.sh)"
    else
        # Finaliza o script
        echo "Operação abortada."
        exit 1
    fi
fi

# Exibe as opções para o usuário
echo "Escolha uma opção:"
echo "1. Instalar"
echo "2. Desinstalar"

# Lê a opção escolhida pelo usuário
read opcao

# Verifica a opção escolhida
case $opcao in
  1) # Opção de instalação
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
