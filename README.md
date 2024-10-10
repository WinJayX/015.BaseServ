# 015.BaseServ

# 015.BaseServ



## 权限配置

```bash
chmod -R 777 ./RocketMQ
chmod -R 666 ./Minio/Data
chmod -R 777 ./ElasticSearch/Data
```





```yaml
version: '3'

networks:
  BaseServ:
    driver: bridge
  RocketMQ:
    driver: bridge
  Static:
    driver: bridge
  FastDFS:
    driver: bridge 


services:
  BaseServ-MySQL:
    image: hub.litsoft.com.cn/tools/mysql:8.0.36
    container_name: BaseServ-MySQL
    restart: on-failure:3
    user: root
    hostname: BaseServ-MySQL
    networks:
      - BaseServ

    environment:
      # 请修改此密码，以配置想要预置的root密码。
      MYSQL_ROOT_PASSWORD: "P@88W0rd"
      TZ: "Asia/Shanghai"
      MYSQL_DATABASE: "Nacos"  #初始时会创建此数据库

    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./MySQL-8/Data:/var/lib/mysql
      - ./MySQL-8/MySQL-Conf:/etc/mysql
      # 数据库还原目录 可将需要还原的sql文件放在这里
      - ./MySQL-8/InitDB:/docker-entrypoint-initdb.d

    command:
      - --lower_case_table_names=1
      - --max_allowed_packet=128M
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_0900_ai_ci
      - --explicit_defaults_for_timestamp=true
      - --default-authentication-plugin=caching_sha2_password

    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
      interval: 3s
      retries: 5
      start_period: 30s




#  BaseServ-MySQL:
#    image: hub.litsoft.com.cn/tools/mysql:5.7
#    container_name: BaseServ-MySQL
#    restart: on-failure:3   # 失败重启次数
#    user: root
#    hostname: BaseServ-MySQL
#    networks:
#      - BaseServ
#
#    environment:
#      - TZ=Asia/Shanghai
#      - MYSQL_ALLOW_EMPTY_PASSWORD=yes
#      - MYSQL_ROOT_HOST=%
#      - MYSQL_ROOT_PASSWORD=P@88W0rd
#
#####  MySQL 5.7 中，使用以下变更方式启动报错，要使用上述
##   key=value，而不是 key: value。
##    environment:
##      - TZ: "Asia/Shanghai"
##      - MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
##      - MYSQL_ROOT_HOST: "%"
##      - MYSQL_ROOT_PASSWORD: "P@88W0rd"  #设置root帐号密码
#
##    environment:
##      - TZ: "Asia/Shanghai"
##      - MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
##      - MYSQL_ROOT_HOST: "%"
##      - MYSQL_ROOT_PASSWORD: "P@88W0rd"  #设置root帐号密码
#
#    volumes:
#      - /etc/localtime:/etc/localtime:ro
#      - ./MySQL-5/Log:/var/log/mysql #日志文件挂载
#      - ./MySQL-5/Data:/var/lib/mysql   #数据文件挂载
#      - ./MySQL-5/MySQL-Conf:/etc/mysql #配置文件挂载
#      - ./MySQL-5/initdb:/docker-entrypoint-initdb.d
#
#    command: mysqld --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
#    ports:
#      - "3306:3306"    
#    healthcheck:
#      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
#      interval: 3s
#      retries: 5
#      start_period: 30s





  BaseServ-Redis:
    image: hub.litsoft.com.cn/tools/redis:7.0.7
    container_name: BaseServ-Redis
    restart: unless-stopped # 只保留了这个 restart 字段
    privileged: true
    hostname: BaseServ-Redis
    networks:
      - BaseServ    

    environment:
      TZ: "Asia/Shanghai"

    volumes:
      - /etc/localtime:/etc/localtime:ro # 设置容器时区与宿主机保持一致
      - ./Redis/Data:/data  #数据文件挂载
      - ./Redis/Config/redis.conf:/etc/redis.conf

    command:
      - redis-server
      - /etc/redis.conf # 启动redis命令
      - --port 6379
      - --requirepass P@88W0rd
      - --appendonly yes 
      - --protected-mode no

    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
      # test: 定义健康检查的命令，这里使用 redis-cli ping 来检查 Redis 服务是否正常。
      # interval: 设置健康检查命令执行的间隔时间，这里为30秒。
      # timeout: 设置健康检查命令的超时时间，这里为10秒。
      # retries: 设置在容器被认为不健康之前，重试健康检查命令的次数，这里为5次。
      # start_period: 设置在开始执行健康检查之前的初始等待时间，这里为30秒。

    deploy:
      resources:
        limits:
          cpus: "2.00"
          memory: 1G
        reservations:
          memory: 200M
#    command: ["redis-server","--port","6379","--requirepass","P@88W0rd","--appendonly","yes","--protected-mode","no"]   #定义Redis密码。
#    command: redis-server --port 6379 --requirepass P@88W0rd --appendonly yes --protected-mode no



  BaseServ-Nginx:
    image: hub.litsoft.com.cn/tools/nginx:1.22
    container_name: BaseServ-Nginx
    restart: always
    user: root
    hostname: BaseServ-Nginx
    depends_on:
      - BaseServ-MySQL

    networks:
      - BaseServ
    volumes:
      - ./Nginx/logs:/var/log/nginx #日志文件挂载
      - ./Nginx/html:/usr/share/nginx/html #静态资源根目录挂载
      - ./Nginx/Conf/conf.d:/etc/nginx/conf.d #配置文件目录挂载
      - ./Nginx/Conf/nginx.conf:/etc/nginx/nginx.conf #配置文件目录挂载
    ports:
      - "80:80"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost || exit 1"]
      interval: 30s     #: 健康检查之间的间隔时间
      timeout: 10s      #: 健康检查超时时间
      retries: 3        #: 健康检查失败重试次数
      start_period: 10s #: 服务启动后开始进行健康检查的等待时间


  BaseServ-Nacos:
    image: hub.litsoft.com.cn/tools/nacos-server:v2.3.2
    container_name: BaseServ-Nacos
    restart: always
    user: root
    hostname: BaseServ-Nacos
    depends_on:
      - BaseServ-MySQL

    networks:
      - BaseServ

    environment:
      - JVM_XMS=512m
      - JVM_XMX=512m
      - MODE=standalone
      - PREFER_HOST_MODE=hostname
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=BaseServ-MySQL
      - MYSQL_SERVICE_DB_NAME=Nacos
      - MYSQL_SERVICE_USER=root
      - MYSQL_SERVICE_PASSWORD=P@88W0rd
      - NACOS_AUTH_ENABLE=true
      - NACOS_CORE_AUTH_PLUGIN_NACOS_TOKEN_SECRET_KEY=TWFsbDRqTWFsbDRjbG91ZE1hbGw0ak1hbGw0Y2xvdWRNYWxsNGpNYWxsNGNsb3Vk
      - NACOS_CORE_AUTH_SERVER_IDENTITY_KEY=SecretKey012345678901234567890123456789012345678901234567890123456789
      - NACOS_CORE_AUTH_SERVER_IDENTITY_VALUE=SecretKey012345678901234567890123456789012345678901234567890123456789
      - MYSQL_SERVICE_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true
    volumes:
      - ./Nacos/Data:/home/nacos/data
      - ./Nacos/Logs:/home/nacos/logs
    ports:
      - "7848:7848"
      - "8848:8848"
      - "9848:9848"
      - "9849:9849"
    healthcheck:
#      test: ["CMD-SHELL", "curl -f http://localhost:8848/nacos/v1/core/health || exit 1"] # 需要确认这个健康检查端点是否正确
      test: ["CMD-SHELL", "curl -f 'http://localhost:8848/nacos/v2/console/namespace/list' || exit 1"] 
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


  BaseServ-MongoDB:
    image: hub.litsoft.com.cn/tools/mongo:7.0.8
    container_name: BaseServ-MongoDB
    restart: on-failure:3
    user: root
    hostname: BaseServ-MongoDB
    networks:
      - BaseServ    

    environment:
      MONGO_INITDB_ROOT_USERNAME: "root"
      MONGO_INITDB_ROOT_PASSWORD: "P@88W0rd"

    volumes:
      - ./Mongo/DataBase:/data/db #数据文件挂载
      - ./Mongo/Backup:/data/backup #数据文件挂载

    ports:
       - "27017:27017"
    healthcheck:
      test: ["CMD-SHELL", "mongosh --eval 'db.adminCommand(\"ping\")' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


  BaseServ-MinIO:
#    image: minio/minio
    image: hub.litsoft.com.cn/tools/minio:RELEASE.2024-04-18T19-09-19Z
    container_name: BaseServ-MinIO
    restart: on-failure:3
    user: root
    hostname: BaseServ-MinIO

    networks:
      - BaseServ

    environment:
#      MINIO_ROOT_USER: "admin"
#      MINIO_ROOT_PASSWORD: "minioadmin"

#  MINIO_ACCESS_KEY and MINIO_SECRET_KEY are deprecated. 此方式已过时，使用上面登录
#      MINIO_ACCESS_KEY: "root"
#      MINIO_SECRET_KEY: "P@88W0rd"
      MINIO_BROWSER_REDIRECT_URL: "https://pvt-info.litsoft.com.cn"

    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./Minio/Buckets:/mnt/Buckets
      - ./Minio/Data:/data #数据目录挂载

#    command: server /data --console-address ":9001" #指定数据目录及console运行端口启动
    command: server /mnt/Buckets --console-address ":9001"

    ports:
      - "9000:9000"
      - "9001:9001"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9001/minio/health/live || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s



  BaseServ-Seata:
#    image: seataio/seata-server:2.0.0
    image: hub.litsoft.com.cn/tools/seata-server:2.0.0
    container_name: BaseServ-Seata
    restart: on-failure:3
    user: root
    hostname: BaseServ-Seata

    networks:
      - BaseServ

    environment:
      TZ: "Asia/Shanghai"
      STORE_MODE: "db"
      SEATA_IP: "10.17.0.26"
      SEATA_PORT: "8091"
    volumes:
      - ./Seata/application.yml:/seata-server/resources/application.yml

    ports:
      - "8091:8091"
      - "7091:7091"  
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:7091 || exit 1"] # 临时方案，/health接口不存在
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


#============ELK================

  BaseServ-ElasticSearch:
#    image: elasticsearch:7.17.3
    image: hub.litsoft.com.cn/tools/elasticsearch_ik:8.14.3
    container_name: BaseServ-ElasticSearch
    restart: always
    hostname: BaseServ-ElasticSearch

    networks:
      - BaseServ

    environment:
      # 此种写法是列表形式
      - "node.name=elasticsearch"
      - "bootstrap.memory_lock=true"
      - "cluster.name=elasticsearch" #设置集群名称为elasticsearch
      - "discovery.type=single-node" #以单一节点模式启动
      - "xpack.security.enabled=false"
      - "xpack.monitoring.collection.enabled=true"
      - "ES_JAVA_OPTS=-Xms512m -Xmx1024m" #设置使用jvm内存大小

    ulimits:
      memlock:
        soft: -1
        hard: -1

    volumes:
#      - ./ElasticSearch/plugins:/usr/share/elasticsearch/plugins #插件文件挂载,此镜像已安装IK，如若想要挂载，需要先docker cp 到本地目录后重启服务.
      - ./ElasticSearch/Data:/usr/share/elasticsearch/data #数据文件挂载;# 映射本地目录权限一定要设置为 777 权限，否则启动不成功
      - ./ElasticSearch/elasticsearch.log:/usr/share/elasticsearch/logs/elasticsearch.log
#      - ./elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml # 文件内容：http.host: 0.0.0.0
    ports:
      - "9200:9200"
      - "9300:9300"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


  BaseServ-Logstash:
#    image: logstash:7.17.3
    image: hub.litsoft.com.cn/tools/logstash:8.14.3
    container_name: BaseServ-Logstash
    restart: on-failure:3
    user: root
    hostname: BaseServ-Logstash
    networks:
      - BaseServ
          
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./Logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf #挂载logstash的配置文件
    depends_on:
      - BaseServ-ElasticSearch #Logstash在elasticsearch启动之后再启动
    links:
      - BaseServ-ElasticSearch:es #可以用es这个域名访问elasticsearch服务
    ports:
      - "4560:4560"
      - "4561:4561"
      - "4562:4562"
      - "4563:4563"
    healthcheck:
# 容器内没有nc命令，启动后健康检查失败，需要手动apt-get update -y && apt-get install netcat-traditional -y安装后健康状态转为正常
      test: ["CMD-SHELL", "nc -zv localhost 4560 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


  BaseServ-Kibana:
#    image: kibana:7.17.3
    image: hub.litsoft.com.cn/tools/kibana:8.14.3
    container_name: BaseServ-Kibana
    restart: on-failure:3
#    user: root         ES & KB Can not with root to start!
    hostname: BaseServ-Kibana
    networks:
      - BaseServ    
    links:
      - BaseServ-ElasticSearch:es #可以用es这个域名访问elasticsearch服务
    depends_on:
      - BaseServ-ElasticSearch #kibana在elasticsearch启动之后再启动
    environment:
      - "elasticsearch.hosts=http://es:9200" #设置访问elasticsearch的地址
    ports:
      - "5601:5601"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5601/api/status || exit 1"] # 启动后为unhealthy状态，只有初始化连接ES完成后才是healthy状态。
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s



# ===========数据同步=============
  BaseServ-Canal:
#    image: canal/canal-server:v1.1.7
    image: hub.litsoft.com.cn/tools/canal-server:v1.1.7
    container_name: BaseServ-Canal
    restart: on-failure:3
    user: root
    hostname: BaseServ-Canal

    networks:
      - BaseServ

    volumes:
      - ./Canal/Conf/example:/home/admin/canal-server/conf/example
      - ./Canal/Conf/canal.properties:/home/admin/canal-server/conf/canal.properties
      - ./Canal/Logs:/home/admin/canal-server/logs
    ports:
      - "11111:11111"

#  ============ RabbitMQ Cluster ============
  BaseServ-RabbitMQ1:
    image: hub.litsoft.com.cn/tools/rabbitmq:3.13.7-management
    container_name: BaseServ-RabbitMQ1
    restart: on-failure:3
    ports:
      - "15673:15672"
      - "5673:5672"
    hostname: BaseServ-RabbitMQ1
    environment:
      - RABBITMQ_ERLANG_COOKIE=rabbitcookie
    volumes:
      - ./RabbitMQ/MQ1:/var/lib/rabbitmq
      - /etc/localtime:/etc/localtime

  BaseServ-RabbitMQ2:
    image: hub.litsoft.com.cn/tools/rabbitmq:3.13.7-management
    container_name: BaseServ-RabbitMQ2
    restart: on-failure:3
    ports:
      - "15674:15672"
      - "5674:5672"
    hostname: BaseServ-RabbitMQ2
    environment:
      - RABBITMQ_ERLANG_COOKIE=rabbitcookie
    volumes:
      - ./RabbitMQ/MQ2:/var/lib/rabbitmq
      - /etc/localtime:/etc/localtime

  BaseServ-RabbitMQ3:
    image: hub.litsoft.com.cn/tools/rabbitmq:3.13.7-management
    container_name: BaseServ-RabbitMQ3
    restart: on-failure:3
    ports:
      - "15675:15672"
      - "5675:5672"
    hostname: BaseServ-RabbitMQ3
    environment:
      - RABBITMQ_ERLANG_COOKIE=rabbitcookie
    volumes:
      - ./RabbitMQ/MQ3:/var/lib/rabbitmq
      - /etc/localtime:/etc/localtime


###########
#  BaseServ-RabbitMQ:
##    image: rabbitmq:3.9-management
#    image: hub.litsoft.com.cn/tools/rabbitmq:3.9-management
#    container_name: BaseServ-RabbitMQ
#    restart: always
#    user: root
#    privileged: true
#    hostname: BaseServ-RabbitMQ
#    networks:
#      - BaseServ
#
#    environment:
#      discovery.type: "single-node"
#      RMQ_JAVA_OPTS: "-Xms512m -Xmx512m"
#
#    volumes:
#      - /etc/localtime:/etc/localtime
#      - ./RabbitMQ/Plugins:/plugins #插件文件挂载
#      - ./RabbitMQ/Data:/var/lib/rabbitmq #数据文件挂载
#    ports:
#      - "5672:5672"
#      - "15672:15672"

############### RocketMQ ##############
  BaseServ-RMQ-NameSrv:
    image: hub.litsoft.com.cn/tools/rocketmq:5.2.0
    container_name: BaseServ-RMQ-NameSrv
    restart: always
    user: root
    privileged: true
    hostname: BaseServ-RMQ-NameSrv
    networks:
      - BaseServ
    environment:
      JAVA_OPT_EXT: "-Duser.home=/home/rocketmq -Xms512M -Xmx512M -Xmn128M"
    volumes:
      - ./RocketMQ/Namesrv/Logs:/home/rocketmq/logs
      - ./RocketMQ/Namesrv/Store:/home/rocketmq/store
    command: ["sh","mqnamesrv"]
    ports:
      - "9876:9876"

  BaseServ-RMQ-Broker:
    image: hub.litsoft.com.cn/tools/rocketmq:5.2.0
    container_name: BaseServ-RMQ-Broker
    restart: always
    user: root
    privileged: true    
    hostname: BaseServ-RMQ-Broker
    networks:
      - BaseServ

    environment:
      NAMESRV_ADDR: "BaseServ-RMQ-NameSrv:9876"
      JAVA_OPT_EXT: "-Duser.home=/home/rocketmq -Xms512M -Xmx512M -Xmn128M -XX:-AssumeMP"

    volumes:
      # 映射本地目录权限一定要设置为 777 权限，否则启动不成功
      - ./RocketMQ/Broker/Logs:/home/rocketmq/logs
      - ./RocketMQ/Broker/Store:/home/rocketmq/store
      - ./RocketMQ/Broker/broker.conf:/etc/rocketmq/broker.conf
    
    command: ["sh","mqbroker","-c","/etc/rocketmq/broker.conf","-n","BaseServ-RMQ-NameSrv:9876","autoCreateTopicEnable=true"]
    depends_on:
      - BaseServ-RMQ-NameSrv
    ports:
      - "10909:10909"
      - "10911:10911"
      - "10912:10912"


  BaseServ-RMQ-DashBoard:
#    image: apacherocketmq/rocketmq-dashboard:1.0.0
    image: hub.litsoft.com.cn/tools/rocketmq-dashboard:1.0.0
    container_name: BaseServ-RMQ-DashBoard
    restart: always
    user: root
    privileged: true    
    hostname: BaseServ-RMQ-DashBoard
    networks:
      - BaseServ
   
    environment:
      JAVA_OPTS: "-Drocketmq.namesrv.addr=BaseServ-RMQ-NameSrv:9876 -Dcom.rocketmq.sendMessageWithVIPChannel=false"
    depends_on:
      - BaseServ-RMQ-NameSrv
    ports:
      - "8180:8080"


############# Kafka #############
  BaseServ-Zookeeper:
#    image: wurstmeister/zookeeper
    image: hub.litsoft.com.cn/tools/zookeeper:latest
    container_name: BaseServ-Zookeeper
    restart: always
    user: root
    privileged: true
    hostname: BaseServ-Zookeeper

    volumes:
      - "/etc/localtime:/etc/localtime"
    ports:
      - "2181:2181"
    networks:
      - BaseServ

  BaseServ-Kafka:
#    image: wurstmeister/kafka
    image: hub.litsoft.com.cn/tools/kafka:latest
    container_name: BaseServ-Kafka
    restart: always
    user: root
    privileged: true
    hostname: BaseServ-Kafka
    environment:
      KAFKA_BROKER_ID: 0
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://BaseServ-Kafka:9092
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ZOOKEEPER_CONNECT: BaseServ-Zookeeper:2181
      KAFKA_CREATE_TOPICS: "austinBusiness:1:1,austinRecall:1:1,austinTraceLog:1:1"  # ??
      KAFKA_HEAP_OPTS: -Xmx512M -Xms256M
    volumes:
      - "/etc/localtime:/etc/localtime"
    ports:
      - "9092:9092"
    depends_on:
      - BaseServ-Zookeeper
    networks:
      - BaseServ







  # xxl-job 分布式调度中心
  BaseServ-XXL-Job:
    image: hub.litsoft.com.cn/tools/xxl-job-admin:2.4.1
    restart: always
    container_name: BaseServ-XXL-Job
    user: root
    hostname: BaseServ-XXL-Job
    networks:
      - BaseServ

    environment:
#      - PARAMS="--spring.datasource.url=jdbc:mysql://BaseServ-MySQL:3306/xxl_job?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&serverTimezone=Asia/Shanghai --spring.datasource.username=root --spring.datasource.password=P@88W0rd --server.port=9009   --spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver"
      PARAMS: "--spring.datasource.url=jdbc:mysql://BaseServ-MySQL:3306/xxl_job?useUnicode=true&characterEncoding=UTF-8&useSSL=false&autoReconnect=true&serverTimezone=Asia/Shanghai --spring.datasource.username=root --spring.datasource.password=P@88W0rd"
    depends_on:
      - BaseServ-MySQL
    volumes:
      - ./XXL-Job/Data:/data/applogs
    ports:
      - 9009:8080
#    healthcheck:
#      test: ["CMD-SHELL", "curl -f http://localhost:8080/xxl-job-admin/actuator/health || exit 1"]      # 镜像基本啥检测命令都没有，暂时注释掉
#      interval: 30s
#      timeout: 10s
#      retries: 3
#      start_period: 10s


#===================FastDFS=======================
#########version: '3.8'
#########services:

  FDFS-Tracker:
#    image: delron/fastdfs
    image:  hub.litsoft.com.cn/tools/fastdfs:latest
    container_name: FDFS-Tracker
    restart: on-failure:3
    user: root
    hostname: FDFS-Tracker
#    network_mode: host
    networks:
      - FastDFS
    volumes:
      - ./FastDFS/Tracker:/var/fdfs
    command: tracker
    ports:
      - "22122:22122"   #是否需要对外暴露根据实际业务情况而定
    healthcheck:
      test: ["CMD-SHELL", "netstat -an | grep 22122"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


  FDFS-Storage:
#    image: delron/fastdfs
    image:  hub.litsoft.com.cn/tools/fastdfs:latest
    container_name: FDFS-Storage
    restart: on-failure:3
    user: root
    hostname: FDFS-Storage
#    network_mode: host
    networks:
      - FastDFS
    environment:
      - GROUP_NAME=group1 # WinJayGroup
#      - TRACKER_SERVER=10.17.0.21:22122
      - TRACKER_SERVER=FDFS-Tracker:22122
    volumes:
      - ./FastDFS/Storage:/var/fdfs
#      - ./FastDFS/nginx.conf:/usr/local/nginx/conf/ngonx.conf:ro  #若不修改GroupName，可直接使用内置配置文件。
    command: storage
    ports:
      - "8888:8888"
#      - "23000:23000"   #是否需要对外暴露根据实际业务情况而定
    depends_on:
      - FDFS-Tracker
    healthcheck:
      test: ["CMD-SHELL", "netstat -an | grep 23000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s




#################初始配置修改参考###################
#  FDFS-Storage:
##    image: delron/fastdfs
#    image: hub.litsoft.com.cn/tools/fastdfs:latest
#    container_name: FDFS-Storage
#    restart: on-failure:3
#    user: root
#    hostname: FDFS-Storage
#    networks:
#      - FDFS
##    network_mode: host
#    environment:
#      - GROUP_NAME=group1
##      - TRACKER_SERVER=172.17.18.66:22122
#      - TRACKER_SERVER=FDFS-Tracker:22122
#    volumes:
#      - ./storage:/var/fdfs
#    ports:
#      - "8888:8888"
#      - "23000:23000"
#    entrypoint: ["/bin/sh", "-c"]
#    command: >
#      "echo 'Modifying storage.conf' &&
#       sed -i 's/^port=.*/port=23000/' /etc/fdfs/storage.conf &&
#       sed -i 's/^tracker_server=.*/tracker_server=FDFS-Tracker:22122/' /etc/fdfs/storage.conf &&
#       echo 'Starting fdfs_storaged' &&
#       /usr/bin/fdfs_storaged /etc/fdfs/storage.conf start &&
#       sleep 5 &&
#       echo 'Listing /var/fdfs/logs/' &&
#       ls -l /var/fdfs/logs/ &&
#       echo 'Displaying storage.conf' &&
#       cat /etc/fdfs/storage.conf &&
#       tail -f /var/fdfs/logs/storaged.log"
#    healthcheck:
#      test: ["CMD-SHELL", "netstat -an | grep 23000"]
#      interval: 30s
#      timeout: 10s
#      retries: 3
#      start_period: 10s



#---------Docker Build Demo --------------
#
# 
# # 该镜像需要依赖的基础镜像
# FROM openjdk:8-jdk-alpine
# MAINTAINER WinJayX
# LABEL description="This is Java Project"
# LABEL version="0.1"
# USER root
# 
# # 将当前maven目录生成的文件复制到docker容器的/目录下
# COPY App-Name.jar /
# 
# ADD https://litsoft.oss-cn-beijing.aliyuncs.com/OpsTools/Alpine-Zone-Shanghai /etc/localtime
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# RUN apk add fontconfig && fc-cache --force && echo "Asia/Shanghai" > /etc/timezone
# 
# # 声明服务运行在8080端口
# EXPOSE 8080
# # 指定docker容器启动时运行jar包
# ENTRYPOINT ["java", "-jar","/App-Name.jar"]
# # ENTRYPOINT java ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar /Lit_Reconciliation.jar
# 
# 
#
# -------------Docker Start Demo----------------
# #docker container run -d \
# #  --cpus 0.5 \
# #  --memory 2g \
# #  --user root \
# #  --restart always \
# #  --name Lit_Working_Hour \
# #  --publish 10270:8080 \
# #  --volume `pwd`/:/logs \
# #  --hostname Lit_Working_Hour \
# #  --env server.port=8080 \
# #  --add-host Lit_Working_Hour:10.17.0.17 \
# #  --env spring.profiles.active=dev \
# #  --env spring.profiles.instaceId=1 \
# #  --env 'JAVA_OPTS=-Xms4g -Xmx4g -Xmn3000m -Xss256k -XX:SurvivorRatio=8 -XX:ParallelGCThreads=16  -XX:CMSFullGCsBeforeCompaction=20 -XX:+UseCMSCompactAtFullCollection -XX:+PrintGCDetails' \
# #  $REPOSITORY
# 
# 



# nohup java -Xms1024m -Xmx2048m -jar jshERP.jar 1>start.out 2>&1 &

```

