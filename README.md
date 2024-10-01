# README.md

## Tutorial para Configurar WireGuard en Cliente Linux y Servidor MikroTik

Este tutorial te guiará en la configuración de un servidor WireGuard en MikroTik y de un cliente en Linux. Usaremos scripts predefinidos para automatizar la configuración tanto en el servidor como en los clientes.

---

### **Requisitos previos**

- **Servidor MikroTik** con acceso administrativo.
- **Cliente Linux** con acceso sudo para la instalación y configuración de WireGuard.

---

## 1. **Instalación del Servidor WireGuard en MikroTik**

### Pasos

1. **Subir el script del servidor a MikroTik**:

   Descargar el archivoCopia el archivo `mkt_install-server.rsc` al router MikroTik usando herramientas como **Winbox**, **FTP**, o **SCP**. Este archivo contiene las instrucciones necesarias para configurar la interfaz WireGuard, asignar direcciones IP y configurar las reglas de firewall.

2. **Importar y ejecutar el script en MikroTik**:

   Abre la consola en MikroTik (por ejemplo, usando Winbox o SSH) y ejecuta el siguiente comando para importar el script y configurarlo:

   ```bash
   /import file="mkt_install-server.rsc"
   ```

3. **Verificar la clave privada del servidor**:

   Después de ejecutar el script, se imprimirá en la consola la **clave privada** del servidor WireGuard (interfaz `wg0`), que deberás copiar para configurarla en los clientes.

---

## 2. **Instalación del Cliente WireGuard en Linux**

### Pasos

1. **Subir el script del cliente a la máquina Linux**:

   Ejecutar el siguiente comando en tu máquina Linux. Este script configurará el cliente WireGuard automáticamente.

   ```bash
   wget https://raw.githubusercontent.com/avillalba96/script-altahost/main/install/systemd/pvebanner-service_example -O /usr/bin/pvebanner && chmod +x /usr/bin/pvebanner && systemctl restart pvebanner.service
   ```

2. **Interacción con el script**:

   - El script te solicitará ciertos datos, como el nombre del cliente, si deseas generar una nueva clave privada, la IP y el puerto del cliente, la clave pública del servidor, entre otros. Si no ingresas ningún dato, se utilizarán los valores por defecto.

   - El script generará el archivo de configuración en `/etc/wireguard/CLIENTE-wg0.conf` y habilitará el servicio WireGuard en el arranque de la máquina.

3. **Configurar el Peer en MikroTik**:

   Al finalizar la ejecución del script, se imprimirá un comando que deberás ejecutar en MikroTik para agregar el peer (cliente) al servidor. Este comando será algo similar a lo siguiente:

   ```bash
   /interface wireguard peers add interface=wg0 name=CLIENTE-wg0 public-key=<CLIENTE_PUBLIC_KEY> allowed-address=<CLIENTE_IP>/32 persistent-keepalive=25
   ```

---

## **Consideraciones adicionales:**

- **Firewall**: El script de MikroTik incluye reglas de firewall básicas. Asegúrate de ajustarlas según las necesidades de tu red.
  
- **Claves y Seguridad**: Es fundamental que mantengas las claves privadas seguras y que solo compartas las claves públicas entre el cliente y el servidor.

- **Configuración adicional del cliente**: Si necesitas configurar más peers en el cliente Linux, puedes modificar el archivo de configuración que el script genera en `/etc/wireguard/CLIENTE-wg0.conf`.
