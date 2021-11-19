#!/bin/bash

VERS=$(hostnamectl | egrep 'Operating System' | awk -F ":" '{print $2}')
WHO=$(whoami)
EXISTS_APCH=$(systemctl status apache2| egrep 'Loaded' | awk -F ":" '{print $1}')
APCH=$(systemctl status apache2| egrep 'Active' | awk -F " " '{print $3}')

EXISTS_MARI=$(systemctl status mariadb| egrep 'Loaded' | awk -F ":" '{print $1}')
MARI=$(systemctl status mariadb| egrep 'Active' | awk -F " " '{print $3}')

PHP_VER=$(php -v | egrep 'PHP'| awk -F " " '{print $1}'| egrep 'PHP')
GET_IP=$(ifconfig | egrep 'inet ' | grep -v '127.0.0.1' | awk -F " " '{print $2}')


################### SO y TIPO DE USUARIO ##############################

so () {
	echo "Revisando SO"
	sleep 2
	if [[ $VERS =~ "Debian" ]]
	then
		echo "Es Debian. La instalación continua"
		sleep 2
		checar_usr
		echo "########################## Revisando estado de LAMP ##########################" 
		sleep 1
		checar_apache
		checar_mariadb
		checar_php
		checar_git
		sleep 1
		echo "########################## LAMP ya está instalado y activo ##########################"
	else
		echo "No es Debian. Consulta otro script"
		exit
	fi
}


checar_usr () {
	echo "Revisando usuario"
	sleep 2
	if [[ $WHO == "root" ]]
	then
		echo "Es root. Continua la instalacion"
		sleep 3
	else
		echo "No eres root. No puedes usar este script"
		exit
	fi
}

################################ LAMP #############################################

checar_apache () {
	echo "Revisando instalación de apache"
	sleep 2
	if [[ $EXISTS_APCH =~ "Loaded" ]]
	then
		if [[ $APCH =~ "(running)" ]]
		then
			echo "Apache está instalado y corriendo"
			sleep 2
		else
			echo "Apache existe pero no está corriendo"
			echo -n "Desea activarlo? Y/N: "
			read activate
			if [[ $activate == "Y" ]]
			then
				$(systemctl start apache2)
			else
				echo "El servicio no está activado"
				exit
			fi
		fi
	else
		echo "Apache no existe"
		echo -n "Desea instalar? Y/N: "
		read install_apache
		if [[ $install_apache == "Y" ]]
		then
			$(apt install -y apache2)
			echo "Listo! APACHE INSTALADO"
		else
			echo "El servicio no está instalado"
			exit
		fi
	fi

}

checar_mariadb () {
	echo "Revisando instalación de Mariadb"
	sleep 2
	if [[ $EXISTS_MARI =~ "Loaded" ]]
	then
		if [[ $MARI =~ "(running)" ]]
		then
			echo "Mariadb está instalado y corriendo"
			sleep 2
		else
			echo "Mariadb existe pero no está corriendo"
			echo -n "Desea activarlo? Y/N: "
			read activate
			if [[ $activate == "Y" ]]
			then
				$(systemctl start mariadb)
			else
				echo "El servicio no está activado"
				exit
			fi
		fi
	else
		echo "Mariadb no existe"
		echo -n "Desea instalar? Y/N: "
		read install_mariadb
		if [[ $install_mariadb == "Y" ]]
		then
			$(apt install -y mariadb-server)
			mysql_secure_installation

			echo "Listo! MariaDB INSTALADO"
		else
			echo "El servicio no está instalado"
			exit
		fi
	fi

}

checar_php () {
	echo "Revisando instalación de php"
	sleep 2
	if [[ $PHP_VER =~ "PHP" ]]
	then
		echo "Ya cuenta con PHP"
	else
		echo "No cuenta con PHP"
		echo -n "Desea instalarlo? Y/N: "
		read install_php
		if [[ $install_php == "Y" ]]
		then
			$(apt install -y php libapache2-mod-php php-cli php-fpm php-json php-pdo php-mysql php-zip php-gd php-intl php-soap php-mbstring php-curl php-xml php-pear php-bcmath)
		else
			echo "PHP no está instalado"
			exit
		fi
	fi
}


checar_git () {

	echo "Comprobando instalacion de git"
	sleep 1
	GITV=$(which git)
	if [ $GITV = "/usr/bin/git" ]
	then
		echo "git ya esta instalado"
	else
		$(apt install -y git)
	fi
}


####################### FIN LAMP ##########################################

######################## MOODLE #######################################

chk_moodle () {
	echo "Revisando si Moodle ya esta instalado"
	sleep 1
	if [[ -d "/var/www/html/moodle" ]] && [[ -d "/var/www/moodledata" ]]
	then
		echo "Moodle ya está descargado"
		if [[ -f /var/www/html/moodle/config.php ]]
		then
			echo "Y ya está instalado"
			exit
		else
			echo "Pero aún no está instalado"
		fi
	else
		echo "Moodle no está instalado"
		dwnld_moodle
	fi
}



