class ocf::apt ( $desktop = false ) {
  package { ['aptitude', 'imvirt']: }

  class { '::apt':
    purge_sources_list   => true,
    purge_sources_list_d => true;
  }

  case $::operatingsystem {
    'Debian': {
      $repos = 'main contrib non-free'

      apt::source {
        'debian':
          location  => 'http://mirrors/debian/',
          release   => $::lsbdistcodename,
          repos     => $repos;

        'debian-security':
          location  => 'http://mirrors/debian-security/',
          release   => "${::lsbdistcodename}/updates",
          repos     => $repos;

        'ocf':
          location  => 'http://apt/',
          release   => $::lsbdistcodename,
          repos     => 'main',
          include_src => false;
      }

      # repos available only for stable/oldstable
      if $::lsbdistcodename in ['wheezy', 'jessie'] {
        apt::source { 'debian-updates':
          location  => 'http://mirrors/debian/',
          release   => "${::lsbdistcodename}-updates",
          repos     => $repos;
        }

        # XXX: we use a _different_ hostname from the regular archive because
        # the puppetlabs apt module uses hostname-based apt pinning, which
        # causes _all_ packages to be pinned at equal priority
        class { 'apt::backports':
          location => 'http://mirrors.ocf.berkeley.edu/debian/';
        }
      }
    }

    default: {
      warning('Unrecognized operating system; can\'t configure apt!')
    }
  }

  apt::key { 'puppetlabs':
    key        => '4BD6EC30',
    key_source => 'https://apt.puppetlabs.com/pubkey.gpg';
  }

  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com/',
    repos      => 'main dependencies',
    require    => Apt::Key['puppetlabs'];
  }

  apt::key { 'ocf':
    key        => '45A686E7D72A0AF4',
    key_source => 'https://apt.ocf.berkeley.edu/pubkey.gpg';
  }

  if $desktop {
    exec {
      'add-i386':
        command => 'dpkg --add-architecture i386',
        unless  => 'dpkg --print-foreign-architectures | grep i386',
        notify => Exec['apt_update'];
    }

    apt::key { 'google':
      key        => '7FAC5991',
      key_source => 'https://dl-ssl.google.com/linux/linux_signing_key.pub';
    }

    # Chrome creates /etc/apt/sources.list.d/google-chrome.list upon
    # installation, so we use the name 'google-chrome' to avoid duplicates
    #
    # Chrome will overwrite the puppet apt source during install, but puppet
    # will later change it back. They say the same thing so it's cool.
    apt::source {
      'google-chrome':
        location    => 'http://dl.google.com/linux/chrome/deb/',
        release     => 'stable',
        repos       => 'main',
        include_src => false,
        require     => Apt::Key['google'];
    }
  }

  file { '/etc/cron.daily/ocf-apt':
    mode    => '0755',
    content => template('ocf/apt/ocf-apt.erb'),
    require => Package['aptitude'];
  }
}
