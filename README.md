![image](https://github.com/user-attachments/assets/99ccc770-3c3b-4f8f-b2b0-c3d7a18c37ae)

Hello / Hola 

Este es mi repositorio de Github para el reto Mensagl de 2025. 
En el encontraremos principalmente 3 directorios 
  AWSCLI - contiene scripts que se ejecutan desde la consola de AWS.
  CloudFormation - contiene los stacks o pilas que se ejecutan en AWS Cloud Formation.
  Datos_usuario - contiene los datos de usuario que cargamos en las instancias, en este caso de AWS Cloudformation.

El funcionamiento es el siguiente: desde la carpeta de AWSCLI ejecutamos el script deploy.sh el cual realiza varias cosas.
  1 - Como variables se establecen el nombre de los stacks de AWSCF y la ruta de los archivos .yaml 
  2 - El script cuenta con la opcion --force-redeploy el cual automaticamente elimina los stacks de AWSCF antes de volver a lanzarlos
  3 - El script verifica si el par de claves para conectarse a las instancias ha sido creado, si no lo crea. 
  4 - Por orden va lanzando las pilas o stacks, utilizando un orden lógico, comenzando por la VPC, seguido de los grupos de seguridad y terminando con las instancias.

En el archivo Cloudformation-ec2.yaml se incluye como datos de usuario un git clone del repositorio de github, del cual luego se extrae la carpeta determinada para la instancia.
Esta carpeta contiene scripts para agilizar la instalacion, una vez que tenemos la carpeta de la instancia, eliminamos el resto del repositorio, ya que no lo necesitamos ni queremos.
