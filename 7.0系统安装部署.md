# 7.0系统安装部署
## 0.0 将7.0soft目录拷贝至/tmp/目录下，文件列表如下

    [root@localhost 7.0soft]# pwd
    /tmp/7.0soft
    [root@oracledb 7.0soft]# ls -la
    总用量 8
    drwxr-xr-x  10 root root  123 3月  23 16:53 .
    drwxrwxrwt. 23 root root 4096 3月  23 16:52 ..
    drwxr-xr-x   2 root root    6 3月  23 16:53 activeMq
    drwxr-xr-x   2 root root    6 3月  23 16:52 fastDFS
    drwxr-xr-x   2 root root 4096 3月  23 16:50 lib
    drwxr-xr-x   4 root root  141 3月  23 16:50 nginx
    drwxr-xr-x   2 root root    6 3月  23 16:51 oracle11g
    drwxr-xr-x   2 root root    6 3月  23 16:52 redis
    drwxr-xr-x   3 root root   86 3月  23 16:50 tomcat8
    drwxr-xr-x   2 root root    6 3月  23 16:52 zookeeper
    其中lib目录中包含了安装所有软件所需要的依赖
## 0.1 所有软件将安装至/home/hxsoft/目录下，如没有hxsoft目录需要自行创建，软件版本列表如下

    apache-activemq-5.15.5
    apache-tomcat-8.5.87
    apache-zookeeper-3.7.1
    fastdfs6.06
    nginx-1.16.1
    redis-7.0.2
## 0.2 此包可离线部署，步骤如下
### 0.2.1 编辑repo文件
```bash
mkdir /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
vi /etc/yum.repos.d/local.repo
```
写入以下内容

    [local]
    name=local
    baseurl=file:///tmp/7.0soft/lib
    enbale=1
    gpgcheck=0
### 0.2.2 清理yum缓存，并重新建立缓存
```bash
yum clean all
yum makecache
```
查看软件源列表
```bash
yum repolist
```
### 0.2.3 输出以下内容则表示本地软件源建立成功，可以愉快的部署软件了

    [root@localhost ~]# yum clean all
    已加载插件：fastestmirror
    正在清理软件源： local
    Cleaning up list of fastest mirrors
    Other repos take up 546 M of disk space (use --verbose for details)
    [root@localhost ~]# yum makecache
    已加载插件：fastestmirror
    Determining fastest mirrors
    local                                                                                           | 2.9 kB  00:00:00     
    (1/3): local/filelists_db                                                                       | 119 kB  00:00:00     
    (2/3): local/other_db                                                                           |  76 kB  00:00:00     
    (3/3): local/primary_db                                                                         |  96 kB  00:00:00     
    元数据缓存已建立
    [root@localhost ~]# yum repolist
    已加载插件：fastestmirror
    Loading mirror speeds from cached hostfile
    源标识                                                    源名称                                                   状态
    local                                                     local                                                    163
    repolist: 163
## 1. 安装编译环境
```bash
yum install -y gcc gcc-c++ glibc glibc-common gd gd-devel xinetd openssl openssl-devel pcre-devel expat-devel python-devel mysql-devel cmake ncurses-devel bison devtoolset ruby rubygems tcl gpg2 pcre patch vim unzip libevent 
```
## 2. 安装JDK1.8
```bash
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel.x86_64
```
## 3. 安装Tomcat8
### 3.1 解压Tomcat8并移动到指定目录
```bash
cd /tmp/7.0soft/tomcat8
tar -xzvf apache-tomcat-8.5.87.tar.gz
mv apache-tomcat-8.5.87 /home/hxsoft/apache-tomcat-8.5.87
```
### 3.2 添加JVM参数脚本
```bash
vim /home/hxsoft/apache-tomcat-8.5.87/bin/setenv.sh
```
写入以下内容
```bash
#!/bin/sh
export CATALINA_OPTS=" -Djava.net.preferIPv4Stack=true -Dcom.sun.management.jmxremote=true -Djava.security.egd=file:/dev/./urandom -Xms512M -Xmx4096M -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime -XX:+PrintHeapAtGC -Xloggc:$CATALINA_HOME/logs/`date +"%Y-%m-%d"`_gc.log"
```
赋予脚本可执行权限
```bash
chmod +x /home/hxsoft/apache-tomcat-8.5.87/bin/setenv.sh
```
### 3.3 tomcat开启PID文件
编辑catalina.sh文件，在PRGDIR下面一行添加CATALIN_APID参数行
```bash
vim /home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh
```
在PRGDIR下面一行添加CATALIN_APID参数行
 
    # Get standard environment variables
    PRGDIR=`dirname "$PRG"`
    CATALINA_PID=$PRGDIR/tomcat.pid
