#!/bin/bash
InDir='../output/55_GlobeYAGB_CMG010DEG';
OuDir='../output/56_GlobeYAGB_CMG1KM';

mkdir -p $OuDir/

 Thread=0;
 Number=10;

#for Year in {2001..2018..1}; do
 # YearName="A$Year"

for InName in $(ls $InDir/*tif); do     # for InName in $(ls $InDir/$Year/*tif); do
  InFile=$(echo $InName | awk -F/ '{print $NF}');
  OuFile=$(echo $InFile | sed 's/CMG010/CMG1KM/g') ;
  #mkdir -p $OuDir/$Year/
  OuName=$OuDir/$OuFile;

  echo "gdalwarp $InName $OuName -r bilinear -tr 0.008333333 0.008333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs \""+proj=longlat +ellps=WGS84\"" & "

  gdalwarp $InName $OuName -r bilinear -tr 0.00833333333 0.00833333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

  Thread=`expr $Thread + $Number`;echo $Thread; if (( $Thread % 12 ==0 )); then wait; fi

  #echo $(( Thread++ )); if (( $Thread % 12 ==0 )); then wait; fi
done
#done

