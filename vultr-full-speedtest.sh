#!/bin/bash
# Vultr 全节点一键测速脚本
# 作者：豆包 | 2025-12
# 功能：Ping测试（延迟/丢包）+ 100MB下载测试（带宽）

# ==================== 配置区（全节点完整）====================
NODE_LIST=(
  # 一、稳定优先节点（Top5）
  "硅谷(Silicon Valley)|sjo-ca-us-ping.vultr.com|https://sjo-ca-us-ping.vultr.com/vultr.com.100MB.bin"
  "斯德哥尔摩(Stockholm)|sto-se-ping.vultr.com|https://sto-se-ping.vultr.com/vultr.com.100MB.bin"
  "墨西哥城(Mexico City)|mex-mx-ping.vultr.com|https://mex-mx-ping.vultr.com/vultr.com.100MB.bin"
  "迈阿密(Miami)|fl-us-ping.vultr.com|https://fl-us-ping.vultr.com/vultr.com.100MB.bin"
  "多伦多(Toronto)|tor-ca-ping.vultr.com|https://tor-ca-ping.vultr.com/vultr.com.100MB.bin"

  # 二、亚洲地区节点
  "首尔(Seoul, South Korea)|sel-kor-ping.vultr.com|https://sel-kor-ping.vultr.com/vultr.com.100MB.bin"
  "大阪(Osaka, Japan)|osk-jp-ping.vultr.com|https://osk-jp-ping.vultr.com/vultr.com.100MB.bin"
  "东京(Tokyo, Japan)|hnd-jp-ping.vultr.com|https://hnd-jp-ping.vultr.com/vultr.com.100MB.bin"
  "新加坡(Singapore)|sgp-ping.vultr.com|https://sgp-ping.vultr.com/vultr.com.100MB.bin"
  "德里NCR(Delhi NCR, India)|del-in-ping.vultr.com|https://del-in-ping.vultr.com/vultr.com.100MB.bin"
  "孟买(Mumbai, India)|bom-in-ping.vultr.com|https://bom-in-ping.vultr.com/vultr.com.100MB.bin"
  "班加罗尔(Bangalore, India)|blr-in-ping.vultr.com|https://blr-in-ping.vultr.com/vultr.com.100MB.bin"

  # 三、欧洲地区节点
  "华沙(Warsaw, Poland)|waw-pl-ping.vultr.com|https://waw-pl-ping.vultr.com/vultr.com.100MB.bin"
  "特拉维夫(Tel Aviv, Israel)|tlv-il-ping.vultr.com|https://tlv-il-ping.vultr.com/vultr.com.100MB.bin"
  "法兰克福(Frankfurt, DE)|fra-de-ping.vultr.com|https://fra-de-ping.vultr.com/vultr.com.100MB.bin"
  "阿姆斯特丹(Amsterdam, NL)|ams-nl-ping.vultr.com|https://ams-nl-ping.vultr.com/vultr.com.100MB.bin"
  "曼彻斯特(Manchester, England)|man-uk-ping.vultr.com|https://man-uk-ping.vultr.com/vultr.com.100MB.bin"
  "伦敦(London, UK)|lon-gb-ping.vultr.com|https://lon-gb-ping.vultr.com/vultr.com.100MB.bin"
  "巴黎(Paris, France)|par-fr-ping.vultr.com|https://par-fr-ping.vultr.com/vultr.com.100MB.bin"
  "马德里(Madrid, Spain)|mad-es-ping.vultr.com|https://mad-es-ping.vultr.com/vultr.com.100MB.bin"

  # 四、美洲地区节点（补充）
  "火奴鲁鲁(Honolulu, Hawaii)|hon-hi-us-ping.vultr.com|https://hon-hi-us-ping.vultr.com/vultr.com.100MB.bin"
  "洛杉矶(Los Angeles, California)|lax-ca-us-ping.vultr.com|https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin"
  "西雅图(Seattle, Washington)|wa-us-ping.vultr.com|https://wa-us-ping.vultr.com/vultr.com.100MB.bin"
  "芝加哥(Chicago, Illinois)|il-us-ping.vultr.com|https://il-us-ping.vultr.com/vultr.com.100MB.bin"
  "纽约(New York, NJ)|nj-us-ping.vultr.com|https://nj-us-ping.vultr.com/vultr.com.100MB.bin"
  "达拉斯(Dallas, Texas)|tx-us-ping.vultr.com|https://tx-us-ping.vultr.com/vultr.com.100MB.bin"
  "亚特兰大(Atlanta, Georgia)|ga-us-ping.vultr.com|https://ga-us-ping.vultr.com/vultr.com.100MB.bin"
  "圣保罗(São Paulo, Brazil)|sao-br-ping.vultr.com|https://sao-br-ping.vultr.com/vultr.com.100MB.bin"
  "圣地亚哥(Santiago, Chile)|scl-cl-ping.vultr.com|https://scl-cl-ping.vultr.com/vultr.com.100MB.bin"

  # 五、大洋洲地区节点
  "悉尼(Sydney, Australia)|syd-au-ping.vultr.com|https://syd-au-ping.vultr.com/vultr.com.100MB.bin"
  "墨尔本(Melbourne, Australia)|mel-au-ping.vultr.com|https://mel-au-ping.vultr.com/vultr.com.100MB.bin"

  # 六、非洲地区节点
  "约翰内斯堡(Johannesburg, South Africa)|jnb-za-ping.vultr.com|https://jnb-za-ping.vultr.com/vultr.com.100MB.bin"
)

