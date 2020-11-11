#
#
#
class profile_consul::certs (
  Optional[String] $root_ca_cert = undef,
  Optional[String] $consul_cert  = undef,
  Optional[String] $consul_key   = undef,
) {
  file { '/etc/ssl/certs/consul':
    ensure => directory,
  }
  file { '/etc/ssl/certs/consul/root-ca-cert.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $root_ca_cert,
    notify  => Service['consul'],
  }
  file { '/etc/ssl/certs/consul/consul_cert.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $consul_cert,
    notify  => Service['consul'],
  }
  file { '/etc/ssl/certs/consul/consul_key.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $consul_key,
    notify  => Service['consul'],
  }
}
