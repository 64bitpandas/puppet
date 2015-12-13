class ocf_mirrors::debian {
  exec { 'get-ftpsync-debian':
    command => 'wget -O - -q https://ftp-master.debian.org/ftpsync.tar.gz | tar xvfz - -C /opt/mirrors/project/debian',
    user    => 'mirrors',
    creates => '/opt/mirrors/project/debian/distrib',
    require => File['/opt/mirrors/project/debian'];
  }

  File {
    owner => mirrors,
    group => mirrors
  }

  file {
    ['/opt/mirrors/project/debian', '/opt/mirrors/project/debian/log', '/opt/mirrors/project/debian/etc']:
      ensure  => directory,
      mode    => '0755';
    '/opt/mirrors/project/debian/bin':
      ensure  => link,
      target  => '/opt/mirrors/project/debian/distrib/bin',
      require => Exec['get-ftpsync-debian'];
    ['/opt/mirrors/project/debian/bin/ftpsync-security', '/opt/mirrors/project/debian/bin/ftpsync-cd']:
      ensure  => link,
      target  => '/opt/mirrors/project/debian/bin/ftpsync';
    '/opt/mirrors/project/debian/etc/ftpsync.conf':
      source  => 'puppet:///modules/ocf_mirrors/project/debian/ftpsync.conf',
      mode    => '0644';
    '/opt/mirrors/project/debian/etc/ftpsync-security.conf':
      source  => 'puppet:///modules/ocf_mirrors/project/debian/ftpsync-security.conf',
      mode    => '0644';
    '/opt/mirrors/project/debian/etc/ftpsync-cd.conf':
      source  => 'puppet:///modules/ocf_mirrors/project/debian/ftpsync-cd.conf',
      mode    => '0644';
    '/opt/mirrors/project/debian/health':
      source  => 'puppet:///modules/ocf_mirrors/project/debian/health',
      mode    => '0755';
    '/opt/mirrors/project/debian/etc/common':
      ensure  => link,
      target  => '/opt/mirrors/project/debian/distrib/etc/common';
  }

  cron {
    'debian':
      command => 'BASEDIR=/opt/mirrors/project/debian /opt/mirrors/project/debian/bin/ftpsync',
      user    => 'mirrors',
      hour    => '*',
      minute  => '42';

    'debian-security':
      command => 'BASEDIR=/opt/mirrors/project/debian /opt/mirrors/project/debian/bin/ftpsync-security',
      user    => 'mirrors',
      hour    => '*',
      minute  => '16';

    'debian-cd':
      command => 'BASEDIR=/opt/mirrors/project/debian /opt/mirrors/project/debian/bin/ftpsync-cd',
      user    => 'mirrors',
      hour    => '*/7',
      minute  => '33';

    'debian-health':
      command => '/opt/mirrors/project/debian/health',
      user    => 'mirrors',
      hour    => '*',
      minute  => '0';
  }
}
