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
  String                     $options                    = '',
  String                     $sd_service_name            = 'consul-ui',
  Array                      $sd_service_tags            = [],
  Boolean                    $server                     = false,
  Hash                       $services                   = {},
  String                     $version                    = '1.8.5',
  Boolean                    $ui                         = true,
  Hash                       $watches                    = {},
  Boolean                    $manage_repo                = true,
  String                     $repo_gpg_key               = 'E8A032E094D8EB4EA189D270DA418C88A3219F7B',
  Stdlib::HTTPUrl            $repo_gpg_url               = 'https://apt.releases.hashicorp.com',
  Stdlib::HTTPUrl            $repo_url                   = 'https://apt.releases.hashicorp.com',
) {
  if $connect {
    $_connect_config = {
      'connect' => { 'enabled' => true },
      'ports'   => { 'grpc' => $connect_grpc_port },
    }
    $_config = deep_merge($_connect_config, $config)
    firewall { '08502 allow consul connect':
      dport  => 8502,
      action => 'accept',
    }
    firewall { '08502 allow consul connect sidecars':
      dport  => [$connect_sidecar_port_range],
      action => 'accept',
    }
  } else {
    $_config = $config
  }
  if $manage_repo {
    if ! defined(Apt::Source['Hashicorp']) {
      apt::source { 'Hashicorp':
        location => $repo_url,
        repos    => 'main',
        key      => {
          id     => $repo_gpg_key,
          server => $repo_gpg_url,
        }
      }
    }
  }
  class { 'consul':
    config_defaults => $config_defaults,
    config_dir      => $config_dir,
    config_hash     => $_config,
    extra_options   => options,
    join_wan        => $join_wan,
    version         => $version,
    install_method  => 'package',
    bin_dir         => '/usr/bin',
  }
  if $server {
    if $manage_firewall_entry {
      firewall { '08300 allow consul rpc':
        dport  => 8300,
        action => 'accept',
      }
    }
    if $join_wan {
      if $manage_firewall_entry {
        firewall { '08302 allow consul serf WAN':
          dport  => 8302,
          action => 'accept',
        }
      }
    }
    if $ui {
      if $manage_firewall_entry {
        firewall { '08500 allow consul ui':
          dport  => 8500,
          action => 'accept',
        }
      }
      if $manage_sd_service {
        consul::service { $sd_service_name:
          checks => [
            {
              http     => "http://${facts['networking']['fqdn']}:8500",
              interval => '10s',
            }
          ],
          port   => 8500,
          tags   => $sd_service_tags,
        }
      }
    }
    if $manage_firewall_entry {
      firewall { '08301 allow consul serf LAN':
        dport  => 8600,
        action => accept,
      }
      firewall { '08600 allow consul DNS TCP':
        dport    => 8600,
        action   => accept,
        protocol => 'tcp',
      }
      firewall { '08600 allow consul DNS UDP':
        dport    => 8600,
        action   => accept,
        protocol => 'udp',
      }
    }
  }
  create_resources(consul::check, $checks)
  create_resources(consul::service, $services)
  create_resources(consul::watch, $watches)
}
