#!/bin/bash

InDir='../input'
OuDir='../output/01f_Irrigation_Y00'

mkdir -p "$OuDir"

Thread=0
MaxThreads=12
Increment=1

for InName in "$InDir"/GWirrgate.tif; do
  InFile=$(basename "$InName")
  OuFile="Irrigation_Y00_CMG1KM.tif"
  OuName="$OuDir/$OuFile"

  echo "Processing: $InName -> $OuName"
  gdalwarp "$InName" "$OuName" -r average -tr 0.008333333 0.008333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

  ((Thread+=Increment))
  if (( Thread % MaxThreads == 0 )); then
    wait
  fi
done

wait
