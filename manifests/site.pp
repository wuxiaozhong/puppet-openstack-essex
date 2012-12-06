$public_interface                = 'eth0'
$private_interface               = 'eth0'
#db
$mysql_root_password             = 'root'
$keystone_db_password            = 'keystone'
$nova_db_password                = 'nova'
$glance_db_password              = 'glance'
# keystone
$keystone_admin_token            = 'admin_token'

$keystone_admin_email             = 'root@localhost'
$keystone_admin_password         = 'admin'

$nova_keystone_user_password     = 'nova'
$glance_keystone_user_password   = 'glance'
#$rabbit_password                 = 'openstack_rabbit_password'
#$rabbit_user                     = 'openstack_rabbit_user'
$fixed_network_range             = '10.0.0.0/24'
$floating_network_range          = '192.168.222.200/27'

$secret_key              = 'secret'
$verbose                 = true
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = false
#单节点部署模式
node /allinone.*/ {

  class { 'openstack::all':
    public_address          => $ipaddress_eth0,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
#    mysql_root_password     => $mysql_root_password,
    keystone_db_password    => $keystone_db_password,
    nova_db_password        => $nova_db_password,
    glance_db_password      => $glance_db_password,
    
    keystone_admin_token    => $keystone_admin_token,
    keystone_admin_email    => $keystone_admin_email,
    keystone_admin_password => $keystone_admin_password,
   
    nova_keystone_user_password      => $nova_user_password,
    glance_keystone_user_password    => $glance_user_password,
#    rabbit_password         => $rabbit_password,
#    rabbit_user             => $rabbit_user,
    libvirt_type            => 'qemu',#kvm,qemu
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    secret_key              => $secret_key,
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
  }

  class { 'openstack::component::auth_file':
    keystone_admin_password       => $keystone_admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

}
#多节点部署模式
#示例值
node /controller.*/ {
  #根据当前控制节点eth0网卡的IP地址作为其控制节点IP
  class { 'openstack::controller':
    #nic
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    #ip
    public_address          => $ipaddress_eth0,
    internal_address        => $ipaddress_eth0,
    #db password
#    mysql_root_password     => $mysql_root_password,
    keystone_db_password    => $keystone_db_password,
    glance_db_password      => $glance_db_password,
    nova_db_password        => $nova_db_password,
    #keystone config
    keystone_admin_token    => $keystone_admin_token,
    keystone_admin_email    => $keystone_admin_email,
    keystone_admin_password => $keystone_admin_password,
    glance_keystone_user_password    => $glance_keystone_user_password,
    nova_keystone_user_password      => $nova_keystone_user_password,
    #network
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    multi_host              => true,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    #volume
    volume_enabled          => true,
    secret_key              =>$secret_key,
    verbose                 => $verbose,
#    rabbit_password         => $rabbit_password,
#    rabbit_user             => $rabbit_user,
#    export_resources        => false,
  }

  class { 'openstack::component::auth_file':
    keystone_admin_password       => $keystone_admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $ipaddress_eth0,
  }


}

node /computer\d+.*/ {
  $controller_node_public   = '192.168.222.135'
  $controller_node_internal = '192.168.222.135'
  if($controller_node_public != undef){#已安装控制节点
    $computer_public_address = $ipaddress_eth0
    $computer_internal_address = $ipaddress_eth0
    class { 'openstack::compute':
      public_interface   => $public_interface,
      private_interface  => $private_interface,
      internal_address   => $computer_internal_address,
      nova_db_host       => $controller_node_public,
      nova_db_password   => 'nova',
      nova_keystone_user_password => $nova_keystone_user_password,
      rabbit_host        => $controller_node_internal,
      glance_api_servers => "${controller_node_internal}:9292",
      vncproxy_host      => $controller_node_public,
      #network
      network_manager    => 'nova.network.manager.FlatDHCPManager',
      fixed_range        => $fixed_network_range,
      libvirt_type       => 'qemu',#qemu,kvm
      multi_host         => true,
      
  #    rabbit_password    => $rabbit_password,
  #    rabbit_user        => $rabbit_user,
      verbose            => $verbose,
    }
  }
}