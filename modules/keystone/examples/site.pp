Exec { logoutput => 'on_failure' }

package { 'curl': ensure => present }

# example of how to build a single node
# keystone instance backed by sqlite
# with all of the default admin roles
node keystone_sqlite {
  class { 'keystone':
    verbose      => true,
    debug        => true,
    catalog_type => 'sql',
    admin_token  => 'admin_token',
  }
  class { 'keystone::roles::admin':
    email    => 'example@abc.com',
    password => 'ChangeMe',
  }
}

node keystone_mysql {
  class { 'mysql::server': 
    config_hash => {'bind_address' => '0.0.0.0'}
  }
  class { 'keystone::db::mysql':
    user     => 'keystone',
    password => 'keystone',
  }
  class { 'keystone':
    verbose        => true,
    debug          => true,
    sql_connection => 'mysql://keystone:keystone@127.0.0.1/keystone',
    catalog_type   => 'sql',
    admin_token    => 'admin_token',
  }
  class { 'keystone::roles::admin':
    email    => 'test@puppetlabs.com',
    password => 'admin',
  }
}


# keystone with mysql on another node
node keystone {
  class { 'keystone':
    verbose        => true,
    debug          => true,
    sql_connection => 'mysql://keystone_admin:password@127.0.0.1/keystone',
    catalog_type   => 'sql',
    admin_token    => 'admin_token',
  }
  class { 'keystone::db::mysql':
    password => 'keystone',
  }
  class { 'keystone::roles::admin':
    email    => 'example@abc.com',
    password => 'ChangeMe',
  }
}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}
