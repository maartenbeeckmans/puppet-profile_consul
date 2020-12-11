#
#
#
class profile_consul::server (
  String                     $bind_address      = $::profile_consul::bind_addr,
  Array[String]              $agent_nodes       = $::profile_consul::agent_nodes,
  Array[String]              $server_nodes      = $::profile_consul::server_nodes,
  Stdlib::Absolutepath       $root_ca_file      = $::profile_consul::root_ca_file,
  Stdlib::Absolutepath       $cert_file         = $::profile_consul::cert_file,
  Stdlib::Absolutepath       $key_file          = $::profile_consul::key_file,
  String                     $client_address    = $::profile_consul::client_address,
  Stdlib::Absolutepath       $data_dir          = $::profile_consul::data_dir,
  String                     $datacenter        = $::profile_consul::datacenter,
  String                     $encrypt_key       = $::profile_consul::encrypt_key,
  String                     $node_name         = $::profile_consul::node_name,
  Boolean                    $ui                = $::profile_consul::ui,
  String                     $user              = $::profile_consul::user,
  String                     $group             = $::profile_consul::group,
  Boolean                    $manage_user       = $::profile_consul::manage_user,
  Boolean                    $manage_group      = $::profile_consul::manage_group,
  Boolean                    $connect           = $::profile_consul::connect,
  Stdlib::Port::Unprivileged $connect_grpc_port = $::profile_consul::connect_grpc_port,
  Stdlib::Absolutepath       $config_dir        = $::profile_consul::config_dir,
  String                     $options           = $::profile_consul::options,
  Optional[String[1]]        $join_wan          = $::profile_consul::join_wan,
  String                     $version           = $::profile_consul::version,
) {
  $config_hash = {
    bind_addr               => $bind_address,
    bootstrap_expect        => size($server_nodes),
    ca_file                 => $root_ca_file,
    cert_file               => $cert_file,
    key_file                => $cert_file,
    client_address          => $client_address,
    data_dir                => $data_dir,
    datacenter              => $datacenter,
    dns_config              => {
      service_ttl => {
        '*' => '120s',
      }
    },
    domain                  => $facts['networking']['domain'],
    encrypt                 => $encrypt_key,
    encrypt_verify_incoming => true,
    encrypt_verify_outgoing => true,
    log_level               => 'INFO',
    node_name               => $node_name,
    ports                   => {
      http     => '-1',
      https    => '8500',
    },
    retry_join              => concat($server_nodes,$agent_nodes),
    server                  => true,
    ui                      => true,
    verify_outgoing         => true,
    vefify_server_hostname  => true,
    telemetry               => {
      prometheus_retention_time => '5m',
    },
    start_join              => $server_nodes,
    advertise_addr          => $facts['networking']['ip'],
    addresses               => {
      http           => "127.0.0.1 ${facts['networking']['ip']}",
    },
    enable_script_checks    => true,
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
    join_wan       => $join_wan,
    version        => $version,
    install_method => 'package',
    bin_dir        => '/usr/bin',
  }
}
