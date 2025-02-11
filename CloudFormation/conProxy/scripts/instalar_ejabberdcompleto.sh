#!/bin/bash

# Comprobamos el hostname en nuestro servidor
echo "Comprobando el hostname actual..."
hostnamectl status

# Cambiamos el hostname a 'dcastillop.local'
echo "Cambiando el hostname a 'dcastillop.local'..."
sudo hostnamectl set-hostname dcastillop.local
echo "Hostname cambiado a: $(hostnamectl status | grep 'Static hostname')"

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

# Configuramos ejabberd
echo "Configurando ejabberd..."
# Modificamos la línea 92 de ejabberd.yml para añadir la ACL del admin
CONFIG_FILE="/opt/ejabberd/conf/ejabberd.yml"

# Verificamos si el archivo existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: No se encontró el archivo de configuración ejabberd.yml."
    exit 1
fi

# Reemplazamos la línea 92 con la configuración correcta
sudo sed -i '92s|.*|acl:\n  admin:\n    user:\n      - "admin@dcastillop.local"|' "$CONFIG_FILE"

# Reemplazamos la línea 198 con la configuración de mod_muc
sudo sed -i '/mod_muc:/a \ \ \ \ host: muc.dcastillop.local' "$CONFIG_FILE"

echo "Configuración de mod_muc aplicada en la línea 198 de ejabberd.yml."


echo "Configuración de ACL admin aplicada en la línea 92 de ejabberd.yml."

# Reiniciamos el servicio
echo "Reiniciando el servicio ejabberd..."
sudo systemctl restart ejabberd

# Verificamos el estado del servicio
sudo systemctl is-active --quiet ejabberd || { echo "El servicio ejabberd no está activo"; exit 1; }

# Registramos un usuario admin
# Buscamos la ubicación correcta de ejabberdctl
EJABBERDCTL=$(command -v ejabberdctl || sudo find / -name ejabberdctl -type f 2>/dev/null | head -n 1)

# Si no se encuentra, mostramos un error y salimos
if [ -z "$EJABBERDCTL" ]; then
    echo "Error: No se encontró ejabberdctl en el sistema."
    exit 1
fi

# Registramos el usuario admin
echo "Registrando el usuario 'admin' con contraseña 'User123'..."
sudo "$EJABBERDCTL" register admin dcastillop.local User123 || { echo "Error registrando usuario"; exit 1; }


echo "Configuración completada con éxito."
