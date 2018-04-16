class ocf_mirrors::ubuntu {
  ocf_mirrors::ftpsync { 'ubuntu':
    rsync_host  => 'mirrors.kernel.org',
    cron_minute => '50';
  }

  ocf_mirrors::monitoring { 'ubuntu':
    type          => 'debian',
    dist_to_check => 'devel',
    upstream_host => 'archive.ubuntu.com';
  }

  file { '/opt/mirrors/project/ubuntu/sync-releases':
    source => 'puppet:///modules/ocf_mirrors/project/ubuntu/sync-releases',
    mode   => '0755',
    owner  => mirrors,
    group  => mirrors;
  }

  cron { 'ubuntu-releases':
    command => '/opt/mirrors/project/ubuntu/sync-releases > /dev/null',
    user    => 'mirrors',
    hour    => '*/7',
    minute  => '18';
  }
}
