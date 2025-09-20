#!/bin/bash

######################### VARIABLES POR DEFECTO #########################
DEFAULT_CLIENT_SERVER_IF="wg0"
DEFAULT_CLIENT_SERVER_NAME="CLIENTE-${DEFAULT_CLIENT_SERVER_IF}"
DEFAULT_CLIENT_PRIVATE_KEY="DEFAULT_CLIENT_PRIVATE_KEY_example" # Dato por defecto, reemplazar si se tiene uno propio
DEFAULT_CLIENT_PUBLIC_KEY="DEFAULT_CLIENT_PUBLIC_KEY_example"   # Dato por defecto, reemplazar si se tiene uno propio
DEFAULT_CLIENT_ADDRESS="10.10.9.50"
DEFAULT_CLIENT_NETMASK="24"
DEFAULT_SERVER_PUBLIC_KEY="DEFAULT_SERVER_PUBLIC_KEY_example" # Reemplazar si se tiene uno propio
DEFAULT_SERVER_ENDPOINT="vpn.example.com.ar:13232"
DEFAULT_ALLOWED_IPS="10.10.9.2/32"
DEFAULT_KEEPALIVE=25
DEFAULT_DNS_SERVER="1.1.1.1"
DEFAULT_HOSTNAME=$(hostname -f)
###########################################################################

######################### FUNCIONES ######################################

# Colores para mayor legibilidad
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para instalar WireGuard
install_wireguard() {
    echo -e "${BLUE}Actualizando los repositorios...${NC}"
    apt-get update
    echo -e "${BLUE}Instalando WireGuard...${NC}"
    apt-get install -y wireguard

    if command -v wg &>/dev/null; then
        echo -e "${GREEN}WireGuard se instaló correctamente.${NC}"
    else
        echo -e "${RED}Hubo un error en la instalación de WireGuard.${NC}"
        exit 1
    fi
}

# Función para desinstalar WireGuard
uninstall_wireguard() {
    echo -e "${BLUE}Desinstalando WireGuard...${NC}"
    apt-get remove --purge -y wireguard
    apt-get autoremove wireguard -y
    rm -r /etc/wireguard

    if ! command -v wg &>/dev/null; then
        echo -e "${GREEN}WireGuard se desinstaló correctamente.${NC}"
    else
        echo -e "${RED}Hubo un error al desinstalar WireGuard.${NC}"
        exit 1
    fi
}

# Función para solicitar valores al usuario (o utilizar los valores por defecto)
solicitar_valores_cliente() {
    echo -e "${YELLOW}Solicitando valores para configurar WireGuard...${NC}"

    read -p "Ingrese el nombre del cliente (por defecto: ${DEFAULT_CLIENT_SERVER_NAME}): " CLIENT_SERVER_NAME
    CLIENT_SERVER_NAME=${CLIENT_SERVER_NAME:-$DEFAULT_CLIENT_SERVER_NAME}

    read -p "¿Desea generar una nueva clave privada para el cliente? (s/n, por defecto: ${DEFAULT_CLIENT_PRIVATE_KEY}): " GENERAR_CLAVE
    if [[ "$GENERAR_CLAVE" == "s" || "$GENERAR_CLAVE" == "S" ]]; then
        CLIENT_PRIVATE_KEY=$(wg genkey)
        CLIENT_PUBLIC_KEY=$(echo "${CLIENT_PRIVATE_KEY}" | wg pubkey)
        echo -e "${GREEN}Clave publica generada: ${CLIENT_PUBLIC_KEY}${NC}"
        echo -e "${GREEN}Clave privada generada: ${CLIENT_PRIVATE_KEY}${NC}"
    else
        CLIENT_PRIVATE_KEY=${DEFAULT_CLIENT_PRIVATE_KEY}
        CLIENT_PUBLIC_KEY=${DEFAULT_CLIENT_PUBLIC_KEY}
    fi

    read -p "Ingrese la dirección IP del cliente (por defecto: ${DEFAULT_CLIENT_ADDRESS}): " CLIENT_ADDRESS
    CLIENT_ADDRESS=${CLIENT_ADDRESS:-$DEFAULT_CLIENT_ADDRESS}

    read -p "Ingrese la máscara de red para el cliente (por defecto: ${DEFAULT_CLIENT_NETMASK}): " CLIENT_NETMASK
    CLIENT_NETMASK=${CLIENT_NETMASK:-$DEFAULT_CLIENT_NETMASK}

    read -p "Ingrese la clave pública del servidor (por defecto: ${DEFAULT_SERVER_PUBLIC_KEY}): " SERVER_PUBLIC_KEY
    SERVER_PUBLIC_KEY=${SERVER_PUBLIC_KEY:-$DEFAULT_SERVER_PUBLIC_KEY}

    read -p "Ingrese el endpoint del servidor (IP o dominio:puerto, por defecto: ${DEFAULT_SERVER_ENDPOINT}): " SERVER_ENDPOINT
    SERVER_ENDPOINT=${SERVER_ENDPOINT:-$DEFAULT_SERVER_ENDPOINT}

    if ! [[ "$SERVER_ENDPOINT" =~ ^([a-zA-Z0-9.-]+|\[[a-fA-F0-9:]+\]):[0-9]+$ ]]; then
        echo -e "${RED}Error: El endpoint debe tener el formato 'IP_o_dominio:puerto'.${NC}"
        exit 1
    fi

    read -p "Ingrese las AllowedIPs para el cliente (por defecto: ${DEFAULT_ALLOWED_IPS}): " ALLOWED_IPS
    ALLOWED_IPS=${ALLOWED_IPS:-$DEFAULT_ALLOWED_IPS}

    read -p "Ingrese el valor de PersistentKeepalive (por defecto: ${DEFAULT_KEEPALIVE}): " KEEPALIVE
    KEEPALIVE=${KEEPALIVE:-$DEFAULT_KEEPALIVE}

    read -p "Ingrese el servidor DNS (por defecto: ${DEFAULT_DNS_SERVER}): " DNS_SERVER
    DNS_SERVER=${DNS_SERVER:-$DEFAULT_DNS_SERVER}
}

