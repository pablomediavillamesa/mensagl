#!/bin/bash

set -e  # Detener la ejecución en caso de error

STACK_VPC="equipo3-vpc"
STACK_SG="equipo3-sg"
STACK_S3="equipo3-s3-scripts"
STACK_INSTANCES="equipo3-instances"
KEY_NAME="mensagl"
KEY_FILE="${KEY_NAME}.pem"

# Directorios de los archivos YAML
VPC_FILE="Cloudformation-vpc.yaml"
SG_FILE="Cloudformation-sg.yaml"
INSTANCES_FILE="Cloudformation-ec2.yaml"
S3_FILE="Cloudformation-s3.yaml"

# Verificar si se usa --force-redeploy
FORCE_REDEPLOY=false
if [[ "$1" == "--force-redeploy" ]]; then
    FORCE_REDEPLOY=true
    echo "Se ha activado el modo de reimplementación forzada (--force-redeploy)."
fi

# 1️ Verificar si la clave SSH existe
echo "Verificando clave SSH ($KEY_NAME)..."
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
    echo "Creando clave SSH: $KEY_NAME"
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"
    chmod 400 "$KEY_FILE"
    echo "Clave SSH creada y guardada en $KEY_FILE"
else
    echo "La clave SSH ya existe."
fi

echo ""

# 2️ Validar sintaxis de los archivos YAML
echo "Validando la sintaxis de los archivos YAML..."
for file in $VPC_FILE $SG_AZ1_FILE $SG_AZ2_FILE $INSTANCES_FILE $RDS_FILE $S3_FILE; do
    aws cloudformation validate-template --template-body file://$file
    echo "$file es válido."
done

echo ""

# 3️ Eliminar stacks si se usa --force-redeploy
if [ "$FORCE_REDEPLOY" = true ]; then
    echo "Eliminando stacks previos..."
    aws cloudformation delete-stack --stack-name "$STACK_INSTANCES"
    aws cloudformation delete-stack --stack-name "$STACK_SG"
    aws cloudformation delete-stack --stack-name "$STACK_VPC"
    aws cloudformation delete-stack --stack-name "$STACK_RDS"
    
    echo "Esperando a que se eliminen los stacks..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_INSTANCES" || true
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_SG" || true
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_VPC" || true
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_RDS" || true
    echo "Stacks eliminados."
fi

echo ""

# 4 Crear la VPC
echo "Creando la VPC ($STACK_VPC)..."
aws cloudformation create-stack --stack-name "$STACK_VPC" --template-body file://$VPC_FILE --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$STACK_VPC"
echo "VPC creada exitosamente."

echo ""

# 5️ Crear los Security Groups
echo "Creando los Security Groups en AZ1 y AZ2..."
aws cloudformation create-stack --stack-name "$STACK_SG" --template-body file://$SG_FILE --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$STACK_SG"
echo "Security Groups creados exitosamente."

echo ""

# 6️ Crear el bucket S3
echo "Creando el bucket S3 ($STACK_S3)..."
aws cloudformation create-stack --stack-name "$STACK_S3" --template-body file://$S3_FILE --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$STACK_S3"
echo "Bucket S3 creado exitosamente."

echo ""

# 7 Subir los scripts a S3
echo "Subiendo la carpeta de scripts a S3..."
aws s3 cp ./scripts s3://equipo3-scripts/ --recursive
echo "Todos los scripts han sido subidos correctamente a S3."


echo "Creando grupo de subredes para RDS MySQL"
    
RDS_SUBNET_GROUP_NAME="cms-db-subnet-group"
SUBNET_PRIVATE1_ID=$(aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --query "Stacks[0].Outputs[?ExportName=='equipo3-SubnetPrivate1-ID'].OutputValue" --output text)
SUBNET_PRIVATE2_ID=$(aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --query "Stacks[0].Outputs[?ExportName=='equipo3-SubnetPrivate2-ID'].OutputValue" --output text)

if [ -z "$SUBNET_PRIVATE1_ID" ] || [ -z "$SUBNET_PRIVATE2_ID" ]; then
  echo "Error: No se pudieron obtener las subredes privadas de la VPC."
  exit 1
fi

# Crear grupo de subredes para RDS MySQL
echo "Creando grupo de subredes para RDS MySQL..."
aws rds create-db-subnet
-group \
    --db-subnet-group-name "$RDS_SUBNET_GROUP_NAME" \
    --db-subnet-group-description "Grupo de subredes para RDS MySQL CMS" \
    --subnet-ids "$SUBNET_PRIVATE1_ID" "$SUBNET_PRIVATE2_ID" \
    --tags Key=Name,Value="$RDS_SUBNET_GROUP_NAME"
echo "Grupo de subredes creado exitosamente."

# Crear instancia RDS MySQL
echo "Creando instancia de RDS MySQL..."
aws rds create-db-instance \
    --db-instance-identifier "cms-database" \
    --allocated-storage 20 \
    --storage-type "gp2" \
    --db-instance-class "db.t3.micro" \
    --engine "mysql" \
    --engine-version "8.0" \
    --master-username "admin" \
    --master-user-password "Admin123" \
    --db-name "wordpress_db" \
    --db-subnet-group-name "$RDS_SUBNET_GROUP_NAME" \
    --vpc-security-group-ids "$SG_DB_CMS_ID" \
    --publicly-accessible \
    --tags Key=Name,Value="wordpress_db"
echo "Instancia RDS MySQL creada exitosamente."


# 6️ Crear las instancias EC2
echo "Creando las instancias EC2 ($STACK_INSTANCES)..."
aws cloudformation create-stack --stack-name "$STACK_INSTANCES" --template-body file://$INSTANCES_FILE --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEY_NAME
aws cloudformation wait stack-create-complete --stack-name "$STACK_INSTANCES"
echo "Instancias EC2 creadas exitosamente."

echo "Infraestructura desplegada con éxito."

