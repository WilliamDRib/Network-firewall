#!/bin/bash
ip route del default
ip route add default via 192.168.2.2
ip route add 192.168.1.0/24 via eth0

echo 1 > /proc/sys/net/ipv4/ip_forward

#eth0 - DMZ
#eth1 - Int

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

# Políticas padrão 
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT DROP

# Permitir conexões de saída da rede interna para a Internet/DMZ
iptables -A FORWARD -i eth1 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 443 -j ACCEPT

# Permitir conexões de saída da rede interna para a Internet nas portas de e-mail
iptables -A FORWARD -i eth1 -p tcp --dport 465 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 995 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 143 -j ACCEPT
iptables -A FORWARD -i eth1 -p tcp --dport 993 -j ACCEPT

# Permitir acesso da rede interna ao servidor de aplicações
iptables -A FORWARD -i eth1 -d 192.168.2.8 -p tcp -j ACCEPT

# Bloquear acesso da rede interna
iptables -A FORWARD -i eth0 -p tcp --dport 80 -j LOG --log-prefix "Reject-HTTP: " --log-level 4
iptables -A FORWARD -i eth0 -p tcp --dport 80 -j REJECT

iptables -A FORWARD -i eth0 -p tcp --dport 443 -j LOG --log-prefix "Reject-HTTPS: " --log-level 4
iptables -A FORWARD -i eth0 -p tcp --dport 443 -j REJECT

# Bloquear todo o outro acesso à porta 5432 no servidor de banco de dados
iptables -A FORWARD -i eth1 -d 192.168.2.7 -p tcp --dport 5432 -j LOG --log-prefix "Dropped-DB: " --log-level 4
iptables -A FORWARD -i eth1 -d 192.168.2.7 -p tcp --dport 5432 -j DROP

iptables -A FORWARD -i eth1 -d 192.168.2.7 -p udp --dport 5432 -j LOG --log-prefix "Dropped-DB: " --log-level 4
iptables -A FORWARD -i eth1 -d 192.168.2.7 -p udp --dport 5432 -j DROP

#Bloquear acesso direto da Internet para a estação de trabalho e permitir respostas.
iptables -A FORWARD -s 192.168.1.0/24 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A FORWARD -s 192.168.1.0/24 -j LOG --log-prefix "Dropped-DirectAccessFromInternet: " --log-level 4
iptables -A FORWARD -s 192.168.1.0/24 -j DROP

# Impedir que a rede interna acesse portas aleatórias da internet
iptables -A FORWARD -d 192.168.1.0/24 -j LOG --log-prefix "Dropped-TryToAccessDeniedPortsOfInternet: " --log-level 4
iptables -A FORWARD -d 192.168.1.0/24 -j DROP

# Permitir todo o tráfego entre a rede interna e DMZ
# A rede interna pode requisitar os servidores da DMZ, mas os servidores podem apenas responder
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT 
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT 