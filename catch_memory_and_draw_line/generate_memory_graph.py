import matplotlib.pyplot as plt
import pandas as pd
import sys

def generate_graph(output_file, prev_pid):
    # 读取 CSV 文件
    data = pd.read_csv(output_file)
    data['timestamp'] = pd.to_datetime(data['timestamp'], errors='coerce')  # 使用 errors='coerce' 忽略无效的时间戳
    data = data.dropna(subset=['timestamp'])  # 删除任何不合法的时间戳行

    # 绘制曲线图
    plt.figure(figsize=(10, 6))
    plt.plot(data['timestamp'], data['java_heap_usage'], marker='o', linestyle='-', color='b')
    plt.title(f'Java Heap Usage Over Time (PID: {prev_pid})')
    plt.xlabel('Time')
    plt.ylabel('Java Heap Usage (KB)')
    plt.xticks(rotation=45)
    plt.grid()
    plt.tight_layout()

    # 保存为 PNG 文件, 使用 PREV_PID
    png_file = f"java_heap_usage_PID_{prev_pid}.png"
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
