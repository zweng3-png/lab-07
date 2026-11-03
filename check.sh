#!/bin/bash

# 先假设四组 Testcase 全部通过。
# 只要有一组失败，就把这个变量改为 0。
all_pass=1

# 依次检查 Testcase1、Testcase2、Testcase3、Testcase4。
for number in 1 2 3 4
do
    # 每开始检查一组，都先假设这一组通过。
    case_pass=1

    # expected_count：这一组按原始文件比较后，应该有多少个差异文件。
    # actual_count：对应 Diff 文件夹里实际有多少个文件。
    expected_count=0
    actual_count=0

    # 例如 number 为 2 时，folder 就是 Testcase2Diff。
    folder="Testcase${number}Diff"

    # 遍历当前 Testcase 文件夹里所有以 .1.txt 结尾的文件。
    # 每个 .1.txt 都要与同名的 .2.txt 比较。
    for first in "Testcase${number}"/*.1.txt
    do
        # 从完整路径中取出文件名。
        # 例如 Testcase2/Version1.1.txt 得到 Version1.1.txt。
        filename=$(basename "$first")

        # 去掉文件名末尾的 .1.txt，得到版本名。
        # 例如 Version1.1.txt 得到 Version1。
        version=${filename%.1.txt}

        # 找到与当前 .1.txt 配对的 .2.txt 文件。
        # 例如 Testcase2/Version1.2.txt。
        second="Testcase${number}/${version}.2.txt"

        # 如果两个文件不同，script.sh 应生成这个差异文件。
        # 例如 Testcase2Diff/Version1Diff.txt。
        result="${folder}/${version}Diff.txt"

        # diff 返回 0 表示两份原始文件内容完全相同。
        # 输出送到 /dev/null，因为这里仅需要判断是否相同。
        if diff -u "$first" "$second" > /dev/null
        then
            # 原始文件相同时，不应该存在对应的差异文件。
            # 如果差异文件存在，说明结果有误。
            if [ -e "$result" ]
            then
                case_pass=0
            fi
        else
            # 原始文件不同时，应该产生一个差异文件。
            expected_count=$((expected_count + 1))

            # 应有的差异文件不存在，这一组检查失败。
            if [ ! -f "$result" ]
            then
                case_pass=0
            else
                # 重新比较两份原始文件，得到正确的 diff 内容。
                # tail -n +3 跳过 diff 输出的前两行：
                # 那两行包含文件名和时间戳，时间戳可能发生变化。
                expected=$(diff -u "$first" "$second" | tail -n +3)

                # 读取 script.sh 已生成的差异文件，
                # 同样跳过前两行，再比较实际的差异内容。
                actual=$(tail -n +3 "$result")

                # 差异内容不一致，说明生成的文件有误。
                if [ "$expected" != "$actual" ]
                then
                    case_pass=0
                fi
            fi
        fi
    done

    if [ "$expected_count" -eq 0 ]
    then
        # 如果这一组所有文件都相同，就不应该创建 Diff 文件夹。
        if [ -d "$folder" ]
        then
            case_pass=0
        fi
    else
        # 如果这一组至少有一对文件不同，就应该存在 Diff 文件夹。
        if [ ! -d "$folder" ]
        then
            case_pass=0
        else
            # 统计 Diff 文件夹里实际生成的文件数。
            for generated in "$folder"/*
            do
                # 当文件夹为空时，* 不会匹配到文件；
                # 因此先确认当前路径确实存在。
                if [ -e "$generated" ]
                then
                    actual_count=$((actual_count + 1))

                    # Diff 文件夹中应该放差异文件，而不是子文件夹。
                    if [ ! -f "$generated" ]
                    then
                        case_pass=0
                    fi
                fi
            done

            # 实际文件数与应有文件数不同，表示缺少或多出了文件。
            if [ "$actual_count" -ne "$expected_count" ]
            then
                case_pass=0
            fi
        fi
    fi

    # 每组只打印一行检查结果。
    if [ "$case_pass" -eq 1 ]
    then
        echo "Testcase${number}: PASS"
    else
        echo "Testcase${number}: FAIL"

        # 记录“至少有一组失败”，供最后确定退出状态。
        all_pass=0
    fi
done

# 四组全部通过时返回 0；有任何一组失败时返回 1。
if [ "$all_pass" -eq 1 ]
then
    exit 0
else
    exit 1
fi