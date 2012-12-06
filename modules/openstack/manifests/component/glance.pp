#
# == Class: openstack::glance
# glance安装与配置
#
# 功能描述：
#  1.安装glance软件包
#  2.配置glance-api和glance-registry
#
# 使用条件:
#  1.完成Glance的keystone配置
#  2.其keystone租间必须是services
#  3.其keystone租户名必须是glance
# === Parameters
#
# [glance_db_host] Glance数据库IP地址
# [glance_db_type] Glance数据库类型，默认为'mysql'
# [glance_db_dbname] Glance数据库名，默认为'glance'
# [glance_db_user]  Glance数据库用户名，默认为：glance
# [glance_db_password] Glance数据库密码

# [keystone_host] Keystone服务器IP地址，默认为'127.0.0.1'
# [glance_keystone_user_password] Glance的keystone用户密码
#
# [verbose] Log verbosely. Optional. Defaults to 'False'
# [enabled] Used to indicate if the service should be active (true) or passive (false).
#   Optional. Defaults to true
#
# === Example
#
# class { 'openstack::glance':
#   glance_user_password => 'changeme',
#   db_password          => 'changeme',
#   db_host              => '127.0.0.1',
# }

class openstack::component::glance (
  $glance_db_host,
  $glance_keystone_user_password,
  $glance_db_password,
  $keystone_host        = '127.0.0.1',
  $glance_db_type       = 'mysql',
  $glance_db_user       = 'glance',
  $glance_db_dbname     = 'glance',
  $verbose              = 'False',
  $enabled              = true
) {

  # Configure the db string
  case $glance_db_type {
    'mysql': {
      $sql_connection = "mysql://${glance_db_user}:${glance_db_password}@${glance_db_host}/${glance_db_dbname}"
    }
  }

  # Install and configure glance-api
  class { 'glance::api':
    verbose           => $verbose,
    debug             => $verbose,
    auth_type         => 'keystone',
    auth_port         => '35357',
    auth_host         => $keystone_host,
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_keystone_user_password,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose           => $verbose,
    debug             => $verbose,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_keystone_user_password,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
  }

  # Configure file storage backend
  class { 'glance::backend::file': }

}
