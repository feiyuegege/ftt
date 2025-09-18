#!/bin/bash

# 进入目标文件夹
cd /root/feiyuege/

# 检查文件夹中的文件（确认ceshi.txt已存在）
ls -l
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
# 执行Git操作
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git pull origin main --rebase
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git add .
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git commit -m "[$TIMESTAMP] $commit_message"
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519" git push --force origin main

exit