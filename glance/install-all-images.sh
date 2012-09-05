#!/bin/bash
#
# Script para cadastrar as images no GLANCE baixando de repositorios/mirrors
#
# Danilo Ferri Perogil [20120827]: Desenvolvimento do script para adicionar todas as images no GLANCE
#

# Variaveis da API GLANCE
NOVA=$(which nova)
HOST_IP=${HOST:-127.0.0.1}
NOVA_TENANT_ID=${TENANT:-1}
NOVA_USERNAME=${USERNAME:-admin}
NOVA_API_KEY=${ADMIN_PASSWORD:-password}
SERVICE_TOKEN=`curl -s -d "{\"auth\":{\"passwordCredentials\": {\"username\": \"$NOVA_USERNAME\", \"password\": \"$NOVA_API_KEY\"}, \"tenantId\": \"$NOVA_TENANT_ID\"}}" -H "Content-type: application/json" http://$HOST_IP:5000/v2.0/tokens | python -c "import sys; import json; tok = json.loads(sys.stdin.read()); print tok['access']['token']['id'];"`

# Variaveis do script
# Caso haja a necessidade de incluir mais images, adicione a URL para Download na variavel MIRROS
MIRRORS='https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img http://stackops.s3.amazonaws.com/images/debian-6.0.4-amd64.img.tar.gz http://stackops.s3.amazonaws.com/images/centos-5.7-x86_64.img.tar.gz http://stackops.s3.amazonaws.com/images/centos-6.2-x86_64.img.tar.gz http://cloud-images.ubuntu.com/lucid/current/lucid-server-cloudimg-amd64.tar.gz http://uec-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-root.tar.gz http://stackops.s3.amazonaws.com/images/ttylinux-uec-amd64-12.1_2.6.35-22_1.tar.gz'
TMP_IMAGES='/tmp/stackops-images'

WINDOWS() {
	date
	glance add -A $SERVICE_TOKEN name=windows2008R-SP1-DataCenter is_public=true container_format=ovf disk_format=raw < /tmp/stackops-images/windows/windowsR2008SP1.img
	date
}

# Funcao para cadastrar as images no Glance
GLANCE() {
	local NAME="$1"
	local DISK="$2"
	local IMG="$3"
	local KERNEL="$4"

	$NOVA image-list | grep "$NAME" > /dev/null 2>&1
	[ "$?" -eq 0 ] && printf "\nImage ja cadastrada no Glance\n\n" && return 0

	if [ "$DISK" = ami ]; then 
		glance add -A $SERVICE_TOKEN name="$IMAGE_NAME" is_public=true container_format=$DISK disk_format=$DISK kernel_id=$KERNEL < "$IMG"
		[ "$?" -ne 0 ] && printf "\nProblem Image: $IMG\n"
	else
		glance add -A $SERVICE_TOKEN name="$NAME" is_public=true container_format=bare disk_format=$DISK  < "$IMG"
		[ "$?" -ne 0 ] && printf "\n\nProblem Image: $IMG\n"
	fi
}

