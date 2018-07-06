class ocf_admin {
  include ocf::extrapackages
  include ocf::firewall::allow_mosh
  include ocf::firewall::allow_ssh
  include ocf::firewall::output_all
  include ocf::hostkeys
  include ocf::packages::cups
  include ocf::tmpfs
  include ocf_ocfweb::dev_config

  include ocf_admin::apt_dater
  include ocf_admin::create

  class { 'ocf::nfs':
    cron => true,
    web  => true;
  }

  class { 'ocf::packages::docker':
    admin_group => 'ocfroot';
  }

  package {
    [
      'ipmitool',
      'wakeonlan',
    ]:;
  }

  file {
    '/opt/passwords':
      source    => 'puppet:///private/passwords',
      group     => ocfroot,
      mode      => '0640',
      show_diff => false;

    '/etc/ocfprinting.json':
      source    => 'puppet:///private/ocfprinting.json',
      group     => ocfstaff,
      mode      => '0640',
      show_diff => false;

    '/etc/ocfstats-ro.passwd':
      source    => 'puppet:///private/ocfstats-ro.passwd',
      group     => ocfstaff,
      mode      => '0640',
      show_diff => false;
  }

  # Allow Redis
  ocf::firewall::firewall46 {
    '101 allow redis':
      opts => {
        chain  => 'PUPPET-INPUT',
        proto  => 'tcp',
        dport  => 6378,
        action => 'accept',
      };
  }
  # Allow 8000-8999 for ocfweb etc. dev work
  ocf::firewall::firewall46 {
    '101 allow dev ports':
      opts => {
        chain  => 'PUPPET-INPUT',
        proto  => 'tcp',
        dport  => '8000-8999',
        action => 'accept',
      };
  }
}
