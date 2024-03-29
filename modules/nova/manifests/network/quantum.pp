#
# == parameters
#  * quantum_admin_password: password for quantum keystone user.
#  * quantum_auth_strategy: auth strategy used by quantum.
#  * quantum_connection_host
#  * quantum_url
#  * quantum_admin_tenant_name
#  * quantum_admin_username
#  * quantum_admin_auth_url
class nova::network::quantum (
  $fixed_range,
  $quantum_admin_password,
  $use_dhcp                  = 'True',
  $public_interface          = undef,
  $quantum_connection_host   = localhost,
  $quantum_auth_strategy     = 'keystone',
  $quantum_url               = 'http://127.0.0.1:9696',
  $quantum_admin_tenant_name = 'services',
  $quantum_admin_username    = 'quantum',
  $quantum_admin_auth_url    = 'http://127.0.0.1:35357/v2.0'
) {

  if $public_interface {
    nova_config { 'public_interface': value => $public_interface }
  }

  if $quantum_connection_host != 'localhost' {
    nova_config { 'quantum_connection_host': value => $quantum_connection_host }
  }

  nova_config {
    'fixed_range':               value => $fixed_range;
    'quantum_use_dhcp':          value => $use_dhcp;
    'quantum_auth_strategy':     value => $quantum_auth_strategy;
    'network_api_class':         value => 'nova.network.quantumv2.api.API';
    'quantum_url':               value => $quantum_url;
    'quantum_admin_tenant_name': value => $quantum_admin_tenant_name;
    'quantum_admin_username':    value => $quantum_admin_username;
    'quantum_admin_password':    value => $quantum_admin_password;
    'quantum_admin_auth_url':    value => $quantum_admin_auth_url;
  }
}
