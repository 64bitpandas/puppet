class supernova {

  package {
    # account creation dependecies
    ['python-twisted', 'python-argparse', 'python-crypto']:
    ;
  }

  service { 'rsyslog': }

  user { 'atool':
    comment  => 'OCF Account Creation',
    home     => '/srv/atool',
    system   => true,
    groups   => ['sys'];
  }

  # log directory, crontab, and keytab for create
  file {
    '/opt/create/private':
      ensure  => 'directory',
      owner   => 'atool',
      group   => 'approve',
      mode    => '0750';

    '/opt/create/private/backup':
      ensure  => 'directory',
      owner   => 'atool',
      group   => 'approve',
      mode    => '0750';

    '/etc/cron.d/create':
      source => 'puppet:///modules/supernova/create.cron';

    '/opt/create/private/create.keytab':
      owner  => 'atool',
      group  => 'approve',
      mode   => '0400',
      source => 'puppet:///private/create.keytab';

    '/opt/create/private/mid_approved.users':
      ensure => 'file',
      owner  => 'atool',
      group  => 'approve',
      mode   => '0640';

    '/opt/create/private/private_pass.pem':
      ensure => 'file',
      owner  => 'atool',
      group  => 'approve',
      mode   => '0400',
      source => 'puppet:///private/private_pass.pem';

    '/etc/sudoers.d/atool':
      mode   => '0440',
      source => 'puppet:///modules/supernova/atool.sudoers';
  }

  # receive remote syslog from tsunami
  file { '/etc/rsyslog.d/tsunami.conf':
    content => "if \$FROMHOST startswith 'tsunami' then /var/log/tsunami.log\n& ~\n",
    notify  => Service['rsyslog'],
  }

  # provide logrotate rule for account creation scripts
  file { '/etc/logrotate.d/account-creation':
    ensure => file,
    source => 'puppet:///modules/supernova/logrotate/account-creation';
  }
}
