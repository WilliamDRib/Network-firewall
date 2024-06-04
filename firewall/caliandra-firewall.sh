#!/bin/bash
ip route del default
ip route add default via 192.168.2.2
ip route add 192.168.3.0/24 via eth0

echo 1 > /proc/sys/net/ipv4/ip_forward

#eth0 - DMZ
#eth1 - Ext

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\

# Políticas padrão 
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Permitir conexões HTTP e HTTPS de entrada na DMZ vindas da rede externa
iptables -A FORWARD -i eth1 -o eth0 -d 192.168.2.6 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -d 192.168.2.6 -p tcp --dport 443 -j ACCEPT

# Permitir conexões HTTP e HTTPS da DMZ para a rede externa 
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 443 -j ACCEPT

# Permitir conexão estabelecida em http e https vinda da rede externa para a DMZ
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 80 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 443 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Permitir conexões DNS de entrada e saída através das interfaces específicas
iptables -A FORWARD -i eth1 -o eth0 -d 192.168.2.4 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p udp --dport 53 -j ACCEPT 

iptables -A FORWARD -i eth1 -o eth0 -d 192.168.2.4 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 53 -j ACCEPT 

# Permitir tráfego SMTP e IMAP de entrada para e-mail através das interfaces específicas
iptables -A FORWARD -i eth1 -p tcp --dport 465 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 995 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 143 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 993 -j ACCEPT

# Bloquear todo o outro acesso à porta 5432 no servidor de banco de dados
iptables -A FORWARD -i eth1 -d 192.168.2.7 -p tcp --dport 5432 -j LOG --log-prefix "Dropped-DBAcess: " --log-level 4
iptables -A FORWARD -i eth1 -d 192.168.2.7 -p tcp --dport 5432 -j DROP

# Bloquear o acesso ao servidor de aplicações (permitir no outro firewall)
iptables -A FORWARD -i eth1 -d 192.168.2.8 -p tcp -j LOG --log-prefix "Dropped-AppServerExternalConnection: " --log-level 4
iptables -A FORWARD -i eth1 -d 192.168.2.8 -p tcp -j DROP

# A rede externa podem requisitar os servidores da DMZ, mas os servidores podem apenas responder, não requisitar
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Permitir respostas da rede externa e bloquear acesso direto da internet
iptables -A FORWARD -i eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A FORWARD -i eth1 -j LOG --log-prefix "Dropped-DirectAccessFromInternet: " --log-level 4
iptables -A FORWARD -i eth1 -j DROP