# Funcao para localizar os arquivos img e vmlinuz repassando os parametros para o Glance
SETUP() {
	for IMAGE in `echo $MIRRORS` ; do
		PACKAGE=$(echo "$IMAGE" | sed -r 's,(.*/)(.*),\2,' | xargs)
		NAME_FOLDER=$(echo "$IMAGE" | sed -r 's,(.*/)(.*),\2,' | sed 's/\.tar.gz//g' | xargs)

		# Caso não exista as pastas tmp as mesmas sao criadas
		[ ! -e "$TMP_IMAGES" ] && mkdir -p "$TMP_IMAGES"
		[ ! -e "$TMP_IMAGES/$NAME_FOLDER" ] && mkdir -p "$TMP_IMAGES/$NAME_FOLDER"

		# Cria o nome da pasta conforme o nome do arquivo da image e descompacta
		if [ ! -e "$TMP_IMAGES/$NAME_FOLDER/$PACKAGE" ]; then
			printf "\nIniciando Download da Image: $PACKAGE ...\n"
			wget "$IMAGE" -O "$TMP_IMAGES/$NAME_FOLDER/$PACKAGE" > /dev/null 2>&1
		fi

		printf "\nDescompactando Image: $NAME_FOLDER ...\n"
		ls "$TMP_IMAGES/$NAME_FOLDER/$PACKAGE" | egrep -i '(tar.gz|.gz)' > /dev/null 2>&1
		[ "$?" -eq 0 ] && tar -xvzf "$TMP_IMAGES/$NAME_FOLDER/$PACKAGE" -C "$TMP_IMAGES/$NAME_FOLDER/"

		# Definindo as variaveis das images e do vmlinuz buscando os arquivos nos diretórios
		cd $TMP_IMAGES/$NAME_FOLDER
		IMG=`find . -iname *.img`
		IMG=`echo $TMP_IMAGES/$NAME_FOLDER/$IMG | sed 's/\.\///g'`
		VMLINUZ=`find . -iname *vmlinuz*`
		VMLINUZ=`echo $TMP_IMAGES/$NAME_FOLDER/$VMLINUZ | sed 's/\.\///g'`

		# Caso a instalacao seja Centos ou Debian o Glance altera os parametros de kernel e disco
		echo "$PACKAGE" | egrep -i '(cent|debian|cirros)' > /dev/null
		if [ "$?" -eq 0 ]; then
			GLANCE "$NAME_FOLDER" qcow2 "$IMG"
		fi

		# Caso a instalacao seja derivadas de Debian altera os parametros de kernel e disco
		echo "$PACKAGE" | egrep -i '(tty|ubuntu|lucid|precise)' > /dev/null
		if [ "$?" -eq 0 ]; then
			# Especificando a instalacao do Ubuntu 12.04.1 (Precise) que o padrao é diferente de image e vmlinuz
			echo "$PACKAGE" | egrep -i '(precise)' > /dev/null
			if [ "$?" -eq 0 ]; then
				cd $TMP_IMAGES/$NAME_FOLDER/boot
				IMG=`find . -iname *img*virtual*`
				IMG=`echo $TMP_IMAGES/$NAME_FOLDER/boot/$IMG | sed 's/\.\///g'`
				VMLINUZ=`find . -iname *vmlinuz*`
				VMLINUZ=`echo $TMP_IMAGES/$NAME_FOLDER/boot/$VMLINUZ | sed 's/\.\///g'`
				IMAGE_NAME=`echo "$NAME_FOLDER" | sed 's/lucid/ubuntu-10.04/g' | sed 's/precise/ubuntu-12.04.1/g' `
		SOURCE_IMAGE_NAME=$(echo "$IMAGE" | sed -r 's,(.*/)(.*),\2,' | xargs)
		IMAGE_NAME_FOLDER=$(echo "$IMAGE" | sed -r 's,(.*/)(.*),\2,' | sed 's/\.tar.gz//g' | xargs)

		# Caso não exista as pastas tmp as mesmas sao criadas
		[ ! -e "$TMP_IMAGES" ] && mkdir -p "$TMP_IMAGES"
		[ ! -e "$TMP_IMAGES/$IMAGE_NAME_FOLDER" ] && mkdir -p "$TMP_IMAGES/$IMAGE_NAME_FOLDER"

		# Cria o nome da pasta conforme o nome do arquivo da image e descompacta
		if [ ! -e "$TMP_IMAGES/$SOURCE_IMAGE_NAME" ]; then
			printf "\nIniciando Download da Image: $IMAGE_NAME_FOLDER ...\n"
			wget "$IMAGE" -O "$TMP_IMAGES/$SOURCE_IMAGE_NAME" > /dev/null 2>&1
			printf "\nDescompactando Image: $IMAGE_NAME_FOLDER ...\n"
			tar -xvzf "$TMP_IMAGES/$SOURCE_IMAGE_NAME" -C "$TMP_IMAGES/$IMAGE_NAME_FOLDER"
		fi

		# Definindo as variaveis das images e do vmlinuz buscando os arquivos nos diretórios
		cd $TMP_IMAGES/$IMAGE_NAME_FOLDER
		IMG=`find . -iname *.img`
		IMG=`echo $TMP_IMAGES/$IMAGE_NAME_FOLDER/$IMG | sed 's/\.\///g'`
		VMLINUZ=`find . -iname *vmlinuz*`
		VMLINUZ=`echo $TMP_IMAGES/$IMAGE_NAME_FOLDER/$VMLINUZ | sed 's/\.\///g'`

		# Caso a instalacao seja Centos ou Debian o Glance altera os parametros de kernel e disco
		echo "$SOURCE_IMAGE_NAME" | egrep -i '(cent|debian)' > /dev/null
		if [ "$?" -eq 0 ]; then
			GLANCE "$IMAGE_NAME_FOLDER" qcow2 "$IMG"
		fi

		# Caso a instalacao seja derivadas de Debian altera os parametros de kernel e disco
		echo "$SOURCE_IMAGE_NAME" | egrep -i '(tty|ubuntu|lucid|precise)' > /dev/null
		if [ "$?" -eq 0 ]; then
			# Especificando a instalacao do Ubuntu 12.04.1 (Precise) que o padrao é diferente de image e vmlinuz
			echo "$SOURCE_IMAGE_NAME" | egrep -i '(precise)' > /dev/null
			if [ "$?" -eq 0 ]; then
				cd $TMP_IMAGES/$IMAGE_NAME_FOLDER/boot
				IMG=`find . -iname *img*virtual*`
				IMG=`echo $TMP_IMAGES/$IMAGE_NAME_FOLDER/boot/$IMG | sed 's/\.\///g'`
				VMLINUZ=`find . -iname *vmlinuz*`
				VMLINUZ=`echo $TMP_IMAGES/$IMAGE_NAME_FOLDER/boot/$VMLINUZ | sed 's/\.\///g'`
				IMAGE_NAME=`echo "$IMAGE_NAME_FOLDER" | sed 's/lucid/ubuntu-10.04/g' | sed 's/precise/ubuntu-12.04.1/g' `
				RVAL=`glance add -A $SERVICE_TOKEN name="$IMAGE_NAME-kernel" is_public=true 													container_format=aki disk_format=aki < "$VMLINUZ"`
				KERNEL_ID=`echo $RVAL | cut -d":" -f2 | tr -d " "`
				GLANCE "$IMAGE_NAME" ami "$IMG" "$KERNEL_ID"
						
			# Caso seja derivado de Debian mas NAO SEJA PRECISE altera os parametros de kernel e disco
			else
				IMAGE_NAME=`echo "$NAME_FOLDER" | sed 's/lucid/ubuntu-10.04/g' | sed 's/precise/ubuntu-12.04.1/g' `
				RVAL=`glance add -A $SERVICE_TOKEN name="$IMAGE_NAME-kernel" is_public=true 													container_format=aki disk_format=aki < "$VMLINUZ"`
				KERNEL_ID=`echo $RVAL | cut -d":" -f2 | tr -d " "`
				GLANCE "$IMAGE_NAME" ami "$IMG" "$KERNEL_ID"
			fi
		fi
	done
}

# Begin
SETUP
#WINDOWS
