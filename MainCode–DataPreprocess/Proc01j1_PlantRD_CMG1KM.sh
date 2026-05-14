#!/bin/bash

InDir='../input/Water-TableDepth'
OuDir='../input/Water-TableDepth'


Thread=0
MaxThreads=12
Increment=1

for InName in "$InDir"/PlantRootDepth-merge.tif; do
  InFile=$(basename "$InName")
  OuFile="PRD_Y00_CMG1KM.tif"
  OuName="$OuDir/$OuFile"

  echo "Processing: $InName -> $OuName"
  gdalwarp "$InName" "$OuName" -r bilinear -tr 0.008333333 0.008333333 -te -180 -60 180 90 -srcnodata nan -dstnodata nan -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

  ((Thread+=Increment))
  if (( Thread % MaxThreads == 0 )); then
    wait
  fi
done

wait
