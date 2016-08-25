class ocf_irc::services {
  package { 'anope':; }

  service { 'anope':
    enable  => true,
    require => [Package['anope'], Service['inspircd']],
  }

  $passwords = parsejson(file("/opt/puppet/shares/private/${::hostname}/services-passwords"))

  $root_nicks = ['waf', 'nattofriends', 'ckuehl', 'jvperrin', 'mattmcal']

  $file_defaults = {
    require => Package['anope'],
    notify  => Service['anope'],
    owner   => irc,
    group   => irc,
  }

  file {
    default:
      * => $file_defaults;

    '/etc/default/anope':
      content => "START=yes\n",
      owner   => root,
      group   => root;

    '/etc/anope/services.conf':
      content => template('ocf_irc/services.conf.erb'),
      mode    => '0640';

    '/etc/anope/services.motd':
      content => "Welcome to OCF IRC Services!\n";

    '/etc/anope':
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/ocf_irc/anope';
  }
}
