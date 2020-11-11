#
#
#
class profile_consul::firewall (
  Boolean             $connect                    = $::profile_consul::connect,
  String              $connect_sidecar_port_range = $::profile_consul::connect_sidecar_port_range,
  Boolean             $server                     = $::profile_consul::server,
  Boolean             $ui                         = $::profile_consul::ui,
  Optional[String[1]] $join_wan                   = $::profile_consul::join_wan,
) {
  if $connect {
    firewall { '08502 allow consul connect':
      dport  => 8502,
      action => 'accept',
    }
    firewall { '08502 allow consul connect sidecars':
      dport  => $connect_sidecar_port_range,
      action => 'accept',
    }
  }
  if $server {
    firewall { '08300 allow consul rpc':
      dport  => 8300,
      action => 'accept',
    }
    if $join_wan {
      firewall { '08302 allow consul serf WAN':
        dport  => 8302,
        action => 'accept',
      }
    }
    if $ui {
      firewall { '08500 allow consul ui':
        dport  => 8500,
        action => 'accept',
      }
    }
    firewall { '08301 allow consul serf LAN':
      dport  => 8301,
      action => accept,
    }
    firewall { '08600 allow consul DNS TCP':
      dport  => 8600,
      action => accept,
      proto  => 'tcp',
    }
    firewall { '08600 allow consul DNS UDP':
      dport  => 8600,
      action => accept,
      proto  => 'udp',
    }
  }
}
