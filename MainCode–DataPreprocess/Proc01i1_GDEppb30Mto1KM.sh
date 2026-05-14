#!/bin/bash

# 输入包含已提取 Band 2 的 tif 文件目录
InDir='./gde_temp_band2'
OuDir='./gde_merged_output'

rm -rf $OuDir/
mkdir -p $OuDir


# 构建文件列表
find $InDir -name "*.tif" > $OuDir/input_list.txt

# 构建 VRT 虚拟拼接图层
echo "Building virtual mosaic (VRT)..."
gdalbuildvrt -input_file_list $OuDir/input_list.txt $OuDir/global_GDE_band2.vrt

# 使用 gdalwarp 进行重采样并输出为全球1km图层
echo 'Resampling to ~1 km resolution...'
gdalwarp -overwrite -t_srs EPSG:4326 \
  -tr 0.00833333333 0.00833333333 \
  -r average \
  -te -180 -60 180 90 \
  -co COMPRESS=LZW -co BIGTIFF=YES \
  $OuDir/global_GDE_band2.vrt \
  $OuDir/global_GDE_1km_band2.tif

