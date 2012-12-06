#
# == Class: openstack::component::keystone
# Keystone安装与配置
#
# 功能描述：
# 1.安装Keystone软件包
# 2.建立管理员的keystone(用户、角色、租间、Endpoint)
# 3.配置glance和nova的keystone(用户、角色、租间、Endpoint)
#
# 使用条件：
#  1.数据库服务器已安装，并建立keystone数据库（可以使用例如openstack::db::mysql来完成数据库初始化）
#
# 参数：
# [keystone_db_host] keystone数据库IP地址
# [keystone_db_type] keystone数据库类型，默认为'mysql'
# [keystone_db_dbname] keystone数据库名，默认为'keystone'
# [keystone_db_user] keystone数据库用户名，默认为'keystone'
# [keystone_db_password] keystone数据库密码. 必输项.
#
# [admin_tenant] 管理员租间，默认为：'admin'
# [admin_email] 管理员Email
# [admin_password] 管理员密码
#
# [glance_keystone_user_password] 用于Glance的租间用户密码
# [nova_keystone_user_password] 用于Nova的租间用户密码

# [public_address] 用于Endpoint的公共授权地址 Required.
# [internal_address] 用于Endpoint的内部授权地址. Defaults to  $public_address
# [admin_address] 用于Endpoint的管理授权地址. Defaults to  $internal_address

# [verbose] Log verbosely. Optional. Defaults to  'False'

# [admin_token] 管理员令牌. 默认为：'admin_token'.
# [glance_enabled] Set up glance endpoints and auth. Optional. Defaults to  true
# [nova_enabled] Set up nova endpoints and auth. Optional. Defaults to  true


# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
#
# === Example
#
# class { 'openstack::keystone':
#   keystone_db_host               => '127.0.0.1',
#   keystone_db_password  => 'changeme',
#   keystone_admin_token  => '12345',
#   admin_email           => 'root@localhost',
#   admin_password        => 'changeme',
#   public_address        => '192.168.1.1',
#  }

class openstack::component::keystone (
  #keystone db
  $keystone_db_host,
  $keystone_db_type                  = 'mysql',
  $keystone_db_name                  = 'keystone',
  $keystone_db_user                  = 'keystone',
  $keystone_db_password,
  #admin endpoint
  $keystone_admin_tenant                      = 'admin',
  $keystone_admin_email,
  $keystone_admin_password,
  #glance endpoint
  $glance_keystone_user_password,
  #nova endpoint
  $nova_keystone_user_password,
  
  $public_address,
  $internal_address         = false,
  $admin_address            = false,
  
  $glance_enabled           = true,
  $glance_public_address    = false,
  $glance_internal_address  = false,
  $glance_admin_address     = false,
  
  $nova_enabled             = true,
  $nova_public_address      = false,
  $nova_internal_address    = false,
  $nova_admin_address       = false,
  #common
  $admin_token,
  $region                   = 'RegionOne',
  $verbose                  = 'False',
  $enabled                  = true
) {

  # Install and configure Keystone
  if $keystone_db_type == 'mysql' {
    $sql_conn = "mysql://${$keystone_db_user}:${keystone_db_password}@${keystone_db_host}/${keystone_db_name}"
  } else {
    fail("keystone_db_type ${keystone_db_type} is not supported")
  }

  # I have to do all of this crazy munging b/c parameters are not
  # set procedurally in Pupet
  if($internal_address) {
    $internal_real = $internal_address
  } else {
    $internal_real = $public_address
  }
  if($admin_address) {
    $admin_real = $admin_address
  } else {
    $admin_real = $internal_real
  }
  if($glance_public_address) {
    $glance_public_real = $public_address
  } else {
    $glance_public_real = $public_address
  }
  if($glance_internal_address) {
    $glance_internal_real = $glance_internal_address
  } else {
    $glance_internal_real = $glance_public_real
  }
  if($glance_admin_address) {
    $glance_admin_real = $glance_admin_address
  } else {
    $glance_admin_real = $glance_internal_real
  }
  if($nova_public_address) {
    $nova_public_real = $nova_public_address
  } else {
    $nova_public_real = $public_address
  }
  if($nova_internal_address) {
    $nova_internal_real = $nova_internal_address
  } else {
    $nova_internal_real = $nova_public_real
  }
  if($nova_admin_address) {
    $nova_admin_real = $nova_admin_address
  } else {
    $nova_admin_real = $nova_internal_real
  }

  class { '::keystone':
    verbose        => $verbose,
    debug          => $verbose,
    catalog_type   => 'sql',
    admin_token    => $admin_token,
    enabled        => $enabled,
    sql_connection => $sql_conn,
  }

  if ($enabled) {
    # Setup the admin user
    class { 'keystone::roles::admin':
      email        => $keystone_admin_email,
      password     => $keystone_admin_password,
      admin_tenant => $keystone_admin_tenant,
    }

    # Setup the Keystone Identity Endpoint
    class { 'keystone::endpoint':
      public_address   => $public_address,
      admin_address    => $admin_real,
      internal_address => $internal_real,
      region           => $region,
    }

    # Configure Glance endpoint in Keystone
    if $glance_enabled {
      class { 'glance::keystone::auth':
        password         => $glance_keystone_user_password,
        public_address   => $glance_public_real,
        admin_address    => $glance_admin_real,
        internal_address => $glance_internal_real,
        region           => $region,
      }
    }

    # Configure Nova endpoint in Keystone
    if $nova_enabled {
      class { 'nova::keystone::auth':
        password         => $nova_keystone_user_password,
        public_address   => $nova_public_real,
        admin_address    => $nova_admin_real,
        internal_address => $nova_internal_real,
        region           => $region,
      }
    }
  }
}
