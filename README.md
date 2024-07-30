# Instalador

El siguiente script es un instalador de Odoo en servidores de Linux 

##### 1. Descargar el Archivo

```
sudo wget https://raw.githubusercontent.com/kaizerenrique/instalador_v17e/main/insta_v17e.sh
```

##### 2. Modificar Parámetros 
Hay algunas cosas que puedes configurar, esta es la lista más utilizada:<br/>
```OE_USER``` Será el nombre de usuario para el usuario del sistema..<br/>
```GENERATE_RANDOM_PASSWORD``` Si esto está configurado en ```True``` El script generará una contraseña aleatoria, si se configura en ```False```Estableceremos la contraseña que está configurada en ```OE_SUPERADMIN```. Por defecto el valor es ```True``` y el script generará una contraseña aleatoria y segura.<br/>
```INSTALL_WKHTMLTOPDF``` ajustado a ```False``` Si no desea instalar Wkhtmltopdf, si desea instalarlo debe configurarlo en ```True```.<br/>
```OE_PORT``` es el puerto donde debería ejecutarse Odoo, por ejemplo 8069.<br/>
```OE_VERSION``` ¿Cuál es la versión de Odoo a instalar, por ejemplo? ```17.0``` para Odoo V17.<br/>
```IS_ENTERPRISE``` instalará la versión Enterprise encima de```17.0``` Si lo configuras en ```True```, configúrelo en ```False``` Si quieres la versión comunitaria de Odoo 17.<br/>
```OE_SUPERADMIN``` es la contraseña maestra para esta instalación de Odoo.<br/>
```INSTALL_NGINX``` se establece en ```False``` De forma predeterminada, configure esto en```True``` Si quieres instalar Nginx.<br/>
```WEBSITE_NAME``` Establezca aquí el nombre del sitio web para la configuración de nginx<br/>
```ENABLE_SSL``` Establezca esto en ```True``` instalar [certbot](https://github.com/certbot/certbot) y configurar nginx con https usando un certificado gratuito Let's Encrypted<br/>
```ADMIN_EMAIL``` Se necesita una dirección de correo electrónico para registrarse en Let's Encrypt. Reemplace el marcador de posición predeterminado con una dirección de correo electrónico de su organización.<br/>
```INSTALL_NGINX``` y ```ENABLE_SSL``` debe estar configurado en ```True``` y el marcador de posición en ```ADMIN_EMAIL``` Debe reemplazarse con una dirección de correo electrónico válida para la instalación de certbot<br/>