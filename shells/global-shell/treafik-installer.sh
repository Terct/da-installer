#!/bin/bash

# Função para validar o formato de e-mail
function validar_email() {
    local email=$1
    local regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"

    if [[ $email =~ $regex ]]; then
        echo ""
        return 0
    else
        echo "E-mail inválido. Por favor, tente novamente."
        return 1
    fi
}

# Solicita o email do cliente e valida
while true; do
    read -p "Digite o seu e-mail: " client_email
    if [ -n "$client_email" ] && validar_email "$client_email"; then
        break
    fi
done

# Cria o diretório se não existir
mkdir -p /opt/traefik/


# Cria a rede overlay e atachable
docker swarm init

docker network create --driver=overlay --attachable dagestao_network

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF > /opt/traefik/docker-compose.yml
version: "3.7"

services:
  traefik:
    image: traefik:latest
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=dagestao_network"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=${client_email}"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/etc/traefik/letsencrypt/acme.json"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "vol_certificates:/etc/traefik/letsencrypt"
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
    networks:
      - dagestao_network  

volumes:
  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:
  dagestao_network:  
    external: true
    name: dagestao_network
EOF

# Implanta o stack com Docker deploy
docker stack deploy -c /opt/traefik/docker-compose.yml traefik_stack
