#!/bin/bash

# 配置参数
IP_LIST_URL="https://raw.githubusercontent.com/feiyuegege/ftt/refs/heads/main/v4.txt"
TARGET_COUNTRY="CA"  # 国家代码
OUTPUT_FILE="/root/cfipopw/ip.txt"
RESULT_FILE="/root/cfipopw/result.csv"  # 新增result.csv路径定义
TEMP_FILE=$(mktemp)
BATCH_SIZE=100       # 每次批量查询的IP数量
DEBUG=0              # 1=开启调试模式，0=关闭
API_CHOICE=1         # 1=ip-api.com, 2=ipinfo.io批量API
DIRECT_SAVE=0        # 1=直接保存IP列表不查询，0=正常筛选模式

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -d, --direct    直接保存IP列表，不进行国家筛选"
    echo "  -h, --help      显示帮助信息"
    echo "  -v, --verbose   开启调试模式"
    echo
    echo "默认行为: 筛选来自$TARGET_COUNTRY的IP并保存到$OUTPUT_FILE"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--direct)
                DIRECT_SAVE=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                DEBUG=1
                shift
                ;;
            *)
                echo "错误: 未知选项 $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 清理临时文件
cleanup() {
    rm -f "$TEMP_FILE"
    [ $DEBUG -eq 1 ] && echo "清理临时文件完成"
    exit 0
}
trap cleanup INT TERM EXIT

# 检查必要工具
check_dependencies() {
    local dependencies=("curl")
    # 如果不是直接保存模式，还需要jq工具
    if [ $DIRECT_SAVE -eq 0 ]; then
        dependencies+=("jq")
    fi
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "错误: 未找到必要的工具 '$dep'，请先安装。"
            exit 1
        fi
    done
}

# 获取IP列表
fetch_ip_list() {
    echo "正在从 $IP_LIST_URL 获取IP列表..."
    if ! curl -s "$IP_LIST_URL" -o "$TEMP_FILE"; then
        echo "错误: 无法获取IP列表"
        exit 1
    fi
    
    # 去除空行和注释行
    sed -i '/^#/d; /^$/d' "$TEMP_FILE"
    local ip_count=$(wc -l < "$TEMP_FILE")
    echo "成功获取 $ip_count 个IP地址"
    
    if [ $ip_count -eq 0 ]; then
        echo "错误: 未找到任何IP地址"
        exit 1
    fi
    
    # 调试模式：显示前10个IP
    if [ $DEBUG -eq 1 ]; then
        echo "前10个IP地址示例："
        head -n 10 "$TEMP_FILE"
    fi
    
    # 如果是直接保存模式，直接复制文件并退出
    if [ $DIRECT_SAVE -eq 1 ]; then
        cp "$TEMP_FILE" "$OUTPUT_FILE"
        echo "IP列表已直接保存到 $OUTPUT_FILE"
        exit 0
    fi
}

# 使用ip-api.com查询
query_with_ipapi() {
    local json_data=$1
    return $(curl -s "http://ip-api.com/batch?fields=query,countryCode" \
        -H "Content-Type: application/json" \
        -d "[$json_data]")
}

# 使用ipinfo.io查询
query_with_ipinfo() {
    local ip_list=$1
    return $(curl -s "https://ipinfo.io/$ip_list?token=YOUR_TOKEN_HERE"  # 需要注册获取免费token
        -H "Content-Type: application/json")
}

# 批量筛选IP
filter_country_ips() {
    echo "正在筛选 $TARGET_COUNTRY 国家的IP地址（批量处理模式，每次$BATCH_SIZE个）..."
    > "$OUTPUT_FILE"  # 清空输出文件
    
    local total=$(wc -l < "$TEMP_FILE")
    local current=0
    local found=0
    local batch=()
    
    # 读取IP并按批次处理
    while IFS= read -r ip; do
        current=$((current + 1))
        batch+=("$ip")
        
        # 当批次达到指定大小或处理完所有IP时，进行批量查询
        if [ ${#batch[@]} -ge $BATCH_SIZE ] || [ $current -eq $total ]; then
            # 构建批量查询的JSON数据
            local json_data=$(printf '{"query":"%s"},' "${batch[@]}" | sed 's/,$//')
            local ip_list=$(IFS=,; echo "${batch[*]}")
            
            # 调试模式：显示当前批次信息
            if [ $DEBUG -eq 1 ]; then
                echo -e "\n处理批次: $current/$total"
                echo "IP列表: $ip_list"
            fi
            
            # 选择API进行查询
            if [ $API_CHOICE -eq 1 ]; then
                local response=$(curl -s "http://ip-api.com/batch?fields=query,countryCode" \
                    -H "Content-Type: application/json" \
                    -d "[$json_data]")
            else
                # ipinfo.io批量查询需要注册免费token
                local response=$(curl -s "https://ipinfo.io/$ip_list?token=YOUR_TOKEN_HERE")
            fi
            
            # 调试模式：显示API响应
            if [ $DEBUG -eq 1 ]; then
                echo "API响应:"
                echo "$response" | jq .
            fi
            
            # 解析响应并提取符合条件的IP
            # 根据不同API调整解析方式
            if [ $API_CHOICE -eq 1 ]; then
                local batch_found=$(echo "$response" | jq -r \
                    --arg country "$TARGET_COUNTRY" \
                    '.[] | select(.countryCode == $country) | .query' | tee -a "$OUTPUT_FILE" | wc -l)
            else
                local batch_found=$(echo "$response" | jq -r \
                    --arg country "$TARGET_COUNTRY" \
                    '.[] | select(.country == $country) | .ip' | tee -a "$OUTPUT_FILE" | wc -l)
            fi
            
            found=$((found + batch_found))
            echo -ne "处理中: $current/$total, 已找到: $found\r"
            
            # 清空当前批次
            batch=()
            
            # 适当延迟，避免触发API限制
            sleep 1
        fi
    done < "$TEMP_FILE"
    
    echo -e "\n筛选完成，共找到 $found 个属于 $TARGET_COUNTRY 的IP地址"
    echo "结果已保存到 $OUTPUT_FILE"
    
    # 显示部分结果用于验证
    if [ -s "$OUTPUT_FILE" ]; then
        echo "前5个结果示例："
        head -n 5 "$OUTPUT_FILE"
    fi
}

# 主流程
main() {
    parse_args "$@"
    check_dependencies
    
    # 执行前清空两个文件
    > "$OUTPUT_FILE"
    > "$RESULT_FILE"
    [ $DEBUG -eq 1 ] && echo "已清空 $OUTPUT_FILE 和 $RESULT_FILE 原有内容"
    
    fetch_ip_list
    filter_country_ips
}

main "$@"
