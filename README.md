# 015.BaseServ

# 015.BaseServ



## 权限配置

```bash
chmod -R 777 ./RocketMQ
chmod -R 666 ./Minio/Data
chmod -R 777 ./ElasticSearch/Data
```





```yaml
################初始配置修改参考###################
  FDFS-Storage:
#    image: delron/fastdfs
    image: hub.litsoft.com.cn/tools/fastdfs:latest
    container_name: FDFS-Storage
    restart: on-failure:3
    user: root
    hostname: FDFS-Storage
    networks:
      - FDFS
#    network_mode: host
    environment:
      - GROUP_NAME=group1
#      - TRACKER_SERVER=172.17.18.66:22122
      - TRACKER_SERVER=FDFS-Tracker:22122
    volumes:
      - ./storage:/var/fdfs
    ports:
      - "8888:8888"
      - "23000:23000"
    entrypoint: ["/bin/sh", "-c"]
    command: >
      "echo 'Modifying storage.conf' &&
       sed -i 's/^port=.*/port=23000/' /etc/fdfs/storage.conf &&
       sed -i 's/^tracker_server=.*/tracker_server=FDFS-Tracker:22122/' /etc/fdfs/storage.conf &&
       echo 'Starting fdfs_storaged' &&
       /usr/bin/fdfs_storaged /etc/fdfs/storage.conf start &&
       sleep 5 &&
       echo 'Listing /var/fdfs/logs/' &&
       ls -l /var/fdfs/logs/ &&
       echo 'Displaying storage.conf' &&
       cat /etc/fdfs/storage.conf &&
       tail -f /var/fdfs/logs/storaged.log"
    healthcheck:
      test: ["CMD-SHELL", "netstat -an | grep 23000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s


```



```dockerfile
#---------Docker Build Demo --------------

# 该镜像需要依赖的基础镜像
FROM openjdk:8-jdk-alpine
MAINTAINER WinJayX
LABEL description="This is Java Project"
LABEL version="0.1"
USER root

# 将当前maven目录生成的文件复制到docker容器的/目录下
COPY App-Name.jar /

ADD https://litsoft.oss-cn-beijing.aliyuncs.com/OpsTools/Alpine-Zone-Shanghai /etc/localtime
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk add fontconfig && fc-cache --force && echo "Asia/Shanghai" > /etc/timezone

# 声明服务运行在8080端口
EXPOSE 8080
# 指定docker容器启动时运行jar包
ENTRYPOINT ["java", "-jar","/App-Name.jar"]
# ENTRYPOINT java ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar /Lit_Reconciliation.jar

```



```bash




# -------------Docker Start Demo----------------
docker container run -d \
  --cpus 0.5 \
  --memory 2g \
  --user root \
  --restart always \
  --name Lit_Working \
  --publish 10270:8080 \
  --volume `pwd`/:/logs \
  --hostname Lit_Working \
  --env server.port=8080 \
  --env spring.profiles.active=dev \
  --env spring.profiles.instaceId=1 \
  --add-host Lit_Working:10.17.0.17 \
  --env 'JAVA_OPTS=-Xms4g -Xmx4g -Xmn3000m -Xss256k -XX:SurvivorRatio=8 -XX:ParallelGCThreads=16  -XX:CMSFullGCsBeforeCompaction=20 -XX:+UseCMSCompactAtFullCollection -XX:+PrintGCDetails' \
  $REPOSITORY





nohup java -Xms1024m -Xmx2048m -jar jshERP.jar 1>start.out 2>&1 &

```



