class ocf_mirrors::qt {
  file {
    '/opt/mirrors/project/qt':
      ensure  => directory,
      source  => 'puppet:///modules/ocf_mirrors/project/qt/',
      owner   => mirrors,
      group   => mirrors,
      mode    => '0755',
      recurse => true;
  }

  ocf_mirrors::monitoring { 'qt':
    type          => 'ts',
    upstream_host => 'download.qt.io',
    upstream_path => '',
    ts_path       => 'timestamp.txt',
  }

  cron {
    'qt':
      command => '/opt/mirrors/project/qt/sync-archive > /dev/null',
      user    => 'mirrors',
      hour    => '*/4',
      minute  => '5';
  }
}
