######################### EDITAR A PARTIR DE AQUÍ #########################
# Variables
:local WGINTERFACENAME wg0
:local WGLISTENPORT 13232
:local WGMTU 1420
:local WGADDRESS "10.10.9.1/24"
:local WGNETWORK "10.10.9.0"
###########################################################################

######################### NO TOCAR A PARTIR DE AQUÍ #########################
# Crear la interfaz de WireGuard
/interface wireguard add name=$WGINTERFACENAME listen-port=$WGLISTENPORT mtu=$WGMTU

# Asignar una dirección IP a la interfaz de WireGuard
/ip address add address=$WGADDRESS interface=$WGINTERFACENAME network=$WGNETWORK

# Configurar reglas de firewall (opcional, ajusta según tu entorno)
/ip firewall filter add action=jump chain=input comment="#### WAN: Reglas ####" disabled=yes jump-target=""
/ip firewall filter add action=accept chain=input comment="Permitir WireGuard" dst-port=$WGLISTENPORT limit=10,20:packet protocol=udp
/ip firewall filter add action=jump chain=input comment="#### WIREGUARD ####" disabled=yes jump-target=""
/ip firewall filter add action=accept chain=forward comment="Permitir ping entre peers" dst-address=$WGNETWORK/24 src-address=$WGNETWORK/24 protocol=icmp
###########################################################################

######################### IMPRIMIR PRIVATE-KEY DEL INTERFACE WG0 #########################
# Imprimir solo la private-key del wg0
:local wgPrivateKey [/interface wireguard get [find where name=$WGINTERFACENAME] private-key]
:put ("La clave privada de " . $WGINTERFACENAME . " es: " . $wgPrivateKey)
###########################################################################

/file remove mkt_install-server.rsc
