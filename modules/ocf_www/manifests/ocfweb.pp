class ocf_www::ocfweb {
  include ocf_ssl
  package {
    'ocfweb':
      ensure  => latest,
      require => [
        Package['redis-server'],
        Exec['ocfweb: apt-get update'],
        Augeas['/etc/redis/redis.conf'],
      ],
      # restart redis when we push to invalidate cache and sessions
      notify  => Service['redis-server'];

    'redis-server':;
  }

  # Redis config for caching and sessions.
  augeas { '/etc/redis/redis.conf':
    lens    => 'Spacevars.simple_lns',
    incl    => '/etc/redis/redis.conf',
    changes => [
      # no persistence, in-memory only
      'set appendonly no',
      'rm save',
    ],
    require => Package['redis-server'],
    notify  => Service['redis-server'];
  }

  service { 'redis-server':
    require => Package['redis-server'];
  }

  exec { 'ocfweb: apt-get update':
    command => 'apt-get update';
  }
  service { 'ocfweb':
    require => Package['ocfweb'];
  }

  class { 'nginx':
    manage_repo => false,
    confd_purge => true,
    vhost_purge => true,
  }

  nginx::resource::upstream { 'ocfweb':
    members => ['localhost:8000'];
  }

  nginx::resource::vhost {
    # proxy to ocfweb running on localhost:8000;
    # this is intended to be accessed only by death, not by the public
    'ocfweb.ocf.berkeley.edu':
      server_name => ['ocfweb.ocf.berkeley.edu', 'ocfweb'],

      proxy            => 'http://ocfweb',
      proxy_set_header => [
        'X-Forwarded-Proto https',
        'X-Forwarded-For $proxy_add_x_forwarded_for',
        'Host $host'
      ],

      listen_port      => 8001;

    # serve static assets to the public (not death)
    'static.ocf.berkeley.edu':
      www_root => '/usr/share/ocfweb/static',

      server_name => ['static.ocf.berkeley.edu'],

      ssl         => true,
      ssl_cert    => "/etc/ssl/private/${::fqdn}.bundle",
      ssl_key     => "/etc/ssl/private/${::fqdn}.key",
      ssl_dhparam => '/etc/ssl/dhparam.pem',

      add_header  => {
        'Strict-Transport-Security'   => 'max-age=31536000',
        'Access-Control-Allow-Origin' => '*',
      },

      listen_port      => 443,
      rewrite_to_https => true;
  }

  # TODO: stop copy-pasting this everywhere
  $redis_password = file('/opt/puppet/shares/private/create/redis-password')
  validate_re($redis_password, '^[a-zA-Z0-9]*$', 'Bad Redis password')
  $django_secret = file("/opt/puppet/shares/private/${::hostname}/django-secret")
  validate_re($django_secret, '^[a-zA-Z0-9]*$', 'Bad Django secret')
  $ocfmail_password = file("/opt/puppet/shares/private/${::hostname}/ocfmail-password")
  validate_re($ocfmail_password, '^[a-zA-Z0-9]*$', 'Bad ocfmail password')

  $broker = "redis://:${redis_password}@localhost:6378"
  $backend = $broker

  augeas { '/etc/ocfweb/ocfweb.conf':
    lens      => 'Puppet.lns',
    incl      => '/etc/ocfweb/ocfweb.conf',
    changes   =>  [
      "set django/secret ${django_secret}",
      "set celery/broker ${broker}",
      "set celery/backend ${backend}",
      'set ocfmail/user ocfmail',
      "set ocfmail/password ${ocfmail_password}",
      'set ocfmail/db ocfmail',
    ],
    show_diff => false,
    notify    => Service['ocfweb'],
    require   => Package['ocfweb'];
  }

  # create redis
  spiped::tunnel::client { 'create-redis':
    source  => 'localhost:6378',
    dest    => 'create:6379',
    secret  => file('/opt/puppet/shares/private/create/spiped-key');
  }
}
