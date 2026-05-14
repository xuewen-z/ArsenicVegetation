import os
import subprocess
import shutil
import numpy as np
import rasterio

# 定义输入和输出文件路径
InPath = '../input/AsData'
Path_GeoAsMaps = '../output/01a_AsProb_CMG1KM/'

# 删除并重新创建输出目录
def recreate_directory(path):
    if os.path.exists(path):
        shutil.rmtree(path)
    os.makedirs(path)

recreate_directory(Path_GeoAsMaps)

# 处理输入文件并转换为指定分辨率
def process_file(InPath, InName, OuPath, OuName, resolution):
    InFile = os.path.join(InPath, InName)
    OuFile = os.path.join(OuPath, OuName)

    # 删除已有的输出文件
    if os.path.exists(OuFile):
        os.remove(OuFile)

    # 构建 gdalwarp 命令
    command = [
        'gdalwarp', InFile, OuFile,
        '-r', 'mode',
        '-tr', str(resolution), str(resolution),
        '-te', '-180', '-60', '180', '90',
        '-co', 'COMPRESS=DEFLATE',
        '-t_srs', '+proj=longlat +ellps=WGS84'
    ]

    # 打印并运行命令
    print(f"Running command: {' '.join(command)}")
    subprocess.run(command)

# 处理输入文件并转换为指定分辨率的GeoTIFF文件
process_file(InPath, 'probability_arsenic_gt_5ppb.tif', Path_GeoAsMaps, 'AsProb_GT5ppb_CMG1KM.tif', 0.00833333333)
process_file(InPath, 'probability_arsenic_gt_10ppb.tif', Path_GeoAsMaps, 'AsProb_GT10ppb_CMG1KM.tif', 0.00833333333)
process_file(InPath, 'probability_arsenic_gt_50ppb.tif', Path_GeoAsMaps, 'AsProb_GT50ppb_CMG1KM.tif', 0.00833333333)
