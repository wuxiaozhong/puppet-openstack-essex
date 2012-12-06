#
# == Class: openstack::component::horizon
#
# 用于安装并配置horizon.
#
# 功能描述：
# 1.会自动安装Apache
# 2.默认使用memcache作为缓存服务器
#
# 参数：
# secret_key 
# cache_server_ip 
# cache_server_port
#
# === Examples
#
# class { 'openstack::horizon':
#   secret_key => 'dummy_secret_key',
# }
#

class openstack::component::horizon (
  $secret_key,
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $swift                 = false,
  $quantum               = false,
  $horizon_app_links     = undef,
  $keystone_host         = '127.0.0.1',
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $django_debug          = 'False',
  $api_result_limit      = 1000
) {
  include 'apache'
  
  class { 'memcached':
    listen_ip => $cache_server_ip,
    tcp_port  => $cache_server_port,
    udp_port  => $cache_server_port,
  }

  class { '::horizon':
    cache_server_ip       => $cache_server_ip,
    cache_server_port     => $cache_server_port,
    secret_key            => $secret_key,
    swift                 => $swift,
    quantum               => $quantum,
    horizon_app_links     => $horizon_app_links,
    keystone_host         => $keystone_host,
    keystone_scheme       => $keystone_scheme,
    keystone_default_role => $keystone_default_role,
    django_debug          => $django_debug,
    api_result_limit      => $api_result_limit,
  }
}
