#!/bin/bash

ip=$1
key=$2

# Função para exibir os termos e condições
mostrar_termos() {
    echo "Bem-vindo à instalação da aplicação XYZ."
    echo "Por favor, leia atentamente os termos e condições a seguir:"
    echo "1. Esta chave de instalação é válida apenas para a máquina atual."
    echo "2. A chave expira em 3 dias após a assinatura."
    echo "3. Você pode repetir a instalação várias vezes na mesma máquina."
    echo "4. Certifique-se de revisar cuidadosamente os parâmetros quando solicitado."
    echo "5. Não nos responsabilizamos por erros relacionados à instalação."
    echo ""
    echo "Ao prosseguir, você concorda com os termos e condições mencionados acima."
    echo ""
}

# Função para verificar se o usuário concorda com os termos
verificar_concordancia() {
    read -p "Você concorda com os termos e condições? (Digite 'yes' para concordar, 'no' para sair): " concordar
    if [ "$concordar" != "yes" ]; then
        echo "Você optou por não concordar com os termos. Instalação cancelada."
        exit 1
    fi
}

# Função para realizar a instalação
realizar_instalacao() {
    echo "Iniciando a assinatura..."

     url="https://installer.dagestao.com/install/update-key-used?ip=$ip&key=$key"

    bash -c "$(curl -fsSL $url)"

    echo "assinatura concluída com sucesso!"
}

# Função principal
instalador() {
    mostrar_termos
    verificar_concordancia

    # Coloque aqui a lógica para assinatura de chave e verificação de expiração

    realizar_instalacao
}

# Executar o instalador
instalador
