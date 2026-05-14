#!/bin/bash

# 输入和输出目录
InDir='../output/04b_SIF_Y00_CMG005DEG/'
OuDir='../output/05b_SIF_Y00_CMG1KM/'

# 删除并重新创建输出文件夹
rm -rf "$OuDir"
mkdir -p "$OuDir"

# 线程控制参数
MaxJobs=12  # 最大并行任务数
Thread=0    # 线程计数器

# 遍历所有 TIFF 文件
for InFile in "$InDir"/*.tif; do
    # 获取文件名
    FileName=$(basename "$InFile")
    
    # 替换 005DEG 为 1KM 以生成输出文件名
    OuName="${FileName/005DEG/1KM}"
    OuFile="$OuDir/$OuName"

    # 输出日志
    echo "gdalwarp $InFile $OuFile -r bilinear -tr 0.008333333 0.008333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs \""+proj=longlat +ellps=WGS84\"" & "

    # 执行 gdalwarp
    gdalwarp "$InFile" "$OuFile" -r bilinear -tr 0.00833333333 0.00833333333 -te -180 -60 180 90 -co COMPRESS=DEFLATE -t_srs "+proj=longlat +ellps=WGS84" &

    # 控制最大并行进程数
    ((Thread++))
    if (( Thread % MaxJobs == 0 )); then
        wait
    fi
done

# 确保所有后台任务完成
wait
echo "所有文件处理完成！"
