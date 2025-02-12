#!/bin/bash

# Dar permisos de ejecución al script secundario
chmod +x duckdns-ejabberd-proxy.sh

echo "Ejecutando script duckdns..."
sudo ./duckdns-wordpresspmm-proxy.sh

echo "Instalando HAProxy"
sudo apt install haproxy -y
# Mover configuración de HAProxy
echo "Configurando HAProxy..."
sudo mv haproxy.cfg /etc/haproxy/haproxy.cfg

# Reiniciar HAProxy para aplicar los cambios
echo "Reiniciando HAProxy..."
sudo systemctl restart haproxy

echo "Proceso completado exitosamente."
