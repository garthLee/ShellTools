import matplotlib.pyplot as plt
import pandas as pd
import sys

# 预定义的颜色池
COLOR_POOL = ['blue', 'green', 'red', 'cyan', 'magenta', 'yellow']

def generate_graph(output_file, prev_pid):
    # 读取 CSV 文件，使用适当的列名
    data = pd.read_csv(output_file, header=None, names=['timestamp', 'java_heap_usage', 'native_heap_usage', 'dalvik_heap_usage', 'pss_usage'], skip_blank_lines=True)

    # 转换时间戳为 datetime 格式，忽略无效的时间戳
    data['timestamp'] = pd.to_datetime(data['timestamp'], errors='coerce')
    data = data.dropna(subset=['timestamp'])  # 删除不合法的时间戳行

    # 绘制曲线图
    plt.figure(figsize=(10, 6))

    color_index = 0  # 用于跟踪当前使用的颜色索引

    # 动态绘制每一列
    for column in data.columns:
        if column != 'timestamp':
            color = COLOR_POOL[color_index % len(COLOR_POOL)]  # 循环使用颜色池中的颜色
            plt.plot(data['timestamp'], data[column], marker='o', linestyle='-', label=column, color=color)
            color_index += 1  # 更新颜色索引

    plt.title(f'Memory Usage Over Time (PID: {prev_pid})')
    plt.xlabel('Time')
    plt.ylabel('Memory Usage (KB)')
    plt.xticks(rotation=45)
    plt.legend()  # 显示图例
    plt.grid()
    plt.tight_layout()

    # 保存为 PNG 文件
    png_file = f"memory_usage_PID_{prev_pid}.png"
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
