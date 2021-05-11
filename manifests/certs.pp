#
#
#
class profile_consul::certs (
  Stdlib::Absolutepath $root_ca_file     = $::profile_consul::root_ca_file,
  Stdlib::Absolutepath $cert_file        = $::profile_consul::cert_file,
  Stdlib::Absolutepath $key_file         = $::profile_consul::key_file,
  Stdlib::Absolutepath $certs_dir        = $::profile_consul::certs_dir,
  Boolean              $use_puppet_certs = $::profile_consul::use_puppet_certs,
  Optional[String]     $root_ca_cert     = $::profile_consul::root_ca_cert,
  Optional[String]     $consul_cert      = $::profile_consul::consul_cert,
  Optional[String]     $consul_key       = $::profile_consul::consul_key,
) {
  file { $certs_dir:
    ensure => directory,
  }
  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['consul'],
  }
  if $use_puppet_certs {
    file { $root_ca_file:
      ensure => present,
      source => $facts['extlib.puppet_config']['localcacert'],
    }
    file { $cert_file:
      ensure => present,
      source => $facts['extlib.puppet_config']['hostcert'],
    }
    file { $key_file:
      ensure => present,
      source => $facts['extlib.puppet_config']['hostprivkey'],
    }
  } else {
    file { $root_ca_file:
      ensure  => present,
      content => $root_ca_cert,
    }
    file { $cert_file:
      ensure  => present,
      content => $consul_cert,
    }
    file { $key_file:
      ensure  => present,
      content => $consul_key,
    }
  }
}
