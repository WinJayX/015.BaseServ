#!/bin/bash

#reset first node
echo "Reset first rabbitmq node."
docker exec BaseServ-RabbitMQ1 /bin/bash -c 'rabbitmqctl stop_app'
docker exec BaseServ-RabbitMQ1 /bin/bash -c 'rabbitmqctl reset'
docker exec BaseServ-RabbitMQ1 /bin/bash -c 'rabbitmqctl start_app'

#build cluster
echo "Starting to build rabbitmq cluster with two ram nodes."
docker exec BaseServ-RabbitMQ2 /bin/bash -c 'rabbitmqctl stop_app'
docker exec BaseServ-RabbitMQ2 /bin/bash -c 'rabbitmqctl reset'
docker exec BaseServ-RabbitMQ2 /bin/bash -c 'rabbitmqctl join_cluster --ram rabbit@BaseServ-RabbitMQ1'
docker exec BaseServ-RabbitMQ2 /bin/bash -c 'rabbitmqctl start_app'

docker exec BaseServ-RabbitMQ3 /bin/bash -c 'rabbitmqctl stop_app'
docker exec BaseServ-RabbitMQ3 /bin/bash -c 'rabbitmqctl reset'
docker exec BaseServ-RabbitMQ3 /bin/bash -c 'rabbitmqctl join_cluster --ram rabbit@BaseServ-RabbitMQ1'
docker exec BaseServ-RabbitMQ3 /bin/bash -c 'rabbitmqctl start_app'

#check cluster status
echo "Check cluster status:"
docker exec BaseServ-RabbitMQ1 /bin/bash -c 'rabbitmqctl cluster_status'
docker exec BaseServ-RabbitMQ2 /bin/bash -c 'rabbitmqctl cluster_status'
docker exec BaseServ-RabbitMQ3 /bin/bash -c 'rabbitmqctl cluster_status'
