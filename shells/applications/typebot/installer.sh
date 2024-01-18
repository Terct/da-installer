#!/bin/bash

# Função para validar o formato de domínio
function validar_dominio() {
    local dominio=$1
    local regex="^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

    if [[ $dominio =~ $regex ]]; then
        echo "Domínio válido."
        return 0
    else
        echo "Domínio inválido. Por favor, tente novamente."
        return 1
    fi
}


# Função para validar o formato de e-mail
function validar_email() {
    local email=$1
    local regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"

    if [[ $email =~ $regex ]]; then
        echo "E-mail válido."
        return 0
    else
        echo "E-mail inválido. Por favor, tente novamente."
        return 1
    fi
}

# Solicitação de informações do usuário

while true; do
    read -p "Digite o domínio do painel (por exemplo, painel.typebot.com): " dominio_painel
    if [ -n "$dominio_painel" ] && validar_dominio "$dominio_painel"; then
        break
    fi
done

while true; do
    read -p "Digite o domínio do bot (por exemplo, bot.typebot.com): " dominio_bot
    if [ -n "$dominio_bot" ] && validar_dominio "$dominio_bot"; then
        break
    fi
done

while true; do
    read -p "Digite o domínio do banco de dados (por exemplo, db.typebot.com): " dominio_db
    if [ -n "$dominio_db" ] && validar_dominio "$dominio_db"; then
        break
    fi
done


while true; do
    read -p "Digite o domínio para o painel do banco de dados (por exemplo, minio.typebot.com): " dominio_api_db
    if [ -n "$dominio_api_db" ] && validar_dominio "$dominio_api_db"; then
        break
    fi
done

# Solicita o email do cliente e valida
while true; do
    read -p "Digite o seu e-mail: " client_email
    if [ -n "$client_email" ] && validar_email "$client_email"; then
        break
    fi
done



# Verifica se os subdomínios resolvem para os IPs locais da máquina
seu_ip=$(hostname -I | cut -d' ' -f1)  # Obtém o primeiro IP associado à máquina

