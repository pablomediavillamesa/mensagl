#!/bin/bash

# Actualizamos la máquina
echo "Actualizando la máquina..."
sudo apt update

# Instalamos dependencias necesarias
echo "Instalando dependencias..."
sudo apt install -y wget dpkg || { echo "Error instalando dependencias"; exit 1; }

# Descargamos el instalador de ejabberd
echo "Descargando ejabberd..."
wget -q https://github.com/processone/ejabberd/releases/download/24.12/ejabberd-24.12-1-linux-x64.run -O ejabberd.run || { echo "Error descargando ejabberd"; exit 1; }

# Damos permisos de ejecución al instalador
chmod +x ejabberd.run

# Instalamos ejabberd en modo desatendido
echo "Instalando ejabberd..."
yes | sudo ./ejabberd.run --confirm || { echo "La instalación de ejabberd falló"; exit 1; }

# Verificamos la instalación
if [ ! -d "/opt/ejabberd" ]; then
    echo "Error: ejabberd no parece estar instalado correctamente."
    exit 1
fi
