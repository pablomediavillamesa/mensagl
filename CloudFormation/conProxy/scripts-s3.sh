
S3_FILE="Cloudformation-s3.yaml"
STACK_S3="equipo3-s3"

# 6️ Asegurar que el bucket S3 existe (no lo borra, solo lo crea si no existe)
BUCKET_NAME="equipo3-scripts"

if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "El bucket S3 no existe. Creándolo..."
    aws cloudformation create-stack --stack-name "$STACK_S3" --template-body file://$S3_FILE --capabilities CAPABILITY_NAMED_IAM
    aws cloudformation wait stack-create-complete --stack-name "$STACK_S3"
    echo "Bucket S3 creado exitosamente."
else
    echo "El bucket S3 ya existe. Saltando la creación."
fi

echo ""

# 7 Subir solo los scripts nuevos/modificados a S3
BUCKET_NAME="equipo3-scripts"

echo "Actualizando scripts en S3..."
aws s3 sync ./scripts s3://$BUCKET_NAME/ --exact-timestamps
echo "Actualización de scripts completada."

echo ""