# 测试参数
PING_COUNT=20  # Ping包数量（越多越精准，默认20）
DOWNLOAD_TIMEOUT=70  # 下载超时时间（秒，默认120）
TEMP_FILE="/tmp/vultr-test.bin"  # 临时下载文件（自动删除）

# ==================== 工具函数====================
# 打印分隔线
print_separator() {
  echo "=================================================="
}

# 打印标题
print_title() {
  echo -e "\033[1;34m$1\033[0m"
}

# 安全转换为数字（处理非数字情况）
to_number() {
  local input=$1
  local num=$(echo "$input" | grep -oE '([0-9]+(\.[0-9]+)?)|(\.[0-9]+)' | head -n1)
  if [[ "$num" =~ ^\..* ]]; then
    num="0$num"
  fi
  echo "${num:-0}"
}

# 计算推荐等级
get_recommend_level() {
  local delay=$(to_number "$1")
  local loss=$(to_number "$2")
  local speed=$(to_number "$3")

  # 使用awk进行数值比较，避免bc的语法问题
  if awk -v d="$delay" -v l="$loss" -v s="$speed" 'BEGIN {exit !(d < 160 && l < 5 && s > 2.0)}'; then
    echo -e "\033[1;32m★★★ 强烈推荐\033[0m"
  elif awk -v d="$delay" -v l="$loss" -v s="$speed" 'BEGIN {exit !(d < 200 && l < 10 && s > 1.0)}'; then
    echo -e "\033[1;33m★★ 推荐\033[0m"
  elif awk -v d="$delay" -v l="$loss" -v s="$speed" 'BEGIN {exit !(d < 300 && l < 20 && s > 0.5)}'; then
    echo -e "\033[1;36m★ 可用\033[0m"
  else
    echo -e "\033[1;31m× 不推荐\033[0m"
  fi
}

# 提取丢包率（兼容Linux/macOS ping输出格式）
extract_loss_rate() {
  local ping_result="$1"
  local loss=$(echo "$ping_result" | grep -Eo '[0-9]+(\.[0-9]+)?% packet loss|[0-9]+ packets lost' | head -n1 | grep -Eo '[0-9]+(\.[0-9]+)?')
  if [ -n "$loss" ]; then
    loss=$(awk -v v="$loss" 'BEGIN{printf("%.0f", v+0)}')
  fi
  echo "${loss:-100}"
}

# 提取平均延迟（兼容Linux/macOS ping输出格式）
extract_avg_delay() {
  local ping_result="$1"
  local delay=$(echo "$ping_result" | grep -E 'rtt .* =|round-trip .* =' | tail -n1 | awk -F'=' '{print $2}' | awk -F'/' '{print int($2)}')
  echo "${delay:-999}"
}

# ==================== 主测试流程 ====================
print_title "Vultr 全节点测速脚本"
print_separator
START_TS=$(date +%s)
echo "测试时间：$(date +"%Y-%m-%d %H:%M:%S")"
echo "测试节点数：${#NODE_LIST[@]}"
echo "Ping包数量：$PING_COUNT 个"
echo "下载文件：100MB（超时时间：$DOWNLOAD_TIMEOUT 秒）"
echo -e "\033[1;36m提示：全节点测试耗时较长（约30分钟），可按 Ctrl+C 中断，已测试节点结果仍会保留。\033[0m"
print_separator

