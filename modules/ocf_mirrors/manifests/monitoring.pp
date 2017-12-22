define ocf_mirrors::monitoring(
    $type = 'debian',
    $project_path = "/opt/mirrors/project/${title}",
    $upstream_host = undef,
    $dist_to_check = undef,
    $local_path = "/${title}",
    $upstream_path = "/${title}",
    $upstream_protocol = 'http',
    $ensure = 'present',
  ) {
  $local_url = "http://mirrors.ocf.berkeley.edu${local_path}/dists/${dist_to_check}/Release"
  $upstream_url = "${upstream_protocol}://${upstream_host}${upstream_path}/dists/${dist_to_check}/Release"
  if $ensure == 'present' {
    file { "${project_path}/health":
      ensure => link,
      target => "/opt/mirrors/bin/${type}-healthcheck",
      owner  => mirrors,
      group  => mirrors,
    } ->
    cron { "${title}-health":
      command => "${project_path}/health ${local_url} ${upstream_url}",
      user    => mirrors,
      hour    => '*/6',
      minute  => '0';
    }
  } else {
    file { "${project_path}/health":
      ensure => absent;
    }

    cron { "${title}-health":
      ensure => absent,
      user   => mirrors;
    }
  }
}
