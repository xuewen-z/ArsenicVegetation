#!/bin/bash

InDir='../input/Global-AI_ET0_v3_annual'
OuDir='../output/01e_AridIndex_Y00'

mkdir -p $OuDir

Thread=0
MaxThreads=12
Increment=1

for InName in $InDir/ai_v3_yr.tif; do
  InFile=$(basename $InName)
  OuFile=${InFile/ai_v3_yr/AridIndex_Y00_CMG083DEG}
  OuName=$OuDir/$OuFile

  echo "Processing: $InName -> $OuName"
  gdalwarp $InName $OuName -r bilinear -tr 0.8333333 0.8333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

  ((Thread+=Increment))
  if (( Thread % MaxThreads == 0 )); then
    wait
  fi
done

wait
