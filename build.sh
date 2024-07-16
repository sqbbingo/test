#!/bin/bash

# 初始化BOARD变量  
BOARD=""  

#检查是否有拉取了代码，没有则拉取
function check_armbian_source {
    if [[ 0 -eq $# ]]; then
        echo "Error check_armbian_source, must input branch"
        exit -1
    fi

    # 定义仓库URL和分支  
    REPO_URL="https://github.com/armbian/build"  
    BRANCH=$1
    BUILD_DIR="./build"  

    echo "BRANCH:"$BRANCH
      
    # 检查build目录是否存在  
    if [ ! -d "$BUILD_DIR" ]; then  
        echo "Build directory does not exist, creating..."  
        mkdir -p "$BUILD_DIR"  
    fi  
      
    # 检查build目录内是否存在git仓库  
    if [ -d "$BUILD_DIR/.git" ]; then  
        echo "Git repository found in $BUILD_DIR, updating..."  
        # 进入仓库目录  
        cd "$BUILD_DIR"  
        # 尝试获取远程分支的最新状态，并更新到该状态  
        git fetch origin "$BRANCH"  
        git reset --hard origin/"$BRANCH"  
        # 如果需要，也可以尝试git pull，但这会合并更改，而不是重置  
        # git pull origin "$BRANCH"  
        echo "Updated to the latest commit on $BRANCH branch."  
    else  
        echo "Git repository not found in $BUILD_DIR, cloning..."  
        # 克隆仓库到build目录，仅获取最近的提交  
        git clone --depth=1 --branch="$BRANCH" "$REPO_URL" "$BUILD_DIR"  
        echo "Cloned repository to $BUILD_DIR."  
    fi  
      
    # 可选：回到脚本开始时的目录  
    cd - 
}


function get_board_name {
    # 检查是否有输入参数 --board  
    while [[ $# -gt 0 ]]; do  
        case $1 in  
            --board)  
                shift  
                BOARD=$1  
                # 检查BOARD变量是否已设置且非空  
                if [[ -z "$BOARD" ]]; then  
                    echo "Error: No board name specified after --board."  
                    exit 1  
                fi  
                # 跳出循环，因为我们已经找到了需要的参数  
                break  
                ;;  
            *)  
                # 忽略未知参数  
                ;;  
        esac  
        shift  
    done  
      
    # 如果没有通过参数设置BOARD，则让用户选择  
    if [[ -z "$BOARD" ]]; then  
        echo "Please select a board from the list:"  
        # 列出board/下的所有子文件夹，并存储到数组中  
        boards=($(ls -d board/*/ | sed 's|board/||'))  
          
        PS3="Please enter your choice (1-N): "  # 自定义select的提示信息  
        select board_choice in "${boards[@]}"; do  
            if [[ -n "$board_choice" ]]; then  
                echo "You chose $board_choice"  
                BOARD="$board_choice"  
                break  
            else  
                echo "Invalid input, please try again."  
            fi  
        done  
      
        # 检查用户输入的BOARD是否有效  
        if [[ ! -d "board/$BOARD" ]]; then  
            echo "Error: The selected board directory does not exist."  
            exit 1  
        fi  
    fi  
}  

function main {
    get_board_name $@
    # 检查board/$BOARD目录下是否有build.sh脚本  
    if [[ ! -f "board/$BOARD/build_board.sh" ]]; then  
        echo "Error: No build_board.sh script found in board/$BOARD."  
        exit 1  
    fi  

    # 使用source执行build_board.sh脚本  
    echo "Executing build_board.sh for board $BOARD..."  
    source "board/$BOARD/build_board.sh" 


    board_pull_source
    board_patch
    board_armbian_compile
}

main $@