# 初始化报告变量
REPORT=()
TOTAL_NODE=${#NODE_LIST[@]}
PASS_NODE=0

# 循环测试每个节点
for ((i=0; i<TOTAL_NODE; i++)); do
  # 解析节点信息
  NODE_INFO=${NODE_LIST[$i]}
  NAME=$(echo "$NODE_INFO" | cut -d'|' -f1)
  DOMAIN=$(echo "$NODE_INFO" | cut -d'|' -f2)
  DOWNLOAD_URL=$(echo "$NODE_INFO" | cut -d'|' -f3)

  print_title "正在测试第 $((i+1))/$TOTAL_NODE 节点：$NAME"
  
  # 1. Ping测试（延迟/丢包）
  echo -n "Ping测试中..."
  PING_RESULT=$(ping -c "$PING_COUNT" "$DOMAIN" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo -e "\033[1;31m 失败（节点不可达）\033[0m"
    RECOMMEND=$(get_recommend_level "999" "100" "0")
    REPORT+=("$NAME | 不可达 | 100% | 0 MB/s | $RECOMMEND")
    print_separator
    continue
  fi

  # 提取Ping数据（修复兼容逻辑）
  AVG_DELAY=$(extract_avg_delay "$PING_RESULT")
  LOSS_RATE=$(extract_loss_rate "$PING_RESULT")
  
  echo -e " 完成"
  echo "  平均延迟：$AVG_DELAY ms"
  echo "  丢包率：$LOSS_RATE%"

  # 2. 下载测试（真实带宽）
  echo -n "下载测试中..."
  rm -f "$TEMP_FILE"  # 删除旧文件
  DOWNLOAD_RESULT=$(curl -o "$TEMP_FILE" -s -w "%{speed_download}\n" -m "$DOWNLOAD_TIMEOUT" "$DOWNLOAD_URL")
  if [ $? -ne 0 ] || [ -z "$DOWNLOAD_RESULT" ] || awk -v v="$DOWNLOAD_RESULT" 'BEGIN{exit !(v+0 < 1024)}'; then
    echo -e "\033[1;31m 失败（超时/下载中断）\033[0m"
    RECOMMEND=$(get_recommend_level "$AVG_DELAY" "$LOSS_RATE" "0")
    REPORT+=("$NAME | $AVG_DELAY ms | $LOSS_RATE% | 0 MB/s | $RECOMMEND")
    print_separator
    continue
  fi

  # 计算下载速度（Byte/s → MB/s）
  DOWNLOAD_SPEED=$(awk -v b="$DOWNLOAD_RESULT" 'BEGIN{printf "%.2f", b/1024/1024}')
  echo -e " 完成"
  echo "  下载速度：$DOWNLOAD_SPEED MB/s"

  # 3. 推荐等级（修复数值比较）
  RECOMMEND=$(get_recommend_level "$AVG_DELAY" "$LOSS_RATE" "$DOWNLOAD_SPEED")
  echo "  推荐等级：$RECOMMEND"

  # 记录报告
  REPORT+=("$NAME | $AVG_DELAY ms | $LOSS_RATE% | $DOWNLOAD_SPEED MB/s | $RECOMMEND")
  PASS_NODE=$((PASS_NODE+1))
  print_separator
done

# ==================== 生成汇总报告 ====================
print_title "===== 全节点测速汇总报告 ====="
echo "总测试节点：$TOTAL_NODE 个"
echo "有效节点：$PASS_NODE 个"
echo -e "\n节点排名（按推荐等级排序）："
echo "--------------------------------------------------"
echo "节点名称 | 平均延迟 | 丢包率 | 下载速度 | 推荐等级"
echo "--------------------------------------------------"

# 按推荐等级排序（强烈推荐→推荐→可用→不推荐）
for line in "${REPORT[@]}"; do
  if echo "$line" | grep -q "强烈推荐"; then
    echo "$line"
  fi
done
for line in "${REPORT[@]}"; do
  if echo "$line" | grep -q "★★ 推荐"; then
    echo "$line"
  fi
done
for line in "${REPORT[@]}"; do
  if echo "$line" | grep -q "★ 可用"; then
    echo "$line"
  fi
done
for line in "${REPORT[@]}"; do
  if echo "$line" | grep -q "× 不推荐"; then
    echo "$line"
  fi
done

# 清理临时文件
rm -f "$TEMP_FILE"
echo -e "\n\033[1;34m测试完成！推荐优先选择「强烈推荐」等级的节点部署代理。\033[0m"
END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))
H=$((ELAPSED/3600))
M=$(((ELAPSED%3600)/60))
S=$((ELAPSED%60))
echo "结束时间：$(date +"%Y-%m-%d %H:%M:%S")"
printf "总耗时：%02d:%02d:%02d\n" "$H" "$M" "$S"
