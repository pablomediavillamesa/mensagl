#!/bin/bash

set -e  # Detener la ejecución en caso de error

STACK_VPC="equipo3-vpc"
STACK_SG_AZ1="equipo3-sg-az1"
STACK_SG_AZ2="equipo3-sg-az2"
STACK_INSTANCES="equipo3-instances"
STACK_RDS="equipo3-rds"
KEY_NAME="mensagl"
KEY_FILE="${KEY_NAME}.pem"

# Directorios de los archivos YAML
VPC_FILE="Cloudformation-vpc.yaml"
SG_AZ1_FILE="Cloudformation-sg-az1.yaml"
SG_AZ2_FILE="Cloudformation-sg-az2.yaml"
INSTANCES_FILE="Cloudformation-ec2.yaml"
RDS_FILE="Cloudformation-rds.yaml"

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
for file in $VPC_FILE $SG_AZ1_FILE $SG_AZ2_FILE $INSTANCES_FILE $RDS_FILE; do
    aws cloudformation validate-template --template-body file://$file
    echo "$file es válido."
done

echo ""

# 3️ Eliminar stacks si se usa --force-redeploy
if [ "$FORCE_REDEPLOY" = true ]; then
    echo "Eliminando stacks previos..."
    aws cloudformation delete-stack --stack-name "$STACK_INSTANCES"
    aws cloudformation delete-stack --stack-name "$STACK_SG_AZ1"
    aws cloudformation delete-stack --stack-name "$STACK_SG_AZ2"
    aws cloudformation delete-stack --stack-name "$STACK_VPC"
    aws cloudformation delete-stack --stack-name "$STACK_RDS"
    
    echo "Esperando a que se eliminen los stacks..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_INSTANCES" || true
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_SG_AZ1" || true
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_SG_AZ2" || true
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
aws cloudformation create-stack --stack-name "$STACK_SG_AZ1" --template-body file://$SG_AZ1_FILE --capabilities CAPABILITY_NAMED_IAM
aws cloudformation create-stack --stack-name "$STACK_SG_AZ2" --template-body file://$SG_AZ2_FILE --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$STACK_SG_AZ1"
aws cloudformation wait stack-create-complete --stack-name "$STACK_SG_AZ2"
echo "Security Groups creados exitosamente."

echo ""

# 7 Creando las instancias RDS
echo "Creando las instancias RDS ($STACK_RDS)..."
aws cloudformation create-stack --stack-name "$STACK_RDS" --template-body file://$RDS_FILE --capabilities CAPABILITY_NAMED_IAM 
aws cloudformation wait stack-create-complete --stack-name "$STACK_RDS"
echo "Instancia RDS Creada exitosamente"

echo ""

# 6️ Crear las instancias EC2
echo "Creando las instancias EC2 ($STACK_INSTANCES)..."
aws cloudformation create-stack --stack-name "$STACK_INSTANCES" --template-body file://$INSTANCES_FILE --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEY_NAME
aws cloudformation wait stack-create-complete --stack-name "$STACK_INSTANCES"
echo "Instancias EC2 creadas exitosamente."

echo "Infraestructura desplegada con éxito."

