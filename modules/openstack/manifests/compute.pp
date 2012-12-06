#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::nova::compute':
#   internal_address   => '192.168.2.2',
#   nova_keystone_user_password => 'nova',
#   nova_db_host => '192.168.1.1',
#   nova_db_password => 'nova',
#   fixed_range => '10.0.0.0/24',
#   rabbit_host => '192.168.1.1',
#   glance_api_servers => '192.168.1.1',
#   vncproxy_host      => '192.168.1.1',
# }

class openstack::compute (
  #NIC网卡
  $public_interface              = 'eth0',
  $private_interface             = 'eth1',
  # Required Network
  $internal_address,
  # Required Nova
  $nova_keystone_user_password,
  # Database
  $nova_db_host,
  $nova_db_type              = 'mysql',
  $nova_db_dbname            = 'nova',
  $nova_db_user              = 'nova',
  $nova_db_password,
  # Network
  $fixed_range,
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  # Nova
  $purge_nova_config             = true,
  # Rabbit
  $rabbit_host,
  $rabbit_user                   = 'guest',
  $rabbit_password               = 'guest',
  # Glance
  $glance_api_servers,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = false,
  # volume
  $volume_enabled                = true,
  $volume_group                  = 'nova-volumes',
  # General
  #AMQP协议的实现方式：默认为RabbitMQ，可选其还有：qpid
  $rpc_type                      = 'rabbitmq',
  $migration_support             = false,
  $verbose                       = 'False',
  $enabled                       = true
) {
  # Configure the db string
  case $nova_db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${nova_db_host}/${nova_db_dbname}"
    }
  }
  
  if $vncserver_listen {
    $vncserver_listen_real = $vncserver_listen
  } else {
    $vncserver_listen_real = $internal_address
  }


  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ! defined( Resources[nova_config] ) {
    if ($purge_nova_config) {
      resources { 'nova_config':
        purge => true,
      }
    }
  }

  class { 'nova':
    sql_connection     => $nova_db,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    verbose            => $verbose,
    rabbit_host        => $rabbit_host,
  }
  # 配置使用的AMQP协议实现种类：
  if (!$rpc_type){ #默认使用RabbitMQ
    $rpc_backend = 'nova.rpc.impl_kombu'
  }
  if ($rpc_type =='rabbitmq'){
     $rpc_backend = 'nova.rpc.impl_kombu'
  }
  if($rpc_type =='qpid'){
     $rpc_backend = 'nova.rpc.impl_qpid'
  }
  nova_config { 'rpc_backend': value => $rpc_backend }
  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type      => $libvirt_type,
    vncserver_listen  => $vncserver_listen_real,
    migration_support => $migration_support,
  }

  ######## Nova-Network ########
  if ! $fixed_range {
    fail("Must specify the fixed range when using nova-networks")
  }
  if $multi_host {
    include keystone::python
    nova_config {
      'multi_host':      value => 'True';
      'send_arp_for_ha': value => 'True';
    }
    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }
    $enable_network_service = true
    class { 'nova::api':
      enabled           => true,
      admin_tenant_name => 'services',
      admin_user        => 'nova',
      admin_password    => $nova_keystone_user_password,
      # TODO override enabled_apis
    }
  } else {
    $enable_network_service = false
    nova_config {
      'multi_host':      value => 'False';
      'send_arp_for_ha': value => 'False';
    }
  }

  class { 'nova::network':
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => false,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => false,
    enabled           => $enable_network_service,
    install_service   => $enable_network_service,
  }
  ######## Nova-Volume ########
  if($volume_enabled){
    class { 'nova::volume': 
      enabled => true,
    }
    
    class { 'nova::volume::iscsi': 
      volume_group     => $volume_group
    }
  }

}
