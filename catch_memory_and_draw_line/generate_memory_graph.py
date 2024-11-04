import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import pandas as pd
import sys
import os

# 颜色池
COLORS = ['b', 'g', 'r', 'c', 'm', 'y']

def generate_graph(output_file, prev_pid):
    # 读取 CSV 文件
    data = pd.read_csv(output_file)
    data['timestamp'] = pd.to_datetime(data['timestamp'], errors='coerce')
    data = data.dropna(subset=['timestamp'])

    # 绘制曲线图并指定每个数据的颜色
    plt.figure(figsize=(10, 6))
    
    # 用颜色池循环选择颜色
    columns_to_plot = [col for col in data.columns if col != 'timestamp']
    for i, column in enumerate(columns_to_plot):
        plt.plot(
            data['timestamp'], 
            data[column], 
            linestyle='-', 
            label=column.replace('_', ' ').title(), 
            color=COLORS[i % len(COLORS)]
        )

    # 标题和标签
    plt.title(f'Memory Usage Over Time (PID: {prev_pid})')
    plt.xlabel('Time')
    plt.ylabel('Memory Usage (KB)')
    plt.xticks(rotation=45)
    plt.legend(loc='upper left')

    # 旋转 x 轴标签
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_locator(mdates.HourLocator(interval=1))
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter("%m-%d %H:%M"))

    # 关闭辅助网格线并减少 Y 轴的刻度数量
    plt.grid(False)  # 禁用网格
    plt.locator_params(axis='y', nbins=5)  # 限制 Y 轴刻度数量为 5

    # 保存到指定的输出目录
    output_dir = os.path.dirname(output_file)
    png_file = os.path.join(output_dir, f"memory_usage_PID_{prev_pid}.png")
    plt.tight_layout()
    plt.savefig(png_file)
    plt.close()

    print(f"曲线图已保存为 {png_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python generate_memory_graph.py <output_file> <prev_pid>")
    else:
        output_file = sys.argv[1]
        prev_pid = sys.argv[2]
        generate_graph(output_file, prev_pid)
