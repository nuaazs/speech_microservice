#!/bin/bash

export MICRO_SERVICE_PATH="/home/zhaosheng/asr_damo_websocket/online/microservice"
export GUNICORN="/opt/anaconda/anaconda3/envs/server_dev/bin/gunicorn"
# 服务配置
declare -A server_paths=(
    ["asr_server"]="${MICRO_SERVICE_PATH}/servers/asr_server/offline/python_cpu"
    ["encode_server"]="${MICRO_SERVICE_PATH}/servers/encode_server"
    ["language_classify_server"]="${MICRO_SERVICE_PATH}/servers/language_classify_server"
    ["text_classify_server"]="${MICRO_SERVICE_PATH}/servers/text_classify_server"
    ["vad_server_nn"]="${MICRO_SERVICE_PATH}/servers/vad_server/nn"
    ["vad_server_energybase"]="${MICRO_SERVICE_PATH}/servers/vad_server/energybase"
)

declare -A ports=(
    ["asr_server"]="5000"
    ["encode_server"]="5001"
    ["language_classify_server"]="5002"
    ["text_classify_server"]="5003"
    ["vad_server_nn"]="5004"
    ["vad_server_energybase"]="5005"
)

declare -A workers=(
    ["asr_server"]="1"
    ["encode_server"]="1"
    ["language_classify_server"]="1"
    ["text_classify_server"]="1"
    ["vad_server_nn"]="1"
    ["vad_server_energybase"]="1"
)

# Gunicorn配置
declare -A daemon=(
    ["start"]="0"
    ["stop"]="1"
)

worker_class="gevent"
worker_connections="1000"

manage_status() {
    service_name=$1
    service_path=${server_paths[$service_name]}
    pid_file="$service_path/log/gunicorn.pid"

    if [ -f "$pid_file" ]; then
        echo "$service_name 服务正在运行。"
        echo "服务路径：$service_path"
        echo "端口号：${ports[$service_name]}"
    else
        echo "$service_name 服务未运行。"
    fi
}

start_service() {
    service_name=$1
    service_path=${server_paths[$service_name]}
    port=${ports[$service_name]}
    worker=${workers[$service_name]}
    pid_file="$service_path/log/gunicorn.pid"
    # 切换到服务目录
    cd "$service_path" || exit 1

    # 创建日志目录
    mkdir -p "./log"

    echo "正在启动 $service_name 服务，路径：$service_path，端口号：$port，工作进程数：$worker"

    # echo cmd
    # echo "$GUNICORN main:app \
    #     --bind '0.0.0.0:$port' \
    #     --workers '$worker' \
    #     --daemon \
    #     --worker-class '$worker_class' \
    #     --worker-connections '$worker_connections' \
    #     --pid "$pid_file" \
    #     --access-logfile '$service_path/log/gunicorn_access.log' \
    #     --error-logfile '$service_path/log/gunicorn_error.log' \
    #     --log-level "info" &"
    # 启动服务
    $GUNICORN main:app \
        --bind "0.0.0.0:$port" \
        --workers "$worker" \
        --daemon \
        --worker-class "$worker_class" \
        --worker-connections "$worker_connections" \
        --pid "$pid_file" \
        --access-logfile "$service_path/log/gunicorn_access.log" \
        --error-logfile "$service_path/log/gunicorn_error.log" \
        --log-level "info" &
    
    # 检查启动是否成功
    sleep 2
    if [ -f "$pid_file" ]; then
        echo "$service_name 服务已成功启动。"
    else
        echo "$service_name 服务启动失败，请检查日志文件：$service_path/log/gunicorn_error.log"
    fi
}

stop_service() {
    service_name=$1
    service_path=${server_paths[$service_name]}
    pid_file="$service_path/log/gunicorn.pid"

    if [ -f "$pid_file" ]; then
        echo "正在停止 $service_name 服务..."
        pid=$(cat "$pid_file")
        kill "$pid"
        echo "服务已停止。"
        # 删除pid文件
        rm "$pid_file"
    else
        echo "找不到 $service_name 服务的PID文件，服务可能未在运行中。"
    fi
}

test_service() {
    service_name=$1
    service_path=${server_paths[$service_name]}
    test_file="$service_path/test_api.py"

    if [ -f "$test_file" ]; then
        echo "正在运行 $service_name 服务的测试脚本..."
        python "$test_file"
    else
        echo "找不到 $service_name 服务的测试脚本。"
    fi
}

# 解析命令行选项
action=""
services=()

usage() {
    echo "用法: $0 <start|stop|status|test> <service_names>"
    echo "可用的服务名称: ${!server_paths[@]}"
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

action=$1
shift

case "$action" in
    "start")
        if [ "$1" == "all" ]; then
            services=("${!server_paths[@]}")
        else
            services=("$@")
        fi
        
        for service in "${services[@]}"; do
            if [ -z "${server_paths[$service]}" ]; then
                echo "无效的服务名称：$service"
                usage
            fi
            start_service "$service"
        done
        ;;
    "stop")
        if [ "$1" == "all" ]; then
            services=("${!server_paths[@]}")
        else
            services=("$@")
        fi
        
        for service in "${services[@]}"; do
            if [ -z "${server_paths[$service]}" ]; then
                echo "无效的服务名称：$service"
                usage
            fi
            stop_service "$service"
        done
        ;;
    "status")
        if [ "$1" == "all" ]; then
            services=("${!server_paths[@]}")
        else
            services=("$@")
        fi
        
        for service in "${services[@]}"; do
            if [ -z "${server_paths[$service]}" ]; then
                echo "无效的服务名称：$service"
                usage
            fi
            manage_status "$service"
            echo ""
        done
        ;;
    "test")
        if [ "$1" == "all" ]; then
            services=("${!server_paths[@]}")
        else
            services=("$@")
        fi
        
        for service in "${services[@]}"; do
            if [ -z "${server_paths[$service]}" ]; then
                echo "无效的服务名称：$service"
                usage
            fi
            test_service "$service"
        done
        ;;
    "-h"|"--help"|"--h"|"-help")
        usage
        ;;
    *)
        usage
        ;;
esac