dwnld_moodle () {
	echo "Preparando la descarga de MOODLE"
	sleep 1
	echo "Clonando git de Moodle"
	sleep 1
	$(git clone -b MOODLE_310_STABLE git://git.moodle.org/moodle.git)
	$(mv moodle /var/www/html/)
	echo "Extrayendo Moodle"
	$(chown -R www-data: /var/www/html/moodle/)
	echo "Creando directorio de comunicación"
	sleep 1
	$(mkdir /var/www/moodledata)
	$(chown www-data: /var/www/moodledata)
}


edit_mariadb () {

	echo "Preparando la base de datos"
	sleep 1
	echo "Para su creación, necesita establecer los siguientes parámetros:"
	sleep 1
	echo "Nombre de la base de datos"
	read name_database
	echo "Listo!"
	sleep 1
	echo "Nombre del usuario administrador"
	read name_user_database
	echo "Listo!"
	sleep 1
	echo "Contraseña del usuario administrador"
	echo -n "Desea una contraseña creada automáticamente? y/n: "
	read auto_manual
		if [[ $auto_manual =~ "y" ]]
		then
			new_psswd=$(< /dev/urandom tr -dc _A-Za-z-0-9*\&\! | head -c12;echo)
			echo "Su contraseña es: $new_psswd"
		else
			echo "Establezca su contraseña"
			read paswd_user_database
		fi
	sleep 1
	echo "Listo!"
	sleep 1
	$(cd /root)
	echo "Comienza a configurar base de datos"
	sleep 1
	echo "Creando la base de datos"
	sleep 1
	$(mysql -u root -e"create database $name_database charset utf8mb4 collate utf8mb4_unicode_ci;")
	echo "Creando usuario para moodle"

	if [[ $auto_manual =~ "y" ]]
		then
			$(mysql -u root -e"create user $name_user_database@localhost identified by '$new_psswd';")
			whatif='yes'
		else
			$(mysql -u root -e"create user $name_user_database@localhost identified by '$paswd_user_database';")
			whatif='nel'
		fi

	$(mysql -u root -e"grant all privileges on $name_database.* to $name_user_database@localhost;")
}


ver_web () {

	echo "Desea realizar la instalación en su navegador? y/n"
	read web_ok
	if [[ $web_ok =~ "y" ]]
		then
			sleep 1
			echo "Continue con la instalacion de la version web. Abra un navegador y coloque: http://$GET_IP/moodle"
			exit
		else
			ver_parametros
		fi

}

######################### FIN MOODLE ###################################
######################### MOODLE EN CONSOLA ###################################

ver_parametros () {

	IP=$(hostname -I | awk -F " " '{print $1}')
	URL="http://$IP/moodle"
	echo "Instalando Moodle mediante terminal"
	sleep 1
	admin_passwd=$(date +%s | sha256sum| base64 | head -c16;echo)
	echo "Ingrese el nombre de administrador para Moodle"
	read admin_name
	echo "Ingrese el correo para Moodle: "
	read get_email
	echo "Ingrese el nombre de su Moodle: "
	read mood_name
        echo "Ingrese el nombre corto de su Moodle: "
        read mood_short
	echo "Configurando Moodle"
	sleep 1
	if [[ $whatif == "yes" ]]
		then
			php /var/www/html/moodle/admin/cli/install.php --chmod=0777 --lang=es_mx --wwwroot=$URL --dataroot=/var/www/moodledata --dbtype=mariadb --dbhost=localhost --dbname=$name_database --dbuser=$name_user_database --dbpass=$new_psswd --dbport= --dbsocket= --prefix=mdl_ --fullname=$mood_name --shortname=$mood_short  --adminuser=$admin_name --adminpass=$admin_passwd --adminemail=$get_email --agree-license=s --non-interactive
		else
			php /var/www/html/moodle/admin/cli/install.php --chmod=0777 --lang=es_mx --wwwroot=$URL --dataroot=/var/www/moodledata --dbtype=mariadb --dbhost=localhost --dbname=$name_database --dbuser=$name_user_database --dbpass=$paswd_user_database --dbport= --dbsocket= --prefix=mdl_ --fullname=$mood_name --shortname=$mood_short --adminuser=$admin_name --adminpass=$admin_passwd --adminemail=$get_email --agree-license=s --non-interactive
                fi

        chown -R www-data /var/www/html/moodle
        chown -R www-data /var/www/moodledata

	echo "-----------------------------------------------------------------------------"
	echo "Usuario de Moodle: $admin_name"
	echo "Password de Moodle: $admin_passwd"
	echo "Entre al navegador a la siguiente direccion: $URL"
	echo "------------------------------------------------------------------------------"

}



echo "Iniciando instalacion"
sleep 1
so
clear
chk_moodle
edit_mariadb
ver_web

echo "LISTO!"
