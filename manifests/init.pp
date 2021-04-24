#
class profile_consul (
  String                     $bind_address,
  Stdlib::Absolutepath       $root_ca_file,
  Stdlib::Absolutepath       $cert_file,
  Stdlib::Absolutepath       $key_file,
  Stdlib::Absolutepath       $certs_dir,
  String                     $root_ca_cert,
  String                     $consul_cert,
  String                     $consul_key,
  String                     $client_address,
  Stdlib::Absolutepath       $data_dir,
  String                     $datacenter,
  String                     $encrypt_key,
  String                     $node_name,
  Boolean                    $server,
  Boolean                    $ui,
  String                     $user,
  String                     $group,
  Boolean                    $manage_user,
  Boolean                    $manage_group,
  String                     $advertise_address,
  Boolean                    $connect,
  Stdlib::Port::Unprivileged $connect_grpc_port,
  String                     $connect_sidecar_port_range,
  Stdlib::Absolutepath       $config_dir,
  String                     $options,
  String                     $version,
  Boolean                    $manage_firewall_entry,
  Boolean                    $manage_repo,
  String                     $sd_service_name,
  Array[String]              $sd_service_tags,
  Hash                       $checks,
  Hash                       $services,
  Hash                       $watches,
  Boolean                    $consul_backup,
  Stdlib::Absolutepath       $backup_dir,
  String                     $backup_ssh_command,
  Boolean                    $manage_prometheus_exporter,
  Boolean                    $manage_sd_service            = lookup('manage_sd_service', Boolean, first, true),
) {
  if $server {
    include profile_consul::server
  } else {
    include profile_consul::agent
  }

  include profile_consul::certs

  if $manage_firewall_entry {
    include profile_consul::firewall
  }
  if $manage_repo {
    include hashi_stack::repo
  }
  if $manage_sd_service {
    consul::service { 'consul-dns':
      checks => [
        {
          tcp      => "${advertise_address}:8600",
          interval => '10s',
        }
      ],
      port   => Integer($port),
    }
  }

  file { '/etc/profile.d/consul.sh':
    ensure  => file,
    mode    => '0644',
    content => "export CONSUL_HTTP_ADDR=https://${advertise_address}:8500\nexport CONSUL_CACERT=${root_ca_file}",
  }
  create_resources(consul::check, $checks)
  create_resources(consul::service, $services)
  create_resources(consul::watch, $watches)
}
