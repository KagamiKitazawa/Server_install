#!/bin/bash

# 提示用户选择测试类型
echo "请选择要进行的测试类型："
echo "1) GB5 测试"
echo "2) GB6 测试"
read -p "请输入选项（1 或 2）： " choice

# 根据用户输入执行相应的测试命令
case $choice in
    1)
        echo "正在进行 GB5 测试..."
        wget -qO- yabs.sh | bash -s -- -i -5
        ;;
    2)
        echo "正在进行 GB6 测试..."
        wget -qO- yabs.sh | bash -s -- -i -6
        ;;
    *)
        echo "无效的选择，请选择 1 或 2。"
        exit 1
        ;;
esac

echo "测试完成。"
