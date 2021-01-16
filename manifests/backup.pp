#
#
#
class profile_consul::backup (
  String               $advertise_address  = $::profile_consul::advertise_address,
  Stdlib::Absolutepath $root_ca_file       = $::profile_consul::root_ca_file,
  Stdlib::Absolutepath $backup_dir         = $::profile_consul::backup_dir,
  String               $backup_ssh_command = $::profile_consul::backup_ssh_command,
) {
  include profile_rsnapshot::user

  file { $backup_dir:
    ensure => directory,
    owner  => 'rsnapshot',
    group  => 'rsnapshot',
  }

  $_consul_backup_config = {
    'advertise_address' => $advertise_address,
    'root_ca_file'      => $root_ca_file,
    'backup_dir'        => $backup_dir,
  }
  file { '/opt/rsnapshot/consul_backup.sh':
    content => epp('profile_consul/consul_backup.sh.epp', $_consul_backup_config),
    mode    => '0700',
    owner   => 'rsnapshot',
  }

  @@rsnapshot::backup_script{ "backup-script ${facts['networking']['fqdn']} consul-data":
    command      => "${backup_ssh_command} rsnapshot@${facts['networking']['fqdn']} \"/opt/rsnapshot/consul_backup.sh\"",
    target_dir   => "${facts['networking']['fqdn']}/consul_snapshots_before_backup",
    concat_order => '49',
    tag          => lookup('rsnapshot_tag', String, undef, 'rsnapshot'),
  }

  @@rsnapshot::backup{ "backup ${facts['networking']['fqdn']} consul-data":
    source     => "rsnapshot@${facts['networking']['fqdn']}:${backup_dir}",
    target_dir => "${facts['networking']['fqdn']}/consul_snapshots",
    tag        => lookup('rsnapshot_tag', String, undef, 'rsnapshot'),
  }
}