# Función para generar el archivo de configuración de WireGuard
generar_configuracion_cliente() {
    # Crear el directorio /etc/wireguard si no existe
    if [ ! -d "/etc/wireguard" ]; then
        echo -e "${BLUE}Creando el directorio /etc/wireguard...${NC}"
        mkdir -p /etc/wireguard
    fi

    # Generar el archivo de configuración del cliente con el formato CLIENT_SERVER_NAME-INTERFACE.conf
    echo -e "${BLUE}Generando archivo de configuración en /etc/wireguard/${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}.conf${NC}"
    cat <<EOL >/etc/wireguard/${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}.conf
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_ADDRESS}/${CLIENT_NETMASK}
#PostUp = iptables -A FORWARD -i ${CLIENT_SERVER_NAME} -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#PostDown = iptables -D FORWARD -i ${CLIENT_SERVER_NAME} -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
#DNS = ${DNS_SERVER}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_ENDPOINT}
AllowedIPs = ${ALLOWED_IPS}
PersistentKeepalive = ${KEEPALIVE}
EOL

    chmod 600 /etc/wireguard/${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}.conf
    echo -e "${GREEN}Archivo de configuración generado correctamente.${NC}"
}

# Función para habilitar e iniciar WireGuard en el cliente, con confirmación
habilitar_wireguard_cliente() {
    # Preguntar al usuario si desea habilitar el servicio
    echo -e "${YELLOW}¿Desea habilitar e iniciar el servicio WireGuard ahora? (s/n)${NC}"
    read -p "Respuesta (por defecto: s): " habilitar_servicio
    habilitar_servicio=${habilitar_servicio:-s}

    # Si la respuesta es 's' o 'S', habilitar e iniciar el servicio
    if [[ "$habilitar_servicio" == "s" || "$habilitar_servicio" == "S" ]]; then
        if systemctl enable wg-quick@${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}; then
            echo -e "${GREEN}Servicio wg-quick@${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF} habilitado correctamente.${NC}"
        else
            echo -e "${RED}Error al habilitar el servicio wg-quick@${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}.${NC}" >&2
            exit 1
        fi

        if systemctl start wg-quick@${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}; then
            echo -e "${GREEN}Servicio wg-quick@${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF} iniciado correctamente.${NC}"
        else
            echo -e "${RED}Error al iniciar el servicio wg-quick@${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}.${NC}" >&2
            exit 1
        fi

        wg show ${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}
        echo -e "${GREEN}WireGuard configurado e iniciado correctamente para ${CLIENT_SERVER_NAME}-${DEFAULT_CLIENT_SERVER_IF}.${NC}"
    else
        echo -e "${YELLOW}Servicio no habilitado ni iniciado.${NC}"
    fi
}

# Función para mostrar el comando necesario en MikroTik para configurar el peer
mostrar_comando_mikrotik() {
    echo -e "${BLUE}Ejecutar el siguiente comando en su MikroTik:${NC}"
    echo -e "${YELLOW}/interface wireguard peers add interface=$DEFAULT_CLIENT_SERVER_IF name=$DEFAULT_HOSTNAME public-key=\"$CLIENT_PUBLIC_KEY\" allowed-address=$CLIENT_ADDRESS/32 ${NC}"
#    echo -e "${YELLOW}/interface wireguard peers add interface=$DEFAULT_CLIENT_SERVER_IF name=$DEFAULT_HOSTNAME public-key=\"$CLIENT_PUBLIC_KEY\" allowed-address=$CLIENT_ADDRESS/32 persistent-keepalive=$DEFAULT_KEEPALIVE${NC}"
}

###########################################################################

# Función del menú principal
menu_principal() {
    echo -e "${BLUE}Seleccione una opción:${NC}"
    echo "1) Instalar WireGuard"
    echo "2) Desinstalar WireGuard"
    read -p "Ingrese su elección (1 o 2): " user_choice

    case $user_choice in
    1)
        install_wireguard
        solicitar_valores_cliente
        generar_configuracion_cliente
        habilitar_wireguard_cliente
        mostrar_comando_mikrotik
        ;;
    2)
        uninstall_wireguard
        ;;
    *)
        echo -e "${RED}Opción no válida. Saliendo.${NC}"
        exit 1
        ;;
    esac
}

###########################################################################
# Ejecutar el menú principal
menu_principal

# Autoeliminar el script después de la ejecución
rm -- "$0"
