class firestorm::kerberos {
  package { 'heimdal-kdc':
    # if local realm has not been defined installation will fail
    require => File['/etc/krb5.conf'];
  }

  service { 'heimdal-kdc':
    subscribe => File['/etc/heimdal-kdc/kdc.conf', '/etc/heimdal-kdc/kadmind.acl'],
    require   => Package['heimdal-kdc'];
  }

  file {
    '/etc/heimdal-kdc/kdc.conf':
      source  => 'puppet:///modules/firestorm/kdc.conf',
      require => Package['heimdal-kdc'];

    '/etc/heimdal-kdc/kadmind.acl':
      source  => 'puppet:///modules/firestorm/kadmind.acl',
      require => Package['heimdal-kdc'];

    '/etc/logrotate.d/heimdal-kdc':
      source  => 'puppet:///modules/firestorm/heimdal-kdc-logrotate',
      require => Package['heimdal-kdc'];
  }

  # daily git backup
  if $::hostname == 'firestorm' {
    file { '/usr/local/sbin/kerberos-git-backup':
      mode   => '0755',
      source => 'puppet:///modules/firestorm/kerberos-git-backup';
    }

    cron { 'kerberos-git-backup':
      command => '/usr/local/sbin/kerberos-git-backup',
      minute  => 0,
      hour    => 4,
      require => File['/usr/local/sbin/kerberos-git-backup'];
    }
  }
}
