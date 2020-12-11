#
#
#
class profile_consul::agent (
  Array[String]              $agent_nodes       = $::profile_consul::agent_nodes,
  Array[String]              $server_nodes      = $::profile_consul::server_nodes,
  String                     $bind_address      = $::profile_consul::bind_addr,
  Stdlib::Absolutepath       $root_ca_file      = $::profile_consul::root_ca_file,
  Stdlib::Absolutepath       $cert_file         = $::profile_consul::cert_file,
  Stdlib::Absolutepath       $key_file          = $::profile_consul::key_file,
  String                     $client_address    = $::profile_consul::client_address,
  Stdlib::Absolutepath       $data_dir          = $::profile_consul::data_dir,
  String                     $datacenter        = $::profile_consul::datacenter,
  String                     $encrypt_key       = $::profile_consul::encrypt_key,
  String                     $node_name         = $::profile_consul::node_name,
  Stdlib::Absolutepath       $config_dir        = $::profile_consul::config_dir,
  String                     $options           = $::profile_consul::options,
  Optional[String[1]]        $join_wan          = $::profile_consul::join_wan,
  String                     $version           = $::profile_consul::version,
) {
  $_config_hash = {
    bind_addr               => $bind_address,
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
    domain                 => $facts['networking']['domain'],
    encrypt                => $encrypt_key,
    encryt_verify_incoming => true,
    encryt_verify_outgoing => true,
    log_level              => 'INFO',
    node_name              => $node_name,
    ports                  => {
      http  => '-1',
      https => '8500',
    },
    retry_join             => concat($server_nodes, $agent_nodes),
    verify_outgoing        => true,
    vefify_server_hostname => true,
    enable_syslog          => true,
    leave_on_terminate     => true,
    rejoin_after_leave     => true,
    advertise_addr         => $facts['networking']['ip'],
  }
  class { 'consul':
    config_dir     => $config_dir,
    config_hash    => $_config_hash,
    extra_options  => $options,
    join_wan       => $join_wan,
    version        => $version,
    install_method => 'package',
    bin_dir        => '/usr/bin',
  }
}
