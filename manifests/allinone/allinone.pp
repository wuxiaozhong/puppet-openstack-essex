# 单节点部署模式-完全安装Openstack
node allinone {
  # 初始化机器：
  class { 'openstack_init': }

  # 安装Openstack
  class { 'openstack::all':
    public_address => $ipaddress_eth0,
    public_interface              => $public_interface,
    private_interface             => $private_interface,
    #    mysql_root_password     => $mysql_root_password,
    keystone_db_password          => $keystone_db_password,
    nova_db_password              => $nova_db_password,
    glance_db_password            => $glance_db_password,
    keystone_admin_token          => $keystone_admin_token,
    keystone_admin_email          => $keystone_admin_email,
    keystone_admin_password       => $keystone_admin_password,
    nova_keystone_user_password   => $nova_user_password,
    glance_keystone_user_password => $glance_user_password,
    #    rabbit_password         => $rabbit_password,
    #    rabbit_user             => $rabbit_user,
    libvirt_type   => 'kvm',
    # kvm,qemu
    floating_range => $floating_network_range,
    fixed_range    => $fixed_network_range,
    secret_key     => $secret_key,
    verbose        => $verbose,
    auto_assign_floating_ip       => $auto_assign_floating_ip,
    require        => Class['openstack_init'],
  }

  # 生成环境变量文件
  class { 'openstack::component::auth_file':
    keystone_admin_password => $keystone_admin_password,
    keystone_admin_token    => $keystone_admin_token,
    controller_node         => '127.0.0.1',
    require                 => Class['openstack::all'],
  }

}