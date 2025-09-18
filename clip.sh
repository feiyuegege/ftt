
#!/bin/sh

# 配置参数
INPUT_FILE="/root/cfipopw/result.csv"
OUTPUT_DIR="/root/feiyuege"
OUTPUT_FILE="${OUTPUT_DIR}/formatted_result.txt"

# 创建输出目录
mkdir -p "$OUTPUT_DIR" || {
    echo "错误: 无法创建目录 $OUTPUT_DIR" >&2
    exit 1
}

# 检查输入文件
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 $INPUT_FILE 不存在" >&2
    exit 1
fi

# 处理CSV文件
awk -F',' '{
    if(NR>1 && $1 != "" && $NF != "") {  # 改为判断字段不为空字符串
        gsub(/[[:space:]]/, "", $1)  # 清理IP地址
        print $1":443#"$NF  # 格式化为ip:443#最后字段
    }
}' "$INPUT_FILE" > "$OUTPUT_FILE"

# 验证结果
if [ -s "$OUTPUT_FILE" ]; then
    echo "成功处理 $(wc -l < "$OUTPUT_FILE") 条记录"
    echo "输出文件: $OUTPUT_FILE"
    chmod 644 "$OUTPUT_FILE"
    exit 0
else
    echo "错误: 未生成有效数据" >&2
    rm -f "$OUTPUT_FILE"
    exit 1
fi
