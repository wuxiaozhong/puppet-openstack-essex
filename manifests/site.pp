#yum
$openstack_yum_host='10.8.18.217'
#network interface
$public_interface = 'eth0'
$private_interface = 'eth0'
# db
$mysql_root_password = 'root'
$keystone_db_password = 'keystone'
$nova_db_password = 'nova'
$glance_db_password = 'glance'
# keystone
$keystone_admin_token = 'admin_token'

$keystone_admin_email = 'root@localhost'
$keystone_admin_password = 'admin'

$nova_keystone_user_password = 'nova'
$glance_keystone_user_password = 'glance'
# $rabbit_password                 = 'openstack_rabbit_password'
# $rabbit_user                     = 'openstack_rabbit_user'
$fixed_network_range = '10.0.0.0/24'
$floating_network_range = false

$secret_key = 'secret'
$verbose = true
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = false

# 机器初始化
# ntp_servers 已知NTP服务器列表，默认为CentOS NTP服务器
# volume_group 卷组名， 默认为nova-volumes
# volume_image 卷文件路径，默认为/data/nova-volumes.img
# volume_size 卷大小，默认为100G
class openstack_init ($ntp_servers = 'UNSET', $volume_group = 'nova-volumes', $volume_image = '/data/nova-volumes.img', $volume_size = '100') 
{
  # 配置主NTP服务器
  class { 'ntp': servers => $ntp_servers }

  # 创建nova-volume
  file { '/root/nova-volume-setup.sh':
    ensure  => present,
    content => template('nova-volume-setup.sh.erb'),
    group   => root,
    owner   => root,
    mode    => 755
  }

  exec { 'nova-volume-setup':
    command => '/root/nova-volume-setup.sh',
    require => File['/root/nova-volume-setup.sh'],
  }

  # 启动挂载nova-volumes
  file { '/etc/rc.d/init.d/nova-volume-mount':
    ensure  => present,
    content => template('nova-volume-mount.erb'),
    group   => root,
    owner   => root,
    mode    => 755
  }

  file { ['/etc/rc.d/rc5.d/S96nova-volume-mount', '/etc/rc.d/rc3.d/S96nova-volume-mount']:
    ensure  => link,
    target  => '/etc/rc.d/init.d/nova-volume-mount',
    require => File['/etc/rc.d/init.d/nova-volume-mount'],
  }

  # 配置Iptables
  service { 'iptables':
    ensure => 'stopped',
    enable => false,
  }

  # 配置Openstack YUM源
  file { '/etc/yum.repos.d':
    ensure  => directory,
    path    => '/etc/yum.repos.d',
    recurse => true,
    purge   => true,
  }

  file { "/etc/yum.repos.d/openstack-essex.repo":
    ensure  => present,
    content => template("openstack-essex.repo.erb"),
    require => File['/etc/yum.repos.d'],
  }
}
####  import hosts  ####
import "allinone/*.pp"
import "controller/*.pp"
import "computer/*.pp"