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

# Solicita o subdomínio para webhooks e valida
while true; do
    read -p "Digite o subdomínio para webhooks: " subdominio_webhooks
    if [ -n "$subdominio_webhooks" ] && validar_dominio "$subdominio_webhooks"; then
        break
    fi
done

# Solicita o subdomínio para n8n e valida
while true; do
    read -p "Digite o subdomínio para n8n: " subdominio_n8n
    if [ -n "$subdominio_n8n" ] && validar_dominio "$subdominio_n8n"; then
        break
    fi
done

# Verifica se os subdomínios resolvem para os IPs locais da máquina
seu_ip=$(hostname -I | cut -d' ' -f1)  # Obtém o primeiro IP associado à máquina

# Verifica para webhooks
if [ "$(nslookup "$subdominio_webhooks" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio para webhooks não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "O subdomínio para webhooks está apontado para o IP local da sua máquina."
fi

# Verifica para n8n
if [ "$(nslookup "$subdominio_n8n" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
    echo "Erro: O subdomínio para n8n não está apontado para o IP local da sua máquina."
    exit 1
else
    echo "O subdomínio para n8n está apontado para o IP local da sua máquina."
fi

# Cria o diretório se não existir
mkdir -p /opt/n8n/

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF > /opt/n8n/docker-compose.yml

version: "3.7"

services:

  n8n-db:
    image: postgres:14
    environment:
      - POSTGRES_DB=n8n_queue
      - POSTGRES_PASSWORD=n8nPassWord
    networks:
      - dagestao_network
    #ports:
    #  - 5432:5432
    volumes:
      - postgres_data:/var/lib/postgresql/data
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "0.5"
          memory: 1024M

  redis:
    image: redis:latest
    command: [
        "redis-server",
        "--appendonly",
        "yes",
        "--port",
        "6379"
      ]
    volumes:
      - redis_data:/data
    networks:
      - dagestao_network
    deploy:
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "0.5"
          memory: 1024M


  n8n_editor:
    image: n8nio/n8n:latest
    command: start
    networks:
      - dagestao_network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n_queue
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=n8nPassWord
      - N8N_ENCRYPTION_KEY=r3djGX2vPoeL9zKL
      - N8N_HOST=${subdominio_n8n}
      - N8N_EDITOR_BASE_URL=https://${subdominio_n8n}/
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${subdominio_webhooks}/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=2
      - NODE_FUNCTION_ALLOW_EXTERNAL=moment,lodash,moment-with-locales
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=336
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
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
        - traefik.http.routers.n8n_editor.rule=Host(\`${subdominio_n8n}\`)
        - traefik.http.routers.n8n_editor.entrypoints=websecure
        - traefik.http.routers.n8n_editor.priority=1
        - traefik.http.routers.n8n_editor.tls.certresolver=letsencryptresolver
        - traefik.http.routers.n8n_editor.service=n8n_editor
        - traefik.http.services.n8n_editor.loadbalancer.server.port=5678
        - traefik.http.services.n8n_editor.loadbalancer.passHostHeader=1

  n8n_webhook:
    image: n8nio/n8n:latest
    command: webhook
    networks:
      - dagestao_network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n_queue
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=n8nPassWord
      - N8N_ENCRYPTION_KEY=r3djGX2vPoeL9zKL
      - N8N_HOST=${subdominio_n8n}
      - N8N_EDITOR_BASE_URL=https://${subdominio_n8n}/
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${subdominio_webhooks}/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=2
      - NODE_FUNCTION_ALLOW_EXTERNAL=moment,lodash,moment-with-locales
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=336
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
    deploy:
      mode: replicated
      replicas: 2
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 1024M
      labels:
        - traefik.enable=true
        - traefik.http.routers.n8n_webhook.rule=Host(\`${subdominio_webhooks}\`)
        - traefik.http.routers.n8n_webhook.entrypoints=websecure
        - traefik.http.routers.n8n_webhook.priority=1
        - traefik.http.routers.n8n_webhook.tls.certresolver=letsencryptresolver
        - traefik.http.routers.n8n_webhook.service=n8n_webhook
        - traefik.http.services.n8n_webhook.loadbalancer.server.port=5678
        - traefik.http.services.n8n_webhook.loadbalancer.passHostHeader=1

  n8n_worker:
    image: n8nio/n8n:latest
    command: worker --concurrency=10
    networks:
      - dagestao_network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n_queue
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=n8nPassWord
      - N8N_ENCRYPTION_KEY=r3djGX2vPoeL9zKL
      - N8N_HOST=${subdominio_n8n}
      - N8N_EDITOR_BASE_URL=https://${subdominio_n8n}/
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${subdominio_webhooks}/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=2
      - NODE_FUNCTION_ALLOW_EXTERNAL=moment,lodash,moment-with-locales
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=336
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
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
  redis_data:
    external: true
    name: redis_data
  postgres_data:
    external: true
    name: postgres_data


networks:
  dagestao_network:
    name: dagestao_network
    external: true

EOF


# Implanta o stack com Docker deploy
docker-compose -f /opt/n8n/docker-compose.yml pull

docker stack deploy -c /opt/n8n/docker-compose.yml n8n_stack
