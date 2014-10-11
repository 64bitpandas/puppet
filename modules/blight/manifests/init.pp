class blight {

  # for ikiwiki and ikiwiki search
  package { [ 'ikiwiki', 'xapian-omega', 'libsearch-xapian-perl' ]: }
  package { ['libyaml-perl']: }

  package { 'gitweb': }

  # for old wiki
  package { ['php5', 'php5-cli', 'php5-mysql']: }

  # the location of ikwiki
  file { '/srv/ikiwiki':
    ensure => 'directory',
    owner  => 'root',
    group  => 'ocfstaff',
    mode   => '0775',
  }

  # www-data user private key used to deploy to github
  file {
    '/var/www/.ssh':
      ensure => 'directory',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0750';
    '/var/www/.ssh/config':
      source => 'puppet:///modules/blight/ssh/config',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0640';
    '/srv/ikiwiki/id_rsa':
      mode   => '0400',
      owner  => 'www-data',
      group  => 'www-data',
      source => 'puppet:///private/id_rsa';
  }

  # the serverlist ikiwiki plugin needs to be in a certain folder
  file {
    '/srv/ikiwiki/.ikiwiki/IkiWiki/Plugin':
      ensure  => 'directory',
      owner   => 'root',
      group   => 'ocfstaff',
      recurse => true,
      mode    => '0775';
    '/srv/ikiwiki/.ikiwiki/IkiWiki':
      ensure  => 'directory';
    '/srv/ikiwiki/.ikiwiki':
      ensure  => 'directory';
  }
  file { '/srv/ikiwiki/.ikiwiki/IkiWiki/Plugin/serverlist.pm':
    source => 'puppet:///modules/blight/ikiwiki/plugins/serverlist.pm',
  }

  # the location of the wiki public_html
  file {
    '/srv/ikiwiki/public_html/wiki':
      ensure  => 'directory',
      require => Exec['ikiwiki_setup'],
      owner   => 'www-data',
      group   => 'ocfstaff',
      recurse => true;
    '/srv/ikiwiki/public_html/wiki/ikiwiki.cgi':
      owner   => 'www-data',
      group   => 'ocfstaff',
      mode    => '2760';
  }

  file {
    '/srv/ikiwiki/wiki.git':
      ensure  => 'directory',
      owner   => 'www-data',
      group   => 'ocfstaff',
      recurse => true;
    '/srv/ikiwiki/wiki.git/description':
      content => 'wiki.OCF ikiwiki pages';
  }

  # the config file replaces the default
  file {
    '/srv/ikiwiki/wiki.git/config':
      source  => 'puppet:///modules/blight/ikiwiki/git_config',
      owner   => 'root',
      group   => 'ocfstaff',
      mode    => '0775';
    '/srv/ikiwiki/wiki.git/hooks/post-receive':
      source  => 'puppet:///modules/blight/ikiwiki/post-receive',
      owner   => 'www-data',
      group   => 'ocfstaff',
      mode    => '0774';
  }

  # the lockfile is necessary for 'ikiwiki --setup'
  file {
    '/srv/ikiwiki/wiki':
      ensure  => 'directory',
      owner   => 'www-data',
      group   => 'ocfstaff',
      recurse => true,
  }
  file {
    '/srv/ikiwiki/wiki/.ikiwiki':
      ensure  => 'directory',
      owner   => 'www-data',
      group   => 'ocfstaff',
      mode    => '0775',
      recurse => true;
  }

  file {
    '/srv/ikiwiki/wiki/.git/hooks/post-commit':
      source  => 'puppet:///modules/blight/ikiwiki/post-commit',
      owner   => 'www-data',
      group   => 'ocfstaff',
      mode    => '0774';
  }

  exec { 'ikiwiki_setup':
    require => File[ '/srv/ikiwiki/wiki.setup'],
    command => 'ikiwiki --setup wiki.setup',
    creates => '/srv/ikiwiki/public_html/wiki',
    cwd     => '/srv/ikiwiki',
  }

  exec { 'refresh_ikiwiki_setup':
    require     => File[ '/srv/ikiwiki/wiki.setup'],
    command     => 'ikiwiki --setup wiki.setup',
    cwd         => '/srv/ikiwiki',
    subscribe   => File['/srv/ikiwiki/wiki.setup'],
    refreshonly => true,
  }

  file { '/srv/ikiwiki/wiki.setup':
    source => 'puppet:///modules/blight/ikiwiki/wiki.setup',
    owner  => 'root',
    group  => 'ocfstaff',
    mode   => '0640',
  }

  service { 'apache2':
    subscribe => File[ '/etc/apache2/sites-available/ikiwiki',
      '/etc/apache2/sites-enabled/ikiwiki',
      '/etc/apache2/sites-available/gitweb',
      '/etc/apache2/sites-enabled/gitweb' ],
  }

  file {
    '/etc/apache2/sites-available/ikiwiki':
      source => 'puppet:///modules/blight/apache2/ikiwiki';
    '/etc/apache2/sites-enabled/ikiwiki':
      ensure => symlink,
      links  => manage,
      target => '/etc/apache2/sites-available/ikiwiki';
    '/etc/apache2/sites-available/gitweb':
      source => 'puppet:///modules/blight/apache2/gitweb';
    '/etc/apache2/sites-enabled/gitweb':
      ensure => symlink,
      links  => manage,
      target => '/etc/apache2/sites-available/gitweb';
  }

  file {
    '/etc/ssl/private/blight_ocf_berkeley_edu.crt':
      source => 'puppet:///private/blight.ocf.berkeley.edu.crt',
      mode   => '0444';
    '/etc/ssl/private/blight_ocf_berkeley_edu.key':
      source => 'puppet:///private/blight.ocf.berkeley.edu.key',
      owner  => root,
      mode   => '0400';
  }

  # gitweb setup
  file {
    '/srv/gitweb':
      ensure  => symlink,
      links   => manage,
      target  => '/usr/share/gitweb';
    '/srv/gitweb/projects.list':
      content => 'wiki.git';
    '/etc/gitweb.conf':
      source  => 'puppet:///modules/blight/gitweb/gitweb.conf';
  }

  # old wiki (docs)
  file { '/etc/apache2/sites-available/docs':
    ensure => file,
    source => 'puppet:///modules/blight/apache2/docs',
  }
  exec { '/usr/sbin/a2ensite docs':
    unless  => '/bin/readlink -e /etc/apache2/sites-enabled/docs',
    notify  => Service['apache2'],
    require => File['/etc/apache2/sites-available/docs'],
  }

  # default blight site
  file { '/etc/apache2/sites-available/000-default':
    ensure => file,
    source => 'puppet:///modules/blight/apache2/000-default',
  }
  exec { '/usr/sbin/a2ensite default':
    unless  => '/bin/readlink -e /etc/apache2/sites-enabled/000-default',
    notify  => Service['apache2'],
    require => File['/etc/apache2/sites-available/000-default'],
  }
}
