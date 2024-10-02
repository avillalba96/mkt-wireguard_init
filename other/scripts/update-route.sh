#!/bin/bash

# Función para verificar si un comando está disponible
check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        logger -t update-route "Error: El comando '$1' no está instalado."
        exit 1
    }
}

# Verificar si dig e ip están instalados
check_command "dig"
check_command "ip"

# Nombre del host que queremos resolver
ENDPOINT="vpn.example.com.ar"
INTERFACE="ens160"

# Resolver la IP actual del endpoint
CURRENT_IP=$(dig +short $ENDPOINT)

# Verificar si la resolución DNS fue exitosa
if [ -z "$CURRENT_IP" ]; then
    logger -t update-route "Error: No se pudo resolver la IP de $ENDPOINT"
    exit 1
fi

# Eliminar cualquier ruta anterior que apunte al endpoint
OLD_ROUTE=$(ip route | grep "$INTERFACE" | grep "$ENDPOINT" | awk '{print $1}')
if [ -n "$OLD_ROUTE" ]; then
    logger -t update-route "Eliminando la ruta anterior hacia $OLD_ROUTE en $INTERFACE"
    sudo ip route del $OLD_ROUTE
fi

# Verificar si la nueva ruta ya está agregada
ROUTE_EXISTS=$(ip route | grep "$CURRENT_IP" | grep "$INTERFACE")

# Si no existe la nueva ruta, agregarla
if [ -z "$ROUTE_EXISTS" ]; then
    logger -t update-route "Agregando nueva ruta a $CURRENT_IP por $INTERFACE"
    sudo ip route add $CURRENT_IP dev $INTERFACE
fi
