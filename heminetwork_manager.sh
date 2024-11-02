#!/bin/bash

# 定义变量
HEMINETWORK_VERSION="v0.5.0"
# 检测操作系统和架构
case "$(uname -s)" in
    Darwin)
        case "$(uname -m)" in
            x86_64)
                HEMINETWORK_URL="https://github.com/hemilabs/heminetwork/releases/download/${HEMINETWORK_VERSION}/heminetwork_${HEMINETWORK_VERSION}_darwin_amd64.tar.gz"
                HEMINETWORK_DIR="heminetwork_${HEMINETWORK_VERSION}_darwin_amd64"
                ;;
            arm64)
                HEMINETWORK_URL="https://github.com/hemilabs/heminetwork/releases/download/${HEMINETWORK_VERSION}/heminetwork_${HEMINETWORK_VERSION}_darwin_arm64.tar.gz"
                HEMINETWORK_DIR="heminetwork_${HEMINETWORK_VERSION}_darwin_arm64"
                ;;
            *)
                echo "不支持的架构: $(uname -m)"
                exit 1
                ;;
        esac
        ;;
    Linux)
        case "$(uname -m)" in
            x86_64)
                HEMINETWORK_URL="https://github.com/hemilabs/heminetwork/releases/download/${HEMINETWORK_VERSION}/heminetwork_${HEMINETWORK_VERSION}_linux_amd64.tar.gz"
                HEMINETWORK_DIR="heminetwork_${HEMINETWORK_VERSION}_linux_amd64"
                ;;
            aarch64)
                HEMINETWORK_URL="https://github.com/hemilabs/heminetwork/releases/download/${HEMINETWORK_VERSION}/heminetwork_${HEMINETWORK_VERSION}_linux_arm64.tar.gz"
                HEMINETWORK_DIR="heminetwork_${HEMINETWORK_VERSION}_linux_arm64"
                ;;
            *)
                echo "不支持的架构: $(uname -m)"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "不支持的操作系统: $(uname -s)"
        exit 1
        ;;
esac

download() {
    # 下载并解压
    if [ ! -d "$HEMINETWORK_DIR" ]; then
        echo "下载 heminetwork..."
        wget "$HEMINETWORK_URL" -O heminetwork.tar.gz
        echo "解压 heminetwork..."
        tar xvf heminetwork.tar.gz
        rm heminetwork.tar.gz
    else
        # echo "heminetwork 已经存在，跳过下载。"
        echo " "
    fi
}

download
cd "$HEMINETWORK_DIR" || { echo "目录 $HEMINETWORK_DIR 不存在"; exit 1; }

# 在子目录下定义 PID 和 LOG 文件
PID_FILE="heminetwork.pid"
LOG_FILE="log.log"

start() {
    # 检查 wget 是否安装，如果没有安装则安装
    check_wget

    # 下载并解压
    # download

    # 获取用户输入
    read -p "请输入 POPM_STATIC_FEE: " POPM_STATIC_FEE
    read -p "请输入 POPM_BTC_PRIVKEY: " POPM_BTC_PRIVKEY

    # 检查是否已经在运行
    if [ -f "$PID_FILE" ]; then
        echo "程序已经在运行，PID: $(cat "$PID_FILE")"
        exit 1
    fi

    # 导出环境变量
    export POPM_STATIC_FEE
    export POPM_BTC_PRIVKEY
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public

    # 切换到 heminetwork 目录并启动程序
    # cd "$HEMINETWORK_DIR" || { echo "目录 $HEMINETWORK_DIR 不存在"; exit 1; }
    nohup ./popmd > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "程序已启动，PID: $(cat "$PID_FILE")"
}

check_wget() {
    if ! command -v wget &> /dev/null; then
        echo "wget 未安装，正在安装..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install wget
        else
            sudo apt-get update && sudo apt-get install -y wget
        fi
    else
        echo "wget 已安装。"
    fi
}

stop() {
    # 检查 PID 文件是否存在
    if [ ! -f "$PID_FILE" ]; then
        echo "程序未运行。"
        exit 1
    fi

    # 读取 PID 并停止程序
    PID=$(cat "$PID_FILE")
    kill "$PID" && echo "程序已停止，PID: $PID"
    rm -f "$PID_FILE"
}

log() {
    # 查看日志文件
    if [ -f "$LOG_FILE" ]; then
        tail -f  "$LOG_FILE"
    else
        echo "日志文件不存在。"
    fi
}
show_help() {
    echo "用法: $0 {start|stop|log}"
    echo ""
    echo "命令:"
    echo "  start   启动 heminetwork 程序"
    echo "          在启动时，会提示输入环境变量 POPM_STATIC_FEE 和 POPM_BTC_PRIVKEY。"
    echo "          程序会在后台运行，并将 PID 写入到 heminetwork.pid 文件中。"
    echo ""
    echo "  stop    停止 heminetwork 程序"
    echo "          根据 PID 文件停止运行的程序，并删除 PID 文件。"
    echo ""
    echo "  log     查看 heminetwork 的日志"
    echo "          实时显示程序的日志输出。"
    echo ""
    echo "示例:"
    echo "  $0 start  # 启动 heminetwork 程序"
    echo "  $0 stop   # 停止 heminetwork 程序"
    echo "  $0 log    # 查看 heminetwork 日志"
}

# 处理脚本参数
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    log)
        log
        ;;
    *)
        show_help
        exit 1
        ;;
esac
