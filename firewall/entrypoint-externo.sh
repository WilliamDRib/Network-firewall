#!/bin/sh
ip route del default 
ip route add default via 192.168.1.2

# Manter o container em execução
tail -f /dev/null
