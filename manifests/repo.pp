#
#
#
class profile_consul::repo (
  String          $repo_gpg_key = $::profile_consul::repo_gpg_key,
  Stdlib::HTTPUrl $repo_gpg_url = $::profile_consul::repo_gpg_url,
  Stdlib::HTTPUrl $repo_url     = $::profile_consul::repo_url,
) {
  if $facts['os']['family'] == 'RedHat' {
    if ! defined(Yumrepo['Hashicorp']) {
      yumrepo { 'Hashicorp':
        ensure   => present,
        baseurl  => $repo_url,
        gpgcheck => true,
        gpgkey   => $repo_gpg_key,
      }
    }
  } else {
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
}
