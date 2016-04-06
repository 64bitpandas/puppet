# The ocf_mail::site_ocf class configures postfix to serve the @ocf domain,
# including LDAP users and internal mail (and mailing lists).

class ocf_mail::site_ocf {
  include spam

  package {
    ['postfix', 'postfix-ldap', 'rt4-clients']:;
  }

  service { 'postfix':
    require => [Package['postfix'], Package['rt4-clients']],
  }

  user { 'ocfmail':
    ensure  => present,
    name    => 'ocfmail',
    gid     => 'ocfmail',
    groups  => ['sys'],
    home    => '/var/mail',
    shell   => '/bin/false',
    system  => true,
    require => Group['ocfmail'],
  }

  group { 'ocfmail':
    ensure  => present,
    name    => 'ocfmail',
    system  => true,
  }

  exec { 'newaliases':
    refreshonly => true,
    command     => '/usr/bin/newaliases',
    require     => Service['postfix'],
  }

  cron {
    'update-aliases':
      command => '/usr/local/sbin/update-aliases',
      user    => root,
      minute  => '*/15',
      require => [
        File['/usr/local/sbin/update-aliases'],
        Service['postfix']
      ];

    'update-nomail-hashes':
      command => '/usr/local/sbin/update-nomail-hashes',
      user    => root,
      minute  => '*/15',
      require => [
        File['/usr/local/sbin/update-nomail-hashes'],
        Service['postfix']
      ];

    'update-cred-cache':
      command => '/usr/local/sbin/update-cred-cache',
      user    => root,
      special => 'hourly',
      require => [
        File['/usr/local/sbin/update-cred-cache'],
        File['/etc/postfix/ocf/smtp-krb5.keytab'],
        Service['postfix']
      ];

    'update-cred-cache-reboot':
      command => '/usr/local/sbin/update-cred-cache',
      user    => root,
      special => 'reboot',
      require => [
        File['/usr/local/sbin/update-cred-cache'],
        File['/etc/postfix/ocf/smtp-krb5.keytab'],
        Service['postfix']
      ];
  }

  file {
    '/etc/postfix/ocf/smtp-krb5.keytab':
      mode    => '0600',
      owner   => root,
      group   => root,
      source  => 'puppet:///private/smtp-krb5.keytab',
      require => Package['postfix'];

    # postfix config
    '/etc/postfix/main.cf':
      mode    => '0644',
      source  => 'puppet:///modules/ocf_mail/site_ocf/postfix/main.cf',
      notify  => Service['postfix'],
      require => Package['postfix'];
    '/etc/postfix/ldap-aliases.cf':
      mode    => '0644',
      source  => 'puppet:///modules/ocf_mail/site_ocf/postfix/ldap-aliases.cf',
      notify  => Service['postfix'],
      require => Package['postfix'];
    '/etc/postfix/ocf':
      ensure  => directory,
      require => Service['postfix'];
    '/etc/postfix/ocf/nomail':
      ensure  => file,
      require => Service['postfix'];
    '/etc/postfix/ocf/helo_access':
      source  => 'puppet:///modules/ocf_mail/site_ocf/postfix/helo_access',
      require => Service['postfix'];

    # aliases and hashes
    '/etc/aliases':
      mode    => '0644',
      source  => 'puppet:///modules/ocf_mail/site_ocf/aliases',
      notify  => Exec['newaliases'];
    '/usr/local/sbin/update-aliases':
      mode    => '0755',
      source  => 'puppet:///modules/ocf_mail/site_ocf/update-aliases';
    '/usr/local/sbin/update-nomail-hashes':
      mode    => '0755',
      source  => 'puppet:///modules/ocf_mail/site_ocf/update-nomail-hashes';
    '/usr/local/sbin/update-cred-cache':
      mode    => '0755',
      source  => 'puppet:///modules/ocf_mail/site_ocf/update-cred-cache';

    # outgoing nomail logging
    '/var/mail/nomail':
      ensure  => directory,
      mode    => '0755',
      owner   => ocfmail,
      group   => ocfmail;
    '/etc/logrotate.d/nomail':
      ensure  => file,
      source  => 'puppet:///modules/ocf_mail/site_ocf/logrotate/nomail';
  }

  ocf::munin::plugin { 'mails-past-hour':
    source => 'puppet:///modules/ocf_mail/site_ocf/munin/mails-past-hour',
    user   => root,
  }
}
