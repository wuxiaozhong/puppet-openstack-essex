# 多节点部署模式-安装计算节点
node computer {
  $controller_node_public = '10.8.18.136'
  $controller_node_internal = '10.8.18.136'
  $computer_public_address = $ipaddress_eth0
  $computer_internal_address = $ipaddress_eth0

  # 已安装控制节点
  if ($controller_node_public != undef) {
    # 初始化机器：
    class { 'openstack_init':
      ntp_servers => $controller_node_public
    }

    # 安装Openstack计算节点模块
    class { 'openstack::compute':
      public_interface            => $public_interface,
      private_interface           => $private_interface,
      internal_address            => $computer_internal_address,
      nova_db_host                => $controller_node_public,
      nova_db_password            => 'nova',
      nova_keystone_user_password => $nova_keystone_user_password,
      rabbit_host                 => $controller_node_internal,
      glance_api_servers          => "${controller_node_internal}:9292",
      vncproxy_host               => $controller_node_public,
      # network
      network_manager             => 'nova.network.manager.FlatDHCPManager',
      fixed_range                 => $fixed_network_range,
      libvirt_type                => 'kvm',
      # qemu,kvm
      multi_host                  => true,
      #    rabbit_password    => $rabbit_password,
      #    rabbit_user        => $rabbit_user,
      verbose                     => $verbose,
      require                     => Class['openstack_init'],
    }
  }
}