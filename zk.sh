#!/bin/bash
echo "=== 开始执行全套流程 ==="

# 步骤1：执行第一个前置脚本（带 -d参数直接下载ip）
echo -n "1. 执行前置脚本1（ip.sh -d）..."
cd /root/cfipopw/ &&bash ip.sh -d && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤2：执行第二个前置脚本（ip优选解析域名）
echo -n "2. 执行前置脚本2（cdnip.sh）..."
cd /root/cfipopw/ &&bash cdnip.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤3：执行第三个前置脚本（ip筛选）
echo -n "2. 执行前置脚本3（ip.sh）..."
cd /root/v4/ &&bash ip.sh -d && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤4：执行第四个前置脚本（ip优选）
echo -n "2. 执行前置脚本4（cdnip.sh）..."
cd /root/v4/ &&bash cdnip.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤5：执行第五个前置脚本（ip优选）
echo -n "2. 执行前置脚本5（sc.sh）..."
cd /root/v4/ &&bash clip.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤6：执行第六个前置脚本（上传git库）
echo -n "2. 执行前置脚本6（sc.sh）..."
cd /root/v4/ &&bash sc.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤7：执行第七个前置脚本（ip筛选）
echo -n "2. 执行前置脚本7（ip.sh）..."
cd /root/v6/ &&bash ip.sh -d && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤8：执行第八个前置脚本（ip优选）
echo -n "2. 执行前置脚本8（cdnip.sh）..."
cd /root/v6/ &&bash cdnip.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤9：执行第九个前置脚本（ip优选）
echo -n "2. 执行前置脚本9（sc.sh）..."
cd /root/v6/ &&bash clip.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

# 步骤10：执行第十个前置脚本（上传git库）
echo -n "2. 执行前置脚本10（sc.sh）..."
cd /root/v6/ &&bash sc.sh && echo "成功" || {
    echo "失败！"
    exit 1
}

echo "=== 全套流程执行完成 ==="