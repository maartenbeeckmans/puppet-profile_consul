#
class profile_consul (
  Hash                       $checks                     = {},
  Hash                       $config                     = {},
  Hash                       $config_defaults            = {
    'data_dir'   => '/var/lib/consul',
    'datacenter' => 'beeckmans',
  },
  Stdlib::Absolutepath       $config_dir                 = '/etc/consul.d',
  Boolean                    $connect                    = false,
  Stdlib::Port::Unprivileged $connect_grpc_port          = 8502,
  String                     $connect_sidecar_port_range = '21000-21255',
  Optional[String[1]]        $join_wan                   = undef,
  Boolean                    $manage_firewall_entry      = true,
  Boolean                    $manage_sd_service          = false,
  String                     $options                    = '-enable-script-checks -syslog',
  String                     $sd_service_name            = 'consul-ui',
  Array                      $sd_service_tags            = [],
  Boolean                    $server                     = false,
  Hash                       $services                   = {},
  String                     $version                    = '1.8.5',
  Boolean                    $ui                         = true,
  Hash                       $watches                    = {},
  Optional[String]           $root_ca_cert               = undef,
  Optional[String]           $consul_cert                = undef,
  Optional[String]           $consul_key                 = undef,
  Boolean                    $manage_repo                = true,
  String                     $repo_gpg_key               = 'E8A032E094D8EB4EA189D270DA418C88A3219F7B',
  Stdlib::HTTPUrl            $repo_gpg_url               = 'https://apt.releases.hashicorp.com/gpg',
  Stdlib::HTTPUrl            $repo_url                   = 'https://apt.releases.hashicorp.com',
) {
  if $connect {
    $_connect_config = {
      'connect' => { 'enabled' => true },
      'ports'   => { 'grpc' => $connect_grpc_port },
    }
    $_config = deep_merge($_connect_config, $config)
  } else {
    $_config = $config
  }
  if $root_ca_cert and $consul_cert and $consul_key {
    include profile_consul::certs
  }
  class { 'consul':
    config_defaults => $config_defaults,
    config_dir      => $config_dir,
    config_hash     => $_config,
    extra_options   => $options,
    join_wan        => $join_wan,
    version         => $version,
    install_method  => 'package',
    bin_dir         => '/usr/bin',
  }
  if $manage_firewall_entry {
    include profile_consul::firewall
  }
  if $manage_repo {
    include profile_consul::repo
  }
  if $manage_sd_service {
    consul::service { $sd_service_name:
      checks => [
        {
          http     => "http://${facts['networking']['ip']}:8500",
          interval => '10s',
        }
      ],
      port   => 8500,
      tags   => $sd_service_tags,
    }
  }

  file { '/etc/profile.d/consul.sh':
    ensure  => file,
    mode    => '0644',
    content => "export CONSUL_HTTP_ADDR=https:///127.0.0.1:8500\nexport CONSUL_CACERT=/etc/ssl/certs/consul/root-ca-cert.pem"
  }
  create_resources(consul::check, $checks)
  create_resources(consul::service, $services)
  create_resources(consul::watch, $watches)
}
