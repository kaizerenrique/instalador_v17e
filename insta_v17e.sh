#!/bin/bash
################################################################################
# Script para instalar Odoo en Ubuntu 16.04, 18.04, 20.04 and 22.04 
#-------------------------------------------------------------------------------
# Este script instalará Odoo en su servidor Ubuntu. Puede instalar múltiples instancias de Odoo.
# en un Ubuntu debido a los diferentes xmlrpc_ports
#-------------------------------------------------------------------------------# 
# sudo nano insta_v17e.sh 
# sudo chmod +x insta_v17e.sh 
# ./insta_v17e
################################################################################

OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
# El puerto predeterminado donde se ejecutará esta instancia de Odoo (siempre que use el comando -c en la terminal)
# Establezca en verdadero si desea instalarlo, en falso si no lo necesita o ya lo tiene instalado.
INSTALL_WKHTMLTOPDF="True"
# Configure el puerto predeterminado de Odoo (aún debe usar -c /etc/odoo-server.conf, por ejemplo, para usar esto).
OE_PORT="8069"
# ¡IMPORTANTE! Este script contiene bibliotecas adicionales que se necesitan específicamente para Odoo 17.0
OE_VERSION="17.0"
# Instala postgreSQL V14 en lugar de los valores predeterminados (por ejemplo, V12 para Ubuntu 20/22): esto mejora el rendimiento.
INSTALL_POSTGRESQL_FOURTEEN="True"
# ¡Establezca esto en Verdadero si desea instalar Nginx!
INSTALL_NGINX="True"
# Establezca la contraseña de superadministrador: si GENERATE_RANDOM_PASSWORD está configurado en "Verdadero", generaremos automáticamente una contraseña aleatoria; de lo contrario, usaremos esta
OE_SUPERADMIN="admin"
# Establezca en "Verdadero" para generar una contraseña aleatoria, "Falso" para usar la variable en OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="True"
OE_CONFIG="${OE_USER}-server"
# Establecer el nombre del sitio web
WEBSITE_NAME="_"
# Configure el puerto de sondeo largo predeterminado de Odoo (aún debe usar -c /etc/odoo-server.conf, por ejemplo, para usar esto).
LONGPOLLING_PORT="8072"
# Establezca en "Verdadero" para instalar certbot y tener SSL habilitado, "Falso" para usar http
ENABLE_SSL="False"
# Proporcione un correo electrónico para registrar el certificado SSL
ADMIN_EMAIL="proyectocharlie99@gmail.com"
##
### Enlaces de descarga WKHTMLTOPDF
## === Ubuntu Trusty x64 y x32 === (para otras distribuciones, reemplace estos dos enlaces,
## para tener instalada la versión correcta de wkhtmltopdf, para obtener una nota de peligro, consulte
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/16.0/administration/install.html

# Comprueba si el sistema operativo es Ubuntu 22.04
if [[ $(lsb_release -r -s) == "22.04" ]]; then
    WKHTMLTOX_X64="https://packages.ubuntu.com/jammy/wkhtmltopdf"
    WKHTMLTOX_X32="https://packages.ubuntu.com/jammy/wkhtmltopdf"
    #No El mismo enlace funciona tanto para 64 como para 32 bits en Ubuntu 22.04
else
    # Para versiones anteriores de Ubuntu
    WKHTMLTOX_X64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_amd64.deb"
    WKHTMLTOX_X32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_i386.deb"
fi

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
# El paquete Universe es para Ubuntu 18.x.
# universo sudo add-apt-repository
# Dependencia libpng12-0 para wkhtmltopdf para versiones anteriores de Ubuntu
# sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ xenial main"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install libpq-dev

#--------------------------------------------------
# Instalar PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Instalar PostgreSQL Server ----"
if [ $INSTALL_POSTGRESQL_FOURTEEN = "True" ]; then
    echo -e "\n---- Instalación de postgreSQL V14 por elección del usuario ----"
    sudo curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt-get update
    sudo apt-get install postgresql-16
else
    echo -e "\n---- Instalación de la versión predeterminada de PostgreSQL basada en la versión de Linux ----"
    sudo apt-get install postgresql postgresql-server-dev-all -y
fi


echo -e "\n---- Creación del usuario PostgreSQL de ODOO  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Instalar Dependencies
#--------------------------------------------------
echo -e "\n--- Instalar Python 3 + pip3 --"
sudo apt-get install python3 python3-pip
sudo apt-get install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y

echo -e "\n---- Instalar python packages/requirements ----"
sudo -H pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt

echo -e "\n---- Instalar nodeJS NPM and rtlcss for LTR support ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss

#--------------------------------------------------
# Instalar Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Instale wkhtml y coloque accesos directos en el lugar correcto para ODOO ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url  

  if [[ $(lsb_release -r -s) == "22.04" ]]; then
    # Ubuntu 22.04 LTS
    sudo apt install wkhtmltopdf -y
  else
      # Para versiones anteriores de Ubuntu
    sudo gdebi --n `basename $_url`
  fi
  
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "¡Wkhtmltopdf no se instala debido a la elección del usuario!"
fi

