#!/bin/bash

# 读取配置文件
CONFIG_FILE="./config.txt"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件 $CONFIG_FILE 不存在！"
    exit 1
fi

# 从配置文件中读取包名、间隔时间和目标路径
PACKAGE_NAME=$(grep "^PACKAGE_NAME" "$CONFIG_FILE" | cut -d'=' -f2)
INTERVAL=$(grep "^INTERVAL" "$CONFIG_FILE" | cut -d'=' -f2)
DESTINATION_PATH=$(grep "^DESTINATION_PATH" "$CONFIG_FILE" | cut -d'=' -f2)

# 检查必需的值是否为空
if [ -z "$PACKAGE_NAME" ] || [ -z "$INTERVAL" ] || [ -z "$DESTINATION_PATH" ]; then
    echo "配置文件中的值不完整！请确保 PACKAGE_NAME, INTERVAL 和 DESTINATION_PATH 都设置了。"
    exit 1
fi


# 将包名列表转换为数组
IFS=',' read -r -a PACKAGE_LIST <<< "$PACKAGE_NAME"

# 找到第一个已安装的包
PACKAGE_NAME=""
for pkg in "${PACKAGE_LIST[@]}"; do
    echo "search package $pkg"
    if adb shell pm path "$pkg" > /dev/null 2>&1; then
        PACKAGE_NAME="$pkg"
        echo "找到已安装的包: $PACKAGE_NAME"
        break
    fi
done

if [ -z "$PACKAGE_NAME" ]; then
    echo "列表中的包都未安装，脚本终止。"
    exit 1
fi



# 无限循环
while true; do
    # 获取应用的进程号 (PID)
    PID=$(adb shell pidof "$PACKAGE_NAME")

    if [ -z "$PID" ]; then
        echo "未找到包名 $PACKAGE_NAME 对应的进程！"
    else
        # 获取设备上当前时间作为文件名的一部分
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

        # HPROF 文件路径，使用进程号作为文件名
        filename=${PID}_${TIMESTAMP}.hprof
        HPROF_FILE="/data/local/tmp/$filename"

        if [ ! -d "$DESTINATION_PATH" ]; then
            echo "目标文件夹 $DESTINATION_PATH 不存在，正在创建..."
            mkdir -p "$DESTINATION_PATH"
            if [ $? -eq 0 ]; then
                echo "成功创建目标文件夹 $DESTINATION_PATH"
            else
                echo "无法创建目标文件夹 $DESTINATION_PATH"
                exit 1
            fi
        fi


        # 生成 HPROF 文件
        adb shell am dumpheap "$PACKAGE_NAME" "$HPROF_FILE"

        # 等待生成完成
        FILE_SIZE=-1
        while true; do
            NEW_SIZE=$(adb shell stat -c%s "$HPROF_FILE" 2>/dev/null)
            
            if [ "$NEW_SIZE" = "$FILE_SIZE" ]; then
                echo "HPROF 文件生成完成: $HPROF_FILE"
                break
            fi

            FILE_SIZE=$NEW_SIZE
            sleep 1
        done


        adb pull "$HPROF_FILE" "$DESTINATION_PATH/$filename"

        # 如果 pull 成功，删除手机上的源文件
        if [ $? -eq 0 ]; then
            adb shell rm "$HPROF_FILE"
        fi
    fi

    # 等待指定的时间后再次执行
    echo "等待${INTERVAL}s后开始下一次"
    sleep "$INTERVAL"
done
