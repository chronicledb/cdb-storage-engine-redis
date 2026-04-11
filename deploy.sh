#!/bin/bash
set -e

ENGINE="redis"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/cdb-storage-engines"

echo "Building..."
docker build -t cdb-storage-engines:$ENGINE .

echo "Authenticating with ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "Pushing..."
docker tag cdb-storage-engines:$ENGINE $REPO:$ENGINE
docker push $REPO:$ENGINE

echo "Done! Image available at $REPO:$ENGINE"