### 3.4 添加tomcat为系统服务
```bash
vim /usr/lib/systemd/system/tomcat.service
```
写入以下内容

    [Unit]
    Description=Tomcat
    After=network.target
    
    [Service]
    Type=forking
    PIDFile=/home/hxsoft/apache-tomcat-8.5.87/bin/tomcat.pid
    ExecStart=/home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh start
    ExecReload=/home/hxsoft/apache-tomcat-8.5.87/bin//catalina.sh restart
    ExecStop=/home/hxsoft/apache-tomcat-8.5.87/bin/catalina.sh stop
    
    [Install]
    WantedBy=multi-user.target
使用systemctl命令即可控制tomcat

    systemctl daemon-reload
    #重载系统服务
    systemctl start tomcat
    #启动服务
    systemctl stop tomcat
    #停止服务
    systemctl enable tomcat
    #设置开机自启动
    systemctl disable tomcat
    #停止开机自启动
    systemctl status tomcat
    #查看服务当前状态
    systemctl restart tomcat
    #重新启动服务
如果systemctl命令无法启动tomcat服务，请检查是否已经存在tomcat进程。将其结束掉后重试。
## 4. 安装Nginx1.16.1
### 4.1 解压缩nginx1.16.1和nginx_upstream_check_module源码
```bash
cd /tmp/7.0soft/nginx
unzip nginx_upstream_check_module-master.zip
tar -zxvf nginx-1.16.1.tar.gz
```
### 4.2 为nginx源码打上nginx_upstream_check_module补丁
```bash
cd /tmp/7.0soft/nginx/nginx-1.16.1
patch -p1 < ../nginx_upstream_check_module-master/check_1.16.1+.patch
```
### 4.3 设置编译参数
```bash
./configure --prefix=/home/hxsoft/nginx-1.16.1 --sbin-path=/home/hxsoft/nginx-1.16.1/bin/nginx --conf-path=/home/hxsoft/nginx-1.16.1/etc/nginx.conf --error-log-path=/home/hxsoft/nginx-1.16.1/log/error.log --http-log-path=/home/hxsoft/nginx-1.16.1/log/access.log --pid-path=/home/hxsoft/nginx-1.16.1/run/nginx.pid --lock-path=/home/hxsoft/nginx-1.16.1/run/nginx.lock --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=/home/hxsoft/nginx-1.16.1/tmp/client/ --http-scgi-temp-path=/home/hxsoft/nginx-1.16.1/tmp/scgi --with-pcre --with-file-aio --with-http_image_filter_module --add-module=../nginx_upstream_check_module-master
echo $? #如果返回0则继续
```
### 4.4 编译并安装
```bash
make && make install
```
### 4.5 创建必要的文件夹
```bahs
mkdir /home/hxsoft/nginx-1.16.1/tmp
```
### 4.6 添加nginx为系统服务
```bash
vim /usr/lib/systemd/system/nginx.service
```
写入以下内容
    
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
编辑nginx的配置文件，设置pid路径
```bash
vim /home/hxsoft/nginx-1.16.1/etc/nginx.conf
```
将80端口改为其他端口，这里改为8088

        #gzip  on;

    server {
        listen       8088;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

将PID前的注释去掉，并改为

    pid /home/hxsoft/nginx-1.16.1/run/nginx.pid;
使用systemctl命令即可控制nginx

    systemctl daemon-reload
    #重载系统服务
    systemctl start nginx
    #启动nginx服务
    systemctl stop nginx
    #停止nginx服务
    systemctl enable nginx
    #设置开机自启动
    systemctl disable nginx
    #停止开机自启动
    systemctl status nginx
    #查看服务当前状态
    systemctl restart nginx
    #重新启动服务
如果systemctl命令无法启动nginx服务，请检查是否已经存在nginx进程。将其结束掉后重试。
## 5. 安装Redis
### 5.1 解压redis安装包
```bash
cd /tmp/7.0soft/redis
tar zxvf redis-7.0.2.tar.gz
```
### 5.2 编译并安装redis
```bash
cd /tmp/7.0soft/redis/redis-7.0.2
make
echo $? #返回0则继续
make install PREFIX=/home/hxsoft/redis-7.0.2
```
### 5.3 配置环境变量
```bash
vim ~/.bash_profile
```
添加以下内容

    REDIS_HOME=/home/hxsoft/redis-7.0.2
    PATH=$PATH:$REDIS_HOME/bin
```bash
source ~/.bash_profile
```
### 5.4 为方便管理，进行文件整合
```bash
mkdir /home/hxsoft/redis-7.0.2/etc
cp /tmp/7.0soft/redis/redis-7.0.2/redis.conf /home/hxsoft/redis-7.0.2/etc/redis1.conf
cp /tmp/7.0soft/redis/redis-7.0.2/sentinel.conf /home/hxsoft/redis-7.0.2/etc/sentinel1.conf
```
### 5.5 修改redis配置文件
```bash
vim /home/hxsoft/redis-7.0.2/etc/redis1.conf
```
    #设置后台启动，如果不是后台启动，每次推出redis就关闭了
    daemonize yes
    #开启密码保护，注释则不需要密码
    requirepass 密码
    #设置端口号
    port 端口号
    #允许访问的ip，改为0.0.0.0就是所有ip均可
    bind 127.0.0.1 -::1
    bind 0.0.0.0
### 5.6 添加redis为系统服务
```bash
vim /usr/lib/systemd/system/redis.service
```
写入以下内容

    [Unit]
    Description=redis-server
    After=network.target
    
    [Service]
    Type=forking
    
    ExecStart=/home/hxsoft/redis-7.0.2/bin/redis-server /home/hxsoft/redis-7.0.2/etc/redis1.conf
    PrivateTmp=true
    
    [Install]
    WantedBy=multi-user.target
使用systemctl命令即可控制redis

    systemctl daemon-reload
    #重载系统服务
    systemctl start redis
    #启动服务
    systemctl stop redis
    #停止服务
    systemctl enable redis
    #设置开机自启动
    systemctl disable redis
    #停止开机自启动
    systemctl status redis
    #查看服务当前状态
    systemctl restart redis
    #重新启动服务
如果systemctl命令无法启动redis服务，请检查是否已经存在redis进程。将其结束掉后重试。
重复5.4-5.6步骤，创建不同的配置文件及服务，可以起多个redis，如redis2，redis3等。
## 6. 安装fastDFS
### 6.1 解压fastdfs和libfastcommon
```bash
cd /tmp/7.0soft/fastDFS
tar zxvf fastdfs-6.06.tar.gz
tar zxvf libfastcommon-1.0.43.tar.gz
```
### 6.2 编译安装libfastcommon
```bash
cd /tmp/7.0soft/fastDFS/libfastcommon-1.0.43
./make.sh && ./make.sh install
```
### 6.3 编译安装fastdfs
```bash
cd /tmp/7.0soft/fastDFS/fastdfs-6.06
vim /tmp/7.0soft/fastDFS/fastdfs-6.06/make.sh
```
修改安装目录和配置文件目录

    TARGET_PREFIX=$DESTDIR/home/hxsoft/fastdfs6.06
    TARGET_CONF_PATH=$DESTDIR/home/hxsoft/fastdfs6.06/etc
```bash
cd /tmp/7.0soft/fastDFS/fastdfs-6.06
./make.sh && ./make.sh install
```
### 6.4 编辑配置文件
```bash
cp /home/hxsoft/fastdfs6.06/etc/http.conf.sample /home/hxsoft/fastdfs6.06/etc/http.conf
vim /home/hxsoft/fastdfs6.06/etc/http.conf
```
设置http.anti_steal.token_check_fail为空

    # return the content of the file when check token fail
    # default value is empty (no file sepecified)
    http.anti_steal.token_check_fail =
```bash
vim /home/hxsoft/fastdfs6.06/etc/tracker.conf
```
写入以下内容

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
```bash
vim /home/hxsoft/fastdfs6.06/etc/storage.conf
```
写入以下内容，tracker_server=localhost:22122根据实际情况填写

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
    tracker_server=localhost:22122
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
    rotate_error_log = false
    error_log_rotate_time=00:00
    rotate_access_log_size = 0
    rotate_error_log_size = 0
    log_file_keep_days = 0
    file_sync_skip_invalid_record=false
    use_connection_pool = false
    connection_pool_max_idle_time = 3600
    http.domain_name=
    http.server_port=8888
### 6.5 添加fastdfs为系统服务
```bash
vim /usr/lib/systemd/system/tracker.service
```

写入以下内容

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

创建必要的文件夹
```bash
mkdir -p /data/hxsoft/fastdfs/data/
```
```bash
vim /usr/lib/systemd/system/storage.service
```
写入以下内容

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
使用systemctl命令即可控制tracker和storage
## 7. 安装zookeeper
### 7.1 解压文件并移动文件
```bash
cd /tmp/7.0soft/zookeeper/
tar zxvf apache-zookeeper-3.7.1-bin.tar.gz
mv /tmp/7.0soft/zookeeper/apache-zookeeper-3.7.1-bin /home/hxsoft
```
###7.2 配置zookeeper的jvm参数
```bash
vim /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/java.env
```
写入以下内容

    #!/bin/sh
    export JVMFLAGS=" -Xmx5g -Xms128m -Xss1280k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 $JVMFLAGS"
### 7.3 修改配置文件
```bash
cp /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo_sample.cfg /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo.cfg
vim /home/hxsoft/apache-zookeeper-3.7.1-bin/conf/zoo.cfg
```
修改以下内容，localhost及端口号根据实际情况填写

    dataDir=/data/hxsoft/zookeeper/data
    dataLogDir=/data/hxsoft/zookeeper/log
    server.1=localhost:2888:3888
    admin.serverPort=8887
    #修改zookeeper端口，防止与tomcat产生冲突
### 7.4 添加zookeeper为系统服务
```bash
vim /usr/lib/systemd/system/zookeeper.service
```
写入以下内容

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
使用systemctl命令即可控制zookeeper
## 8. 安装ActiveMq
### 8.1 解压activemq，并移动文件
```bash
cd /tmp/7.0soft/activeMq
tar zxvf apache-activemq-5.15.5-bin.tar.gz
mv /tmp/7.0soft/activeMq/apache-activemq-5.15.5 /home/hxsoft
```
### 8.2 修改密码文件
```bash
vim /home/hxsoft/apache-activemq-5.15.5/conf/jetty-realm.properties
```
修改以下内容

    admin: adminpasswd, admin
    user: userpasswd, user
admin密码修改为 adminpasswd
user密码修改为 userpasswd
### 8.3 修改activemq.xml文件。（不需要修改，只要配置了多集群才需要，不然修改了会报错）
```bash
vim /home/hxsoft/apache-activemq-5.15.5/conf/activemq.xml
```
变更内容：

注释掉就可以，不要删除，如果不好用再添加回来

    <persistenceAdapter>
    <kahaDB directory="${activemq.data}/kahadb"/>
    </persistenceAdapter>

添加(Ip地址和端口请根据实际情况填写)

    <persistenceAdapter>
                <replicatedLevelDB
                  directory="${activemq.data}/leveldb"
                  replicas="3"
                  bind="tcp://0.0.0.0:0"
                  zkAddress="192.168.1.122:2181,192.168.1.123:2181,192.168.1.124:2181"
                  hostname="192.168.1.123"
                  sync="local_disk"
                  zkPath="/activemq/leveldb-stores"/>
            </persistenceAdapter>
### 8.4 添加activemq为系统服务
```bash
vim /usr/lib/systemd/system/activemq.service
```
写入以下内容

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
使用systemctl命令即可控制activemq
***
```bash
systemctl list-units --type=service 
#查看所有已启动的服务
netstat -anpt 
#查看服务使用的端口
firewall-cmd --list-ports --permanent
#查看防火墙开放的端口
firewall-cmd --zone=public --add-port=8088/tcp --permanent
#在防火墙上开放端口
firewall-cmd --zone=public --remove-port=8088/tcp --permanent
#在防火墙上关闭端口
```

***

## 9. 应用项目部署
### 9.1 将项目文件拷贝至tomcat的webapp文件夹
这里所使用的项目文件夹为hlbr

    [root@oracledb webapps]# pwd
    /home/hxsoft/apache-tomcat-8.5.87/webapps
    [root@oracledb webapps]# ls -la
    总用量 8
    drwxr-x---  8 root root   93 3月  28 16:40 .
    drwxr-xr-x  9 root root  220 3月  27 08:36 ..
    drwxr-x--- 16 root root 4096 3月  27 08:36 docs
    drwxr-x---  7 root root   99 3月  27 08:36 examples
    drwxr-xr-x 27 root root 4096 3月  28 16:27 hlbr
    drwxr-x---  6 root root   79 3月  27 08:36 host-manager
    drwxr-x---  6 root root  114 3月  27 08:36 manager
    drwxr-x---  3 root root  223 3月  27 08:36 ROOT
### 9.2 修改配置文件
#### 9.2.1 查看web.xml，指定的是sf
```bash
vim /home/hxsoft/apache-tomcat-8.5.87/webapps/hlbr/WEB-INF/web.xml
```
按“/”键搜索    spring.profiles.default
查看<param-value>sf</param-value>中的值是什么（这里是sf）
#### 9.2.2 在config中找到后缀为sf的文件夹进行配置
```bash
cd /home/hxsoft/apache-tomcat-8.5.87/webapps/hlbr/WEB-INF/config/*_sf
ls
```
可看到有以下文件

    [root@oracledb property_sf]# ls -la
    总用量 68
    drwxr-xr-x  2 root root 4096 3月  28 17:32 .
    drwxr-xr-x 11 root root  159 3月  28 16:44 ..
    -rw-r--r--  1 root root  645 1月   8 2021 config-366.properties
    -rw-r--r--  1 root root 4637 8月  19 2021 config-base.properties
    -rw-r--r--  1 root root 1214 1月   8 2021 config-custom.properties
    -rw-r--r--  1 root root 1432 3月  28 16:35 config-db.properties
    -rw-r--r--  1 root root  535 1月   8 2021 config-fileupload.properties
    -rw-r--r--  1 root root  991 1月   8 2021 config-fineReport.properties
    -rw-r--r--  1 root root  470 1月  15 2021 config-Interface.properties
    -rw-r--r--  1 root root  908 8月   4 2021 config-invoice.properties
    -rw-r--r--  1 root root  236 1月   8 2021 config-livechat.properties
    -rw-r--r--  1 root root  138 12月  8 2021 config-mq.properties
    -rw-r--r--  1 root root 1492 12月  7 2021 config-redis.properties
    -rw-r--r--  1 root root  422 1月   8 2021 config-report.properties
    -rw-r--r--  1 root root  232 1月   8 2021 config-solr.properties
    -rw-r--r--  1 root root  101 1月   8 2021 config-thread.properties
    -rw-r--r--  1 root root  397 1月   8 2021 resource.properties
粗体的为需要修改的文件，其中：
config-db.properties：配置数据库地址，实例名，密码等

    # c3p0参数(Oracle)
    jdbc_driver=oracle.jdbc.OracleDriver
    jdbc_url=jdbc:oracle:thin:@//192.168.3.55:1521/hx
    jdbc_username= **hlbr_sys** 
    jdbc_password= **hlbr_sys** 
    
    jdbc_urlB=jdbc:oracle:thin:@//192.168.3.55:1521/hx
    jdbc_usernameB= **hlbr_sys** 
    jdbc_passwordB= **hlbr_sys** 
    
    jdbc_urlC=jdbc:oracle:thin:@//192.168.3.55:1521/hx
    jdbc_usernameC=hlbr_sys
    jdbc_passwordC=hlbr_sys
config-mq.properties：配置mq安装时设置的用户名和密码

    mq.username=admin
    mq.password=adminpasswd
    mq.brokerUrl=failover:(tcp://localhost:61616)?initialReconnectDelay=5000&maxReconnectAttempts=2
config-redis.properties：配置redis安装时候的密码

    ################### Redis 池的配置 ###################
    #redis 启动方式，stand_alone 单机模式， sentinels哨兵模式（缺省默认）
    #redis.setuptype = sentinels
    redis.setuptype=stand_alone
    #redis地址(单机模式使用)
    redis.host=127.0.0.1
    #redis端口号(单机模式使用)
    redis.port=6379
    #redis哨兵地址(哨兵模式使用)
    #redis.sentinels=192.168.2.211:10000,192.168.2.211:10001,192.168.2.213:10000,192.168.2.213:10001,192.168.2.215:10000,192.168.2.215:10001
    redis.sentinels=
    #192.168.2.201:10000,192.168.2.201:10001
    
    #redisMasterName
    redis.masterName=hxsoft
    #redis密码
    #redis.password=hxsoft
    redis.password=hxsoft
    #redis 使用的数据库
    redis.dbIndex=1

#### 9.2.3 配置hlbr\WEB-INF\classes里的fastdfs-client.properties
```bash
vim /home/hxsoft/apache-tomcat-8.5.87/webapps/hlbr/WEB-INF/classes/fastdfs-client.properties
```
修改fastdfs的IP地址

    fastdfs.connect_timeout_in_seconds=5
    fastdfs.network_timeout_in_seconds=30
    
    fastdfs.charset=UTF-8
    
    fastdfs.tracker_servers=192.168.233.140:22122
    
    # it sames not useful
    fastdfs.http_anti_steal_token=false
    fastdfs.http_secret_key=FastDFS1234567890
    fastdfs.http_tracker_http_port=80
### 9.3 重启tomcat，部署完成
```bash
systemctl restart tomcat
```

浏览器输入http://IP:port/hlbr，显示如下页面，说明部署成功。

![7.0收费系统](image.png)
