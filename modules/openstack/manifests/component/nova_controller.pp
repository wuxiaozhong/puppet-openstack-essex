#
# == Class: openstack::component::nova_controller
# 用于在控制节点安装和配置Nova组件，包含的组件有RabbitMQ、nova-common、nova-api、nova-newwork、nova-volume
# nova-scheduler、nova-objectstore、nova-cert，nova-consoleauth
# 功能描述：
#
#
# 参数：
#
# 示例：
#
# class { 'openstack::nova::controller':
#   public_address     => '192.168.1.1',
#   db_host            => '127.0.0.1',
#   rabbit_password    => 'changeme',
#   nova_user_password => 'changeme',
#   nova_db_password   => 'changeme',
# }
#

class openstack::component::nova_controller (
  # NIC网卡配置，默认使用一个网卡，只需要配置public_address
  $public_address,
  $admin_address             = undef,
  $internal_address          = undef,
  #DB
  $nova_db_host,
  $nova_db_type              = 'mysql',
  $nova_db_dbname            = 'nova',
  $nova_db_user              = 'nova',
  $nova_db_password,
  # RabbitMQ
  $rabbit_user               = 'guest',
  $rabbit_password           = 'guest',
  # nova keystone 
  $keystone_host             = '127.0.0.1',
  $nova_keystone_user_password,
  # Glance
  $glance_api_servers        = undef,
  # Network,默认有两网卡配置
  $public_interface          = 'eth0',
  $private_interface         = 'eth1',
  $network_manager           = 'nova.network.manager.FlatDHCPManager',
  $network_config            = {},
  $floating_range            = false,
  $fixed_range               = '10.0.0.0/24',
  $auto_assign_floating_ip   = false,
  $create_networks           = true,
  $num_networks              = 1,
  $multi_host                = false,
  # VNC
  $vnc_enabled               = true,
  # General
  #AMQP协议的实现方式：默认为RabbitMQ，可选其还有：qpid
  $rpc_type                  = 'rabbitmq',
  $verbose                   = 'False',
  $enabled                   = true
) {

  # Configure the db string
  case $nova_db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${nova_db_host}/${nova_db_dbname}"
    }
  }

  if($admin_address == undef){
    $admin_address = $public_address
  }
  
  if($internal_address == undef){
    $internal_address = $public_address
  }
  
  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }

  $sql_connection    = $nova_db
  $glance_connection = $real_glance_api_servers
  $rabbit_connection = $internal_address

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
    enabled  => $enabled,
  }

  # Configure Nova
  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_connection,
    verbose            => $verbose,
    rabbit_host        => $rabbit_connection,
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
  # Configure nova-api
  class { 'nova::api':
    enabled           => $enabled,
    admin_password    => $nova_keystone_user_password,
    auth_host         => $keystone_host,
  }


  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }
	# Configure nova-network
	if $multi_host {#当前启用多网络服务主机时，控制点不启用网络服务，而各计算节点启动网络服务
	  nova_config { 'multi_host': value => 'True' }
	  $enable_network_service = false
	} else {
	  if $enabled {
	    $enable_network_service = true
	  } else {
	    $enable_network_service = false
	  }
	}
	
	class { 'nova::network':
	  private_interface => $private_interface,
	  public_interface  => $public_interface,
	  fixed_range       => $fixed_range,
	  floating_range    => $floating_range,
	  network_manager   => $network_manager,
	  config_overrides  => $network_config,
	  create_networks   => $really_create_networks,
	  num_networks      => $num_networks,
	  enabled           => $enable_network_service,
	  install_service   => $enable_network_service,
	}

  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip': value => 'True' }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host    => $public_address,
      enabled => $enabled,
    }
  }

}
