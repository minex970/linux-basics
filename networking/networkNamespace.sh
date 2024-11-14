# 1. create two n/w namespace.
ip netns add web-ns
ip netns add db-ns
# check...
ip netns

# 2. create internal bridge switch on host.
ip link add vnet-0 type bridge
# check...
ip link

# 3. assign ip address to the internal bridge switch.
ip addr add 192.168.15.1/24 dev vnet-0
ip link set dev vnet-0 up
# check...
ip addr

# 4. create a pipe (cable) to connect with the namespace.
ip link add eth0-web type veth peer name veth-web-br
ip link add eth0-db type veth peer name veth-db-br

# 5. attach one end of interface to the namespace  and another to the bridge switch.
ip link set eth0-web netns web-ns
ip link set veth-web-br master vnet-0

ip link set eth0-db netns db-ns
ip link set veth-db-br master vnet-0

# 6. set the bridge ends of the veth pairs up
ip link set dev veth-web-br up
ip link set dev veth-db-br up

# 7. assign ip address to namespace's interface.
ip -n web-ns addr add 192.168.15.5/24 dev eth0-web
ip -n web-ns link set dev eth0-web up
# check...
ip -n web-ns addr
ip netns exec web-ns route

ip -n db-ns addr add 192.168.15.6/24 dev eth0-db
ip -n db-ns link set dev eth0-db up
# check...
ip -n db-ns addr
ip netns exec db-ns route

# 8. ping other interface within the namespace...
ip netns exec web-ns ping 192.168.15.6

ip netns exec db-ns ping 192.168.15.5

----
# 9. add route in the namaspaces to enable the reachability to outside...
ip netns exec web-ns ip route add 192.168.0.0/24 via 192.168.15.1
# check...
ip netns exec web-ns route

ip netns exec db-ns ip route add 192.168.0.0/24 via 192.168.15.1
# check...
ip netns exec db-ns route

# 10. add iptables rule to enable NAT, so that it will receive the ping's response...
iptables -t nat -A POSTROUTING -s 192.168.15.0/24 -j MASQUERADE
# check...
iptables -t nat -L -v

# 11. enable internet in the namespace's interface.
ip netns exec web-ns ip route add default via 192.168.15.1
# check...
ip netns exec web-ns ip route
ip netns exec db-ns ping 8.8.8.8

ip netns exec db-ns ip route add default via 192.168.15.1
# check...
ip netns exec db-ns ip route
ip netns exec db-ns ping 8.8.8.8
