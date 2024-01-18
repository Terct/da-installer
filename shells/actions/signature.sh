#!/bin/bash


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

sleep 10

while true; do
    read -p "Você concorda com os termos e condições? (Digite 'yes' para concordar, 'no' para sair): " concordar

    if [ "$concordar" = "yes" ]; then
        realizar_instalacao
        break  # Sai do loop se a resposta for 'yes'
    elif [ "$concordar" = "no" ]; then
        echo "Você optou por não concordar com os termos. Instalação cancelada."
        exit 1
    else
        echo "Resposta não reconhecida. Por favor, digite 'yes' ou 'no'."
    fi
done


}



# Função para realizar a instalação
realizar_instalacao() {
    echo "Iniciando a assinatura..."


     url="https://installer.dagestao.com/update-key-used?ip=$ip&key=$key"

    bash -c "$(curl -fsSL $url)"

    url2="https://installer.dagestao.com/install?app=$app&key=$key"

    bash -c "$(curl -fsSL $url2)"

}

# Função principal
instalador() {
    mostrar_termos

    # Coloque aqui a lógica para assinatura de chave e verificação de expiração

    
}

# Executar o instalador
instalador
