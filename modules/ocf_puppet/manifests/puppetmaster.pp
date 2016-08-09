class ocf_puppet::puppetmaster {
  package {
    ['puppetmaster-passenger', 'puppet-lint']:;
  }

  class { '::apache':
    default_vhost => false;
  }

  apache::vhost { 'puppetmaster':
    docroot    => '/usr/share/puppet/rack/puppetmasterd/public/',
    port       => 8140,

    ssl               => true,
    ssl_key           => '/var/lib/puppet/ssl/private_keys/puppet.pem',
    ssl_cert          => '/var/lib/puppet/ssl/certs/puppet.pem',
    ssl_chain         => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_ca            => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_crl           => '/var/lib/puppet/ssl/ca/ca_crl.pem',
    ssl_verify_client => 'optional',
    ssl_verify_depth  => 1,
    ssl_options       => ['+StdEnvVars', '+ExportCertData'],

    rack_base_uris => ['/'];
  }

  file {
    '/etc/puppet/fileserver.conf':
      source  => 'puppet:///modules/ocf_puppet/fileserver.conf';

    '/etc/puppet/puppet.conf':
      content => template('ocf_puppet/puppet.conf.erb');

    '/etc/puppet/tagmail.conf':
      content => "warning, err, alert, emerg, crit: puppet\n";

    ['/opt/puppet', '/opt/puppet/env', '/opt/puppet/shares', '/opt/puppet/shares/contrib']:
      ensure  => directory;

    '/opt/puppet/shares/private':
      mode    => '0400',
      owner   => puppet,
      group   => puppet,
      recurse => true;

    '/opt/puppet/scripts':
      ensure  => symlink,
      links   => manage,
      target  => '/opt/share/utils/staff/puppet';
  }
}