# Verifica para painel
if [ "$(nslookup "$dominio_painel" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio para o painel não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "Dominio Verificado"
fi

# Verifica para bot
if [ "$(nslookup "$dominio_bot" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio para o bot não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "Dominio Verificado."
fi


# Verifica para minio
if [ "$(nslookup "$dominio_db" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio para o bando de dados não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "Dominio Verificado."
fi


# Verifica para minio
if [ "$(nslookup "$dominio_api_db" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio para o painel do bando de dados não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "Dominio Verificado."
fi


read -p "Digite a versão do Typebot que deseja usar: " versao_typebot

# Pergunta sobre a configuração do SMTP
read -p "Deseja configurar o SMTP? Digite "N" para usar o do Google (Digite 'sim' ou 'nao'): " configurar_smtp

if [ "$configurar_smtp" == "sim" ]; then
    read -p "Digite o usuário SMTP: " usuario_smtp
    read -p "Digite o host SMTP: " host_smtp
    read -p "Digite a porta SMTP (Pressione Enter para padrão 25): " porta_smtp
    porta_smtp=${porta_smtp:-25}
else
    usuario_smtp=${client_email}
    host_smtp="smtp.gmail.com"
    porta_smtp=25
fi

read -p "Digite a senha do smtp: " senha


# Cria o diretório se não existir
mkdir -p /opt/typebot/

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF > /opt/typebot/docker-compose.yml
version: "3.7"

services:
  typebot-db:
    image: postgres:13
    networks:
      - dagestao_network
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=typebot
      - POSTGRES_PASSWORD=typebot

  typebot_builder:
    image: baptistearno/typebot-builder:2.20.0
    networks:
      - dagestao_network
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - ENCRYPTION_SECRET=do+UspMmB/rewbX2K/rskFmtgGSSZ8Ta
      - DEFAULT_WORKSPACE_PLAN=UNLIMITED
      - NEXTAUTH_URL=https://$dominio_painel
      - NEXT_PUBLIC_VIEWER_URL=https://$dominio_bot
      - NEXTAUTH_URL_INTERNAL=http://localhost:3000
      - DISABLE_SIGNUP=false
      - ADMIN_EMAIL=$client_email
      - NEXT_PUBLIC_SMTP_FROM=='Suporte' <$client_email>
      - SMTP_AUTH_DISABLED=false
      - SMTP_USERNAME=$usuario_smtp
      - SMTP_PASSWORD=$senha
      - SMTP_HOST=$host_smtp
      - SMTP_PORT=$porta_smtp
      - SMTP_SECURE=true
      # Configurações do Typebot e Google Cloud
      #- GOOGLE_CLIENT_ID=
      #- GOOGLE_CLIENT_SECRET=
      # Configurações do Typebot e Minio
      - S3_ACCESS_KEY=OqCEOydCqDaVJ2eXw8TQ
      - S3_SECRET_KEY=ViK4TTnGK05LbY2kmbXLmwuW3uYeqtwvMEC9inFh
      - S3_BUCKET=typebot
      - S3_ENDPOINT=$dominio_db
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 1024M
      labels:
        - traefik.enable=true
        - traefik.http.routers.typebot_builder.rule=Host(\`$dominio_painel\`)
        - traefik.http.routers.typebot_builder.entrypoints=websecure
        - traefik.http.routers.typebot_builder.tls.certresolver=letsencryptresolver
        - traefik.http.services.typebot_builder.loadbalancer.server.port=3000
        - traefik.http.services.typebot_builder.loadbalancer.passHostHeader=true
        - traefik.http.routers.typebot_builder.service=typebot_builder


  typebot_viewer:
    image: baptistearno/typebot-viewer:2.20.0
    networks:
      - dagestao_network
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - ENCRYPTION_SECRET=do+UspMmB/rewbX2K/rskFmtgGSSZ8Ta
      - DEFAULT_WORKSPACE_PLAN=UNLIMITED
      - NEXTAUTH_URL=https://$dominio_painel
      - NEXT_PUBLIC_VIEWER_URL=https://$dominio_bot
      - NEXTAUTH_URL_INTERNAL=http://localhost:3000
      # Configurações do Typebot e Google Cloud
      #- GOOGLE_CLIENT_ID=
      #- GOOGLE_CLIENT_SECRET=
      # Configurações do Typebot e Minio
      - S3_ACCESS_KEY=OqCEOydCqDaVJ2eXw8TQ
      - S3_SECRET_KEY=ViK4TTnGK05LbY2kmbXLmwuW3uYeqtwvMEC9inFh
      - S3_BUCKET=typebot
      - S3_ENDPOINT=$dominio_db
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 1024M
      labels:
        - traefik.enable=true
        - traefik.http.routers.typebot_viewer.rule=Host(\`$dominio_bot\`)
        - traefik.http.routers.typebot_viewer.entrypoints=websecure
        - traefik.http.routers.typebot_viewer.tls.certresolver=letsencryptresolver
        - traefik.http.services.typebot_viewer.loadbalancer.server.port=3000
        - traefik.http.services.typebot_viewer.loadbalancer.passHostHeader=true
        - traefik.http.routers.typebot_viewer.service=typebot_viewer

  minio:
    image: quay.io/minio/minio
    command: server /data --console-address ":9001"
    networks:
      - dagestao_network
    volumes:
      - minio_data:/data
    environment:
      - MINIO_ROOT_USER=admin
      - MINIO_ROOT_PASSWORD=Mfcd62KKxTr!!Mfcd62!!
      - MINIO_BROWSER_REDIRECT_URL=https://$dominio_api_db
      - MINIO_SERVER_URL=https://$dominio_db
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.minio_public.rule=Host(\`$dominio_db\`)
        - traefik.http.routers.minio_public.entrypoints=websecure
        - traefik.http.routers.minio_public.tls.certresolver=letsencryptresolver
        - traefik.http.services.minio_public.loadbalancer.server.port=9000
        - traefik.http.services.minio_public.loadbalancer.passHostHeader=true
        - traefik.http.routers.minio_public.service=minio_public
        - traefik.http.routers.minio_console.rule=Host(\`$dominio_api_db\`)
        - traefik.http.routers.minio_console.entrypoints=websecure
        - traefik.http.routers.minio_console.tls.certresolver=letsencryptresolver
        - traefik.http.services.minio_console.loadbalancer.server.port=9001
        - traefik.http.services.minio_console.loadbalancer.passHostHeader=true
        - traefik.http.routers.minio_console.service=minio_console
volumes:
  minio_data:
    external: true
    name: minio_data
  db_data:


networks:
  dagestao_network:
    external: true
    name: dagestao_network


EOF

# Implanta o stack com Docker deploy
docker-compose -f /opt/typebot/docker-compose.yml pull

docker stack deploy -c /opt/typebot/docker-compose.yml typebot_stack
