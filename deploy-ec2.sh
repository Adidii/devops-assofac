#!/bin/bash
set -e

INSTANCE_NAME="AssofacCloud-Server"
INSTANCE_TYPE="t3.micro"
AMI_ID="ami-02aabe2c1c59b6feb"
KEY_NAME="assofac-key"
SECURITY_GROUP="assofac-sg"
REGION="eu-west-3"

echo "→ Création de la clé SSH..."
aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query "KeyMaterial" \
  --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem
echo "✓ Clé SSH créée"

echo "→ Création du Security Group..."
aws ec2 create-security-group \
  --group-name $SECURITY_GROUP \
  --description "AssofacCloud Security Group" \
  --region $REGION
aws ec2 authorize-security-group-ingress \
  --group-name $SECURITY_GROUP \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-name $SECURITY_GROUP \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "✓ Security Group créé"

USER_DATA="#!/bin/bash
apt update -y
apt install -y docker.io nginx
systemctl start docker nginx
systemctl enable docker nginx"

echo "→ Lancement de l'instance EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-groups $SECURITY_GROUP \
  --user-data "$USER_DATA" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "→ Instance créée : $INSTANCE_ID"
echo "→ Attente du démarrage..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo ""
echo "══════════════════════════════"
echo "✓ DÉPLOIEMENT TERMINÉ !"
echo "  Instance : $INSTANCE_ID"
echo "  IP       : $PUBLIC_IP"
echo "  SSH      : ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
echo "  Web      : http://$PUBLIC_IP"
echo "══════════════════════════════"