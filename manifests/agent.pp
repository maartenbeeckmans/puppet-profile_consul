#
#
#
class profile_consul::agent (
  String                     $bind_address      = $::profile_consul::bind_address,
  Stdlib::Absolutepath       $root_ca_file      = $::profile_consul::root_ca_file,
  Stdlib::Absolutepath       $cert_file         = $::profile_consul::cert_file,
  Stdlib::Absolutepath       $key_file          = $::profile_consul::key_file,
  String                     $client_address    = $::profile_consul::client_address,
  Stdlib::Absolutepath       $data_dir          = $::profile_consul::data_dir,
  String                     $datacenter        = $::profile_consul::datacenter,
  String                     $encrypt_key       = $::profile_consul::encrypt_key,
  String                     $node_name         = $::profile_consul::node_name,
  String                     $advertise_address = $::profile_consul::advertise_address,
  Stdlib::Absolutepath       $config_dir        = $::profile_consul::config_dir,
  String                     $options           = $::profile_consul::options,
  String                     $version           = $::profile_consul::version,
) {
  $_server_results = puppetdb_query("resources[certname] { type=\"Class\" and title = \"Profile_consul::Server\" }")
  $_server_nodes = sort($_server_results.map | $result | { $result['certname'] })
  $_agent_results = puppetdb_query("resources[certname] { type=\"Class\" and title = \"Profile_consul::Agent\" }")
  $_agent_nodes = sort($_agent_results.map | $result | { $result['certname'] })

  $_config_hash = {
    bind_addr                => $bind_address,
    ca_file                  => $root_ca_file,
    cert_file                => $cert_file,
    key_file                 => $key_file,
    client_addr              => $client_address,
    data_dir                 => $data_dir,
    datacenter               => $datacenter,
    dns_config               => {
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
      http  => -1,
      https => 8500,
    },
    retry_join              => concat($_server_nodes, $_agent_nodes),
    verify_outgoing         => true,
    verify_server_hostname  => true,
    enable_syslog           => true,
    leave_on_terminate      => true,
    rejoin_after_leave      => true,
    advertise_addr          => $advertise_address,
  }
  class { 'consul':
    config_dir     => $config_dir,
    config_hash    => $_config_hash,
    extra_options  => $options,
    version        => $version,
    install_method => 'package',
    bin_dir        => '/usr/bin',
  }
}
