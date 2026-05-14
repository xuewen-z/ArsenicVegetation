#!/bin/bash
InDir='../output/43_BESSGPPmax_CMG005';  #43_BESSGPPmax_CMG005 44_BESSWUE_CUE_CMG005
OuDir='../output/45_BESSEco_CMG1KM';


 Thread=0;
 Number=10;

#for Year in {2015..2015..1}; do
 # YearName="A$Year"

for InName in $(ls $InDir/*tif); do     # for InName in $(ls $InDir/$Year/*tif); do
  InFile=$(echo $InName | awk -F/ '{print $NF}');
  OuFile=$(echo $InFile | sed 's/CMG005DEG/CMG1KM/g') ;
  #mkdir -p $OuDir/$Year/
  OuName=$OuDir/$OuFile;

  echo "gdalwarp $InName $OuName -r bilinear -tr 0.008333333 0.008333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs \""+proj=longlat +ellps=WGS84\"" & "

  gdalwarp $InName $OuName -r bilinear -tr 0.00833333333 0.00833333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

  Thread=`expr $Thread + $Number`;echo $Thread; if (( $Thread % 12 ==0 )); then wait; fi

  #echo $(( Thread++ )); if (( $Thread % 12 ==0 )); then wait; fi
done
#done

