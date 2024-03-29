#
#
#
class profile_consul::server (
  String                     $bind_address               = $::profile_consul::bind_address,
  Stdlib::Absolutepath       $root_ca_file               = $::profile_consul::root_ca_file,
  Stdlib::Absolutepath       $cert_file                  = $::profile_consul::cert_file,
  Stdlib::Absolutepath       $key_file                   = $::profile_consul::key_file,
  String                     $client_address             = $::profile_consul::client_address,
  Stdlib::Absolutepath       $data_dir                   = $::profile_consul::data_dir,
  String                     $datacenter                 = $::profile_consul::datacenter,
  String                     $encrypt_key                = $::profile_consul::encrypt_key,
  String                     $node_name                  = $::profile_consul::node_name,
  Boolean                    $ui                         = $::profile_consul::ui,
  String                     $user                       = $::profile_consul::user,
  String                     $group                      = $::profile_consul::group,
  String                     $advertise_address          = $::profile_consul::advertise_address,
  Boolean                    $manage_user                = $::profile_consul::manage_user,
  Boolean                    $manage_group               = $::profile_consul::manage_group,
  Boolean                    $connect                    = $::profile_consul::connect,
  Stdlib::Port::Unprivileged $connect_grpc_port          = $::profile_consul::connect_grpc_port,
  Stdlib::Absolutepath       $config_dir                 = $::profile_consul::config_dir,
  String                     $options                    = $::profile_consul::options,
  String                     $version                    = $::profile_consul::version,
  Boolean                    $manage_sd_service          = $::profile_consul::manage_sd_service,
  String                     $sd_service_name            = $::profile_consul::sd_service_name,
  Array[String]              $sd_service_tags            = $::profile_consul::sd_service_tags,
  Boolean                    $consul_backup              = $::profile_consul::consul_backup,
  Boolean                    $manage_prometheus_exporter = $::profile_consul::manage_prometheus_exporter,
) {
  $_server_results = puppetdb_query("resources[certname] { type=\"Class\" and title = \"Profile_consul::Server\" }")
  $_server_nodes = sort($_server_results.map | $result | { $result['certname'] })
  $_agent_results = puppetdb_query("resources[certname] { type=\"Class\" and title = \"Profile_consul::Agent\" }")
  $_agent_nodes = sort($_agent_results.map | $result | { $result['certname'] })

  $config_hash = {
    bind_addr               => $bind_address,
    bootstrap_expect        => size($_server_nodes),
    ca_file                 => $root_ca_file,
    cert_file               => $cert_file,
    key_file                => $key_file,
    client_addr             => $client_address,
    data_dir                => $data_dir,
    datacenter              => $datacenter,
    dns_config              => {
      service_ttl => {
        '*' => '120s',
      }
    },
    encrypt                 => $encrypt_key,
    encrypt_verify_incoming => true,
    encrypt_verify_outgoing => true,
    log_level               => 'INFO',
    node_name               => $node_name,
    ports                   => {
      http     => -1,
      https    => 8500,
    },
    retry_join              => concat($_server_nodes,$_agent_nodes),
    server                  => true,
    ui                      => true,
    verify_outgoing         => true,
    verify_server_hostname  => true,
    telemetry               => {
      prometheus_retention_time => '5m',
    },
    start_join              => $_server_nodes,
    advertise_addr          => $advertise_address,
    addresses               => {
      http           => "127.0.0.1 ${advertise_address}",
    },
    enable_script_checks    => false,
    disable_remote_exec     => true,
    enable_syslog           => true,
    leave_on_terminate      => true,
    rejoin_after_leave      => true,
  }
  if $connect {
    $_connect_config = {
      'connect' => { 'enabled' => true },
      'ports'   => { 'grpc' => $connect_grpc_port },
    }
    $_config_hash = deep_merge($_connect_config, $config_hash)
  } else {
    $_config_hash = $config_hash
  }
  class { 'consul':
    config_dir     => $config_dir,
    config_hash    => $_config_hash,
    extra_options  => $options,
    user           => $user,
    group          => $group,
    manage_user    => $manage_user,
    manage_group   => $manage_group,
    version        => $version,
    install_method => 'package',
    bin_dir        => '/usr/bin',
  }
  if $manage_sd_service {
    consul::service { $sd_service_name:
      checks => [
        {
          http            => "https://${advertise_address}:8500",
          interval        => '10s',
          tls_skip_verify => true,
        }
      ],
      port   => 8500,
      tags   => $sd_service_tags,
    }
  }
  if $consul_backup {
    include profile_consul::backup
  }
  if $manage_prometheus_exporter {
    include profile_prometheus::consul_exporter
  }
}
