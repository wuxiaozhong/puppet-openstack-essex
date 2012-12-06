#
# Creates an auth file that can be used to export
# environment variables that can be used to authenticate
# against a keystone server.
#
class openstack::component::auth_file(
  $keystone_admin_password,
  $controller_node      = '127.0.0.1',
  $keystone_admin_token = 'keystone_admin_token',
  $keystone_admin_user           = 'admin',
  $keystone_admin_tenant         = 'admin'
) {
  file { '/root/openrc':
    content =>
  "
  export OS_TENANT_NAME=${$keystone_admin_tenant}
  export OS_USERNAME=${$keystone_admin_user}
  export OS_PASSWORD=${keystone_admin_password}
  export OS_AUTH_URL=\"http://${controller_node}:5000/v2.0/\"
  export OS_AUTH_STRATEGY=keystone
  export SERVICE_TOKEN=${keystone_admin_token}
  export SERVICE_ENDPOINT=http://${controller_node}:35357/v2.0/
  "
  }
  exec{'export current environment':
    command   => 'source /root/openrc',
    path      => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
    require   => File['/root/openrc'],
  }
  exec{'export system environment':
    command   => 'cat /root/openrc >> /root/.bashrc',
    path      => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
    require   => File['/root/openrc'],
  }
}
