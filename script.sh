#!/bin/bash

# 依次处理 Testcase1、Testcase2、Testcase3、Testcase4
for number in 1 2 3 4
do
    # 删除上一次运行时生成的差异文件夹。
    # 这样重复运行脚本时，不会留下已经过期的差异文件。
    # 这里不会删除原来的 Testcase1 到 Testcase4 文件夹。
    rm -rf "Testcase${number}Diff"

    # 找出当前 Testcase 文件夹中所有以 .1.txt 结尾的文件
    for first in Testcase"$number"/*.1.txt
    do
        # 取出版本名称。例如 Version1.1.txt 得到 Version1
        version=$(basename "$first" .1.txt)

        # 找到与它配对的 .2.txt 文件
        # 例如 Version1.1.txt 对应 Version1.2.txt
        second="Testcase${number}/${version}.2.txt"

        # 比较这两个文件的内容。
        # “相同”指文件内容完全一样，包括文字、空格和换行。
        # > /dev/null 表示暂时不显示比较结果。
        # 如果内容不同，! 会使程序进入下面的 if 代码块。
        if ! diff -u "$first" "$second" > /dev/null
        then
            # 当前 Testcase 出现差异时，才建立差异文件夹
            mkdir -p "Testcase${number}Diff"

            # 把完整的比较结果写入对应的差异文件；
            # .1.txt 放在前面，.2.txt 放在后面。
            diff -u "$first" "$second" > "Testcase${number}Diff/${version}Diff.txt"
        fi
    done
done