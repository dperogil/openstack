#!/bin/bash
#
#
## Danilo Ferri Perogil [20120903]: Check que verifica se o numero de instancias chegou no limite e ja esta alarmando no log
#
#

LOG='/var/log/nova/apachessl-error.log'
CONF='/etc/nova/nova-controller.conf'
NOVA=$(which nova)
NUM_INSTANCE_POOL=$($NOVA list | egrep -v -- "(ID|--)" | wc -l)
NUM_INSTANCE_CONF=$(grep quota_instances $CONF | awk -F '--quota_instances=' '{print $2}')
LAST_LOG=$(grep -i InstanceLimitExceeded "$LOG" | tail -n1 | awk '{print $3}')
DATE=$(date +%d)
LIMIT=$((NUM_INSTANCE_CONF-2))

if [ "$NUM_INSTANCE_POOL" -eq "$NUM_INSTANCE_CONF" ]; then
	if [ "$LAST_LOG" -eq "$DATE" ]; then
		printf "Tentativa de criar instancia falhou!! Numero de instancias no Controller chegou ao limite: $NUM_INSTANCE_CONF\n"
		exit 0
	fi
fi

if [ "$NUM_INSTANCE_POOL" -ge "$NUM_INSTANCE_CONF" ]; then
		printf "Numero de instancias no Controller chegou ao limite: $NUM_INSTANCE_CONF\n"
		exit 0
fi

if [ "$NUM_INSTANCE_POOL" -ge "$LIMIT" ]; then
	printf "Numero de instancias proximo ao limite do Controller: $NUM_INSTANCE_POOL\n"
	exit 1
fi
		
