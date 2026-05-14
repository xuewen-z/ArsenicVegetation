#!/bin/bash

InDir='../output/01e_AridIndex_Y00'
OuDir='../output/01e_AridIndex_Y00'

mkdir -p "$OuDir"

Thread=0
MaxThreads=12
Increment=1

for InName in "$InDir"/*.tif; do
  InFile=$(basename "$InName")
  OuFile="${InFile/CMG083DEG/CMG1KM}"
  OuName="$OuDir/$OuFile"

  echo "Processing: $InName -> $OuName"
  gdalwarp "$InName" "$OuName" -r bilinear -tr 0.008333333 0.008333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

  ((Thread+=Increment))
  if (( Thread % MaxThreads == 0 )); then
    wait
  fi
done

wait
