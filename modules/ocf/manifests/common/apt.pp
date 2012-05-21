class ocf::common::apt ( $nonfree = false, $desktop = false ) {

  # ensure latest version of aptitude
  package { 'aptitude': }

  file {
    # provide sources.list
    '/etc/apt/sources.list':
      content => template('ocf/common/sources.list.erb'),
      require => Package['aptitude'];
    # override conffiles on package installation
    '/etc/apt/apt.conf.d/90conffiles':
      source  => 'puppet:///modules/ocf/common/apt/conffiles';
    # update apt list and clear apt cache and old config daily
    '/etc/cron.daily/ocf-apt':
      mode    => '0755',
      source  => 'puppet:///modules/ocf/common/apt/cronjob',
      require => [ Package['aptitude'], File['/etc/apt/sources.list'] ]
  }

  exec { 'aptitude update':
    refreshonly => true,
    subscribe   => File['/etc/apt/sources.list']
  }

  if $desktop {
    # trust debian-multimedia and mozilla.debian.net GPG key
    exec {
      'debian-multimedia':
        command => 'aptitude update; aptitude -o Aptitude::CmdLine::Ignore-Trust-Violations=true install deb-multimedia-keyring; aptitude update',
        unless  => 'dpkg -l deb-multimedia-keyring | grep ^ii',
        require => File['/etc/apt/sources.list'];
      'debian-mozilla':
        command => 'aptitude update; aptitude -o Aptitude::CmdLine::Ignore-Trust-Violations=true install pkg-mozilla-archive-keyring; aptitude update',
        unless  => 'dpkg -l pkg-mozilla-archive-keyring | grep ^ii',
        require => File['/etc/apt/sources.list']
    }
  }

}
