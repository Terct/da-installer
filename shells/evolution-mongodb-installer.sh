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

# Solicita o domínio e valida
while true; do
    read -p "Digite o seu subdomínio: " subdominio
    if [ -n "$subdominio" ] && validar_dominio "$subdominio"; then
        break
    fi
done

# Verifica se o subdomínio resolve para o IP local da máquina
seu_ip=$(hostname -I | cut -d' ' -f1)  # Obtém o primeiro IP associado à máquina
if [ "$(nslookup "$subdominio" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "O subdomínio está apontado para o IP local da sua máquina."
fi

# Cria o diretório se não existir
mkdir -p /opt/mongodb/


# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF > /opt/mongodb/docker-compose.yml

version: "3.7"

services:
  mongodb:
    image: mongo:7
    command: mongod --port 27017
    networks:
      - dagestao_network
    volumes:
      - mongodb_data:/data/db
      - mongodb_configdb_data:/data/configdb
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=Mfcd62!!Mfcd62!!
      - PUID=1000
      - PGID=1000
    ports:
      - 27017:27017
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

volumes:
  mongodb_data:
    external: true
    name: mongodb_data
  mongodb_configdb_data:
    external: true
    name: mongodb_configdb_data

networks:
  dagestao_network:
    external: true
    name: dagestao_network

EOF

# Implanta o stack com Docker deploy
docker stack deploy -c /opt/mongodb/docker-compose.yml mongodb_stack

# Cria o diretório se não existir
mkdir -p /opt/evolution/

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF > /opt/evolution/docker-compose.yml
version: "3.7"

services:
  evolution_astra:
    image: davidsongomes/evolution-api:v1.5.4
    command: ["node", "./dist/src/main.js"]
    networks:
      - dagestao_network
    volumes:
    - evolution_astra_instances:/evolution/instances
    - evolution_astra_store:/evolution/store
    environment:
      - SERVER_URL=https://${subdominio}
      - DOCKER_ENV=true
      - LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS
      - DEL_INSTANCE=false
      - CONFIG_SESSION_PHONE_CLIENT=Evolution
      - CONFIG_SESSION_PHONE_NAME=Chrome
      - STORE_MESSAGES=true
      - STORE_MESSAGE_UP=true
      - STORE_CONTACTS=true
      - STORE_CHATS=true
      - CLEAN_STORE_CLEANING_INTERVAL=7200 # seconds === 2h
      - CLEAN_STORE_MESSAGES=true
      - CLEAN_STORE_MESSAGE_UP=true
      - CLEAN_STORE_CONTACTS=true
      - CLEAN_STORE_CHATS=true
      - AUTHENTICATION_TYPE=apikey
      - AUTHENTICATION_API_KEY=0417bf43b0a8969bd6685bcb49d783df
      - AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
      - QRCODE_LIMIT=30
      - WEBHOOK_GLOBAL_ENABLED=false
      - WEBHOOK_GLOBAL_URL=https://URL
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false
      - WEBHOOK_EVENTS_APPLICATION_STARTUP=false
      - WEBHOOK_EVENTS_QRCODE_UPDATED=true
      - WEBHOOK_EVENTS_MESSAGES_SET=false
      - WEBHOOK_EVENTS_MESSAGES_UPSERT=true
      - WEBHOOK_EVENTS_MESSAGES_UPDATE=true
      - WEBHOOK_EVENTS_CONTACTS_SET=true
      - WEBHOOK_EVENTS_CONTACTS_UPSERT=true
      - WEBHOOK_EVENTS_CONTACTS_UPDATE=true
      - WEBHOOK_EVENTS_PRESENCE_UPDATE=true
      - WEBHOOK_EVENTS_CHATS_SET=true
      - WEBHOOK_EVENTS_CHATS_UPSERT=true
      - WEBHOOK_EVENTS_CHATS_UPDATE=true
      - WEBHOOK_EVENTS_CHATS_DELETE=true
      - WEBHOOK_EVENTS_GROUPS_UPSERT=true
      - WEBHOOK_EVENTS_GROUPS_UPDATE=true
      - WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=true
      - WEBHOOK_EVENTS_CONNECTION_UPDATE=true
      - REDIS_ENABLED=false
      - REDIS_URI=redis://redis:6379
      # Aivar Banco de Dados
      - DATABASE_ENABLED=true
      - DATABASE_CONNECTION_URI=mongodb://admin:Mfcd62!!Mfcd62!!@$seu_ip:27017/?authSource=admin&readPreference=primary&ssl=false&directConnection=true
      - DATABASE_CONNECTION_DB_PREFIX_NAME=evo
      # Escolha o que deseja salvar
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=false
      - DATABASE_SAVE_MESSAGE_UPDATE=false
      - DATABASE_SAVE_DATA_CONTACTS=false
      - DATABASE_SAVE_DATA_CHATS=false
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 2048M
      labels:
        - traefik.enable=true
        - traefik.http.routers.evolution_astra.rule=Host(\`${subdominio}\`)
        - traefik.http.routers.evolution_astra.entrypoints=websecure
        - traefik.http.routers.evolution_astra.tls.certresolver=letsencryptresolver
        - traefik.http.routers.evolution_astra.priority=1
        - traefik.http.routers.evolution_astra.service=evolution_astra
        - traefik.http.services.evolution_astra.loadbalancer.server.port=8080
        - traefik.http.services.evolution_astra.loadbalancer.passHostHeader=true

volumes:
  evolution_astra_instances:
    external: true
    name: evolution_astra_instances
  evolution_astra_store:
    external: true
    name: evolution_astra_store

networks:
  dagestao_network:
    name: dagestao_network
    external: true

EOF

# Implanta o stack com Docker deploy
docker stack deploy -c /opt/evolution/docker-compose.yml evolution_stack
