class ocf_wiki {
  include ocf_ssl

  package { 'ikiwiki':; }

  file {
    ['/srv/wiki', '/srv/wiki/webhook']:
      ensure => directory,
      mode   => '0775';

    ['/srv/wiki/wiki', '/srv/wiki/public_html']:
      ensure => directory,
      group  => 'www-data',
      mode   => '0775';

    '/srv/wiki/wiki.setup':
      source => 'puppet:///modules/ocf_wiki/wiki.setup',
      mode   => '0644';

    '/srv/wiki/rebuild-wiki':
      source => 'puppet:///modules/ocf_wiki/rebuild-wiki',
      mode   => '0755';

    '/opt/share/webhook/secrets/github.secret':
      source => 'puppet:///private/github.secret',
      group  => www-data,
      mode   => '0640';
  }

  exec { 'rebuild-wiki':
    command   => '/srv/wiki/rebuild-wiki',
    user      => www-data,
    subscribe => File['/srv/wiki/wiki.setup'],
    require   => [
      Package['ikiwiki'],
      File['/srv/wiki/wiki.setup', '/srv/wiki/rebuild-wiki', '/srv/wiki/wiki'],
      Apache::Vhost['wiki.ocf.berkeley.edu']];
  }

  ocf::webhook { '/srv/wiki/webhook/github.cgi':
    service    => 'github',
    secretfile => '/opt/share/webhook/secrets/github.secret',
    command    => '/srv/wiki/rebuild-wiki';
  }

  class { '::apache':
    default_vhost => false;
  }

  apache::vhost {
    'wiki.ocf.berkeley.edu-redirect':
      servername      => 'wiki.ocf.berkeley.edu',
      serveraliases   => ['wiki'],
      port            => 80,
      docroot         => '/var/www',
      redirect_status => 301,
      redirect_dest   => 'https://wiki.ocf.berkeley.edu/';

    'wiki.ocf.berkeley.edu':
      servername      => 'wiki.ocf.berkeley.edu',
      port            => 443,
      docroot         => '/srv/wiki/public_html',

      aliases => [{
        alias => '/webhook',
        path  => '/srv/wiki/webhook'
      }],

      directories => [{
        path        => '/srv/wiki/webhook',
        options     => ['ExecCGI'],
        addhandlers => [{
          handler    => 'cgi-script',
          extensions => ['.cgi']
        }]
      }],

      ssl             => true,
      ssl_key         => "/etc/ssl/private/${::fqdn}.key",
      ssl_cert        => "/etc/ssl/private/${::fqdn}.crt",
      ssl_chain       => '/etc/ssl/certs/incommon-intermediate.crt',

      headers         => 'set Strict-Transport-Security "max-age=31536000"';
  }
}