echo -e "\n---- Crear usuario del sistema ODOO ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#El usuario también debe agregarse al grupo sudo.
sudo adduser $OE_USER sudo

echo -e "\n---- Crear directorio de registro ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Instalar ODOO
#--------------------------------------------------
echo -e "\n==== Instalar ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

# sudo pip3 install psycopg2-binary pdfminer.six
# sudo ln -s /usr/bin/nodejs /usr/bin/node
# sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
# sudo npm install -g less
# sudo npm install -g less-plugin-clean-css

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"


sudo touch /etc/${OE_CONFIG}.conf
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"

sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons,${OE_HOME}/enterprise/addons\n' >> /etc/${OE_CONFIG}.conf"

sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Agregar ODOO como demonio (script de inicio)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

#--------------------------------------------------
# Instalar Nginx si es necesario
#--------------------------------------------------
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n---- Installing and setting up Nginx ----"
  sudo apt install nginx -y
  cat <<EOF > ~/odoo
server {
  listen 80;

  # set proper server name after domain set
  server_name $WEBSITE_NAME;

  # Add Headers for odoo proxy mode
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header X-Real-IP \$remote_addr;
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-XSS-Protection "1; mode=block";
  proxy_set_header X-Client-IP \$remote_addr;
  proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;

  #   odoo    log files
  access_log  /var/log/nginx/$OE_USER-access.log;
  error_log       /var/log/nginx/$OE_USER-error.log;

  #   increase    proxy   buffer  size
  proxy_buffers   16  64k;
  proxy_buffer_size   128k;

  proxy_read_timeout 900s;
  proxy_connect_timeout 900s;
  proxy_send_timeout 900s;

  #   force   timeouts    if  the backend dies
  proxy_next_upstream error   timeout invalid_header  http_500    http_502
  http_503;

  types {
    text/less less;
    text/scss scss;
  }

  #   enable  data    compression
  gzip    on;
  gzip_min_length 1100;
  gzip_buffers    4   32k;
  gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
  gzip_vary   on;
  client_header_buffer_size 4k;
  large_client_header_buffers 4 64k;
  client_max_body_size 0;

  location / {
    proxy_pass    http://127.0.0.1:$OE_PORT;
    # by default, do not forward anything
    proxy_redirect off;
  }

  location /longpolling {
    proxy_pass http://127.0.0.1:$LONGPOLLING_PORT;
  }

  location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 2d;
    proxy_pass http://127.0.0.1:$OE_PORT;
    add_header Cache-Control "public, no-transform";
  }

  # cache some static data in memory for 60mins.
  location ~ /[a-zA-Z0-9_-]*/static/ {
    proxy_cache_valid 200 302 60m;
    proxy_cache_valid 404      1m;
    proxy_buffering    on;
    expires 864000;
    proxy_pass    http://127.0.0.1:$OE_PORT;
  }
}
EOF

  sudo mv ~/odoo /etc/nginx/sites-available/$WEBSITE_NAME
  sudo ln -s /etc/nginx/sites-available/$WEBSITE_NAME /etc/nginx/sites-enabled/$WEBSITE_NAME
  sudo rm /etc/nginx/sites-enabled/default
  sudo service nginx reload
  sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${OE_CONFIG}.conf"
  echo "Done! The Nginx server is up and running. Configuration can be found at /etc/nginx/sites-available/$WEBSITE_NAME"
else
  echo "Nginx isn't installed due to choice of the user!"
fi

#--------------------------------------------------
# Habilitar SSL con certbot
#--------------------------------------------------

if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "_" ];then
  sudo apt-get update -y
#  sudo apt install snapd -y
#  sudo snap install core; snap refresh core
#  sudo snap install --classic certbot
  sudo apt-get install certbot python3-certbot-nginx -y
#  sudo apt-get install python3-certbot-nginx -y
  sudo certbot --nginx -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo service nginx reload
  echo "SSL/HTTPS is enabled!"
else
  echo "SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration!"
  if $ADMIN_EMAIL = "odoo@example.com";then 
    echo "Certbot does not support registering odoo@example.com. You should use real e-mail address."
  fi
  if $WEBSITE_NAME = "_";then
    echo "Website name is set as _. Cannot obtain SSL Certificate for _. You should use real website address."
  fi
fi

echo -e "* Iniciando el servicio Odoo"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "Configuraton file location: /etc/${OE_CONFIG}.conf"
echo "Logfile location: /var/log/$OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Password superadmin (database): $OE_SUPERADMIN"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
if [ $INSTALL_NGINX = "True" ]; then
  echo "Nginx configuration file: /etc/nginx/sites-available/$WEBSITE_NAME"
fi
echo "-----------------------------------------------------------"