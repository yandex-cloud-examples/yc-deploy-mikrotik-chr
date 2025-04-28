#!/bin/bash
set -e

if [ "$#" != "2" ]; then
  printf "Mikrotik Cloud Hosted Router (CHR) image builder.\n"
  printf "Select required version of CHR software at https://mikrotik.com/download \n"
  printf "$0 <chr-version> <folder-id>\n"
  printf "For example:\n$0 7.18.2 b1g28**********yvxc3 \n"
  exit

else
  CHR_VER=$1
  FOLDER_ID=$2

  mkdir tmp
  cd tmp
  curl -s -O https://download.mikrotik.com/routeros/$CHR_VER/chr-$CHR_VER.img.zip
  unzip chr-$CHR_VER.img.zip
  mv chr-$CHR_VER.img chr-$CHR_VER.qcow2

  BUCKET_NAME=chr-img-${RANDOM:0:5}
  
  yc storage bucket create $BUCKET_NAME --public-read --folder-id $FOLDER_ID
  yc storage s3 cp chr-$CHR_VER.qcow2 s3://$BUCKET_NAME/chr-$CHR_VER.qcow2
  
  yc compute image create --name mikrotik-chr-${CHR_VER//\./-} \
  --folder-id $FOLDER_ID \
  --os-type linux \
  --hardware-generation-id legacy --hardware-features pci_topology=v2 \
  --source-uri https://storage.yandexcloud.net/$BUCKET_NAME/chr-$CHR_VER.qcow2


  yc storage s3 rm s3://$BUCKET_NAME/chr-$CHR_VER.qcow2
  IMAGE_ID=$(yc compute image get --name mikrotik-chr-${CHR_VER//\./-} --jq .id)

  cd ..
  rm -rf tmp

  printf "Replace the following strings at the \"terraform.tfvars\" file:\n\n"
  printf "chr_image_folder_id = \"$FOLDER_ID\""
  printf "chr_image_id = \"$IMAGE_ID\""

fi
  exit
