#!/bin/bash

IP_ADDRESS=""
# 获取本机IP地址
get_ip_address() {
    # 使用ip addr命令获取本机IP地址
    IP_ADDRESS=$(ip addr | awk '/inet / && !/127.0.0.1/ {gsub(/\/.*/,"",$2); print $2}')
}


# 检查系统环境
check_system() {
    # 检查系统是否为Linux
    if [ "$(uname)" != "Linux" ]; then
        echo "错误：本脚本只支持Linux系统"
        exit 1
    fi
    
    # 在这里添加其他系统检查逻辑，例如检查操作系统版本等
}

# 安装依赖
install_dependencies() {
    # 在这里添加安装依赖的命令，例如使用apt-get、yum等
    yum install -y wget gcc gcc-c++ glibc glibc-common gd gd-devel xinetd openssl openssl-devel pcre-devel expat-devel python-devel mysql-devel cmake ncurses-devel bison devtoolset ruby rubygems tcl gpg2 pcre patch vim unzip libevent 
}

# 检查并下载软件包
# 函数：检查并下载软件包
# 参数1：软件包名称数组
# 参数2：下载链接数组
# 参数3：保存路径数组
check_and_download_packages() {
    # 软件包名称数组
    package_names=(
        "apache-activemq-5.15.5-bin.tar.gz"
        "fastdfs-6.06.tar.gz"
        "libfastcommon-1.0.43.tar.gz"
        "nginx-1.16.1.tar.gz"
        "nginx_upstream_check_module-master.zip"
        "redis-7.0.2.tar.gz"
        "apache-zookeeper-3.7.1-bin.tar.gz"
        "apache-tomcat-8.5.87.tar.gz"
    )

    # 下载链接数组
    download_links=(
        "http://archive.apache.org/dist/activemq/5.15.5/apache-activemq-5.15.5-bin.tar.gz"
        "https://codeload.github.com/happyfish100/fastdfs/tar.gz/V6.06"
        "https://codeload.github.com/happyfish100/libfastcommon/tar.gz/V1.0.43"
        "https://nginx.org/download/nginx-1.16.1.tar.gz"
        "https://codeload.github.com/yaoweibin/nginx_upstream_check_module/zip/refs/heads/master"
        "https://download.redis.io/releases/redis-7.0.2.tar.gz"
        "https://archive.apache.org/dist/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz"
        "https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.87/bin/apache-tomcat-8.5.87.tar.gz"
    )

    # 保存路径数组
    save_paths=(
        "/tmp/7.0soft/activeMq"
        "/tmp/7.0soft/fastDFS"
        "/tmp/7.0soft/fastDFS"
        "/tmp/7.0soft/nginx"
        "/tmp/7.0soft/nginx"
        "/tmp/7.0soft/redis"
        "/tmp/7.0soft/zookeeper"
        "/tmp/7.0soft/tomcat8"
    )

    # 定义检查并下载软件包的函数
    check_and_download_package() {
        local package_name=$1
        local download_link=$2
        local save_path=$3

        # 在全盘中查找软件包
        local found_package=$(find / -type f -name "$package_name" -print -quit)

        # 如果找到软件包
        if [ -n "$found_package" ]; then
            echo "发现 $package_name，位于：$found_package"

            # 确定目标目录是否存在
            if [ ! -d "$save_path" ]; then
                echo "创建目录：$save_path"
                mkdir -p "$save_path"
            fi

            # 移动软件包到目标目录
            mv "$found_package" "$save_path"
            echo "已移动 $package_name 到 $save_path"
        else
            # 如果软件包不存在，则下载
            echo "正在下载 $package_name..."
            wget -P "$save_path" "$download_link"
        fi
    }

    # 遍历数组调用函数进行检查和下载
    for ((i=0; i<${#package_names[@]}; i++)); do
        check_and_download_package "${package_names[i]}" "${download_links[i]}" "${save_paths[i]}"
    done

    echo "下载完成。"
}

# 安装JDK 1.8
install_jdk() {
    yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel.x86_64
    sleep 1
}

# 安装Tomcat 8
install_tomcat() {
    # 3.1 解压Tomcat8并移动到指定目录
    mkdir -p /home/hxsoft
    cd /tmp/7.0soft/tomcat8
    tar -xzvf apache-tomcat-8.5.87.tar.gz
    mv apache-tomcat-8.5.87 /home/hxsoft/apache-tomcat-8.5.87
    sleep 3

    # 3.2 添加JVM参数脚本
    cat <<EOF > /home/hxsoft/apache-tomcat-8.5.87/bin/setenv.sh
#!/bin/sh
export CATALINA_OPTS=" -Djava.net.preferIPv4Stack=true -Dcom.sun.management.jmxremote=true -Djava.security.egd=file:/dev/./urandom -Xms512M -Xmx4096M -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime -XX:+PrintHeapAtGC -Xloggc:\$CATALINA_HOME/logs/\`date +"%Y-%m-%d"\`_gc.log"
EOF

    # 赋予脚本可执行权限
    chmod +x /home/hxsoft/apache-tomcat-8.5.87/bin/setenv.sh

    # 3.3 Tomcat开启PID文件
    sed -i '/^PRGDIR/a CATALINA_PID=$PRGDIR/tomcat.pid' /home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh

    # 3.4 添加Tomcat为系统服务
    cat <<EOF > /usr/lib/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking
PIDFile=/home/hxsoft/apache-tomcat-8.5.87/bin/tomcat.pid
ExecStart=/home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh start
ExecReload=/home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh restart
ExecStop=/home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh stop

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable tomcat

}

# 安装Redis
install_redis() {
    # 5.1 解压redis安装包
    cd /tmp/7.0soft/redis
    tar zxvf redis-7.0.2.tar.gz

    # 5.2 编译并安装redis
    cd /tmp/7.0soft/redis/redis-7.0.2
    make
    make install PREFIX=/home/hxsoft/redis-7.0.2

    # 5.3 配置环境变量
    echo 'REDIS_HOME=/home/hxsoft/redis-7.0.2' >> ~/.bash_profile
    echo 'PATH=$PATH:$REDIS_HOME/bin' >> ~/.bash_profile
    source ~/.bash_profile

    # 5.4 为方便管理，进行文件整合
    mkdir /home/hxsoft/redis-7.0.2/etc
    cp /tmp/7.0soft/redis/redis-7.0.2/redis.conf /home/hxsoft/redis-7.0.2/etc/redis1.conf
    cp /tmp/7.0soft/redis/redis-7.0.2/sentinel.conf /home/hxsoft/redis-7.0.2/etc/sentinel1.conf

    # 5.5 修改redis配置文件
    sed -i 's/^daemonize no/daemonize yes/g' /home/hxsoft/redis-7.0.2/etc/redis1.conf
    sed -i 's#^requirepass.*#requirepass password#g' /home/hxsoft/redis-7.0.2/etc/redis1.conf
    sed -i '/^bind 127.0.0.1 -::1/a bind 0.0.0.0' /home/hxsoft/redis-7.0.2/etc/redis1.conf

    # 5.6 添加redis为系统服务
    cat <<EOF > /usr/lib/systemd/system/redis.service
[Unit]
Description=redis-server
After=network.target

[Service]
Type=forking

ExecStart=/home/hxsoft/redis-7.0.2/bin/redis-server /home/hxsoft/redis-7.0.2/etc/redis1.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable redis
}

# 安装Zookeeper
install_zookeeper() {
    # 7.1 解压文件并移动文件
    cd /tmp/7.0soft/zookeeper/
    tar zxvf apache-zookeeper-3.7.1-bin.tar.gz
    mv /tmp/7.0soft/zookeeper/apache-zookeeper-3.7.1-bin /home/hxsoft

    # 7.2 配置zookeeper的jvm参数
    cat <<EOF > /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/java.env
#!/bin/sh
export JVMFLAGS=" -Xmx5g -Xms128m -Xss1280k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 \$JVMFLAGS"
EOF

    # 7.3 修改配置文件
    cp /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo_sample.cfg /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo.cfg
    sed -i 's#dataDir=/tmp/zookeeper#dataDir=/data/hxsoft/zookeeper/data#g' /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo.cfg
    sed -i 's#admin.serverPort=8080#admin.serverPort=8887#g' /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo.cfg
    # 修改zookeeper端口，防止与tomcat产生冲突

    # 7.4 添加zookeeper为系统服务
    cat <<EOF > /usr/lib/systemd/system/zookeeper.service
[Unit]
Description=zookeeper
After=syslog.target network.target

[Service]
Type=forking
Environment=ZOO_LOG_DIR=/home/hxsoft/apache-zookeeper-3.7.1-bin/logs
ExecStart=/home/hxsoft/apache-zookeeper-3.7.1-bin/bin/zkServer.sh start
ExecStop=/home/hxsoft/apache-zookeeper-3.7.1-bin/bin/zkServer.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable zookeeper
}

# 安装ActiveMQ
install_activemq() {
    # 8.1 解压activemq，并移动文件
    cd /tmp/7.0soft/activeMq
    tar zxvf apache-activemq-5.15.5-bin.tar.gz
    mv /tmp/7.0soft/activeMq/apache-activemq-5.15.5 /home/hxsoft

    # 8.2 修改密码文件
    sed -i 's/admin: adminpasswd, admin/admin:adminpasswd, admin/g' /home/hxsoft/apache-activemq-5.15.5/conf/jetty-realm.properties
    sed -i 's/user: userpasswd, user/user:userpasswd, user/g' /home/hxsoft/apache-activemq-5.15.5/conf/jetty-realm.properties

    # 8.4 添加activemq为系统服务
    cat <<EOF > /usr/lib/systemd/system/activemq.service
[Unit]
Description=activemq message queue
After=network.target

[Service]
PIDFile=/home/hxsoft/apache-activemq-5.15.5/data/activemq.pid
ExecStart=/home/hxsoft/apache-activemq-5.15.5/bin/activemq start
ExecStop=/home/hxsoft/apache-activemq-5.15.5/bin/activemq stop
Restart=always
RestartSec=9
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=activemq

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable activemq
}


# 安装Nginx
install_nginx() {
    # 4.1 解压缩nginx1.16.1和nginx_upstream_check_module源码
    cd /tmp/7.0soft/nginx
    unzip nginx_upstream_check_module-master.zip
    tar -zxvf nginx-1.16.1.tar.gz
    
    # 4.2 为nginx源码打上nginx_upstream_check_module补丁
    cd /tmp/7.0soft/nginx/nginx-1.16.1
    patch -p1 < ../nginx_upstream_check_module-master/check_1.16.1+.patch
    
    # 4.3 设置编译参数
    ./configure --prefix=/home/hxsoft/nginx-1.16.1 \
                --sbin-path=/home/hxsoft/nginx-1.16.1/bin/nginx \
                --conf-path=/home/hxsoft/nginx-1.16.1/etc/nginx.conf \
                --error-log-path=/home/hxsoft/nginx-1.16.1/log/error.log \
                --http-log-path=/home/hxsoft/nginx-1.16.1/log/access.log \
                --pid-path=/home/hxsoft/nginx-1.16.1/run/nginx.pid \
                --lock-path=/home/hxsoft/nginx-1.16.1/run/nginx.lock \
                --with-http_ssl_module \
                --with-http_flv_module \
                --with-http_stub_status_module \
                --with-http_gzip_static_module \
                --http-client-body-temp-path=/home/hxsoft/nginx-1.16.1/tmp/client/ \
                --http-scgi-temp-path=/home/hxsoft/nginx-1.16.1/tmp/scgi \
                --with-pcre \
                --with-file-aio \
                --with-http_image_filter_module \
                --add-module=../nginx_upstream_check_module-master
    
    # 4.4 编译并安装
    make && make install
    
    # 4.5 创建必要的文件夹
    mkdir /home/hxsoft/nginx-1.16.1/tmp
    
    # 4.6 添加nginx为系统服务
    cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
PIDFile=/home/hxsoft/nginx-1.16.1/run/nginx.pid
ExecStartPre=/home/hxsoft/nginx-1.16.1/bin/nginx -c /home/hxsoft/nginx-1.16.1/etc/nginx.conf
ExecStart=/home/hxsoft/nginx-1.16.1/bin/nginx
ExecReload=/home/hxsoft/nginx-1.16.1/bin/nginx -s reload
ExecStop=/home/hxsoft/nginx-1.16.1/bin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    # 编辑nginx的配置文件，设置pid路径
    sed -i 's#pid .*;#pid /home/hxsoft/nginx-1.16.1/run/nginx.pid;#g' /home/hxsoft/nginx-1.16.1/etc/nginx.conf
    systemctl enable nginx
}



# 安装FastDFS
install_fastdfs() {
    # 6.1 解压fastdfs和libfastcommon
    cd /tmp/7.0soft/fastDFS
    tar zxvf fastdfs-6.06.tar.gz
    tar zxvf libfastcommon-1.0.43.tar.gz
    
    # 6.2 编译安装libfastcommon
    cd /tmp/7.0soft/fastDFS/libfastcommon-1.0.43
    ./make.sh && ./make.sh install
    
    # 6.3 编译安装fastdfs
    cd /tmp/7.0soft/fastDFS/fastdfs-6.06
    # 修改安装目录和配置文件目录
    sed -i 's#TARGET_PREFIX=.*#TARGET_PREFIX=/home/hxsoft/fastdfs6.06#g' make.sh
    sed -i 's#TARGET_CONF_PATH=.*#TARGET_CONF_PATH=/home/hxsoft/fastdfs6.06/etc#g' make.sh
    ./make.sh && ./make.sh install
    
    # 6.4 编辑配置文件
    cp /home/hxsoft/fastdfs6.06/etc/http.conf.sample /home/hxsoft/fastdfs6.06/etc/http.conf
    # 设置http.anti_steal.token_check_fail为空
    sed -i 's#http.anti_steal.token_check_fail =.*#http.anti_steal.token_check_fail =#g' /home/hxsoft/fastdfs6.06/etc/http.conf
    
    # 编辑tracker.conf
    cat <<EOF > /home/hxsoft/fastdfs6.06/etc/tracker.conf
disabled=false
bind_addr=
port=22122
connect_timeout=10
network_timeout=60
base_path=/data/hxsoft/fastdfs
max_connections=1024
accept_threads=1
work_threads=4
min_buff_size = 8KB
max_buff_size = 128KB
store_lookup=2
store_group=group1
store_server=0
store_path=0
download_server=0
reserved_storage_space = 10%
log_level=info
run_by_group=
run_by_user=
allow_hosts=*
sync_log_buff_interval = 10
check_active_interval = 120
thread_stack_size = 64KB
storage_ip_changed_auto_adjust = true
storage_sync_file_max_delay = 86400
storage_sync_file_max_time = 300
use_trunk_file = false 
slot_min_size = 256
slot_max_size = 16MB
trunk_file_size = 64MB
trunk_create_file_advance = false
trunk_create_file_time_base = 02:00
trunk_create_file_interval = 86400
trunk_create_file_space_threshold = 20G
trunk_init_check_occupying = false
trunk_init_reload_from_binlog = false
trunk_compress_binlog_min_interval = 0
use_storage_id = false
storage_ids_filename = storage_ids.conf
id_type_in_filename = ip
store_slave_file_use_link = false
rotate_error_log = false
error_log_rotate_time=00:00
rotate_error_log_size = 0
log_file_keep_days = 0
use_connection_pool = false
connection_pool_max_idle_time = 3600
http.server_port=8080
http.check_alive_interval=30
http.check_alive_type=tcp
http.check_alive_uri=/status.html
EOF

    # 编辑storage.conf
    cat <<EOF > /home/hxsoft/fastdfs6.06/etc/storage.conf
disabled=false
group_name=group1
bind_addr=
client_bind=true
port=23000
connect_timeout=30
network_timeout=60
heart_beat_interval=30
stat_report_interval=60
base_path=/data/hxsoft/fastdfs
max_connections=1024
buff_size = 256KB
accept_threads=1
work_threads=4
disk_rw_separated = true
disk_reader_threads = 1
disk_writer_threads = 1
sync_wait_msec=50
sync_interval=0
sync_start_time=00:00
sync_end_time=23:59
write_mark_file_freq=500
store_path_count=1
store_path0=/data/hxsoft/fastdfs
subdir_count_per_path=256
tracker_server=$IP_ADDRESS:22122
log_level=info
run_by_group=
run_by_user=
allow_hosts=*
file_distribute_path_mode=0
file_distribute_rotate_count=100
fsync_after_written_bytes=0
sync_log_buff_interval=10
sync_binlog_buff_interval=10
sync_stat_file_interval=300
thread_stack_size=512KB
upload_priority=10
if_alias_prefix=
check_file_duplicate=0
file_signature_method=hash
key_namespace=FastDFS
keep_alive=0
use_access_log = false
rotate_access_log = false
access_log_rotate_time=00:00
rotate_access_log_size = 0
rotate_error_log_size = 0
log_file_keep_days = 0
file_sync_skip_invalid_record=false
use_connection_pool = false
connection_pool_max_idle_time = 3600
http.domain_name=
http.server_port=8888
EOF

    # 添加FastDFS为系统服务
    cat <<EOF > /usr/lib/systemd/system/tracker.service
[Unit]
Description=The FastDFS File server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/data/hxsoft/fastdfs/data/fdfs_trackerd.pid
ExecStart=/home/hxsoft/fastdfs6.06/bin/fdfs_trackerd /home/hxsoft/fastdfs6.06/etc/tracker.conf start
ExecStop=/home/hxsoft/fastdfs6.06/bin/fdfs_trackerd /home/hxsoft/fastdfs6.06/etc/tracker.conf stop

[Install]
WantedBy=multi-user.target
EOF

    mkdir -p /data/hxsoft/fastdfs/data/
    
    cat <<EOF > /usr/lib/systemd/system/storage.service
[Unit]
Description=The FastDFS File server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/data/hxsoft/fastdfs/data/fdfs_storaged.pid
ExecStart=/home/hxsoft/fastdfs6.06/bin/fdfs_storaged /home/hxsoft/fastdfs6.06/etc/storage.conf start
ExecStop=/home/hxsoft/fastdfs6.06/bin/fdfs_storaged /home/hxsoft/fastdfs6.06/etc/storage.conf stop
ExecRestart=/home/hxsoft/fastdfs6.06/bin/fdfs_storaged /home/hxsoft/fastdfs6.06/etc/storage.conf restart

[Install]
WantedBy=multi-user.target
EOF

    cat <<EOF > /etc/fdfs/client.conf
connect_timeout = 5
network_timeout = 60
base_path = /data/hxsoft/fastdfs
tracker_server = $IP_ADDRESS:22122
log_level = info
use_connection_pool = false
connection_pool_max_idle_time = 3600
load_fdfs_parameters_from_tracker = false
use_storage_id = false
storage_ids_filename = storage_ids.conf
http.tracker_server_port = 80
EOF

    systemctl daemon-reload
    systemctl enable tracker.service
    systemctl enable storage.service
}



# 结束
finish() {
    systemctl start tomcat
    systemctl start nginx
    systemctl start tracker
    systemctl start storage
    systemctl start redis
    systemctl start zookeeper
    systemctl start activemq

    systemctl status tomcat
    systemctl status nginx
    systemctl status tracker
    systemctl status storage
    systemctl status redis
    systemctl status zookeeper
    systemctl status activemq

    echo "安装完成"
    # 在这里可以输出安装结果等信息
}

# 主函数，依次调用以上步骤
main() {
    get_ip_address
    #check_system
    install_dependencies
    check_and_download_packages
    install_jdk
    install_tomcat
    install_nginx
    install_redis
    #download_packages
    install_fastdfs
    install_zookeeper
    #configure_packages
    install_activemq
    finish
}

# 执行主函数
main
