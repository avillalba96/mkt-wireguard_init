# README.md

## Tutorial para Configurar WireGuard en Cliente Linux y Servidor MikroTik

Este tutorial te guiará en dos configuraciones diferentes de WireGuard: **Peer-to-Client** (con un cliente en Linux y servidor en MikroTik) y **Peer-to-Peer** (entre dos servidores, MikroTik y pfSense). También se incluye la configuración de scripts para gestionar rutas dinámicas en el cliente Linux y la creación de reglas de firewall en ambas plataformas.

---

## **Requisitos previos**

- **Servidor MikroTik** con acceso administrativo.
- **Cliente Linux** con acceso sudo para la instalación y configuración de WireGuard.
- Herramientas como **Winbox**, **FTP**, o **SCP** para subir archivos al MikroTik.
- **pfSense** si utilizas la configuración Peer-to-Peer.

---

## **WireGuard Peer-to-Client**

### 1. Instalación del Servidor WireGuard en MikroTik

#### Pasos

1. **Subir el script del servidor a MikroTik**:

   Editar las variables necesarias y copia el archivo `mkt_install-server.rsc` al router MikroTik usando **Winbox**, **FTP**, o **SCP**. Este archivo contiene las instrucciones necesarias para configurar la interfaz WireGuard, asignar direcciones IP y establecer las reglas de firewall necesarias.

2. **Importar y ejecutar el script en MikroTik**:

   Abre la consola en MikroTik (usando Winbox o SSH) y ejecuta el siguiente comando para importar y ejecutar el script:

   ```bash
   /import file="mkt_install-server.rsc"
   ```

3. **Verificar la clave privada del servidor**:

   Después de ejecutar el script, en la consola de MikroTik se imprimirá la **clave privada** del servidor (interfaz `wg0`). Copia esta clave, ya que la necesitarás para configurar los clientes Linux.

---

### 2. Instalación del Cliente WireGuard en Linux

#### Pasos

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

### 3. Configuración de Actualización Automática de Rutas en Linux

En el caso de que el servidor MikroTik tenga una dirección IP dinámica (por ejemplo, **vpn.example.com.ar**), es posible que la IP cambie. Para asegurarse de que el cliente Linux se mantenga conectado, es necesario actualizar la ruta que utiliza **WireGuard** para conectarse.

#### Uso del script `update-route.sh`

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

### Consideraciones adicionales

- **Firewall**: El script de MikroTik incluye reglas de firewall básicas. Ajusta estas reglas según los requisitos de seguridad de tu red.
  
- **Claves y Seguridad**: Asegúrate de mantener las claves privadas seguras. Solo se deben compartir las claves públicas entre el servidor y los clientes.

---

## **WireGuard Peer to Peer: MikroTik y pfSense**

### 1. **Pasos en MikroTik**

1. **Subir el script del servidor a MikroTik**:

   Editar las variables necesarias y copia el archivo `mkt_install-server.rsc` al router MikroTik usando **Winbox**, **FTP**, o **SCP**. Este archivo contiene las instrucciones necesarias para configurar la interfaz WireGuard, asignar direcciones IP y establecer las reglas de firewall necesarias.

2. **Importar y ejecutar el script en MikroTik**:

   Abre la consola en MikroTik (usando Winbox o SSH) y ejecuta el siguiente comando para importar y ejecutar el script:

   ```bash
   /import file="mkt_install-server.rsc"
   ```

3. **Configurar el Peer en MikroTik:**

   Configura el peer para el **pfSense**:

   ```bash
   /interface wireguard peers add interface="WGINTERFACENAME" public-key="PUBLICKEY_PFSENSE" endpoint="wiltel.example.com.ar:13233" allowed-address=10.10.8.2/32,192.168.0.0/24 is-responder=yes
   ```

---

### 2. **Pasos en pfSense**

#### 2.1. **Habilitar WireGuard:**

- Ve a **VPN > WireGuard > Settings** y habilita WireGuard. Asegúrate de que **Keep Configuration** esté habilitado y que la resolución de nombres se ajuste si tu **MikroTik** usa un dominio dinámico.

