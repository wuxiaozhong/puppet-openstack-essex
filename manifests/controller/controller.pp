node "NYSJHL100-136.opi.com" {
  # 初始化机器：
  class { 'openstack_init': }

  # 根据当前控制节点eth0网卡的IP地址作为其控制节点IP
  class { 'openstack::controller':
    # nic
    public_interface              => $public_interface,
    private_interface             => $private_interface,
    # ip
    public_address                => $ipaddress_eth0,
    internal_address              => $ipaddress_eth0,
    # db password
    #    mysql_root_password     => $mysql_root_password,
    keystone_db_password          => $keystone_db_password,
    glance_db_password            => $glance_db_password,
    nova_db_password              => $nova_db_password,
    # keystone config
    keystone_admin_token          => $keystone_admin_token,
    keystone_admin_email          => $keystone_admin_email,
    keystone_admin_password       => $keystone_admin_password,
    glance_keystone_user_password => $glance_keystone_user_password,
    nova_keystone_user_password   => $nova_keystone_user_password,
    # network
    network_manager               => 'nova.network.manager.FlatDHCPManager',
    floating_range                => $floating_network_range,
    fixed_range => $fixed_network_range,
    multi_host  => true,
    auto_assign_floating_ip       => $auto_assign_floating_ip,
    # volume
    volume_enabled                => true,
    secret_key  => $secret_key,
    verbose     => $verbose,
    #    rabbit_password         => $rabbit_password,
    #    rabbit_user             => $rabbit_user,
    #    export_resources        => false,
    require     => Class['openstack_init'],
  }

  class { 'openstack::component::auth_file':
    keystone_admin_password => $keystone_admin_password,
    keystone_admin_token    => $keystone_admin_token,
    controller_node         => $ipaddress_eth0,
    require                 => Class['openstack::controller'],
  }
}
