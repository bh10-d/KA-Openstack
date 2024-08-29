IP_VERSION=${IP_VERSION:-4}

DEMO_NET_CIDR=${DEMO_NET_CIDR:-'10.0.0.0/24'}
DEMO_NET_GATEWAY=${DEMO_NET_GATEWAY:-'10.0.0.1'}
DEMO_NET_DNS=${DEMO_NET_DNS:-'8.8.8.8'}

# This EXT_NET_CIDR is your public network,that you want to connect to the internet via.
ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
EXT_NET_CIDR=${EXT_NET_CIDR:-'10.0.2.0/24'}
EXT_NET_RANGE=${EXT_NET_RANGE:-'start=10.0.2.150,end=10.0.2.199'}
EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'10.0.2.1'}


echo Configuring neutron.

$KOLLA_OPENSTACK_COMMAND router create demo-router

SUBNET_CREATE_EXTRA=""

if [[ $IP_VERSION -eq 6 ]]; then
    # NOTE(yoctozepto): Neutron defaults to "unset" (external) addressing for IPv6.
    # The following is to use stateful DHCPv6 (RA for routing + DHCPv6 for addressing)
    # served by Neutron Router and DHCP services.
    # Setting this for IPv4 errors out instead of being ignored.
    SUBNET_CREATE_EXTRA="${SUBNET_CREATE_EXTRA} --ipv6-ra-mode dhcpv6-stateful"
    SUBNET_CREATE_EXTRA="${SUBNET_CREATE_EXTRA} --ipv6-address-mode dhcpv6-stateful"
fi

$KOLLA_OPENSTACK_COMMAND network create demo-net
$KOLLA_OPENSTACK_COMMAND subnet create --ip-version ${IP_VERSION} \
    --subnet-range ${DEMO_NET_CIDR} --network demo-net \
    --gateway ${DEMO_NET_GATEWAY} --dns-nameserver ${DEMO_NET_DNS} \
    ${SUBNET_CREATE_EXTRA} demo-subnet

$KOLLA_OPENSTACK_COMMAND router add subnet demo-router demo-subnet

if [[ $ENABLE_EXT_NET -eq 1 ]]; then
    $KOLLA_OPENSTACK_COMMAND network create --external --provider-physical-network physnet1 \
        --provider-network-type flat public1
    $KOLLA_OPENSTACK_COMMAND subnet create --no-dhcp --ip-version ${IP_VERSION} \
        --allocation-pool ${EXT_NET_RANGE} --network public1 \
        --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet

    if [[ $IP_VERSION -eq 4 ]]; then
        $KOLLA_OPENSTACK_COMMAND router set --external-gateway public1 demo-router
    else
        # NOTE(yoctozepto): In case of IPv6 there is no NAT support in Neutron,
        # so we have to set up native routing. Static routes are the simplest.
        # We need a static IP address for the router to demo.
        $KOLLA_OPENSTACK_COMMAND router set --external-gateway public1 \
            --fixed-ip subnet=public1-subnet,ip-address=${EXT_NET_DEMO_ROUTER_ADDR} \
            demo-router
    fi
fi