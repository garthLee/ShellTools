#!/bin/bash

# 读取配置文件
CONFIG_FILE="./config"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件 $CONFIG_FILE 不存在！"
    exit 1
fi

# 从配置文件中读取包名和间隔时间
PACKAGE_NAME=$(grep "^PACKAGE_NAME" "$CONFIG_FILE" | cut -d'=' -f2)
INTERVAL=$(grep "^INTERVAL" "$CONFIG_FILE" | cut -d'=' -f2)
OUTPUT_DIR=$(grep "^OUTPUT_DIR" "$CONFIG_FILE" | cut -d'=' -f2)

# 检查必需的值是否为空
if [ -z "$PACKAGE_NAME" ] || [ -z "$INTERVAL" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "配置文件中的值不完整！请确保 PACKAGE_NAME, INTERVAL 和 OUTPUT_DIR 都设置了。"
    exit 1
fi

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

# 初始化变量
PREV_PID=""
OUTPUT_FILE=""

# 无限循环，记录内存使用情况
while true; do
    # 获取应用的进程 ID (PID)
    PID=$(adb shell pidof "$PACKAGE_NAME")

    if [ -z "$PID" ]; then
        echo "未找到包名 $PACKAGE_NAME 对应的进程，等待下次检测..."
    else
        # 检查是否为第一次记录
        if [ -z "$PREV_PID" ]; then
            PREV_PID="$PID"
            OUTPUT_FILE="$OUTPUT_DIR/java_memory_usage_$PREV_PID.csv"
            echo "检测到进程 $PID"
            echo "timestamp,java_heap_usage,native_heap_usage,dalvik_heap_usage" > "$OUTPUT_FILE"
        fi

        # 如果进程 ID 变化，生成新的图
        if [ "$PID" != "$PREV_PID" ]; then
            echo "检测到进程 ID 变化: $PREV_PID,记录到$OUTPUT_FILE"

            # 绘制内存使用曲线图
            if [ -f "$OUTPUT_FILE" ]; then
                python3 generate_memory_graph.py "$OUTPUT_FILE" "$PREV_PID"
            fi

            # 重置输出文件，准备记录新的内存数据
            PREV_PID="$PID"
            OUTPUT_FILE="$OUTPUT_DIR/java_memory_usage_$PREV_PID.csv"
            echo "timestamp,java_heap_usage,native_heap_usage,dalvik_heap_usage" > "$OUTPUT_FILE"
        fi

        # 每次获取内存使用情况
        MEMORY_INFO=$(adb shell dumpsys meminfo "$PACKAGE_NAME")

        # 提取 Java Heap、Native Heap、Dalvik Heap
        JAVA_HEAP_USAGE=$(echo "$MEMORY_INFO" | grep "Java Heap:" | awk '{print $3}' | tr -d '[:space:]')
        NATIVE_HEAP_USAGE=$(echo "$MEMORY_INFO" | grep "Native Heap:" | awk '{print $3}' | tr -d '[:space:]')
        DALVIK_HEAP_USAGE=$(echo "$MEMORY_INFO" | grep "Dalvik Heap" | awk '{print $3}' | tr -d '[:space:]')

        # 检查是否成功提取到内存使用数据
        if [[ "$JAVA_HEAP_USAGE" =~ ^[0-9]+$ ]]; then
            # 将当前时间和内存使用值写入输出文件
            echo "$(date +'%Y-%m-%d %H:%M:%S'),$JAVA_HEAP_USAGE,$NATIVE_HEAP_USAGE,$DALVIK_HEAP_USAGE" >> "$OUTPUT_FILE"
        else
            echo "Java Heap 内存使用数据无效，跳过本次记录。"
        fi
    fi

    # 等待指定的时间后再次执行
    sleep "$INTERVAL"
done
