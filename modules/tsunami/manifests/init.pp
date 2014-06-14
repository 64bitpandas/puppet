class tsunami {

  include tsunami::legacy

  # Create directories to mount NFS shares on
  # Directory permissions are set by NFS share when mounted
  # Use exec instead of file so that permissions are not managed
  exec {
    'mkdir /home':
      creates => '/home',
    ;
    'mkdir /opt/ocf':
      creates => '/opt/ocf',
    ;
    'mkdir /services':
      creates => '/services',
    ;
    'mkdir /var/mail':
      creates => '/var/mail',
    ;
    'mkdir /etc/pykota':
      creates => '/etc/pykota',
    ;
    'mkdir /opt/httpd':
      creates => '/opt/httpd',
    ;
  }

  # Mount NFS shares
  mount {
    '/home':
      device  => 'homes:/home',
      fstype  => 'nfs4',
      options => 'rw,bg,noatime,nodev,nosuid',
      require => Exec['mkdir /home'],
    ;
    '/opt/ocf':
      device  => 'opt:/i686-real',
      fstype  => 'nfs4',
      options => 'ro,bg,noatime,nodev',
      require => Exec['mkdir /opt/ocf'],
    ;
    '/services':
      device  => 'services:/services',
      fstype  => 'nfs4',
      options => 'rw,bg,noatime,nodev,nosuid',
      require => Exec['mkdir /services'],
    ;
    '/var/mail':
      device  => 'mailbox:/',
      fstype  => 'nfs4',
      options => 'rw,bg,noatime,nodev,noexec,nosuid',
      require => Exec['mkdir /var/mail'],
    ;
    '/etc/pykota':
      device  => 'printhost:/',
      fstype  => 'nfs4',
      options => 'ro,bg,noatime,nodev,noexec,nosuid',
      require => Exec['mkdir /etc/pykota'],
    ;
    '/opt/httpd':
      device  => 'www:/',
      fstype  => 'nfs4',
      options => 'ro,bg,noatime,nodev,noexec,nosuid',
      require => Exec['mkdir /opt/httpd'],
    ;
  }

  package {
    # Reverse proxy for shellinabox
    ['apache2']:
    ;

    # web ssh
    ['shellinabox']:
    ;
  }

  # Provide SSH host keys
  file {
    '/etc/ssh/ssh_host_dsa_key':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      source  => 'puppet:///private/ssh_host_dsa_key';
    '/etc/ssh/ssh_host_dsa_key.pub':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///private/ssh_host_dsa_key.pub';
    '/etc/ssh/ssh_host_rsa_key':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      source  => 'puppet:///private/ssh_host_rsa_key';
    '/etc/ssh/ssh_host_rsa_key.pub':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///private/ssh_host_rsa_key.pub';
  }

  # apache must subscribe to all conf files
  service { 'apache2': }

  file { '/etc/apache2/sites-available/01-ssh.conf':
    ensure    => file,
    source    => 'puppet:///modules/tsunami/apache/sites/ssh.conf',
    notify    => Service['apache2'],
    require   => [ Package['apache2'] ],
  }

  file { '/etc/apache2/sites-available/02-ssl.conf':
    ensure    => file,
    source    => 'puppet:///modules/tsunami/apache/sites/ssl.conf',
    notify    => Service['apache2'],
    require   => [ Package['apache2'] ],
  }

  exec { '/usr/sbin/a2enmod rewrite':
    unless      => '/bin/readlink -e /etc/apache2/mods-enabled/rewrite.load',
    notify      => Service['apache2'],
    require     => Package['apache2'],
  }

  exec { '/usr/sbin/a2enmod ssl':
    unless      => '/bin/readlink -e /etc/apache2/mods-enabled/ssl.load',
    notify      => Service['apache2'],
    require     => [ File['/etc/ssl/certs/tsunami.ocf.berkeley.edu.crt'], File['/etc/ssl/private/tsunami.ocf.berkeley.edu.key'], Package['apache2'] ],
  }

  exec { '/usr/sbin/a2enmod proxy':
    unless      => '/bin/readlink -e /etc/apache2/mods-enabled/proxy.load',
    notify      => Service['apache2'],
    require     => [ Package['apache2'] ],
  }

  exec { '/usr/sbin/a2enmod proxy_http':
    unless      => '/bin/readlink -e /etc/apache2/mods-enabled/proxy_http.load',
    notify      => Service['apache2'],
    require     => [ Package['apache2'] ],
  }

  exec { '/usr/sbin/a2ensite 01-ssh.conf':
    unless      => '/bin/readlink -e /etc/apache2/sites-enabled/01-ssh.conf',
    notify      => Service['apache2'],
    require     => [Package['apache2'], Exec['/usr/sbin/a2enmod rewrite'], File['/etc/apache2/sites-available/01-ssh.conf']],
  }

  exec { '/usr/sbin/a2ensite 02-ssl.conf':
    unless      => '/bin/readlink -e /etc/apache2/sites-enabled/02-ssl.conf',
    notify      => Service['apache2'],
    require     => [Package['apache2'], Exec['/usr/sbin/a2enmod proxy'], Exec['/usr/sbin/a2enmod proxy_http'], File['/etc/apache2/sites-available/02-ssl.conf']],
  }

  # Provide SSL certificate and key
  file {
    '/etc/ssl/certs/tsunami.ocf.berkeley.edu.crt':
      ensure    => file,
      owner     => 'root',
      group     => 'ssl-cert',
      mode      => '0640',
      source    => 'puppet:///private/tsunami.ocf.berkeley.edu.crt';
    '/etc/ssl/private/tsunami.ocf.berkeley.edu.key':
      ensure    => file,
      owner     => 'root',
      group     => 'ssl-cert',
      mode      => '0640',
      source    => 'puppet:///private/tsunami.ocf.berkeley.edu.key';
    '/etc/ssl/certs/CA-BUNDLE.CRT':
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      source    => 'puppet:///private/CA-BUNDLE.CRT';
  }

  # prevent cron by sorried users
  cron { 'cron-deny':
    command => "ldapsearch -x -LLL gidNumber=2390 uid | grep '^uid:' | cut -d' ' -f2 > /etc/cron.deny",
    user    => root,
    hour    => '*',
    minute  => '*/15';
  }
}
