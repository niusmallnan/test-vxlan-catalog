version: '2'
services:
  vxlan:
    cap_add:
      - NET_ADMIN
    image: niusmallnan/vxlan:dev
    network_mode: host
    environment:
      RANCHER_DEBUG: '${RANCHER_DEBUG}'
      RANCHER_BRIDGE: '${RANCHER_BRIDGE}'
      RANCHER_VTEP_MTU: '${MTU}'
      RANCHER_VXLAN_VNI: '${RANCHER_VXLAN_VNI}'
      RANCHER_METADATA_ADDRESS: '${RANCHER_METADATA_ADDRESS}'
    command: rancher-vxlan
    labels:
      io.rancher.sidekicks: cni-driver
      io.rancher.scheduler.global: 'true'
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent_service.vxlan: 'true'
      io.rancher.cni.link_mtu_overhead: '0'
      io.rancher.internal.service.vxlan: 'true'
      io.rancher.service.selector.link: io.rancher.internal.service.vxlan=true
      io.rancher.network.macsync: 'false'
      io.rancher.network.arpsync: 'false'
      io.rancher.container.dns: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    network_driver:
      name: Rancher VXLAN
      default_network:
        name: vxlan
        host_ports: {{ .Values.HOST_PORTS }}
        subnets:
        - network_address: $SUBNET
        dns:
        - 169.254.169.250
        dns_search:
        - rancher.internal
      cni_config:
        '10-rancher-vxlan.conf':
          name: rancher-cni-network
          type: rancher-bridge
          bridge: $RANCHER_BRIDGE
          bridgeSubnet: $SUBNET
          logToFile: /var/log/rancher-cni.log
          isDebugLevel: ${RANCHER_DEBUG}
          isDefaultGateway: true
          hairpinMode: true
          hostNat: true
          hairpinMode: {{  .Values.RANCHER_HAIRPIN_MODE }}
          promiscMode: {{ .Values.RANCHER_PROMISCUOUS_MODE }}
          mtu: ${MTU}
          linkMTUOverhead: 50
          ipam:
            type: rancher-cni-ipam
            subnetPrefixSize: /{{ .Values.SUBNET_PREFIX }}
            logToFile: /var/log/rancher-cni.log
            isDebugLevel: ${RANCHER_DEBUG}
            routes:
              - dst: 169.254.169.250/32
  cni-driver:
    privileged: true
    image: niusmallnan/vxlan:dev
    command: sh -c "touch /var/log/rancher-cni.log && exec tail ---disable-inotify -F /var/log/rancher-cni.log"
    network_mode: host
    pid: host
    labels:
      io.rancher.scheduler.global: 'true'
      io.rancher.network.cni.binary: 'rancher-bridge'
      io.rancher.container.dns: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