#### 2.2. **Asignar Interfaz a WireGuard:**

   - Ve a **Interfaces > Assignments** y asigna la interfaz tun_wg0 a **WG**.
   - Configura la interfaz:
     - **IPv4 Address**: 10.10.8.2/24.
     - **IPv4 Upstream Gateway**: 10.10.8.1 (la IP de WireGuard en el MikroTik).

   Esto asegurará que el tráfico desde **pfSense** a MikroTik pase por el túnel.

#### 2.3. **Configurar el Tunnel en pfSense:**

   - Ve a **VPN > WireGuard > Tunnels** y configura el túnel con:
     - **Listen Port**: 13233.
     - **Interface Address**: 10.10.8.2/24.
     - Guarda los cambios.

#### 2.4. **Configurar el Peer en pfSense:**

   - Ve a **VPN > WireGuard > Peers** y configura el peer para conectarte a MikroTik:
     - **Endpoint**: vpn.example.com.ar (el dominio o IP de tu MikroTik).
     - **Allowed IPs**: 10.10.8.1/32, 10.10.9.0/24 (la red de tu notebook).
     - **Keep Alive**: 25.

#### 2.5. **Agregar Rutas Estáticas en pfSense:**

   - Ve a **System > Routing > Static Routes** y agrega las siguientes rutas para asegurar que el tráfico hacia la red de tu notebook pase por el túnel:
     - **Network**: 10.10.9.0/24.
     - **Gateway**: WG_Gateway (10.10.8.1).
     - **Interface**: WG (tun_wg0).

---

### **Configurar Reglas de Firewall en MikroTik y pfSense**

#### **1. Reglas en MikroTik:**

Debemos permitir el tráfico tanto de salida desde **10.10.9.0/24** (tu notebook) hacia **192.168.0.0/24** (red del pfSense) como el tráfico de entrada desde la red **192.168.0.0/24** hacia **

10.10.9.0/24**.

##### **Permitir el tráfico desde la red 10.10.9.2 (notebook) a la red 192.168.0.0/24:**

Si quieres que los dispositivos de la red **10.10.9.0/24** (tu notebook) puedan acceder a la red **192.168.0.0/24** (detrás de pfSense), agrega la siguiente regla en el firewall de MikroTik:

```bash
/ip firewall filter add action=accept chain=forward src-address=10.10.9.0/24 dst-address=192.168.0.0/24 comment="Permitir tráfico de 10.10.9.0/24 hacia 192.168.0.0/24"
```

##### **Permitir el tráfico desde pfSense (192.168.0.0/24) hacia la red 10.10.9.0/24 (notebook):**

Si deseas permitir que los dispositivos en **pfSense** (red **192.168.0.0/24**) puedan acceder a dispositivos en la red de tu notebook **10.10.9.0/24**, agrega la siguiente regla:

```bash
/ip firewall filter add action=accept chain=forward src-address=192.168.0.0/24 dst-address=10.10.9.0/24 comment="Permitir tráfico de pfSense (192.168.0.0/24) hacia 10.10.9.0/24"
```

---

#### **2. Reglas en pfSense:**

De forma similar, debes configurar reglas en el firewall de **pfSense** para permitir el tráfico entre las redes.

##### **Permitir el tráfico desde la red 10.10.9.0/24 (notebook) hacia la red 192.168.0.0/24 (detrás de pfSense):**

- Ve a **Firewall > Rules** en pfSense y agrega una regla en la interfaz **WG** (tun_wg0) que permita el tráfico desde la red **10.10.9.0/24** hacia **192.168.0.0/24**:

1. **Interfaz**: WG (tun_wg0).
2. **Protocolo**: TCP/UDP.
3. **Source**: 10.10.9.0/24.
4. **Destination**: 192.168.0.0/24.

##### **Permitir el tráfico desde la red 192.168.0.136 (pfSense) hacia la red 10.10.9.0/24 (notebook):**

Si deseas permitir el acceso desde dispositivos en la red **192.168.0.0/24** (detrás de pfSense) hacia la red de tu notebook **10.10.9.0/24**, configura la siguiente regla en pfSense:

1. **Interfaz**: LAN (vmx1).
2. **Protocolo**: TCP/UDP.
3. **Source**: 192.168.0.136/32 (o 192.168.0.0/24 si quieres permitir toda la subred).
4. **Destination**: 10.10.9.0/24.

Estas reglas de firewall permitirán el tráfico bidireccional entre tu red **10.10.9.0/24** (notebook) y la red **192.168.0.0/24** (detrás de pfSense).
