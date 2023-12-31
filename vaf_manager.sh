#!/bin/bash

export MICRO_SERVICE_PATH="/home/zhaosheng/asr_damo_websocket/online/microservice"
export GUNICORN="/opt/anaconda/anaconda3/envs/server_dev/bin/gunicorn"

gpu_available=0

# 检查系统是否有可用GPU
if command -v nvidia-smi &> /dev/null; then
    gpu_info=$(nvidia-smi -L)
    if [[ ! -z $gpu_info ]]; then
        gpu_available=1
        echo "系统中存在可用的GPU。"
    else
        echo "系统中没有可用的GPU。"
    fi
else
    echo "未找到nvidia-smi命令，无法检测GPU信息。"
fi


# 服务配置
declare -A server_paths=(
    ["asr"]="${MICRO_SERVICE_PATH}/servers/asr_server/offline/python_cpu"
    ["encode"]="${MICRO_SERVICE_PATH}/servers/encode_server"
    ["lang"]="${MICRO_SERVICE_PATH}/servers/language_classify_server"
    ["text_classify"]="${MICRO_SERVICE_PATH}/servers/text_classify_server"
    ["vad_nn"]="${MICRO_SERVICE_PATH}/servers/vad_server/nn"
    ["vad_energy"]="${MICRO_SERVICE_PATH}/servers/vad_server/energybase"
)

declare -A ports=(
    ["asr"]="5000"
    ["encode"]="5001"
    ["lang"]="5002"
    ["text_classify"]="5003"
    ["vad_nn"]="5004"
    ["vad_energy"]="5005"
)

declare -A gpus=(
    ["asr"]="1"
    ["encode"]="2"
    ["lang"]="0"
    ["text_classify"]="0"
    ["vad_nn"]="0"
    ["vad_energy"]="0"
)

declare -A workers=(
    ["asr"]="1"
    ["encode"]="1"
    ["lang"]="1"
    ["text_classify"]="1"
    ["vad_nn"]="1"
    ["vad_energy"]="1"
)

# Gunicorn配置
declare -A daemon=(
    ["start"]="0"
    ["stop"]="1"
)

worker_class="gevent"
worker_connections="1000"

print_table_header() {
    printf "+----------------------------------------------------------+\n"
    printf "| %-30s | %-10s | %-10s |\n" "NAME" "RUNNING" "PORT"
    printf "+----------------------------------------------------------+\n"
    # printf "+----------------------+-----------------+---------------------------------------------------------+\n"
}

print_table_row() {
    service_name=$1
    service_status=$2
    service_path=${server_paths[$service_name]}
    port=${ports[$service_name]}
    # print_table_header()
    if [ "$service_status" == "running" ]; then
        printf "| %-30s | %-10s | %-10s |\n" "$service_name" "YES" "$port"
    else
        printf "| %-30s | %-10s | %-10s |\n" "$service_name" "NO" "NONE"
    fi
}

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
    # 如果service_path不存在log目录，则创建
    if [ ! -d "$service_path/log" ]; then
        mkdir -p "$service_path/log"
    fi
    port=${ports[$service_name]}
    worker=${workers[$service_name]}
    pid_file="$service_path/log/gunicorn.pid"
    # 切换到服务目录
    cd "$service_path" || exit 1

    # 创建日志目录
    mkdir -p "./log"

    echo "正在启动 $service_name 服务，路径：$service_path，端口号：$port，工作进程数：$worker"


    # echo "CUDA_VISIBLE_DEVICES=${gpus[$service_name]} $GUNICORN main:app \
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
    CUDA_VISIBLE_DEVICES=${gpus[$service_name]} $GUNICORN main:app \
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

restart_service() {
    service_name=$1
    service_path=${server_paths[$service_name]}
    stop_service "$service_name"
    start_service "$service_name"
}

clean_service() {
    service_name=$1
    service_path=${server_paths[$service_name]}
    # 停止服务
    stop_service "$service_name"
    # 删除日志文件
    rm -rf "$service_path/log"
    # 递归删除文件名中包含"__"的文件或文件夹
    find "$service_path" -name "*__*" -exec rm -rf {} +
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
        print_table_header
        for service in "${services[@]}"; do
            if [ -z "${server_paths[$service]}" ]; then
                echo "无效的服务名称：$service"
                usage
            fi
            
            if manage_status "$service" | grep -q "正在运行"; then
                print_table_row "$service" "running"
            else
                print_table_row "$service" "not running"
            fi
            # manage_status "$service"
            echo ""
        done
        printf "+----------------------------------------------------------+\n"
        ;;
        
    # if [ "$action" == "restart" ]; then
    #     if [ -z "$1" ]; then
    #         echo "请指定要重启的服务名称。"
    #         usage
    #     fi
    #     service_name=$1
    #     if [ -z "${server_paths[$service_name]}" ]; then
    #         echo "无效的服务名称：$service_name"
    #         usage
    #     fi
    #     restart_service "$service_name"

    # elif [ "$action" == "clean" ]; then
    #     if [ -z "$1" ]; then
    #         echo "请指定要清理的服务名称。"
    #         usage
    #     fi
    #     service_name=$1
    #     if [ -z "${server_paths[$service_name]}" ]; then
    #         echo "无效的服务名称：$service_name"
    #         usage
    #     fi
    #     clean_service "$service_name"
    # fi
    "restart")
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
            restart_service "$service"
        done
        ;;
    "clean")
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
            clean_service "$service"
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
