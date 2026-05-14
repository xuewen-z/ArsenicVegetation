import time
import csv
import os
from pywinauto import Application

def get_rosetta_params(dlg, sand, silt, clay):
    """封装单次抓取逻辑"""
    dlg.Edit0.set_edit_text(str(sand))
    dlg.Edit2.set_edit_text(str(silt))
    dlg.Edit3.set_edit_text(str(clay))
    
    dlg.Predict.click()
    time.sleep(0.4) 

    res = {
        "Thr":   dlg.Edit11.window_text().strip(),
        "Ths":   dlg.Edit12.window_text().strip(),
        "Alpha": dlg.Edit9.window_text().strip(),
        "n":     dlg.Edit10.window_text().strip(),
        "Ks":    dlg.Edit8.window_text().strip()
    }
    return res

if __name__ == "__main__":
    # 配置路径 (请确保路径在你的 H 盘目录下正确)
    base_path = '../output/R06_Site2PyRosetta/'
    input_files = ['input2rosettaTOP.csv', 'input2rosettaSUB.csv']

    try:
        print(">>> 正在连接 Rosetta 窗口...")
        # 32位环境下，title_re 建议稍微模糊一点以防万一
        app = Application(backend="win32").connect(title_re=".*Rosetta.*", timeout=10)
        dlg = app.window(title_re=".*Rosetta.*")
        dlg.set_focus()
        dlg['% Sand, Silt and Clay (SSC)RadioButton'].click()
        print(">>> 连接成功，开始循环处理...")

        for file_name in input_files:
            input_csv = os.path.join(base_path, file_name)
            output_csv = os.path.join(base_path, file_name.replace('.csv', '_results.csv'))
            
            if not os.path.exists(input_csv):
                print(f">>> 找不到文件: {input_csv}")
                continue

            print(f">>> 正在处理: {file_name}")
            
            # 使用原生 csv 库读取，不需要 pandas
            with open(input_csv, 'r', encoding='utf-8') as f_in, \
                 open(output_csv, 'w', encoding='utf-8', newline='') as f_out:
                
                reader = csv.DictReader(f_in)
                writer = csv.writer(f_out)
                
                # 写入表头
                writer.writerow(['Sand', 'Silt', 'Clay', 'Thr', 'Ths', 'Alpha', 'n', 'Ks'])

                for i, row in enumerate(reader):
                    # 获取输入值
                    s, si, c = row['Sand'], row['Silt'], row['Clay']
                    
                    # 获取计算结果
                    data = get_rosetta_params(dlg, s, si, c)
                    
                    # 写入一行
                    writer.writerow([s, si, c, data['Thr'], data['Ths'], data['Alpha'], data['n'], data['Ks']])
                    
                    # 每 100 条显示进度
                    if i % 100 == 0:
                        print(f"[{file_name}] 已完成: {i} 条")

            print(f">>> {file_name} 处理完成！")

    except Exception as e:
        print(f"❌ 运行中出现问题: {e}")