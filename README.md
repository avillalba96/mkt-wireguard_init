# README.md

## Tutorial para Configurar WireGuard en Cliente Linux y Servidor MikroTik

Este tutorial te guiará en la configuración de un servidor **WireGuard** en **MikroTik** y un cliente en **Linux**. Usaremos scripts predefinidos para automatizar la configuración en ambas plataformas. Además, incluimos un script para gestionar rutas dinámicas en el cliente, que se actualizará automáticamente si la IP del servidor cambia.

---

### **Requisitos previos**

- **Servidor MikroTik** con acceso administrativo.
- **Cliente Linux** con acceso sudo para la instalación y configuración de WireGuard.
- Herramientas como **Winbox**, **FTP**, o **SCP** para subir archivos al MikroTik.

---

## 1. **Instalación del Servidor WireGuard en MikroTik**

### Pasos

1. **Subir el script del servidor a MikroTik**:

   Copia el archivo `mkt_install-server.rsc` al router MikroTik usando **Winbox**, **FTP**, o **SCP**. Este archivo contiene las instrucciones necesarias para configurar la interfaz WireGuard, asignar direcciones IP y establecer las reglas de firewall necesarias.

2. **Importar y ejecutar el script en MikroTik**:

   Abre la consola en MikroTik (usando Winbox o SSH) y ejecuta el siguiente comando para importar y ejecutar el script:

   ```bash
   /import file="mkt_install-server.rsc"
   ```

3. **Verificar la clave privada del servidor**:

   Después de ejecutar el script, en la consola de MikroTik se imprimirá la **clave privada** del servidor (interfaz `wg0`). Copia esta clave, ya que la necesitarás para configurar los clientes Linux.

---

## 2. **Instalación del Cliente WireGuard en Linux**

### Pasos

1. **Descargar y ejecutar el script del cliente en Linux**:

   En tu máquina Linux, ejecuta el siguiente comando para descargar y ejecutar el script de configuración del cliente:

   ```bash
   wget https://raw.githubusercontent.com/avillalba96/mkt-wireguard_init/refs/heads/main/linux_install-client.sh -O /tmp/linux_install-client.sh && chmod +x /tmp/linux_install-client.sh && /tmp/linux_install-client.sh
   ```

2. **Interacción con el script**:

   Durante la ejecución del script, te solicitará ciertos datos:

   - Nombre del cliente.
   - Generación de una nueva clave privada o uso de una existente.
   - Dirección IP y puerto del cliente.
   - Clave pública del servidor.

   Si prefieres no ingresar algún valor, se utilizarán los valores por defecto. El script generará el archivo de configuración en `/etc/wireguard/CLIENTE-wg0.conf` y habilitará el servicio de **WireGuard** para que se inicie automáticamente en el arranque del sistema.

3. **Configurar el Peer en MikroTik**:

   Al finalizar la ejecución del script en Linux, se imprimirá un comando que debes ejecutar en MikroTik para agregar el cliente como peer. El comando será algo similar a:

   ```bash
   /interface wireguard peers add interface=wg0 name=CLIENTE-wg0 public-key=<CLIENTE_PUBLIC_KEY> allowed-address=<CLIENTE_IP>/32 persistent-keepalive=25
   ```

---

## 3. **Configuración de Actualización Automática de Rutas en Linux**

En el caso de que el servidor MikroTik tenga una dirección IP dinámica (por ejemplo, **vpn.example.com.ar**), es posible que la IP cambie. Para asegurarse de que el cliente Linux se mantenga conectado, es necesario actualizar la ruta que utiliza **WireGuard** para conectarse.

### Uso del script `update-route.sh`

1. **Descargar y configurar el script `update-route.sh`**:

   Este script resuelve periódicamente el nombre de dominio del servidor y actualiza la ruta para asegurarse de que el tráfico se dirija a la IP correcta. Ejecuta el siguiente comando para descargar y configurar el script:

   ```bash
   wget https://raw.githubusercontent.com/avillalba96/mkt-wireguard_init/refs/heads/main/other/scripts/update-route.sh -O /usr/local/bin/update-route.sh && chmod +x /usr/local/bin/update-route.sh
   ```

2. **Agregar el script al crontab**:

   Para que el script se ejecute automáticamente cada 5 minutos y actualice la ruta si la IP del servidor cambia, agrega la siguiente línea al **crontab**. Esto se puede hacer de forma automática con el siguiente comando:

   ```bash
   (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/update-route.sh") | crontab -
   ```

   Este comando asegura que el script **`update-route.sh`** se ejecute cada 5 minutos y registre la salida en **syslog**.

3. **Verificar la salida del script**:

   Los mensajes generados por el script, incluyendo la actualización de la ruta, se registrarán en **syslog**. Puedes ver la salida ejecutando:

   ```bash
   tail -f /var/log/syslog | grep update-route
   ```

---

## **Consideraciones adicionales**

- **Firewall**: El script de MikroTik incluye reglas de firewall básicas. Ajusta estas reglas según los requisitos de seguridad de tu red.
  
- **Claves y Seguridad**: Asegúrate de mantener las claves privadas seguras. Solo se deben compartir las claves públicas entre el servidor y los clientes.

- **Configuración adicional del cliente**: Si necesitas configurar más peers en el cliente Linux, puedes modificar el archivo de configuración generado en `/etc/wireguard/CLIENTE-wg0.conf`.

- **Monitorización y logs**: Todos los eventos relacionados con la actualización de la ruta del cliente Linux se registrarán en **syslog**, lo que facilita la monitorización de posibles problemas de conexión.
