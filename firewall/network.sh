#!/bin/bash

# Nome das redes
EXTERNAL_NET="external_net"
DMZ_NET="dmz_net"
INTERNAL_NET="internal_net"

# Criar redes Docker
docker network create --driver bridge $EXTERNAL_NET
docker network create --driver bridge $DMZ_NET
docker network create --driver bridge $INTERNAL_NET

# Exibir redes criadas
echo "Redes Docker criadas:"
docker network ls

# Conectar os contêineres às redes (exemplo de comando)
# docker network connect $EXTERNAL_NET <nome_do_conteiner>
# docker network connect $DMZ_NET <nome_do_conteiner>
# docker network connect $INTERNAL_NET <nome_do_conteiner>

echo "Redes configuradas com sucesso."

