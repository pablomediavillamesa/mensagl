#!/bin/bash

# Configuración
DOMAIN="wordpresspmm"
TOKEN="8c9b04da-db3c-4513-9d00-a5ae7356bc91"
DUCKDNS_DIR="/opt/duckdns"

# Crear directorio para DuckDNS
mkdir -p $DUCKDNS_DIR
cd $DUCKDNS_DIR

# Crear script de actualización
echo '#!/bin/bash
IP=$(curl -s https://api.ipify.org)
echo url="https://www.duckdns.org/update?domains='$DOMAIN'&token='$TOKEN'&ip=$IP" | curl -k -o duckdns.log -K -
' > duckdns.sh
chmod +x duckdns.sh

# Ejecutar el script de actualización inicialmente
./duckdns.sh

# Agregar al crontab para actualizar cada 5 minutos
(crontab -l 2>/dev/null; echo "* * * * * $DUCKDNS_DIR/duckdns.sh >/dev/null 2>&1") | crontab -

echo "DuckDNS configurado correctamente para $DOMAIN"
