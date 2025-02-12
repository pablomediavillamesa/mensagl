#!/bin/bash

# Definir variables
tudominio="ejabberdpmm.duckdns.org"

echo "Actualizando repositorios..."
sudo apt update -y

# Dar permisos de ejecución al script secundario
chmod +x duckdns-ejabberd-proxy.sh

echo "Ejecutando script duckdns..."
sudo ./duckdns-ejabberd-proxy.sh

echo "Instalando HAProxy y Certbot para TLS..."
sudo apt install haproxy certbot -y

# Generar certificado TLS con Let's Encrypt
echo "Obteniendo certificado TLS para $tudominio..."
sudo certbot certonly --standalone -d $tudominio --agree-tos --no-eff-email --non-interactive --email tu-email@ejemplo.com

# Concatenar clave privada y certificado en un solo archivo para HAProxy
echo "Concatenando claves TLS para HAProxy..."
sudo cat /etc/letsencrypt/live/$tudominio/fullchain.pem /etc/letsencrypt/live/$tudominio/privkey.pem | sudo tee /etc/haproxy/$tudominio.pem

# Mover configuración de HAProxy
echo "Configurando HAProxy..."
sudo mv haproxy.cfg /etc/haproxy/haproxy.cfg

# Reiniciar HAProxy para aplicar los cambios
echo "Reiniciando HAProxy..."
sudo systemctl restart haproxy

echo "Proceso completado exitosamente."
