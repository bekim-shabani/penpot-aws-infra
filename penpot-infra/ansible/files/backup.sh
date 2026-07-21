#!/bin/bash

ENDPOINT=$1
PASSWORD=$2
ENV=$3
BUCKET="penpot-backup"
REGION="eu-north-1"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/admin/backups"
mkdir -p $BACKUP_DIR

PGPASSWORD="${PASSWORD}" pg_dump \
  -h ${ENDPOINT} \
  -U penpot \
  -d penpot \
  -F c \
  -f $BACKUP_DIR/${ENV}_$DATE.dump && \
aws s3 cp $BACKUP_DIR/${ENV}_$DATE.dump s3://$BUCKET/${ENV}/$DATE.dump --region $REGION

# Supprime les backups de plus de 7 jours
find $BACKUP_DIR -name "*.dump" -mtime +7 -delete

